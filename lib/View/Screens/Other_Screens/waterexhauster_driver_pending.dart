import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';

class DriverAssignmentsScreen extends StatefulWidget {
  final LatLng destination;
  final int rideId;
  final Subcategory category;
  final double fare;
  final LatLng? pickup;

  const DriverAssignmentsScreen({
    super.key,
    required this.destination,
    required this.category,
    required this.fare,
    required this.rideId,
    this.pickup,
  });

  @override
  State<DriverAssignmentsScreen> createState() =>
      _DriverAssignmentScreenState();
}

class _DriverAssignmentScreenState extends State<DriverAssignmentsScreen> {
  Map<String, dynamic>? driverData;
  String? eta;
  double? distanceKm;
  LatLng? driverLocation;

  bool isLoading = true;
  bool isCancelling = false;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    fetchAssignment();
  }

  Future<void> fetchAssignment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final url = Uri.parse('$baseUrl/rides/myrides/${widget.rideId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['driver'] != null) {
          setState(() {
            driverData = data['driver'];
            driverLocation = LatLng(
              data['driver']['latitude'],
              data['driver']['longitude'],
            );
            isLoading = false;

            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('driver'),
                position: driverLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                infoWindow: InfoWindow(title: 'Driver Location'),
              ),
            );
            _markers.add(
              Marker(
                markerId: const MarkerId('destination'),
                position: widget.destination,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(title: 'Destination'),
              ),
            );
          });

          await calculateETAAndDistance(driverLocation!);
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching assignment: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> calculateETAAndDistance(LatLng driverLoc) async {
    final dest = widget.destination;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLoc.latitude},${driverLoc.longitude}&destination=${dest.latitude},${dest.longitude}&key=$mapKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0]['legs'][0];
        setState(() {
          eta = route['duration']['text'];
          distanceKm = route['distance']['value'] / 1000.0;
        });
      }
    } catch (e) {
      debugPrint('Error calculating ETA: $e');
    }
  }

  Future<void> cancelRequest() async {
    setState(() => isCancelling = true);
    final response = await http.post(
      Uri.parse('$baseUrl/rides/cancel/${widget.rideId}'),
    );
    setState(() => isCancelling = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cancellation failed')));
    }
  }

  Future<void> launchAction(String type, String value) async {
    final uri = switch (type) {
      'call' => Uri.parse('tel:$value'),
      'sms' => Uri.parse('sms:$value'),
      'whatsapp' => Uri.parse('https://wa.me/$value'),
      _ => null,
    };

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Driver Assignment"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : driverData == null
              ? const Center(child: Text("No driver assigned yet."))
              : _buildDriverDetails(),
    );
  }

  Widget _buildDriverDetails() {
    final phone = driverData!['phoneNumber'];

    return Column(
      children: [
        if (driverLocation != null) _buildMapSection(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (driverData!['photoUrl'] != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              driverData!['photoUrl'],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          "${driverData!['firstName']} ${driverData!['lastName'] ?? ''}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("📞 $phone"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call),
                              onPressed: () => launchAction('call', phone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.sms),
                              onPressed: () => launchAction('sms', phone),
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.whatsapp),
                            //   onPressed: () => launchAction('whatsapp', phone),
                            // ),
                          ],
                        ),
                        const Divider(height: 30),
                        ListTile(
                          leading: const Icon(Icons.directions_car, size: 30),
                          title: Text(
                            "${driverData!['vehicleMake']} ${driverData!['vehicleModel']}",
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Color: ${driverData!['vehicleColour']}"),
                              Text(
                                "Plate: ${driverData!['registrationNumber']}",
                              ),
                            ],
                          ),
                        ),
                        if (eta != null || distanceKm != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            "ETA: $eta",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Distance: ${distanceKm?.toStringAsFixed(2)} km",
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                isCancelling
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: cancelRequest,
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancel Ride"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return SizedBox(
      height: 250,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: driverLocation!,
          zoom: 14,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          // Optionally animate camera to fit both markers (driver & destination)
          _fitMapToMarkers();
        },
      ),
    );
  }

  Future<void> _fitMapToMarkers() async {
    if (_mapController == null || driverLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(driverLocation!.latitude, widget.destination.latitude),
        min(driverLocation!.longitude, widget.destination.longitude),
      ),
      northeast: LatLng(
        max(driverLocation!.latitude, widget.destination.latitude),
        max(driverLocation!.longitude, widget.destination.longitude),
      ),
    );

    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    await _mapController!.animateCamera(cameraUpdate);
  }
}

// Utility functions (add import 'dart:math'; at the top)

double min(double a, double b) => (a < b) ? a : b;
double max(double a, double b) => (a > b) ? a : b;

// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_map/flutter_map.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';

// class DriverAssignmentsScreen extends StatefulWidget {
//   final LatLng destination;
//   final int rideId;
//   final Subcategory category;
//   final double fare;

//   const DriverAssignmentsScreen({
//     super.key,
//     required this.destination,
//     required this.category,
//     required this.fare,
//     required this.rideId,
//   });

//   @override
//   State<DriverAssignmentsScreen> createState() =>
//       _DriverAssignmentScreenState();
// }

// class _DriverAssignmentScreenState extends State<DriverAssignmentsScreen> {
//   Map<String, dynamic>? driverData;
//   String? eta;
//   double? distanceKm;
//   LatLng? driverLocation;

//   bool isLoading = true;
//   bool isCancelling = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchAssignment();
//   }

//   Future<void> fetchAssignment() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final url = Uri.parse('$baseUrl/rides/myrides/${widget.rideId}');

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['driver'] != null) {
//           setState(() {
//             driverData = data['driver'];
//             driverLocation = LatLng(
//               data['driver']['latitude'],
//               data['driver']['longitude'],
//             );
//             isLoading = false;
//           });

//           await calculateETAAndDistance(driverLocation!);
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       debugPrint('Error fetching assignment: $e');
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> calculateETAAndDistance(LatLng driverLoc) async {
//     final dest = widget.destination;
//     //const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual key

//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLoc.latitude},${driverLoc.longitude}&destination=${dest.latitude},${dest.longitude}&key=$mapKey',
//     );

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final route = data['routes'][0]['legs'][0];
//         setState(() {
//           eta = route['duration']['text'];
//           distanceKm = route['distance']['value'] / 1000.0;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error calculating ETA: $e');
//     }
//   }

//   Future<void> cancelRequest() async {
//     setState(() => isCancelling = true);
//     final response = await http.post(
//       Uri.parse('$baseUrl/rides/cancel/${widget.rideId}'),
//     );
//     setState(() => isCancelling = false);

//     if (response.statusCode == 200) {
//       Navigator.pop(context);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Cancellation failed')));
//     }
//   }

//   Future<void> launchAction(String type, String value) async {
//     final uri = switch (type) {
//       'call' => Uri.parse('tel:$value'),
//       'sms' => Uri.parse('sms:$value'),
//       'whatsapp' => Uri.parse('https://wa.me/$value'),
//       _ => null,
//     };

//     if (uri != null && await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Driver Assignment"),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       body:
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : driverData == null
//               ? const Center(child: Text("No driver assigned yet."))
//               : _buildDriverDetails(),
//     );
//   }

//   Widget _buildDriverDetails() {
//     final phone = driverData!['phoneNumber'];

//     return Column(
//       children: [
//         if (driverLocation != null) _buildMapSection(),
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 4,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       children: [
//                         if (driverData!['photoUrl'] != null)
//                           CircleAvatar(
//                             radius: 40,
//                             backgroundImage: NetworkImage(
//                               driverData!['photoUrl'],
//                             ),
//                           ),
//                         const SizedBox(height: 12),
//                         Text(
//                           "${driverData!['firstName']} ${driverData!['lastName'] ?? ''}",
//                           style: const TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text("📞 $phone"),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.call),
//                               onPressed: () => launchAction('call', phone),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.sms),
//                               onPressed: () => launchAction('sms', phone),
//                             ),
//                             // IconButton(
//                             //   icon: const Icon(Icons.whatsapp),
//                             //   onPressed: () => launchAction('whatsapp', phone),
//                             // ),
//                           ],
//                         ),
//                         const Divider(height: 30),
//                         ListTile(
//                           leading: const Icon(Icons.directions_car, size: 30),
//                           title: Text(
//                             "${driverData!['vehicleMake']} ${driverData!['vehicleModel']}",
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("Color: ${driverData!['vehicleColour']}"),
//                               Text(
//                                 "Plate: ${driverData!['registrationNumber']}",
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (eta != null || distanceKm != null) ...[
//                           const SizedBox(height: 10),
//                           Text(
//                             "ETA: $eta",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           Text(
//                             "Distance: ${distanceKm?.toStringAsFixed(2)} km",
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 isCancelling
//                     ? const CircularProgressIndicator()
//                     : SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: cancelRequest,
//                         icon: const Icon(Icons.cancel),
//                         label: const Text("Cancel Ride"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                         ),
//                       ),
//                     ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMapSection() {
//     return SizedBox(
//       height: 250,
//       child: FlutterMap(
//         options: MapOptions(center: driverLocation, zoom: 13),
//         children: [
//           TileLayer(
//             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//             userAgentPackageName: 'com.example.app',
//           ),
//           MarkerLayer(
//             markers: [
//               Marker(
//                 point: driverLocation!,
//                 width: 60,
//                 height: 60,
//                 builder:
//                     (_) => const Icon(
//                       Icons.local_shipping,
//                       color: Colors.blue,
//                       size: 40,
//                     ),
//               ),
//               Marker(
//                 point: widget.destination,
//                 width: 60,
//                 height: 60,
//                 builder:
//                     (_) => const Icon(
//                       Icons.location_pin,
//                       color: Colors.red,
//                       size: 40,
//                     ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
