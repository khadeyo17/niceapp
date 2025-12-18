import 'dart:convert';
import 'package:flutter/material.dart';
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

  const OrderDetailsScreen({
    super.key,
    this.rideId,
    required this.serviceType,
    this.destination,
    this.pickup,
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
  String quantity = '0';
  VehicleCategory? serviceType;
  List<Map<String, String>> trucks = [];
  LatLng? selectedLatLng;

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      selectedLatLng = widget.destination!;
    }
    if (widget.rideId != null) {
      fetchOrderDetails();
    } else {
      setState(() {
        hasError = true;
        errorMessage = 'Invalid order ID.';
      });
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
        Uri.parse('$baseUrl/rides/${widget.rideId}/$categoryType'),
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
        serviceType = VehicleCategory.values.firstWhere((e) {
          if (serviceTypeValue is String) {
            return e.name.toLowerCase() == serviceTypeValue.toLowerCase();
          } else if (serviceTypeValue is int) {
            return e.index == serviceTypeValue;
          }
          return false;
        }, orElse: () => VehicleCategory.passenger);

        final truck = data['truck'];
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
  // Widget build(BuildContext context) {
  //   if (isLoading) {
  //     return const Scaffold(body: Center(child: CircularProgressIndicator()));
  //   }
  //   if (hasError) {
  //     return Scaffold(body: Center(child: Text(errorMessage)));
  //   }
  //   final bool isPaid = paymentStatus.toLowerCase() == "paid";
  //   return Scaffold(
  //     backgroundColor: Colors.grey.shade100,
  //     appBar: AppBar(
  //       title: const Text("Order Details"),
  //       centerTitle: true,
  //       backgroundColor: Colors.blueAccent,
  //       foregroundColor: Colors.white,
  //       elevation: 0,
  //     ),
  //     body: SafeArea(
  //       child: SingleChildScrollView(
  //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             _buildCard(
  //               title: "🧾 Order Details",
  //               color: Colors.white,
  //               children: [
  //                 _buildRow("Order No:", orderNo),
  //                 _buildRow("Delivery Address:", deliveryAddress),
  //                 _buildRow("Scheduled For:", scheduledFor),
  //                 _buildRow("Quantity:", quantity),
  //               ],
  //             ),
  //             const SizedBox(height: 20),
  //             _buildCard(
  //               title: "💰 Payment Details",
  //               color: Colors.yellow.shade100,
  //               children: [
  //                 _buildRow(
  //                   "Total Amount:",
  //                   "KES ${totalAmount.toStringAsFixed(2)}",
  //                   valueColor: Colors.black87,
  //                 ),
  //                 _buildRow(
  //                   "Payment Status:",
  //                   paymentStatus,
  //                   valueColor: isPaid ? Colors.green : Colors.red,
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 20),
  //             if (isPaid && trucks.isNotEmpty)
  //               _buildCard(
  //                 title: "🚛 Assigned Trucks",
  //                 color: Colors.lightBlue.shade50,
  //                 children:
  //                     trucks.map((truck) => _buildTruckTile(truck)).toList(),
  //               ),
  //             if (!isPaid)
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 24),
  //                 child: SizedBox(
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
  //                       backgroundColor: Colors.green,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(vertical: 16),
  //                       textStyle: const TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hasError) {
      return Scaffold(body: Center(child: Text(errorMessage)));
    }

    final bool isPaid = paymentStatus.toLowerCase() == "paid";

    return WillPopScope(
      onWillPop: () async {
        // Instead of going back, redirect to NavigationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
        );
        return false; // prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Order Details"),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Same behavior for app bar back button
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  title: "🧾 Order Details",
                  color: Colors.white,
                  children: [
                    _buildRow("Order No:", orderNo),
                    _buildRow("Delivery Address:", deliveryAddress),
                    _buildRow("Scheduled For:", scheduledFor),
                    _buildRow("Quantity:", quantity),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCard(
                  title: "💰 Payment Details",
                  color: Colors.yellow.shade100,
                  children: [
                    _buildRow(
                      "Total Amount:",
                      "KES ${totalAmount.toStringAsFixed(2)}",
                      valueColor: Colors.black87,
                    ),
                    _buildRow(
                      "Payment Status:",
                      paymentStatus,
                      valueColor: isPaid ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isPaid && trucks.isNotEmpty)
                  _buildCard(
                    title: "🚛 Assigned Trucks",
                    color: Colors.lightBlue.shade50,
                    children:
                        trucks.map((truck) => _buildTruckTile(truck)).toList(),
                  ),
                if (!isPaid)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
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
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text("Make Payment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckTile(Map<String, String> truck) {
    Color statusColor;
    switch (truck['status']?.toLowerCase()) {
      case 'assigned':
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
}
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
//   //       Uri.parse('$baseUrl/rides/${widget.orderId}'),
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
//   //       Uri.parse('$baseUrl/rides/${widget.rideId}'),
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
//         Uri.parse('$baseUrl/rides/${widget.rideId}/$categoryType'),
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
// //       Uri.parse('$baseUrl/rides/orders/$orderId'),
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
