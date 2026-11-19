import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/general_payment_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final VehicleCategory serviceType;
  final LatLng? destination;
  final LatLng? pickup;
  final int? rideId;
  final bool? isScheduled;

  const OrderDetailsScreen({
    super.key,
    this.rideId,
    required this.serviceType,
    this.destination,
    this.pickup,
    this.isScheduled,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  String orderNo = '';
  String deliveryAddress = '';
  String scheduledFor = '';
  double totalAmount = 0.0;
  String paymentStatus = 'Pending';
  String status = 'Pending';
  String quantity = '0';
  VehicleCategory? serviceType;
  List<Map<String, String>> trucks = [];
  LatLng? selectedLatLng;
  Timer? _timer;

  Duration? _timeRemaining;
  Timer? _countdownTimer;

  bool isAssigning = false;
  List<String> backendCancelReasons = [];
  DateTime? _requestedAt;
  bool isCancellingFlow = false;
  bool wantsAnotherTruck = false;
  Timer? _statusPollingTimer;
  bool _isFetchingStatus = false;

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      selectedLatLng = widget.destination!;
    }
    if (widget.rideId != null) {
      //fetchOrderDetails();
      fetchOrderDetails().then((_) {
        _handleScheduledPendingExit();
        _startSmartStatusPolling();
        _startCountdown();
        // ✅ check right after fetching
      });
      _startAutoAssignCheck();
      _loadCancellationReasons();
    } else {
      setState(() {
        hasError = true;
        errorMessage = 'Invalid order ID.';
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    if (scheduledFor.isEmpty) return;

    try {
      final scheduledTime = DateTime.parse(scheduledFor);

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        final diff = scheduledTime.difference(now);

        if (!mounted) return;

        setState(() {
          _timeRemaining = diff.isNegative ? Duration.zero : diff;
        });
      });
    } catch (_) {}
  }

  void _startSmartStatusPolling() {
    _statusPollingTimer?.cancel();

    _statusPollingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (!mounted) return;
      if (_isFetchingStatus) return;

      _isFetchingStatus = true;

      try {
        await fetchOrderDetailsSilent();

        // 🛑 Stop polling on terminal states
        if ((status == "Completed" && paymentStatus == "Paid") ||
            status == "Cancelled") {
          _statusPollingTimer?.cancel();
        }
      } catch (_) {
        // fail silently (network hiccup safe)
      } finally {
        _isFetchingStatus = false;
      }
    });
  }

  void _payCash() async {
    Navigator.pop(context); // close modal
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/cashpayment/${widget.rideId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': totalAmount}),
      );

      if (response.statusCode == 200) {
        setState(() {
          paymentStatus = "Paid";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Payment received in cash")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Failed to update cash payment")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  String formatAddress(String address) {
    if (address.isEmpty) return "-";

    final parts = address.split(',');

    if (parts.isEmpty) return address;

    // Take only first 1–2 meaningful parts
    if (parts.length >= 2) {
      return "${parts[0]}, ${parts[1]}";
    }

    return parts[0];
  }

  void _payMpesa() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => GeneralPaymentScreen(
              serviceType: serviceType!,
              amount: totalAmount,
              rideId: widget.rideId,
            ),
      ),
    );
  }

  void _payWallet() async {
    Navigator.pop(context);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/walletpayment/${widget.rideId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': totalAmount}),
      );

      if (response.statusCode == 200) {
        setState(() {
          paymentStatus = "Paid";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Payment deducted from wallet")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Wallet payment failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  void _payVisa() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Visa payment coming soon")),
    );
  }

  Future<bool> _handleScheduledPendingExit() async {
    if (scheduledFor.isEmpty) return false;

    try {
      final referenceTime = DateTime.parse(scheduledFor);
      final now = DateTime.now();
      final minutesPassed = now.difference(referenceTime).inMinutes;

      /// 🔵 REQUESTED → valid for 5 mins
      if (status == "Requested") {
        if (minutesPassed <= 5) return false;

        await cancelServiceBooking("No truck found");
        return true;
      }

      /// 🟣 SCHEDULED → valid until +5 mins
      if (status == "Scheduled") {
        if (minutesPassed <= 5) return false;

        await cancelServiceBooking("No truck found");
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<void> _loadCancellationReasons() async {
    final reasons = await fetchCancellationReasons();

    if (!mounted) return;

    setState(() {
      backendCancelReasons = _filteredCancelReasons(reasons);
    });
  }

  bool get canCancelRide {
    switch (status) {
      case "Requested":
      case "Pending":
      //case "DriverAssigned":
      case "Scheduled":
        return true;
      default:
        return false;
    }
  }

  String get serviceName {
    switch (widget.serviceType) {
      case VehicleCategory.waterBowser:
        return "Water Bowser";
      case VehicleCategory.exhauster:
        return "Exhauster";
      default:
        return "Service Vehicle";
    }
  }

  List<String> _filteredCancelReasons(List<String> backendReasons) {
    return backendReasons
        .where(
          (r) =>
              r == 'Changed my mind' ||
              r == 'Found alternative transport' ||
              r == 'Incorrect location' ||
              r == 'Other' ||
              r == 'Driver delayed' ||
              r == 'No truck found',
        )
        .map((r) => r == 'Driver delayed' ? 'Taking too long' : r)
        .toList();
  }

  Future<void> cancelServiceBooking(String reason) async {
    final endpoint =
        widget.serviceType == VehicleCategory.exhauster
            ? '$baseUrl/passengerrides/exhauster/cancel/${widget.rideId}'
            : '$baseUrl/passengerrides/waterbowser/cancel/${widget.rideId}';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      //body: reason, // 👈 IMPORTANT CHANGE
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel ride: ${response.body}');
    }
  }

  Future<void> _cancelCompletely(String reason) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⏳ Cancelling ride, please wait..."),
        duration: Duration(seconds: 5),
      ),
    );

    try {
      await cancelServiceBooking(reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Ride cancelled successfully")),
      );

      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
      //   (_) => false,
      // );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransportServicesScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Failed to cancel booking: $e")),
      );
    }
  }

  void _requestAnotherTruck() {
    setState(() {
      wantsAnotherTruck = true;
      isCancellingFlow = false;
      trucks.clear();
      status = "Pending"; // or "Reassigning" if backend supports
    });

    _startAutoAssignCheck();
  }

  IconData get serviceIcon {
    switch (widget.serviceType) {
      case VehicleCategory.waterBowser:
        return Icons.water_drop;
      case VehicleCategory.exhauster:
        return Icons.delete_outline;
      default:
        return Icons.local_shipping;
    }
  }

  String get quantityLabel {
    switch (widget.serviceType) {
      case VehicleCategory.waterBowser:
        return "Water Quantity";
      case VehicleCategory.exhauster:
        return "Waste Volume";
      default:
        return "Quantity";
    }
  }

  void _startAutoAssignCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;

      if (isCancellingFlow || isAssigning) return;

      // 🔴 FIRST: expiry check
      final expired = await _handleScheduledPendingExit();

      if (expired) {
        _timer?.cancel();

        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
            (_) => false,
          );
        });
        return;
      }

      // stop if assigned
      if (trucks.isNotEmpty) {
        _timer?.cancel();
        return;
      }

      // only auto-assign REQUESTED
      if (status != "Requested") return;

      // 🟢 assign
      isAssigning = true;
      try {
        await _assignDriver();
      } finally {
        isAssigning = false;
      }
    });
  }

  Future<List<String>> fetchCancellationReasons() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/passengerrides/cancellation/reasons'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<String> descriptions =
            data
                .map((item) => item['description']?.toString() ?? '')
                .where((desc) => desc.isNotEmpty)
                .toList();

        return descriptions;
      } else {
        debugPrint('Failed to load reasons: ${response.statusCode}');
        return ["Driver delayed", "Changed my mind", "Other"]; // fallback
      }
    } catch (e) {
      debugPrint("Error fetching cancellation reasons: $e");
      return ["Driver delayed", "Changed my mind", "Other"]; // fallback
    }
  }

  Future<void> cancelRide(String rideId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/passengerrides/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rideId': rideId, 'reason': reason}),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final realRideRef = FirebaseDatabase.instance.ref(
          "rides/${result['rideId']}",
        );

        //final realRideRef = passengerDb.ref("rides/${data['rideId']}");
        // final snapshot = await realRideRefg.get();
        await realRideRef.update({
          "status": "cancelled",
          "cancelledTime": DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Ride cancelled successfully")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => TransportServicesScreen()),
          (route) => false,
        );
      } else {
        final data = jsonDecode(response.body);
        final msg = data['message'] ?? "Failed to cancel ride";

        // ✅ Gracefully handle "already cancelled/completed"
        if (msg.contains("already completed") || msg.contains("cancelled")) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("⚠️ $msg")));

          // Still redirect to TransportServicesScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => TransportServicesScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("❌ $msg")));
        }
      }
    } catch (e) {
      print("Exception cancelling ride: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Something went wrong.")));
    }
  }

  Future<void> fetchOrderDetailsSilent() async {
    try {
      final int categoryType = widget.serviceType.index;

      final response = await http.get(
        Uri.parse('$baseUrl/passengerrides/${widget.rideId}/$categoryType'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      status = data['status'];
      if (status == "Requested" && _requestedAt == null) {
        _requestedAt = DateTime.now();
      }

      paymentStatus = data['paymentStatus'] ?? paymentStatus;

      //final truck = data['truck'];

      final truck =
          data['truck'] ??
          data['vehicle'] ??
          data['assignedVehicle'] ??
          data['assignedExhauster'];

      trucks.clear();

      if (truck != null) {
        trucks.add({
          'rideId': truck['rideId']?.toString() ?? '-',
          'number': truck['number']?.toString() ?? '-',
          'status': truck['status']?.toString() ?? '-',
          'driverName': truck['driverName'] ?? '-',
          'driverId': truck['driverId'] ?? '-',
        });
      }

      if (mounted) setState(() {});
    } catch (_) {
      // silent fail
    }
  }

  Future<void> _assignDriver() async {
    if (widget.rideId == null) return;

    isAssigning = true;

    try {
      final endpoint =
          widget.serviceType == VehicleCategory.exhauster
              ? '$baseUrl/passengerrides/exhauster/assigndriver/${widget.rideId}'
              : '$baseUrl/passengerrides/waterbowser/assigndriver/${widget.rideId}';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchOrderDetailsSilent(); // 👈 NO SCREEN RELOAD
      }
    } finally {
      isAssigning = false;
    }
  }

  Future<void> fetchOrderDetails() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final int categoryType = widget.serviceType.index;

      final response = await http.get(
        Uri.parse('$baseUrl/passengerrides/${widget.rideId}/$categoryType'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        setState(() {
          hasError = true;
          errorMessage = "This ride has already been completed.";
        });
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final double destLat =
            (data['destinationLat'] as num?)?.toDouble() ?? 0.0;
        final double destLng =
            (data['destinationLng'] as num?)?.toDouble() ?? 0.0;
        selectedLatLng = LatLng(destLat, destLng);

        final serviceTypeValue = data['serviceType'];
        status = data['status'];
        serviceType = VehicleCategory.values.firstWhere((e) {
          if (serviceTypeValue is String) {
            return e.name.toLowerCase() == serviceTypeValue.toLowerCase();
          } else if (serviceTypeValue is int) {
            return e.index == serviceTypeValue;
          }
          return false;
        }, orElse: () => VehicleCategory.passenger);

        //final truck = data['truck'];

        final truck =
            data['truck'] ??
            data['vehicle'] ??
            data['assignedVehicle'] ??
            data['assignedExhauster'];

        trucks = [];
        if (truck != null) {
          trucks.add({
            'rideId': truck['rideId']?.toString() ?? '-',
            'number': truck['number']?.toString() ?? '-',
            'status': truck['status']?.toString() ?? '-',
            'driverName': truck['driverName'] ?? '-',
            'driverId': truck['driverId'] ?? '-',
          });
        }

        setState(() {
          orderNo = data['orderNo']?.toString() ?? '-';
          deliveryAddress = data['deliveryAddress']?.toString() ?? '-';
          scheduledFor = data['scheduledFor']?.toString() ?? '-';
          totalAmount = (data['totalAmount'] ?? 0).toDouble();
          paymentStatus = data['paymentStatus']?.toString() ?? 'Pending';
          quantity = data['serviceType']?.toString() ?? 'N/A';
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage =
              'Failed to fetch order details (Status ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _timer?.cancel();
    _countdownTimer?.cancel(); // ✅ ADD THIS
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hasError) {
      return Scaffold(body: Center(child: Text(errorMessage)));
    }

    final rideStatus = status; // backend string e.g. "Completed"

    final bool isPaid = paymentStatus.toLowerCase() == "paid";

    final bool isAssigned =
        rideStatus == "DriverAssigned" ||
        rideStatus == "OnTheWay" ||
        rideStatus == "InProgress" ||
        rideStatus == "Completed";

    final bool isDelivered = rideStatus == "Completed";

    final bool canPay = isDelivered && !isPaid;

    return WillPopScope(
      onWillPop: () async {
        // Instead of going back, redirect to NavigationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
        );
        return false; // prevent default back navigation
      },
      // child: Scaffold(
      //   backgroundColor: Colors.white,
      //   appBar: AppBar(
      //     title: const Text("Order Details"),
      //     centerTitle: true,
      //     backgroundColor: Color(0xFF015ACE),
      //     foregroundColor: Colors.white,
      //     elevation: 0,
      //     leading: IconButton(
      //       icon: const Icon(Icons.arrow_back),
      //       onPressed: () {
      //         // Same behavior for app bar back button
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(
      //             builder: (_) => const TransportServicesScreen(),
      //           ),
      //         );
      //       },
      //     ),
      //   ),
      //   body: SafeArea(
      //     child: SingleChildScrollView(
      //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           _buildCard(
      //             title: "🧾 Order Details",
      //             color: Colors.white,
      //             children: [
      //               _buildRow("Order No:", orderNo),
      //               _buildRow("Address:", formatAddress(deliveryAddress)),
      //               //_buildRow("Delivery Address:", deliveryAddress),
      //               _buildRow("Scheduled For:", scheduledFor),

      //               //_buildRow("Quantity:", quantity),
      //               _buildRow("$quantityLabel:", quantity),
      //               _buildRow(
      //                 "Total Amount:",
      //                 "KES ${totalAmount.toStringAsFixed(2)}",
      //                 //valueColor: Colors.black87,
      //               ),
      //               _buildRow(
      //                 "Payment Status:",
      //                 paymentStatus,
      //                 // valueColor: isPaid ? Colors.green : Colors.red,
      //               ),
      //             ],
      //           ),
      //           const SizedBox(height: 24),

      //           _buildStatusCard(),
      //           const SizedBox(height: 20),

      //           //if (canCancelRide) _cancelBookingButton(backendCancelReasons),
      //           const SizedBox(height: 20),

      //           //if (!isAssigned) _buildWaitingForTruckCard(),
      //           if (isAssigned)
      //             _buildCard(
      //               // title: "🚛 Assigned Truck",
      //               title: "Assigned $serviceName",

      //               color: Colors.lightBlue.shade50,
      //               children:
      //                   trucks.map((truck) => _buildTruckTile(truck)).toList(),
      //             ),

      //           // if (isPaid && trucks.isNotEmpty)
      //           //   _buildCard(
      //           //     title: "🚛 Assigned Trucks",
      //           //     color: Colors.lightBlue.shade50,
      //           //     children:
      //           //         trucks.map((truck) => _buildTruckTile(truck)).toList(),
      //           //   ),
      //           // if (!isPaid)
      //           if (canCancelRide) _cancelBookingButton(backendCancelReasons),
      //           if (canPay)
      //             Padding(
      //               padding: const EdgeInsets.only(top: 24),
      //               child: SizedBox(
      //                 width: double.infinity,
      //                 child: ElevatedButton.icon(
      //                   // onPressed: () {
      //                   //   Navigator.push(
      //                   //     context,
      //                   //     MaterialPageRoute(
      //                   //       builder:
      //                   //           (_) => GeneralPaymentScreen(
      //                   //             serviceType: serviceType!,
      //                   //             amount: totalAmount,
      //                   //             rideId: widget.rideId,
      //                   //           ),
      //                   //     ),
      //                   //   );
      //                   // },
      //                   onPressed: _showPaymentOptionsDialog,
      //                   icon: const Icon(Icons.payment),
      //                   label: const Text("Make Payment"),
      //                   style: ElevatedButton.styleFrom(
      //                     backgroundColor: Color(0xFF015ACE),
      //                     foregroundColor: Colors.white,
      //                     padding: const EdgeInsets.symmetric(vertical: 16),
      //                     textStyle: const TextStyle(
      //                       fontSize: 18,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                     shape: RoundedRectangleBorder(
      //                       borderRadius: BorderRadius.circular(12),
      //                     ),
      //                   ),
      //                 ),
      //               ),
      //             ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),


      
child: Scaffold(
  backgroundColor: const Color(0xFFF7F9FC),
  appBar: AppBar(
    title: Text(
      "Order Details",
      style: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    centerTitle: true,
    backgroundColor: const Color(0xFF015ACE),
    foregroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TransportServicesScreen(),
          ),
        );
      },
    ),
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ORDER DETAILS
          _buildCard(
            title: "Order Details",
            color: Colors.white,
            children: [
              _buildRow("Order No.", orderNo),
              _buildRow(
                "Delivery Address",
                formatAddress(deliveryAddress),
              ),
              _buildRow("Scheduled For", scheduledFor),
              _buildRow("$quantityLabel", quantity),
              _buildRow(
                "Total Amount",
                "KES ${totalAmount.toStringAsFixed(2)}",
              ),
              _buildRow("Payment Status", paymentStatus),
            ],
          ),

          const SizedBox(height: 16),

          // ORDER STATUS
          _buildStatusCard(),

          const SizedBox(height: 16),

          // ASSIGNED VEHICLE
          if (isAssigned)
            _buildCard(
              title: "Assigned $serviceName",
              color: const Color(0xFFF0F7FF),
              children: trucks
                  .map((truck) => _buildTruckTile(truck))
                  .toList(),
            ),

          if (isAssigned) const SizedBox(height: 16),

          // CANCEL ORDER
          if (canCancelRide) ...[
            _cancelBookingButton(backendCancelReasons),
            const SizedBox(height: 12),
          ],

          // PAYMENT
          if (canPay)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE8EEF6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Complete your payment",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Pay securely to proceed with your order.",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: const Color(0xFF778399),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _showPaymentOptionsDialog,
                      icon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 17,
                      ),
                      label: Text(
                        "Make Payment",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF015ACE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  ),
),

    );
  }

  void _showPaymentOptionsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose Payment Method",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _paymentOptionButton("Cash", Icons.money, _payCash),
                const SizedBox(height: 12),
                _paymentOptionButton("Mpesa", Icons.phone_android, _payMpesa),
                const SizedBox(height: 12),
                _paymentOptionButton(
                  "Wallet",
                  Icons.account_balance_wallet,
                  _payWallet,
                ),
                const SizedBox(height: 12),
                _paymentOptionButton(
                  "Visa",
                  Icons.credit_card,
                  _payVisa,
                  enabled: false,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _paymentOptionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? Color(0xFF015ACE) : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cancelBookingButton(List<String> backendReasons) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ), //const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF015ACE),
              foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showCancelDialog(backendReasons),
          child: const Text(
            "Cancel Booking",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    required Color color,
  }) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Divider(thickness: 1.2),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  
Widget _buildRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8491A5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF243247),
            ),
          ),
        ),
      ],
    ),
  );
}


  
Widget _buildStatusCard() {
  switch (status) {
    case "Requested":
      return _infoCard(
        "Request received. Looking for available $serviceName",
        icon: Icons.search_rounded,
        color: const Color(0xFFEAF3FF),
      );

    case "Pending":
      return _infoCard(
        "$serviceName booking pending confirmation",
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFFFF7E8),
      );

    case "DriverAssigned":
      return _infoCard(
        "$serviceName assigned. Preparing for service",
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFFEAF3FF),
      );

    case "OnTheWay":
      return _infoCard(
        "$serviceName is on the way",
        icon: Icons.delivery_dining_rounded,
        color: const Color(0xFFEAF3FF),
      );

    case "InProgress":
      return _infoCard(
        widget.serviceType == VehicleCategory.waterBowser
            ? "Delivering water"
            : "Service in progress",
        icon: Icons.sync_rounded,
        color: const Color(0xFFEAF3FF),
      );

    case "Completed":
      return _infoCard(
        widget.serviceType == VehicleCategory.waterBowser
            ? "Water delivered. Please make payment"
            : "Service completed. Please make payment",
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFFE9F8F0),
      );

    case "Cancelled":
      return _infoCard(
        "$serviceName booking was cancelled",
        icon: Icons.cancel_outlined,
        color: const Color(0xFFF2F3F5),
      );

    case "Scheduled":
      return _scheduledCard();

    default:
      return const SizedBox.shrink();
  }
}


  
Widget _infoCard(
  String message, {
  IconData? icon,
  Color? color,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 15,
      vertical: 16,
    ),
    decoration: BoxDecoration(
      color: color ?? const Color(0xFFF0F7FF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE5EDF7),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon ?? serviceIcon,
            color: const Color(0xFF015ACE),
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF243247),
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}



  // Widget _buildWaitingForTruckCard() {
  //   //final state = _waitingCardState();

  //   //if (state.message.isEmpty) return const SizedBox();

  //   return Card(
  //     elevation: 3,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Row(
  //         children: [
  //           if (state.showSpinner) ...[
  //             const CircularProgressIndicator(),
  //             const SizedBox(width: 14),
  //           ],
  //           Expanded(
  //             child: Text(
  //               state.message,
  //               style: const TextStyle(
  //                 fontSize: 17,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ({bool showSpinner, String message}) _waitingCardState() {
  //   if (trucks.isNotEmpty || isCancellingFlow) {
  //     return (showSpinner: false, message: "");
  //   }

  //   final now = DateTime.now();
  //   DateTime? referenceTime;

  //   if (scheduledFor.isNotEmpty) {
  //     try {
  //       referenceTime = DateTime.parse(scheduledFor);
  //     } catch (_) {}
  //   }

  //   // 🔵 REQUESTED
  //   // if (status == "Requested") {
  //   //   return (
  //   //     showSpinner: true,
  //   //     message: "Kindly wait as we assign your $serviceName",
  //   //   );
  //   // }

  //   // // 🟣 SCHEDULED
  //   // if (status == "Scheduled" && referenceTime != null) {
  //   //   // final minutesDiff = referenceTime.difference(now).inMinutes;

  //   //   // // within 5 min window → assigning
  //   //   // if (minutesDiff <= 5) {
  //   //   //   return (
  //   //   //     showSpinner: true,
  //   //   //     message: "Kindly wait, we are assigning your $serviceName",
  //   //   //   );
  //   //   // }

  //   //   // scheduled later
  //   //   return (
  //   //     showSpinner: false,
  //   //     message:
  //   //         "Your $serviceName will be assigned at "
  //   //         "${referenceTime.hour}:${referenceTime.minute.toString().padLeft(2, '0')}",
  //   //   );
  //   // }

  //   return (showSpinner: false, message: "");
  // }

  Widget _buildTruckTile(Map<String, String> truck) {
    Color statusColor;
    switch (truck['status']?.toLowerCase()) {
      case 'driverassigned':
        statusColor = Colors.blueAccent;
        break;
      case 'inprogress':
        statusColor = Colors.orangeAccent;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;

        Text(
          "Truck: ${truck['number'] ?? '-'}",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        );
        Text(
          "Driver: ${truck['driverName'] ?? '-'}",
          style: const TextStyle(color: Colors.black87, fontSize: 15),
        );
        Text(
          "Phone: ${truck['driverPhone'] ?? '-'}",
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        );
    }

    return InkWell(
      onTap: () {
        if (truck['status']?.toLowerCase() == 'inprogress') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => RideInProgressLiveScreen(
                    rideId: truck['rideId'].toString(),
                    destination: selectedLatLng,
                    driverId: truck['driverId'] ?? '-',
                  ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor,
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ride ID: ${truck['rideId'] ?? '-'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Driver: ${truck['driverName'] ?? '-'}",
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                  Text(
                    "Status: ${truck['status'] ?? '-'}",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (truck['status']?.toLowerCase() == 'inprogress')
              const Icon(Icons.navigation, color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _scheduledCard() {
    String countdownText = "";

    if (_timeRemaining != null) {
      final hours = _timeRemaining!.inHours;
      final minutes = _timeRemaining!.inMinutes % 60;
      final seconds = _timeRemaining!.inSeconds % 60;

      countdownText =
          "${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.orange),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scheduled Ride",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  "Starts at $scheduledFor",
                  style: const TextStyle(fontSize: 16),
                ),

                if (countdownText.isNotEmpty)
                  Text(
                    "⏳ Starts in $countdownText",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: IconButton(
            icon: Icon(icon, color: Colors.black),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  void _showCancelDialog(List<String> backendReasons) {
    final reasons = _filteredCancelReasons(backendReasons);

    setState(() {
      isCancellingFlow = true;
    });

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Cancel Booking",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...reasons.map(
                    (reason) => Card(
                      child: ListTile(
                        title: Text(reason),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _askCancelDecision(reason);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _askCancelDecision(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.help_outline, size: 48, color: Colors.blue),
                  const SizedBox(height: 12),
                  const Text(
                    "What would you like to do?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "We can try assigning another truck, or cancel this booking completely.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Cancel Booking"),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _cancelCompletely(reason);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Assign Another Truck"),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _requestAnotherTruck();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}


  // void _showCancelDialog(List<String> backendReasons) {
  //   final reasons = _filteredCancelReasons(backendReasons);
  //   bool _isCancelling = false;

  //   showDialog(
  //     context: context,
  //     builder:
  //         (dialogContext) => AlertDialog(
  //           title: const Text("Cancel Booking"),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children:
  //                 reasons
  //                     .map(
  //                       (r) => ListTile(
  //                         title: Text(r),
  //                         onTap: () async {
  //                           if (_isCancelling) return;

  //                           _isCancelling = true;
  //                           Navigator.pop(dialogContext);

  //                           try {
  //                             await cancelServiceBooking(r);
  //                             if (!mounted) return;
  //                             setState(() {});
  //                           } finally {
  //                             _isCancelling = false;
  //                           }
  //                         },
  //                       ),
  //                     )
  //                     .toList(),
  //           ),
  //         ),
  //   );
  // }
  // void _showCancelDialog(BuildContext context) async {
  //   final reasons = await fetchCancellationReasons();
  //   if (!mounted) return;

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //     ),
  //     builder: (ctx) {
  //       return DraggableScrollableSheet(
  //         initialChildSize: 0.5,
  //         minChildSize: 0.4,
  //         maxChildSize: 0.9,
  //         expand: false,
  //         builder: (_, scrollController) {
  //           return Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 40,
  //                     height: 4,
  //                     margin: const EdgeInsets.only(bottom: 16),
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[400],
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ),
  //                 ),
  //                 const Center(
  //                   child: Text(
  //                     "Why do you want to cancel?",
  //                     style: TextStyle(
  //                       fontSize: 20,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Expanded(
  //                   child: ListView.builder(
  //                     controller: scrollController,
  //                     itemCount: reasons.length,
  //                     itemBuilder: (ctx, index) {
  //                       final reason = reasons[index];
  //                       return Card(
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                         color: Colors.red[50],
  //                         child: ListTile(
  //                           title: Text(
  //                             reason,
  //                             style: const TextStyle(color: Colors.black),
  //                           ),
  //                           onTap: () async {
  //                             Navigator.of(
  //                               ctx,
  //                             ).pop(); // close bottom sheet first

  //                             final shouldReassign = await showDialog<bool>(
  //                               context: context,
  //                               builder:
  //                                   (dialogCtx) => AlertDialog(
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(16),
  //                                     ),
  //                                     title: const Text(
  //                                       "Cancel Ride",
  //                                       style: TextStyle(
  //                                         fontWeight: FontWeight.bold,
  //                                       ),
  //                                     ),
  //                                     content: Text(
  //                                       "Reason: $reason\n\nShould the rider wait for another driver?",
  //                                       style: const TextStyle(fontSize: 16),
  //                                     ),
  //                                     actions: [
  //                                       TextButton.icon(
  //                                         icon: const Icon(
  //                                           Icons.close,
  //                                           color: Colors.red,
  //                                         ),
  //                                         label: const Text("No"),
  //                                         onPressed: () async {
  //                                           Navigator.of(dialogCtx).pop(false);
  //                                           await cancelRide(
  //                                             widget.rideId.toString(),
  //                                             reason,
  //                                           );
  //                                           if (mounted) {
  //                                             ScaffoldMessenger.of(
  //                                               context,
  //                                             ).showSnackBar(
  //                                               const SnackBar(
  //                                                 content: Text(
  //                                                   "Ride cancelled.",
  //                                                 ),
  //                                               ),
  //                                             );
  //                                           }
  //                                         },
  //                                       ),
  //                                       ElevatedButton.icon(
  //                                         icon: const Icon(Icons.refresh),
  //                                         label: const Text("Yes"),

  //                                         // onPressed: () async {
  //                                         //   Navigator.of(dialogCtx).pop(true);
  //                                         //   await _assignDriver(
  //                                         //     // widget.rideId.toString(),
  //                                         //     // reason,
  //                                         //   );
  //                                         //   if (mounted) {
  //                                         //     ScaffoldMessenger.of(
  //                                         //       context,
  //                                         //     ).showSnackBar(
  //                                         //       const SnackBar(
  //                                         //         content: Text(
  //                                         //           "Driver reassigned.",
  //                                         //         ),
  //                                         //       ),
  //                                         //     );
  //                                         //   }
  //                                         // },
  //                                         onPressed: () async {
  //                                           Navigator.of(dialogCtx).pop(true);

  //                                           // Step 1: Cancel current ride
  //                                           await cancelRide(
  //                                             widget.rideId.toString(),
  //                                             reason,
  //                                           );

  //                                           // Step 2: Reassign new driver
  //                                           await _assignDriver();

  //                                           if (mounted) {
  //                                             ScaffoldMessenger.of(
  //                                               context,
  //                                             ).showSnackBar(
  //                                               const SnackBar(
  //                                                 content: Text(
  //                                                   "🔄 New driver is being assigned",
  //                                                 ),
  //                                               ),
  //                                             );
  //                                           }
  //                                         },
  //                                       ),
  //                                     ],
  //                                   ),
  //                             );

  //                             // ⚡ Do not force pop parent screen,
  //                             // let backend actions decide redirection
  //                             if (shouldReassign == null) return;
  //                           },
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // void _showCancelDialog(List<String> backendReasons) {
  //   final reasons = _filteredCancelReasons(backendReasons);

  //   showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text("Cancel Booking"),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children:
  //                 reasons
  //                     .map(
  //                       (r) => ListTile(
  //                         title: Text(r),
  //                         onTap: () async {
  //                           Navigator.pop(context);
  //                           await cancelServiceBooking(r);
  //                           if (mounted) setState(() {});
  //                         },
  //                       ),
  //                     )
  //                     .toList(),
  //           ),
  //         ),
  //   );
  // }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Vehicles/general_payment_screen.dart';

// class OrderDetailsScreen extends StatefulWidget {
//   final VehicleCategory serviceType;
//   final LatLng? destination;
//   final int? rideId;

//   const OrderDetailsScreen({
//     super.key,
//     this.rideId,
//     required this.serviceType,
//     this.destination,
//   });

//   @override
//   State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
// }

// class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
//   bool isLoading = true;
//   bool hasError = false;
//   String errorMessage = '';

//   String orderNo = '';
//   String deliveryAddress = '';
//   String scheduledFor = '';
//   double totalAmount = 0.0;
//   String paymentStatus = 'Pending';
//   VehicleCategory? serviceType;
//   List<Map<String, String>> trucks = [];
//   LatLng? selectedLatLng;
//   //List<Map<String, String>>? trucks;
//   @override
//   void initState() {
//     super.initState();
//     if (widget.destination != null) {
//       selectedLatLng = widget.destination!;
//     }
//     if (widget.rideId != null) {
//       fetchOrderDetails();
//     } else {
//       setState(() {
//         hasError = true;
//         errorMessage = 'Invalid order ID.';
//       });
//     }
//   }

//   // Future<void> fetchOrderDetails() async {
//   //   setState(() {
//   //     isLoading = true;
//   //   });

//   //   try {
//   //     final response = await http.get(
//   //       Uri.parse('$baseUrl/passengerrides/${widget.orderId}'),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final data = jsonDecode(response.body);
//   //       serviceType = VehicleCategory.values.firstWhere((e) {
//   //         final serviceTypeValue = data['serviceType'];
//   //         if (serviceTypeValue is String) {
//   //           return e.name.toLowerCase() == serviceTypeValue.toLowerCase();
//   //         } else if (serviceTypeValue is int) {
//   //           return e.index == serviceTypeValue;
//   //         }
//   //         return false;
//   //       }, orElse: () => VehicleCategory.passenger);

//   //       // trucks =
//   //       //     (data['trucks'] as List<dynamic>?)
//   //       //         ?.map(
//   //       //           (t) => {
//   //       //             'rideId': t['rideId'].toString(),
//   //       //             'number': t['number'].toString(),
//   //       //             'status': t['status'].toString(),
//   //       //           },
//   //       //         )
//   //       //         .toList();

//   //       // Check for incomplete trip
//   //       if (data['hasIncompleteTrip'] == true) {
//   //         // Stay on this screen but update the data
//   //         setState(() {
//   //           orderNo = data['orderNo'] ?? '';
//   //           deliveryAddress = data['deliveryAddress'] ?? '';
//   //           scheduledFor = data['scheduledFor'] ?? '';
//   //           totalAmount = (data['totalAmount'] ?? 0).toDouble();
//   //           paymentStatus = data['paymentStatus'] ?? 'Pending';

//   //           //  serviceType = VehicleCategory(data['serviceType']);

//   //           trucks = List<Map<String, String>>.from(data['trucks'] ?? []);
//   //         });
//   //       } else {
//   //         // Redirect to Water Bowser screen or other screen if trip completed
//   //         // Navigator.pushReplacement(...);
//   //       }
//   //     } else {
//   //       setState(() {
//   //         hasError = true;
//   //         errorMessage = 'Failed to fetch order details.';
//   //       });
//   //     }
//   //   } catch (e) {
//   //     setState(() {
//   //       hasError = true;
//   //       errorMessage = e.toString();
//   //     });
//   //   } finally {
//   //     setState(() {
//   //       isLoading = false;
//   //     });
//   //   }
//   // }

//   // Future<void> fetchOrderDetails() async {
//   //   setState(() {
//   //     isLoading = true;
//   //   });

//   //   try {
//   //     final response = await http.get(
//   //       Uri.parse('$baseUrl/passengerrides/${widget.rideId}'),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final data = jsonDecode(response.body);

//   //       // Parse serviceType (handle string or int)
//   //       final serviceTypeValue = data['serviceType'];
//   //       serviceType = VehicleCategory.values.firstWhere((e) {
//   //         if (serviceTypeValue is String) {
//   //           return e.name.toLowerCase() == serviceTypeValue.toLowerCase();
//   //         } else if (serviceTypeValue is int) {
//   //           return e.index == serviceTypeValue;
//   //         }
//   //         return false;
//   //       }, orElse: () => VehicleCategory.passenger);

//   //       // Parse trucks safely
//   //       final rawTrucks = data['trucks'] as List<dynamic>? ?? [];
//   //       trucks =
//   //           rawTrucks.map<Map<String, String>>((t) {
//   //             return {
//   //               'rideId': t['rideId']?.toString() ?? '-',
//   //               'number': t['number']?.toString() ?? '-',
//   //               'status': t['status']?.toString() ?? '-',
//   //             };
//   //           }).toList();

//   //       // Update other UI fields
//   //       setState(() {
//   //         orderNo = data['orderNo']?.toString() ?? '-';
//   //         deliveryAddress = data['deliveryAddress']?.toString() ?? '-';
//   //         scheduledFor = data['scheduledFor']?.toString() ?? '-';
//   //         totalAmount = (data['totalAmount'] ?? 0).toDouble();
//   //         paymentStatus = data['paymentStatus']?.toString() ?? 'Pending';
//   //       });
//   //     } else {
//   //       setState(() {
//   //         hasError = true;
//   //         errorMessage = 'Failed to fetch order details.';
//   //       });
//   //     }
//   //   } catch (e) {
//   //     setState(() {
//   //       hasError = true;
//   //       errorMessage = e.toString();
//   //     });
//   //   } finally {
//   //     setState(() {
//   //       isLoading = false;
//   //     });
//   //   }
//   // }

//   Future<void> fetchOrderDetails() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//       errorMessage = '';
//     });

//     try {
//       // You must also pass categoryType (int)
//       // Example: categoryType = 4 for water bowser, etc.
//       // Ideally, this should come from widget or route argument
//       //final int categoryType = serviceType?.index ?? 0;
//       final int categoryType = widget.serviceType.index;

//       final response = await http.get(
//         Uri.parse('$baseUrl/passengerrides/${widget.rideId}/$categoryType'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 204) {
//         // 204 means completed ride -> redirect or show message
//         setState(() {
//           hasError = true;
//           errorMessage = "This ride has already been completed.";
//         });
//         return;
//       }

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         final double destLat =
//             (data['destinationLat'] as num?)?.toDouble() ?? 0.0;
//         final double destLng =
//             (data['destinationLng'] as num?)?.toDouble() ?? 0.0;

//         selectedLatLng = LatLng(destLat, destLng);

//         // Parse serviceType (can be int or string)
//         final serviceTypeValue = data['serviceType'];
//         serviceType = VehicleCategory.values.firstWhere((e) {
//           if (serviceTypeValue is String) {
//             return e.name.toLowerCase() == serviceTypeValue.toLowerCase();
//           } else if (serviceTypeValue is int) {
//             return e.index == serviceTypeValue;
//           }
//           return false;
//         }, orElse: () => VehicleCategory.passenger);

//         // Parse single truck object (not list anymore)
//         final truck = data['truck'];
//         trucks = [];
//         if (truck != null) {
//           trucks.add({
//             'rideId': truck['rideId']?.toString() ?? '-',
//             'number': truck['number']?.toString() ?? '-',
//             'status': truck['status']?.toString() ?? '-',
//           });
//         }

//         setState(() {
//           orderNo = data['orderNo']?.toString() ?? '-';
//           deliveryAddress = data['deliveryAddress']?.toString() ?? '-';
//           scheduledFor = data['scheduledFor']?.toString() ?? '-';
//           totalAmount = (data['totalAmount'] ?? 0).toDouble();
//           paymentStatus = data['paymentStatus']?.toString() ?? 'Pending';
//         });
//       } else {
//         setState(() {
//           hasError = true;
//           errorMessage =
//               'Failed to fetch order details (Status ${response.statusCode}).';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         hasError = true;
//         errorMessage = 'Error: $e';
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (hasError) {
//       return Scaffold(body: Center(child: Text(errorMessage)));
//     }

//     final bool isPaid = paymentStatus.toLowerCase() == "paid";

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Order Details"),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 1,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildCard(
//                 title: "Order Details",
//                 children: [
//                   _buildRow("Order No:", orderNo),
//                   _buildRow("Delivery Address:", deliveryAddress),
//                   _buildRow("Scheduled For:", scheduledFor),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               _buildCard(
//                 title: "Payment Details",
//                 children: [
//                   _buildRow("Total:", "KES ${totalAmount.toStringAsFixed(2)}"),
//                   _buildRow(
//                     "Payment Status:",
//                     paymentStatus,
//                     valueColor: isPaid ? Colors.green : Colors.redAccent,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               if (isPaid && trucks.isNotEmpty)
//                 Expanded(
//                   child: _buildCard(
//                     title: "Assigned Trucks",
//                     children:
//                         trucks.map((truck) => _buildTruckTile(truck)).toList(),
//                   ),
//                 ),
//               if (!isPaid)
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => GeneralPaymentScreen(
//                                 serviceType: serviceType!,
//                                 amount: totalAmount,
//                                 rideId: widget.rideId,
//                               ),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.payment),
//                     label: const Text("Make Payment"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blueAccent,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       textStyle: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCard({required String title, required List<Widget> children}) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const Divider(height: 20),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRow(String label, String value, {Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 3,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 5,
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: valueColor ?? Colors.black87,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTruckTile(Map<String, String> truck) {
//     Color statusColor;
//     switch (truck['status']?.toLowerCase()) {
//       case 'assigned':
//         statusColor = Colors.blueAccent;
//         break;
//       case 'inprogress':
//         statusColor = Colors.orangeAccent;
//         break;
//       case 'completed':
//         statusColor = Colors.green;
//         break;
//       default:
//         statusColor = Colors.grey;
//     }

//     return InkWell(
//       onTap: () {
//         if (truck['status']?.toLowerCase() == 'inprogress') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) => RideInProgressLiveScreen(
//                     rideId: truck['rideId'].toString(),
//                     destination: selectedLatLng,
//                     //driverName: truck['driverName'] ?? 'Unknown',
//                     driverId: truck['driverId'] ?? '-',
//                   ),
//             ),
//           );
//         }
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundColor: statusColor,
//               child: const Icon(
//                 Icons.local_shipping,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Ride ID: ${truck['rideId'] ?? '-'}",
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   Text(
//                     "Driver: ${truck['driverName'] ?? '-'}",
//                     style: const TextStyle(color: Colors.black87),
//                   ),
//                   Text(
//                     "Driver ID: ${truck['driverId'] ?? '-'}",
//                     style: const TextStyle(color: Colors.black54, fontSize: 13),
//                   ),
//                   Text(
//                     "Status: ${truck['status'] ?? '-'}",
//                     style: TextStyle(
//                       color: statusColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (truck['status']?.toLowerCase() == 'inprogress')
//               const Icon(Icons.navigation, color: Colors.orangeAccent),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget _buildTruckTile(Map<String, String> truck) {
//   //   Color statusColor;
//   //   switch (truck['status']?.toLowerCase()) {
//   //     case 'assigned':
//   //       statusColor = Colors.blueAccent;
//   //       break;
//   //     case 'inprogress':
//   //       statusColor = Colors.orangeAccent;
//   //       break;
//   //     case 'completed':
//   //       statusColor = Colors.green;
//   //       break;
//   //     default:
//   //       statusColor = Colors.grey;
//   //   }

//   //   return Container(
//   //     margin: const EdgeInsets.symmetric(vertical: 8),
//   //     padding: const EdgeInsets.all(12),
//   //     decoration: BoxDecoration(
//   //       color: Colors.grey.shade100,
//   //       borderRadius: BorderRadius.circular(12),
//   //       border: Border.all(color: Colors.grey.shade300),
//   //     ),
//   //     child: Row(
//   //       children: [
//   //         CircleAvatar(
//   //           radius: 18,
//   //           backgroundColor: statusColor,
//   //           child: Text(
//   //             truck['number'] ?? '-',
//   //             style: const TextStyle(
//   //               color: Colors.white,
//   //               fontWeight: FontWeight.bold,
//   //             ),
//   //           ),
//   //         ),
//   //         const SizedBox(width: 16),
//   //         Expanded(
//   //           child: Column(
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             children: [
//   //               Text(
//   //                 "Ride ID: ${truck['rideId'] ?? '-'}",
//   //                 style: const TextStyle(fontWeight: FontWeight.w600),
//   //               ),
//   //               const SizedBox(height: 4),
//   //               Text(
//   //                 "Status: ${truck['status'] ?? '-'}",
//   //                 style: TextStyle(
//   //                   color: statusColor,
//   //                   fontWeight: FontWeight.w600,
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
// }
// // import 'dart:convert';

// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:niceapp/Container/utils/keys.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // import 'package:niceapp/View/Screens/Vehicles/general_payment_screen.dart';

// // class OrderDetailsScreen extends StatelessWidget {
// //   final VehicleCategory serviceType;
// //   final String? orderNo;
// //   final String deliveryAddress;
// //   final String scheduledFor;
// //   final double totalAmount;
// //   final int? orderId;
// //   final String paymentStatus;

// //   // New: list of rides/trucks (after payment)
// //   final List<Map<String, String>>? trucks;

// //   const OrderDetailsScreen({
// //     super.key,
// //     this.orderNo,
// //     this.orderId,
// //     required this.serviceType,
// //     required this.deliveryAddress,
// //     required this.scheduledFor,
// //     required this.totalAmount,
// //     required this.paymentStatus,
// //     this.trucks, // optional, only populated if payment done
// //   });

// //   Future<void> fetchorderHistory() async {
// //     final response = await http.get(
// //       Uri.parse('$baseUrl/passengerrides/orders/$orderId'),
// //     );

// //     if (response.statusCode == 200) {
// //       final data = jsonDecode(response.body);
// //       if (data['hasIncompleteTrip'] == true) {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder:
// //                 (_) => OrderDetailsScreen(
// //                   serviceType: data['serviceType'],
// //                   orderId: data['orderId'],
// //                   orderNo: data['orderNo'],
// //                   deliveryAddress: data['deliveryAddress'],
// //                   scheduledFor: data['scheduledFor'],
// //                   totalAmount: data['totalAmount'],
// //                   paymentStatus: data['paymentStatus'],
// //                   trucks: List<Map<String, String>>.from(data['trucks']),
// //                 ),
// //           ),
// //         );
// //       } else {
// //         // Continue to Water Bowser screen
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final bool isPaid = paymentStatus.toLowerCase() == "paid";

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Order Details"),
// //         centerTitle: true,
// //         backgroundColor: Colors.white,
// //         foregroundColor: Colors.black87,
// //         elevation: 1,
// //       ),
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               // 🧾 Order Details
// //               _buildCard(
// //                 title: "Order Details",
// //                 children: [
// //                   _buildRow("Order No:", orderNo ?? "-"),
// //                   _buildRow("Delivery Address:", deliveryAddress),
// //                   _buildRow("Scheduled For:", scheduledFor),
// //                 ],
// //               ),
// //               const SizedBox(height: 20),

// //               // 💰 Payment Details
// //               _buildCard(
// //                 title: "Payment Details",
// //                 children: [
// //                   _buildRow("Total:", "KES ${totalAmount.toStringAsFixed(2)}"),
// //                   _buildRow(
// //                     "Payment Status:",
// //                     paymentStatus,
// //                     valueColor: isPaid ? Colors.green : Colors.redAccent,
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 20),

// //               // 🚛 Trucks/Rides Section (only if paid)
// //               if (isPaid && trucks != null && trucks!.isNotEmpty)
// //                 Expanded(
// //                   child: _buildCard(
// //                     title: "Assigned Trucks",
// //                     children:
// //                         trucks!.map((truck) => _buildTruckTile(truck)).toList(),
// //                   ),
// //                 ),

// //               if (!isPaid)
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton.icon(
// //                     onPressed: () {
// //                       // Navigate to GeneralPaymentScreen with order details
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder:
// //                               (_) => GeneralPaymentScreen(
// //                                 serviceType: serviceType,
// //                                 amount: totalAmount,
// //                                 orderId:
// //                                     orderId, // if you have a rideId for this order, pass it
// //                                 // orderNumber: orderNo,
// //                                 // scheduledTime: scheduledFor,
// //                                 // destination: deliveryAddress,
// //                                 // // Add any other fields needed for your GeneralPaymentScreen
// //                               ),
// //                         ),
// //                       );
// //                     },
// //                     icon: const Icon(Icons.payment),
// //                     label: const Text("Make Payment"),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.blueAccent,
// //                       foregroundColor: Colors.white,
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                       textStyle: const TextStyle(
// //                         fontSize: 16,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildCard({required String title, required List<Widget> children}) {
// //     return Card(
// //       elevation: 2,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //       child: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               title,
// //               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const Divider(height: 20),
// //             ...children,
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildRow(String label, String value, {Color? valueColor}) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 10),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Expanded(
// //             flex: 3,
// //             child: Text(
// //               label,
// //               style: const TextStyle(
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.black54,
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 5,
// //             child: Text(
// //               value,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 color: valueColor ?? Colors.black87,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildTruckTile(Map<String, String> truck) {
// //     Color statusColor;
// //     switch (truck['status']?.toLowerCase()) {
// //       case 'assigned':
// //         statusColor = Colors.blueAccent;
// //         break;
// //       case 'inprogress':
// //         statusColor = Colors.orangeAccent;
// //         break;
// //       case 'completed':
// //         statusColor = Colors.green;
// //         break;
// //       default:
// //         statusColor = Colors.grey;
// //     }

// //     return Container(
// //       margin: const EdgeInsets.symmetric(vertical: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: Colors.grey.shade100,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey.shade300),
// //       ),
// //       child: Row(
// //         children: [
// //           CircleAvatar(
// //             radius: 18,
// //             backgroundColor: statusColor,
// //             child: Text(
// //               truck['number'] ?? '-',
// //               style: const TextStyle(
// //                 color: Colors.white,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   "Ride ID: ${truck['rideId'] ?? '-'}",
// //                   style: const TextStyle(fontWeight: FontWeight.w600),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   "Status: ${truck['status'] ?? '-'}",
// //                   style: TextStyle(
// //                     color: statusColor,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// // // import 'package:flutter/material.dart';

// // // class OrderDetailsScreen extends StatelessWidget {
// // //   final String orderNo;
// // //   final String deliveryAddress;
// // //   final String scheduledFor;
// // //   final double totalAmount;
// // //   final String paymentStatus;

// // //   const OrderDetailsScreen({
// // //     super.key,
// // //     required this.orderNo,
// // //     required this.deliveryAddress,
// // //     required this.scheduledFor,
// // //     required this.totalAmount,
// // //     required this.paymentStatus,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final bool isPaid = paymentStatus.toLowerCase() == "paid";

// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Order Details"),
// // //         centerTitle: true,
// // //         backgroundColor: Colors.white,
// // //         foregroundColor: Colors.black87,
// // //         elevation: 1,
// // //       ),
// // //       body: SafeArea(
// // //         child: Padding(
// // //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               /// 🧾 Order Details Section
// // //               Card(
// // //                 elevation: 2,
// // //                 shape: RoundedRectangleBorder(
// // //                   borderRadius: BorderRadius.circular(16),
// // //                 ),
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.all(16.0),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       const Text(
// // //                         "Order Details",
// // //                         style: TextStyle(
// // //                           fontSize: 18,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                       const Divider(height: 20),
// // //                       _buildRow("Order No:", orderNo),
// // //                       _buildRow("Delivery Address:", deliveryAddress),
// // //                       _buildRow("Scheduled For:", scheduledFor),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),

// // //               const SizedBox(height: 20),

// // //               /// 💰 Payment Details Section
// // //               Card(
// // //                 elevation: 2,
// // //                 shape: RoundedRectangleBorder(
// // //                   borderRadius: BorderRadius.circular(16),
// // //                 ),
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.all(16.0),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       const Text(
// // //                         "Payment Details",
// // //                         style: TextStyle(
// // //                           fontSize: 18,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                       const Divider(height: 20),
// // //                       _buildRow(
// // //                         "Total:",
// // //                         "KES ${totalAmount.toStringAsFixed(2)}",
// // //                         valueColor: Colors.black,
// // //                       ),
// // //                       _buildRow(
// // //                         "Payment Status:",
// // //                         paymentStatus,
// // //                         valueColor: isPaid ? Colors.green : Colors.redAccent,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),

// // //               const Spacer(),

// // //               /// 🪙 Make Payment Button
// // //               SizedBox(
// // //                 width: double.infinity,
// // //                 child: ElevatedButton.icon(
// // //                   onPressed:
// // //                       isPaid
// // //                           ? null
// // //                           : () {
// // //                             // TODO: Add payment integration here
// // //                             ScaffoldMessenger.of(context).showSnackBar(
// // //                               const SnackBar(
// // //                                 content: Text(
// // //                                   "Redirecting to payment gateway...",
// // //                                 ),
// // //                               ),
// // //                             );
// // //                           },
// // //                   icon: const Icon(Icons.payment),
// // //                   label: const Text("Make Payment"),
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: isPaid ? Colors.grey : Colors.blueAccent,
// // //                     foregroundColor: Colors.white,
// // //                     padding: const EdgeInsets.symmetric(vertical: 16),
// // //                     textStyle: const TextStyle(
// // //                       fontSize: 16,
// // //                       fontWeight: FontWeight.bold,
// // //                     ),
// // //                     shape: RoundedRectangleBorder(
// // //                       borderRadius: BorderRadius.circular(12),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildRow(String label, String value, {Color? valueColor}) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 10),
// // //       child: Row(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Expanded(
// // //             flex: 3,
// // //             child: Text(
// // //               label,
// // //               style: const TextStyle(
// // //                 fontSize: 16,
// // //                 fontWeight: FontWeight.w500,
// // //                 color: Colors.black54,
// // //               ),
// // //             ),
// // //           ),
// // //           Expanded(
// // //             flex: 5,
// // //             child: Text(
// // //               value,
// // //               style: TextStyle(
// // //                 fontSize: 16,
// // //                 color: valueColor ?? Colors.black87,
// // //                 fontWeight: FontWeight.w600,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }





  // Future<void> _assignDriver() async {
  //   if (widget.rideId == null) return;

  //   setState(() => isAssigning = true);

  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/passengerrides/waterbowser/assigndriver/${widget.rideId}'),
  //       headers: {'Content-Type': 'application/json'},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       // After assignment, fetch order details again to update trucks
  //       await fetchOrderDetails();
  //     }
  //   } catch (e) {
  //     // optionally handle API errors silently
  //   } finally {
  //     if (mounted) setState(() => isAssigning = false);
  //   }
  // }

  // Future<void> assignWaterBowserDriver(int rideId) async {
  //   final url = Uri.parse('$baseUrl/passengerrides/waterbowser/assigndriver/$rideId');

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         // If your API requires auth, add the token:
  //         // 'Authorization': 'Bearer $token',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       // Example: Show a message
  //       print("Success: ${data['message']}");
  //     } else {
  //       print("Failed: ${response.statusCode} - ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Error calling API: $e");
  //   }
  // }

   // Padding(
                  //   padding: const EdgeInsets.only(top: 16),
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: OutlinedButton.icon(
                  //       onPressed: () => _showCancelDialog(context),
                  //       icon: const Icon(Icons.cancel, color: Colors.red),
                  //       label: const Text(
                  //         "Cancel Booking",
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       style: OutlinedButton.styleFrom(
                  //         foregroundColor: Colors.red,
                  //         side: const BorderSide(color: Colors.red, width: 1.5),
                  //         padding: const EdgeInsets.symmetric(vertical: 14),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(12),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),