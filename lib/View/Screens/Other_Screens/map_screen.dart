// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:niceapp/Container/utils/keys.dart'; // Import API key
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

// class MapScreen extends ConsumerStatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends ConsumerState<MapScreen> {
//   final Completer<GoogleMapController> _controller = Completer();
//   static const CameraPosition _initialPosition = CameraPosition(
//     target: LatLng(-1.286389, 36.817223), // Default location (Nairobi)
//     zoom: 14,
//   );

//   LatLng _currentLocation = const LatLng(-1.286389, 36.817223);

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       ref.read(homeScreenPickUpLocationProvider.notifier).state = null;
//     });
//     _checkPermissionsAndFetchLocation();
//   }

//   Future<void> _checkPermissionsAndFetchLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showErrorDialog("Location services are disabled. Please enable them.");
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showErrorDialog("Location permission denied. Please allow access.");
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showErrorDialog("Location permissions are permanently denied. Enable them in settings.");
//       return;
//     }

//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       setState(() {
//         _currentLocation = LatLng(position.latitude, position.longitude);
//       });

//       final GoogleMapController controller = await _controller.future;
//       controller.animateCamera(CameraUpdate.newLatLng(_currentLocation));

//       ref.read(homeScreenPickUpLocationProvider.notifier).state = LocationModel(
//         humanReadableAddress: "Current Location",
//         latLng: _currentLocation,
//       );
//     } catch (e) {
//       _showErrorDialog("Error getting location: $e");
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Location Error"),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     final userLocation = ref.watch(homeScreenPickUpLocationProvider);

//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: _initialPosition,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             mapType: MapType.normal,
//             onMapCreated: (GoogleMapController controller) {
//               _controller.complete(controller);
//             },
//           ),
//           Positioned(
//             bottom: 0,
//             child: Container(
//               height: 320,
//               width: size.width,
//               decoration: const BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   children: [
//                     buildLocationField("From", Icons.start_outlined, userLocation?.humanReadableAddress ?? "Loading ..."),
//                     buildLocationField("To", Icons.pin_drop_outlined, "Where To", isDestination: true),
//                     buildBottomButtons(context, size),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildLocationField(String label, IconData icon, String text, {bool isDestination = false}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10.0),
//           child: Text(label, style: Theme.of(context).textTheme.bodySmall),
//         ),
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: const BoxDecoration(
//             border: Border(bottom: BorderSide(color: Colors.blue)),
//           ),
//           child: Row(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(right: 10.0),
//                 child: Icon(icon, color: Colors.blue),
//               ),
//               Expanded(
//                 child: Text(text, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildBottomButtons(BuildContext context, Size size) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 20.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           buildButton("Change Pickup Location", Colors.blue, () {
//             HomeScreenLogics().changePickUpLoc(context, ref, _controller.future as GoogleMapController);
//           }),
//           buildButton("Request a Ride", Colors.orange, () {
//             HomeScreenLogics().requestARide(size, context, ref, _controller.future as GoogleMapController);
//           }),
//         ],
//       ),
//     );
//   }

//   Widget buildButton(String text, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         alignment: Alignment.center,
//         height: 50,
//         width: MediaQuery.of(context).size.width * 0.4,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14.0),
//           color: color,
//         ),
//         child: Text(text, style: Theme.of(context).textTheme.bodySmall),
//       ),
//     );
//   }
// }
