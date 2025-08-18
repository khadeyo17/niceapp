// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key, required category});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   LatLng? currentLocation;

//   // Mock vehicle locations (nearby)
//   final List<LatLng> nearbyVehicles = [
//     LatLng(-1.284, 36.822),
//     LatLng(-1.285, 36.820),
//     LatLng(-1.286, 36.823),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   // Future<void> _getCurrentLocation() async {
//   //   final permission = await Geolocator.requestPermission();
//   //   if (permission == LocationPermission.deniedForever ||
//   //       permission == LocationPermission.denied) {
//   //     return;
//   //   }

//   //   final position = await Geolocator.getCurrentPosition(
//   //     desiredAccuracy: LocationAccuracy.high,
//   //   );
//   //   setState(() {
//   //     currentLocation = LatLng(position.latitude, position.longitude);
//   //   });
//   // }
//   Future<void> _getCurrentLocation() async {
//     final permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.deniedForever ||
//         permission == LocationPermission.denied) {
//       return;
//     }

//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     setState(() {
//       currentLocation = LatLng(position.latitude, position.longitude);
//     });
//   }

//   void _navigateToWhereTo() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => WhereToScreen(category: VehicleCategory.passenger),
//       ),
//     );
//     // context.pushNamed(Routes().whereTo);
//     // //Navigator.pushNamed(context, '/whereto');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body:
//           currentLocation == null
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   FlutterMap(
//                     options: MapOptions(center: currentLocation, zoom: 15),
//                     children: [
//                       TileLayer(
//                         urlTemplate:
//                             'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                         subdomains: const ['a', 'b', 'c'],
//                       ),
//                       MarkerLayer(
//                         markers: [
//                           // Current user location
//                           Marker(
//                             point: currentLocation!,
//                             width: 40,
//                             height: 40,
//                             builder:
//                                 (ctx) => const Icon(
//                                   Icons.my_location,
//                                   color: Colors.blue,
//                                   size: 32,
//                                 ),
//                           ),
//                           // Nearby vehicles
//                           ...nearbyVehicles.map(
//                             (vehicle) => Marker(
//                               point: vehicle,
//                               width: 30,
//                               height: 30,
//                               builder:
//                                   (ctx) => const Icon(
//                                     Icons.local_taxi,
//                                     color: Colors.yellow,
//                                     size: 28,
//                                   ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   // Search bar over the map
//                   Positioned(
//                     bottom: 20,
//                     left: 10,
//                     right: 10,
//                     child: GestureDetector(
//                       onTap: _navigateToWhereTo,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 14,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: const [
//                             BoxShadow(color: Colors.black26, blurRadius: 4),
//                           ],
//                         ),
//                         child: const Row(
//                           children: [
//                             Icon(Icons.search, color: Colors.grey),
//                             SizedBox(width: 10),
//                             Text(
//                               'Where to?',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.redAccent,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }
// }
