import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverConfirmationScreen extends StatefulWidget {
  final String driverId;
  final LatLng pickup;
  final int rideId;
  final String? Phone;
  final String? colour;
  final String? regnumber;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? drivername; //photoUrl
  final String? photoUrl;
  const DriverConfirmationScreen({
    super.key,
    required this.driverId,
    required this.pickup,
    required this.rideId,
    this.colour,
    this.Phone,
    this.drivername,
    this.regnumber,
    this.vehicleMake,
    this.vehicleModel,
    this.photoUrl,
  });

  @override
  State<DriverConfirmationScreen> createState() =>
      _DriverConfirmationScreenState();
}

class _DriverConfirmationScreenState extends State<DriverConfirmationScreen> {
  //GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;
  List<LatLng> routePoints = [];
  double driverDistanceKm = 0;
  int estimatedTimeMin = 0;
  late DatabaseReference _driverLocRef;
  LatLng? _driverLocation;
  Marker? _driverMarker;
  List<LatLng> _fullRoute = [];
  Timer? _rideTimer;
  bool _navigated = false;

  late DatabaseReference? _rideRef;
  StreamSubscription<DatabaseEvent>? _rideSub;

  @override
  void initState() {
    super.initState();

    // _rideRef = FirebaseDatabase.instance.ref('rides/${widget.rideId}');
    //_rideSub = _rideRef!.onValue.listen(_handleRideUpdate);
    _listenToDriverLocation();
    _rideTimer = Timer.periodic(Duration(seconds: 2), (_) {
      _checkRideStatus();
    });
  }

  @override
  void dispose() {
    //_rideSub?.cancel();
    _rideTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _handleRideUpdate(DatabaseEvent event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;

    final status = data['status']?.toString().toLowerCase();
    if (status == 'in_progress' && !_navigated) {
      _navigated = true;

      final driverId = data['driverId'] ?? '';
      final pickup = LatLng(
        double.parse(data['pickupLat'].toString()),
        double.parse(data['pickupLng'].toString()),
      );
      final destination = LatLng(
        double.parse(data['destinationLat'].toString()),
        double.parse(data['destinationLng'].toString()),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => RideInProgressLiveScreen(
                rideId: widget.rideId,
                driverId: driverId,
                pickup: pickup,
                destination: destination,
              ),
        ),
      );
    }
  }

  void _checkRideStatus() async {
    final rideRef = FirebaseDatabase.instance.ref('rides/${widget.rideId}');
    final snapshot = await rideRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;

    final status = data['status']?.toString().toLowerCase();
    debugPrint('Ride status (timer): $status');

    if (status == 'in_progress' && !_navigated) {
      _navigated = true;

      final driverId = data['driverId'] ?? '';

      // Access pickup & destination maps
      final pickupMap = data['pickup'] as Map<dynamic, dynamic>?;
      final destinationMap = data['destination'] as Map<dynamic, dynamic>?;

      if (pickupMap == null || destinationMap == null) return;

      final pickup = LatLng(
        double.parse(pickupMap['lat'].toString()),
        double.parse(pickupMap['lng'].toString()),
      );
      final destination = LatLng(
        double.parse(destinationMap['lat'].toString()),
        double.parse(destinationMap['lng'].toString()),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => RideInProgressLiveScreen(
                  rideId: widget.rideId,
                  driverId: driverId,
                  pickup: pickup,
                  destination: destination,
                ),
          ),
        );
      });

      // Stop the timer after navigation
      _rideTimer?.cancel();
    }
  }

  List<String> cancellationReasons = [];
  bool isLoadingReasons = true;

  void _animateDriverMarker(LatLng from, LatLng to) async {
    final steps = 20;
    final latStep = (to.latitude - from.latitude) / steps;
    final lngStep = (to.longitude - from.longitude) / steps;

    for (int i = 1; i <= steps; i++) {
      final newPos = LatLng(
        from.latitude + latStep * i,
        from.longitude + lngStep * i,
      );

      setState(() {
        // Update driver marker
        _driverMarker = _driverMarker!.copyWith(positionParam: newPos);

        // Show only remaining route
        int nearestIndex = _fullRoute.indexWhere(
          (point) => _distanceBetween(point, newPos) < 0.01,
        ); // threshold in km
        final remainingRoute =
            (nearestIndex != -1)
                ? _fullRoute.sublist(nearestIndex)
                : _fullRoute;

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: remainingRoute,
          ),
        };

        _markers = {
          _driverMarker!,
          Marker(
            markerId: const MarkerId('pickup'),
            position: widget.pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };
      });

      await Future.delayed(const Duration(milliseconds: 50));
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
    }
  }

  // Helper to calculate approximate distance in km
  double _distanceBetween(LatLng a, LatLng b) {
    const double R = 6371; // Earth radius in km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final haversine =
        sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<List<String>> fetchCancellationReasons() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/cancellation/reasons'),
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

  Future<void> cancelRide(int rideId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rides/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rideId': rideId, 'reason': reason}),
    );

    if (response.statusCode == 200) {
      print("Cancelled ride successfully");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransportServicesScreen()),
      );
      final result = jsonDecode(response.body);
      // handle result['rideId'] or show confirmation
    } else {
      print("Error cancelling ride: ${response.body}");
    }
  }

  Future<void> reassignDriver(int rideId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rides/cancel-reassign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rideId': rideId, 'reason': reason}),
    );

    if (response.statusCode != 200) {
      debugPrint("Failed to reassign driver: ${response.body}");
    }
  }

  Future<void> _fetchGoogleRoute() async {
    if (_driverLocation == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${_driverLocation!.latitude},${_driverLocation!.longitude}'
        '&destination=${widget.pickup.latitude},${widget.pickup.longitude}'
        '&key=$mapKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        _fullRoute = _decodePolyline(route['overview_polyline']['points']);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: _fullRoute,
            ),
          };

          driverDistanceKm = route['legs'][0]['distance']['value'] / 1000; // km
          estimatedTimeMin =
              (route['legs'][0]['duration']['value'] / 60).round(); // min
        });
      }
    }
  }

  void _listenToDriverLocation() {
    _driverLocRef = FirebaseDatabase.instance.ref(
      'drivers/${widget.driverId}/location',
    );

    _driverLocRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final lat = double.tryParse(data['latitude'].toString());
        final lng = double.tryParse(data['longitude'].toString());

        if (lat != null && lng != null) {
          setState(() {
            _driverLocation = LatLng(lat, lng);
          });

          _updateMarkers(); // ✅ update markers
          _fetchGoogleRoute(); // ✅ get Google Maps route + ETA
        }
      }
    });
  }

  void _updateMarkers() {
    if (_driverLocation != null) {
      if (_driverMarker == null) {
        // First time: add marker
        _driverMarker = Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        );
      } else {
        // Animate movement
        _animateDriverMarker(_driverMarker!.position, _driverLocation!);
      }

      setState(() {
        _markers = {
          _driverMarker!,
          Marker(
            markerId: const MarkerId('pickup'),
            position: widget.pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverLoc = widget.pickup;
    // widget.driver.location;
    //backgroundColor: Colors.white;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Driver is on the way"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () => _showCancelDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 8,
            child:
                (driverLoc.latitude == 0.0 && driverLoc.latitude == 0.0)
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: widget.pickup,
                        zoom: 14,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Driver Info
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          (widget.photoUrl != null &&
                                                  widget.photoUrl!.isNotEmpty)
                                              ? NetworkImage(widget.photoUrl!)
                                              : const AssetImage(
                                                    'assets/imgs/logo.png',
                                                  )
                                                  as ImageProvider,
                                    ),
                                    //   backgroundImage:
                                    //       widget.photoUrl!.isNotEmpty
                                    //           ? NetworkImage(widget.photoUrl!)
                                    //           : const AssetImage(
                                    //                 'assets/imgs/logo.png',
                                    //               )
                                    //               as ImageProvider,
                                    // ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.drivername!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Vehicle: ${widget.vehicleMake}",
                                          ),
                                          Text("Plate: ${widget.regnumber}"),
                                          Text("Color: ${widget.colour}"),
                                          Text(
                                            "ETA: $estimatedTimeMin min • ${driverDistanceKm.toStringAsFixed(1)} km",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _actionButton(Icons.phone, "Call", () {
                                  launchUrl(Uri.parse("tel:${widget.Phone}"));
                                }),
                                _actionButton(
                                  Icons.message,
                                  "Message",
                                  () async {
                                    final Uri smsUri = Uri(
                                      scheme: 'sms',
                                      path: "${widget.Phone}",
                                    );
                                    if (await canLaunchUrl(smsUri)) {
                                      await launchUrl(smsUri);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cannot send message.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                // {
                                //   // TODO: Add chat feature
                                //   ScaffoldMessenger.of(context).showSnackBar(
                                //     const SnackBar(
                                //       content: Text(
                                //         "Chat feature coming soon!",
                                //       ),
                                //     ),
                                //   );
                                // }),
                                // _actionButton(Icons.cancel, "Cancel", () {
                                //   _showCancelDialog(context);
                                // }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Big Cancel Button at Bottom, inside scroll view
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        "Cancel Ride",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  void _showCancelDialog(BuildContext context) async {
    final reasons = await fetchCancellationReasons();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Why do you want to cancel?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: reasons.length,
                      itemBuilder: (context, index) {
                        final reason = reasons[index];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.red[50],
                          child: ListTile(
                            title: Text(
                              reason,
                              style: const TextStyle(color: Colors.black),
                            ),
                            onTap: () async {
                              Navigator.pop(context); // Close bottom sheet

                              final shouldWait = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        "Cancel Ride",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        "Reason: $reason\n\nShould the rider wait for another driver?",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      actionsPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                      actions: [
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                          label: const Text("No"),
                                          onPressed: () async {
                                            Navigator.of(ctx).pop(false);

                                            // 🚀 Call backend to mark ride as cancelled without reassignment
                                            await cancelRide(
                                              widget.rideId,
                                              reason,
                                            );
                                          },
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: const Text("Yes"),
                                          onPressed: () async {
                                            Navigator.of(ctx).pop(true);

                                            // 🚀 Reassign driver
                                            await reassignDriver(
                                              widget.rideId,
                                              reason,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              );
                              if (!mounted) return;
                              if (mounted) {
                                Navigator.of(context).pop(); // Exit ride screen
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //   @override
  // Widget build(BuildContext context) {
  //   final driverLoc = widget.pickup;
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     appBar: AppBar(
  //       title: const Text(
  //         "Driver is on the way 🚗",
  //         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  //       ),
  //       centerTitle: true,
  //       elevation: 0,
  //       backgroundColor: Colors.white,
  //       foregroundColor: Colors.black,
  //       automaticallyImplyLeading: false,
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.cancel, size: 28, color: Colors.red),
  //           onPressed: () => _showCancelDialog(context),
  //         ),
  //       ],
  //     ),
  //     body: Stack(
  //       children: [
  //         // Map background
  //         (driverLoc.latitude == 0.0 && driverLoc.longitude == 0.0)
  //             ? const Center(child: CircularProgressIndicator())
  //             : GoogleMap(
  //               initialCameraPosition: CameraPosition(
  //                 target: widget.pickup,
  //                 zoom: 14,
  //               ),
  //               markers: _markers,
  //               polylines: _polylines,
  //             ),

  //         // Floating driver info card
  //         Align(
  //           alignment: Alignment.bottomCenter,
  //           child: Container(
  //             margin: const EdgeInsets.all(16),
  //             padding: const EdgeInsets.all(20),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 12,
  //                   offset: const Offset(0, 6),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // Driver row
  //                 Row(
  //                   children: [
  //                     CircleAvatar(
  //                       radius: 45,
  //                       backgroundImage:
  //                           (widget.photoUrl != null &&
  //                                   widget.photoUrl!.isNotEmpty)
  //                               ? NetworkImage(widget.photoUrl!)
  //                               : const AssetImage('assets/imgs/logo.png')
  //                                   as ImageProvider,
  //                     ),
  //                     const SizedBox(width: 16),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             widget.drivername ?? "Driver",
  //                             style: const TextStyle(
  //                               fontSize: 20,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 4),
  //                           Text(
  //                             "${widget.vehicleMake ?? ''} ${widget.vehicleModel ?? ''}",
  //                             style: const TextStyle(
  //                               fontSize: 16,
  //                               color: Colors.grey,
  //                             ),
  //                           ),
  //                           Text(
  //                             "Plate: ${widget.regnumber ?? ''} • ${widget.colour ?? ''}",
  //                             style: const TextStyle(fontSize: 15),
  //                           ),
  //                           const SizedBox(height: 4),
  //                           Text(
  //                             "ETA: $estimatedTimeMin min • ${driverDistanceKm.toStringAsFixed(1)} km",
  //                             style: const TextStyle(
  //                               fontSize: 15,
  //                               color: Colors.blueGrey,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),

  //                 const SizedBox(height: 20),

  //                 // Action buttons
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                   children: [
  //                     _modernActionButton(
  //                       Icons.phone,
  //                       "Call",
  //                       Colors.green,
  //                       () {
  //                         launchUrl(Uri.parse("tel:${widget.Phone}"));
  //                       },
  //                     ),
  //                     _modernActionButton(
  //                       Icons.message,
  //                       "Message",
  //                       Colors.blue,
  //                       () async {
  //                         final Uri smsUri = Uri(
  //                           scheme: 'sms',
  //                           path: "${widget.Phone}",
  //                         );
  //                         if (await canLaunchUrl(smsUri)) {
  //                           await launchUrl(smsUri);
  //                         }
  //                       },
  //                     ),
  //                   ],
  //                 ),

  //                 const SizedBox(height: 20),

  //                 // Cancel button
  //                 SizedBox(
  //                   width: double.infinity,
  //                   height: 55,
  //                   child: ElevatedButton.icon(
  //                     onPressed: () => _showCancelDialog(context),
  //                     icon: const Icon(Icons.cancel, color: Colors.white),
  //                     label: const Text(
  //                       "Cancel Ride",
  //                       style: TextStyle(fontSize: 18, color: Colors.white),
  //                     ),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.redAccent,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(14),
  //                       ),
  //                       elevation: 4,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _modernActionButton(
  //   IconData icon,
  //   String label,
  //   Color color,
  //   VoidCallback onTap,
  // ) {
  //   return Column(
  //     children: [
  //       InkWell(
  //         onTap: onTap,
  //         borderRadius: BorderRadius.circular(50),
  //         child: Container(
  //           padding: const EdgeInsets.all(14),
  //           decoration: BoxDecoration(
  //             color: color.withOpacity(0.1),
  //             shape: BoxShape.circle,
  //           ),
  //           child: Icon(icon, color: color, size: 28),
  //         ),
  //       ),
  //       const SizedBox(height: 6),
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  //       ),
  //     ],
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
  //     builder: (context) {
  //       return DraggableScrollableSheet(
  //         initialChildSize: 0.5,
  //         minChildSize: 0.4,
  //         maxChildSize: 0.9,
  //         expand: false,
  //         builder: (context, scrollController) {
  //           return Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               children: [
  //                 const Text(
  //                   "Select Cancellation Reason",
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Expanded(
  //                   child: ListView.builder(
  //                     controller: scrollController,
  //                     itemCount: reasons.length,
  //                     itemBuilder: (context, index) {
  //                       final reason = reasons[index];

  //                       return Card(
  //                         color: Colors.grey[700],
  //                         child: ListTile(
  //                           title: Text(
  //                             reason,
  //                             style: const TextStyle(color: Colors.white),
  //                           ),
  //                           //final dialogContext = context;
  //                           onTap: () async {
  //                             Navigator.pop(context); // Close bottom sheet

  //                             final shouldWait = await showDialog<bool>(
  //                               context: context,
  //                               builder:
  //                                   (ctx) => AlertDialog(
  //                                     title: const Text("Cancel Ride"),
  //                                     content: Text(
  //                                       "Reason: $reason\n\nShould the rider wait for another driver?",
  //                                     ),
  //                                     actions: [
  //                                       TextButton(
  //                                         onPressed:
  //                                             () =>
  //                                                 Navigator.of(ctx).pop(false),
  //                                         child: const Text("No"),
  //                                       ),
  //                                       ElevatedButton(
  //                                         onPressed:
  //                                             () => Navigator.of(ctx).pop(true),
  //                                         child: const Text("Yes"),
  //                                       ),
  //                                     ],
  //                                   ),
  //                             );

  //                             if (shouldWait == true) {
  //                               await reassignDriver(widget.rideId, reason);
  //                             } else {
  //                               // Navigator.push(
  //                               //   context,
  //                               //   MaterialPageRoute(
  //                               //     builder:
  //                               //         (_) => TransportServicesScreen()

  //                               //   ),
  //                               // );
  //                             }

  //                             if (mounted) {
  //                               Navigator.of(context).pop(); // Exit ride screen
  //                             }
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
}

//   void _showCancelDialog(BuildContext context) async {
//     final reasons = await fetchCancellationReasons();

//     if (!mounted) return;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.5,
//           minChildSize: 0.4,
//           maxChildSize: 0.9,
//           expand: false,
//           builder: (context, scrollController) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   const Text(
//                     "Select Cancellation Reason",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: ListView.builder(
//                       controller: scrollController,
//                       itemCount: reasons.length,
//                       itemBuilder: (context, index) {
//                         final reason = reasons[index];

//                         return Card(
//                           color: Colors.grey[700],
//                           child: ListTile(
//                             title: Text(
//                               reason,
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                             onTap: () async {
//                               Navigator.pop(context); // Close bottom sheet

//                               final shouldWait = await showDialog<bool>(
//                                 context: context,
//                                 builder:
//                                     (ctx) => AlertDialog(
//                                       title: const Text("Cancel Ride"),
//                                       content: Text(
//                                         "Reason: $reason\n\nShould the rider wait for another driver?",
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed:
//                                               () =>
//                                                   Navigator.of(ctx).pop(false),
//                                           child: const Text("No"),
//                                         ),
//                                         ElevatedButton(
//                                           onPressed:
//                                               () => Navigator.of(ctx).pop(true),
//                                           child: const Text("Yes"),
//                                         ),
//                                       ],
//                                     ),
//                               );

//                               if (shouldWait == true) {
//                                 await reassignDriver(widget.rideId, reason);
//                               }

//                               if (mounted) {
//                                 Navigator.of(context).pop(); // Exit ride screen
//                               }
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // void _showCancelDialog(BuildContext context) async {
//   //   final reasons = await fetchCancellationReasons();

//   //   if (!mounted) return;

//   //   String? selectedReason;

//   //   showModalBottomSheet(
//   //     context: context,
//   //     isScrollControlled: true,
//   //     shape: const RoundedRectangleBorder(
//   //       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//   //     ),
//   //     builder: (context) {
//   //       return DraggableScrollableSheet(
//   //         initialChildSize: 0.5,
//   //         minChildSize: 0.4,
//   //         maxChildSize: 0.9,
//   //         expand: false,
//   //         builder: (context, scrollController) {
//   //           return Padding(
//   //             padding: const EdgeInsets.all(16),
//   //             child: Column(
//   //               children: [
//   //                 const Text(
//   //                   "Select Cancellation Reason",
//   //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//   //                 ),
//   //                 const SizedBox(height: 16),
//   //                 Expanded(
//   //                   child: ListView.builder(
//   //                     controller: scrollController,
//   //                     itemCount: reasons.length,
//   //                     itemBuilder: (context, index) {
//   //                       final reason = reasons[index];
//   //                       final isSelected = reason == selectedReason;

//   //                       return Card(
//   //                         color: isSelected ? Colors.red[100] : null,
//   //                         child: ListTile(
//   //                           title: Text(reason),
//   //                           trailing:
//   //                               isSelected
//   //                                   ? const Icon(
//   //                                     Icons.check_circle,
//   //                                     color: Colors.red,
//   //                                   )
//   //                                   : null,
//   //                           onTap: () {
//   //                             setState(() {
//   //                               selectedReason = reason;
//   //                             });
//   //                           },
//   //                         ),
//   //                       );
//   //                     },
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 8),
//   //                 ElevatedButton.icon(
//   //                   onPressed:
//   //                       selectedReason == null
//   //                           ? null
//   //                           : () async {
//   //                             Navigator.pop(context); // close sheet
//   //                             await cancelRide(widget.rideId, selectedReason!);
//   //                             if (mounted) Navigator.pop(context); // pop screen
//   //                           },
//   //                   icon: const Icon(Icons.cancel),
//   //                   label: const Text("Confirm Cancel"),
//   //                   style: ElevatedButton.styleFrom(
//   //                     minimumSize: const Size.fromHeight(48),
//   //                     backgroundColor: Colors.red[600],
//   //                     foregroundColor: Colors.white,
//   //                     shape: RoundedRectangleBorder(
//   //                       borderRadius: BorderRadius.circular(12),
//   //                     ),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }

//   // void _showCancelDialog(BuildContext context) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) {
//   //       return FutureBuilder<List<String>>(
//   //         future: fetchCancellationReasons().then((_) => cancellationReasons),
//   //         builder: (context, snapshot) {
//   //           if (snapshot.connectionState == ConnectionState.waiting) {
//   //             return const AlertDialog(
//   //               content: SizedBox(
//   //                 height: 80,
//   //                 child: Center(child: CircularProgressIndicator()),
//   //               ),
//   //             );
//   //           } else if (snapshot.hasError ||
//   //               snapshot.data == null ||
//   //               snapshot.data!.isEmpty) {
//   //             return AlertDialog(
//   //               title: const Text("Error"),
//   //               content: const Text("Failed to load cancellation reasons."),
//   //               actions: [
//   //                 TextButton(
//   //                   onPressed: () => Navigator.pop(context),
//   //                   child: const Text("Back"),
//   //                 ),
//   //               ],
//   //             );
//   //           } else {
//   //             String? selectedReason;

//   //             return StatefulBuilder(
//   //               builder:
//   //                   (context, setState) => AlertDialog(
//   //                     title: const Text("Select Cancellation Reason"),
//   //                     content: SizedBox(
//   //                       height: 250,
//   //                       width: double.maxFinite,
//   //                       child: Scrollbar(
//   //                         child: ListView.builder(
//   //                           itemCount: snapshot.data!.length,
//   //                           itemBuilder: (context, index) {
//   //                             final reason = snapshot.data![index];
//   //                             final isSelected = selectedReason == reason;

//   //                             return Card(
//   //                               color: isSelected ? Colors.red[100] : null,
//   //                               child: ListTile(
//   //                                 title: Text(reason),
//   //                                 trailing:
//   //                                     isSelected
//   //                                         ? const Icon(
//   //                                           Icons.check_circle,
//   //                                           color: Colors.red,
//   //                                         )
//   //                                         : null,
//   //                                 onTap: () {
//   //                                   setState(() {
//   //                                     selectedReason = reason;
//   //                                   });
//   //                                 },
//   //                               ),
//   //                             );
//   //                           },
//   //                         ),
//   //                       ),
//   //                     ),
//   //                     actions: [
//   //                       TextButton(
//   //                         onPressed: () => Navigator.pop(context),
//   //                         child: const Text("Back"),
//   //                       ),
//   //                       ElevatedButton(
//   //                         onPressed:
//   //                             selectedReason == null
//   //                                 ? null
//   //                                 : () async {
//   //                                   Navigator.pop(context); // Close dialog
//   //                                   await cancelRide(
//   //                                     widget.rideId,
//   //                                     selectedReason!,
//   //                                   );
//   //                                   Navigator.pop(
//   //                                     context,
//   //                                   ); // Close DriverConfirmationScreen
//   //                                 },
//   //                         child: const Text("Confirm Cancel"),
//   //                       ),
//   //                     ],
//   //                   ),
//   //             );
//   //           }
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
// }
