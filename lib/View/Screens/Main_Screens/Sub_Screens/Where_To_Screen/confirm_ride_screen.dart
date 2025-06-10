// import 'package:flutter/material.dart';

// class ConfirmRideScreen extends StatelessWidget {
//   final String category;
//   final double fare;
//   final String pickup;
//   final String destination;

//   const ConfirmRideScreen({
//     super.key,
//     required this.category,
//     required this.fare,
//     required this.pickup,
//     required this.destination,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Confirm Ride"),
//         backgroundColor: Colors.red,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildRideDetail("Pickup Location", pickup),
//             const SizedBox(height: 10),
//             _buildRideDetail("Destination", destination),
//             const SizedBox(height: 10),
//             _buildRideDetail("Vehicle Category", category),
//             const SizedBox(height: 10),
//             _buildRideDetail(
//               "Estimated Fare",
//               "KES ${fare.toStringAsFixed(2)}",
//             ),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/driverConfirmation');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   padding: const EdgeInsets.symmetric(vertical: 16.0),
//                   textStyle: const TextStyle(fontSize: 18),
//                 ),
//                 child: const Text("Confirm Ride"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRideDetail(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 16, color: Colors.black87),
//         ),
//         const Divider(thickness: 1.2),
//       ],
//     );
//   }
// }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/http.dart' as ref;
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';

// class ConfirmRideScreen extends StatefulWidget {
//   final String category;
//   final double fare;
//   final LatLng pickup;
//   final LatLng destination;

//   const ConfirmRideScreen({
//     super.key,
//     required this.category,
//     required this.fare,
//     required this.pickup,
//     required this.destination,
//   });

//   @override
//   State<ConfirmRideScreen> createState() => _ConfirmRideScreenState();
// }

// class _ConfirmRideScreenState extends State<ConfirmRideScreen> {
//   double distanceInKm = 0;
//   int durationInMinutes = 0;
//   List<LatLng> routePoints = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchRoute();
//   }

//   void _linkNearestDriver(String category) {
//     final pickup = widget.pickup;

//     final mockDrivers = [
//       Driver(
//         name: "James",
//         vehicle: "Toyota Axio",
//         category: "Sedan",
//         location: LatLng(-1.2921, 36.8219),
//         registrationNumber: "KDA 123A",
//         color: "Silver",
//         photoUrl: "https://example.com/james.jpg",
//       ),
//       Driver(
//         name: "Aisha",
//         vehicle: "Nissan Xtrail",
//         category: "SUV",
//         location: LatLng(-1.3000, 36.8100),
//         registrationNumber: "KBX 456B",
//         color: "White",
//         photoUrl: "https://example.com/aisha.jpg",
//       ),
//       Driver(
//         name: "Otieno",
//         vehicle: "Bajaj Boxer",
//         category: "Bike",
//         location: LatLng(-1.2950, 36.8000),
//         registrationNumber: "KBG 456B",
//         color: "White",
//         photoUrl: "https://example.com/Otieno.jpg",
//       ),
//     ];

//     final filtered = mockDrivers.where((d) => d.category == category).toList();

//     final Distance distance = Distance();
//     Driver? nearest;
//     double? minDist;

//     for (var driver in filtered) {
//       final d = distance(pickup, driver.location);
//       if (minDist == null || d < minDist) {
//         nearest = driver;
//         minDist = d;
//       }
//     }

//     ref.read(availableDriversProvider.notifier).state = filtered;
//     ref.read(linkedDriverProvider.notifier).state = nearest;
//   }

//   Future<void> _fetchRoute() async {
//     final url = Uri.parse(
//       'https://router.project-osrm.org/route/v1/driving/${widget.pickup.longitude},${widget.pickup.latitude};${widget.destination.longitude},${widget.destination.latitude}?overview=full&geometries=geojson',
//     );

//     final response = await http.get(url);
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final route = data['routes'][0];
//       final geometry = route['geometry']['coordinates'];
//       final distance = route['distance']; // meters
//       final duration = route['duration']; // seconds

//       setState(() {
//         distanceInKm = distance / 1000;
//         durationInMinutes = (duration / 60).round();
//         routePoints =
//             geometry
//                 .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
//                 .toList();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Confirm Ride"),
//         backgroundColor: Colors.red,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 2,
//             child: FlutterMap(
//               options: MapOptions(center: widget.pickup, zoom: 13.0),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   subdomains: const ['a', 'b', 'c'],
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: widget.pickup,
//                       width: 40,
//                       height: 40,
//                       builder:
//                           (ctx) => const Icon(
//                             Icons.location_pin,
//                             color: Colors.green,
//                             size: 35,
//                           ),
//                     ),
//                     Marker(
//                       point: widget.destination,
//                       width: 40,
//                       height: 40,
//                       builder:
//                           (ctx) => const Icon(
//                             Icons.flag,
//                             color: Colors.red,
//                             size: 35,
//                           ),
//                     ),
//                   ],
//                 ),
//                 if (routePoints.isNotEmpty)
//                   PolylineLayer(
//                     polylines: [
//                       Polyline(
//                         points: routePoints,
//                         color: Colors.blue,
//                         strokeWidth: 5.0,
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildRideDetail("Vehicle Category", widget.category),
//                   _buildRideDetail(
//                     "Estimated Fare",
//                     "KES ${widget.fare.toStringAsFixed(2)}",
//                   ),
//                   _buildRideDetail(
//                     "Distance",
//                     "${distanceInKm.toStringAsFixed(2)} km",
//                   ),
//                   _buildRideDetail("ETA", "$durationInMinutes minutes"),
//                   const Spacer(),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         ref
//                             .read(selectedCategoryProvider.notifier as Uri)
//                             .state = category;
//                         ref.read(estimatedFareProvider.notifier as Uri).state =
//                             fare;
//                         _linkNearestDriver(category);
//                         final driver = ref.read(linkedDriverProvider);
//                         if (driver != null) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (_) => DriverConfirmationScreen(
//                                     driver: driver,
//                                     onConfirm: () {
//                                       ref
//                                           .read(rideConfirmedProvider.notifier)
//                                           .state = true;
//                                       Navigator.pop(
//                                         context,
//                                       ); // Close confirmation
//                                       setState(
//                                         () {},
//                                       ); // Rebuild HomeScreen to show RideInProgress
//                                     },
//                                   ),
//                             ),
//                           );
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         padding: const EdgeInsets.symmetric(vertical: 16.0),
//                         textStyle: const TextStyle(fontSize: 18),
//                       ),
//                       child: const Text("Confirm Ride"),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRideDetail(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 16, color: Colors.black87),
//         ),
//         const Divider(thickness: 1.2),
//       ],
//     );
//   }
// }
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';

// Import Riverpod (assuming you're using it)
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmRideScreen extends ConsumerStatefulWidget {
  final String category;
  final double fare;
  final LatLng pickup;
  final LatLng destination;

  const ConfirmRideScreen({
    super.key,
    required this.category,
    required this.fare,
    required this.pickup,
    required this.destination,
    String? selectedCategory,
  });

  @override
  ConsumerState<ConfirmRideScreen> createState() => _ConfirmRideScreenState();
}

class _ConfirmRideScreenState extends ConsumerState<ConfirmRideScreen> {
  double distanceInKm = 0;
  int durationInMinutes = 0;
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  void _linkNearestDriver(String category) {
    final pickup = widget.pickup;

    final mockDrivers = [
      Driver(
        name: "James",
        vehicle: "Toyota Axio",
        category: "Sedan",
        location: LatLng(-1.2921, 36.8219),
        registrationNumber: "KDA 123A",
        color: "Silver",
        photoUrl: "https://example.com/james.jpg",
        phoneNumber: "+254707378026",
      ),
      Driver(
        name: "Aisha",
        vehicle: "Nissan Xtrail",
        category: "SUV",
        location: LatLng(-1.3000, 36.8100),
        registrationNumber: "KBX 456B",
        color: "White",
        photoUrl: "https://example.com/aisha.jpg",
        phoneNumber: "+254707378026",
      ),
      Driver(
        name: "Otieno",
        vehicle: "Bajaj Boxer",
        category: "Bike",
        location: LatLng(-1.2950, 36.8000),
        registrationNumber: "KBG 456B",
        color: "White",
        photoUrl: "https://example.com/Otieno.jpg",
        phoneNumber: "+254707378026",
      ),
    ];

    final filtered = mockDrivers.where((d) => d.category == category).toList();

    final Distance distance = Distance();
    Driver? nearest;
    double? minDist;

    for (var driver in filtered) {
      final d = distance(pickup, driver.location);
      if (minDist == null || d < minDist) {
        nearest = driver;
        minDist = d;
      }
    }

    ref.read(availableDriversProvider.notifier).state = filtered;
    ref.read(linkedDriverProvider.notifier).state = nearest;
  }

  Future<void> _fetchRoute() async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${widget.pickup.longitude},${widget.pickup.latitude};${widget.destination.longitude},${widget.destination.latitude}?overview=full&geometries=geojson',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];
      final geometry = route['geometry']['coordinates'];
      final distance = route['distance']; // meters
      final duration = route['duration']; // seconds

      setState(() {
        distanceInKm = distance / 1000;
        durationInMinutes = (duration / 60).round();
        routePoints =
            geometry
                .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                .toList();
      });
    }
  }

  //   @override
  //   Widget build(BuildContext context) {
  //     final category = widget.category;
  //     final fare = widget.fare;

  //     return Scaffold(
  //       // appBar: AppBar(
  //       //   title: const Text("Confirm Ride"),
  //       //   backgroundColor: Colors.red,
  //       // ),
  //       body: Column(
  //         children: [
  //           Expanded(
  //             flex: 2,
  //             child: FlutterMap(
  //               options: MapOptions(center: widget.pickup, zoom: 13.0),
  //               children: [
  //                 TileLayer(
  //                   urlTemplate:
  //                       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  //                   subdomains: const ['a', 'b', 'c'],
  //                 ),
  //                 MarkerLayer(
  //                   markers: [
  //                     Marker(
  //                       point: widget.pickup,
  //                       width: 40,
  //                       height: 40,
  //                       builder:
  //                           (ctx) => const Icon(
  //                             Icons.location_pin,
  //                             color: Colors.green,
  //                             size: 35,
  //                           ),
  //                     ),
  //                     Marker(
  //                       point: widget.destination,
  //                       width: 40,
  //                       height: 40,
  //                       builder:
  //                           (ctx) => const Icon(
  //                             Icons.flag,
  //                             color: Colors.red,
  //                             size: 35,
  //                           ),
  //                     ),
  //                   ],
  //                 ),
  //                 if (routePoints.isNotEmpty)
  //                   PolylineLayer(
  //                     polylines: [
  //                       Polyline(
  //                         points: routePoints,
  //                         color: Colors.blue,
  //                         strokeWidth: 5.0,
  //                       ),
  //                     ],
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),

  //       Positioned(
  //       bottom: 0,
  //       left: 0,
  //       right: 0,
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black12,
  //               blurRadius: 8,
  //               offset: Offset(0, -2),
  //             ),
  //           ],
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Compact row with Pickup, Category, and Fare
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Expanded(
  //                   child: Text(
  //                     widget.pickup.toString() ?? 'Pickup',
  //                     overflow: TextOverflow.ellipsis,
  //                     style: const TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Text(
  //                   widget.category,
  //                   style: const TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Text(
  //                   "KES ${fare.toStringAsFixed(2)}",
  //                   style: const TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.blueAccent,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 10),
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton(
  //                 onPressed: () {
  //                   ref.read(selectedCategoryProvider.notifier).state =
  //                       widget.category;
  //                   ref.read(estimatedFareProvider.notifier).state = fare;
  //                   _linkNearestDriver(widget.category);

  //                   final driver = ref.read(linkedDriverProvider);
  //                   if (driver != null) {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => DriverConfirmationScreen(
  //                           driver: driver,
  //                           onConfirm: () {
  //                             ref.read(rideConfirmedProvider.notifier).state =
  //                                 true;
  //                             Navigator.pop(context);
  //                             setState(() {});
  //                           },
  //                           pickup: widget.pickup,
  //                         ),
  //                       ),
  //                     );
  //                   }
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.blueAccent,
  //                   padding: const EdgeInsets.symmetric(vertical: 12.0),
  //                   textStyle: const TextStyle(fontSize: 16),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //                 child: const Text("Confirm Ride"),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   },
  // }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final fare = widget.fare;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 2,
                child: FlutterMap(
                  options: MapOptions(center: widget.pickup, zoom: 13.0),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.pickup,
                          width: 40,
                          height: 40,
                          builder:
                              (ctx) => const Icon(
                                Icons.location_pin,
                                color: Colors.green,
                                size: 35,
                              ),
                        ),
                        Marker(
                          point: widget.destination,
                          width: 40,
                          height: 40,
                          builder:
                              (ctx) => const Icon(
                                Icons.flag,
                                color: Colors.red,
                                size: 35,
                              ),
                        ),
                      ],
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.blue,
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Positioned Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup
                  Text(
                    "Pickup: ${widget.pickup.toString()}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Category
                  Text(
                    "Category: ${widget.category}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Fare
                  Text(
                    "Fare: KES ${fare.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(selectedCategoryProvider.notifier).state =
                            widget.category;
                        ref.read(estimatedFareProvider.notifier).state = fare;
                        _linkNearestDriver(widget.category);

                        final driver = ref.read(linkedDriverProvider);
                        if (driver != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DriverConfirmationScreen(
                                    driver: driver,
                                    onConfirm: () {
                                      ref
                                          .read(rideConfirmedProvider.notifier)
                                          .state = true;
                                      Navigator.pop(context);
                                      setState(() {});
                                    },
                                    pickup: widget.pickup,
                                  ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Confirm Ride"),
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
}

//   Widget _buildRideDetail(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 16, color: Colors.black87),
//         ),
//         const Divider(thickness: 1.2),
//       ],
//     );
//   }
// }
