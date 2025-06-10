// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:niceapp/Container/utils/firebase_messaging.dart';
// //import 'package:niceapp/Container/utils/set_blackmap.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

// class RideBookingScreen extends ConsumerStatefulWidget {
//   const RideBookingScreen({super.key});

//   @override
//   ConsumerState<RideBookingScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<RideBookingScreen> {
//   final TextEditingController whereToController = TextEditingController();
//   final Completer<GoogleMapController> completer = Completer();
//   GoogleMapController? controller;

//   Future<void> requestPermissions() async {
//     await Permission.location.request();
//     await Permission.locationWhenInUse.request();
//     await Permission.locationAlways.request();
//   }

//   @override
//   void initState() {
//     super.initState();
//     requestPermissions();
//     MessagingService().init(context, ref);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     final polylines = ref.watch(homeScreenMainPolylinesProvider);
//     final markers = ref.watch(homeScreenMainMarkersProvider);
//     final circles = ref.watch(homeScreenMainCirclesProvider);
//     final userLocation = ref.watch(homeScreenPickUpLocationProvider);

//     return Scaffold(
//       body: SafeArea(
//         child: SizedBox(
//           width: size.width,
//           height: size.height,
//           child: Stack(
//             children: [
//               GoogleMap(
//                 mapType: MapType.normal, // Normal map style
//                 myLocationButtonEnabled: true,
//                 myLocationEnabled: true,
//                 compassEnabled: true,
//                 trafficEnabled: true,
//                 zoomControlsEnabled: false,
//                 initialCameraPosition: CameraPosition(
//                   target: userLocation?.latLng ?? const LatLng(0.0, 0.0),
//                   zoom: 14,
//                 ),
//                 polylines: polylines,
//                 markers: markers,
//                 circles: circles,
//                 onMapCreated: (GoogleMapController mapController) async {
//                   completer.complete(mapController);
//                   controller = await completer.future;

//                   // REMOVE THIS to keep map normal
//                   // SetBlackMap().setBlackMapTheme(controller!);

//                   HomeScreenLogics().getUserLoc(context, ref, controller!);
//                 },
//                 onCameraMove: (CameraPosition pos) {
//                   if (ref.watch(homeScreenDropOffLocationProvider) != null)
//                     return;
//                   if (ref.watch(homeScreenCameraMovementProvider) !=
//                       pos.target) {
//                     ref
//                         .read(homeScreenCameraMovementProvider.notifier)
//                         .update((_) => pos.target);
//                   }
//                 },
//                 onCameraIdle: () {
//                   if (ref.watch(homeScreenDropOffLocationProvider) != null)
//                     return;
//                   HomeScreenLogics().getAddressfromCordinates(context, ref);
//                 },
//               ),
//               ref.watch(homeScreenDropOffLocationProvider) != null
//                   ? const SizedBox()
//                   : const Align(
//                     alignment: Alignment.center,
//                     child: Icon(
//                       Icons.location_on,
//                       size: 50,
//                       color: Colors.black,
//                     ),
//                   ),
//               Positioned(
//                 bottom: 0,
//                 child: Container(
//                   width: size.width,
//                   padding: const EdgeInsets.all(16),
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       buildLocationField(
//                         context,
//                         "From",
//                         Icons.my_location,
//                         userLocation?.humanReadableAddress ??
//                             "Detecting location...",
//                         textColor: Colors.black,
//                         isDestination: false,
//                       ),
//                       buildLocationField(
//                         context,
//                         "To",
//                         Icons.pin_drop_outlined,
//                         ref
//                                 .watch(homeScreenDropOffLocationProvider)
//                                 ?.locationName ??
//                             "Where To",
//                         textColor: Colors.black,
//                         isDestination: true,
//                       ),
//                       const SizedBox(height: 10), // Smaller bottom padding
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildLocationField(
//     BuildContext context,
//     String label,
//     IconData icon,
//     String text, {
//     required Color textColor,
//     bool isDestination = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         InkWell(
//           onTap: () async {
//             await context.pushNamed(Routes().whereTo, extra: controller);
//             if (context.mounted) {
//               HomeScreenLogics().openWhereToScreen(context, ref, controller!);
//             }
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//             decoration: BoxDecoration(
//               border: Border(bottom: BorderSide(color: Colors.white)),
//             ),
//             child: Row(
//               children: [
//                 Icon(icon, color: Colors.white),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     text,
//                     style: TextStyle(color: textColor, fontSize: 16),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildBottomButtons(BuildContext context, Size size) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         buildButton(
//           "Change Pickup",
//           onTap: () async {
//             // Get user location again
//             if (controller != null) {
//               HomeScreenLogics().getUserLoc(context, ref, controller!);
//               // Move camera to new location
//               final userLoc = ref.read(homeScreenPickUpLocationProvider);
//               if (userLoc != null) {
//                 await controller!.animateCamera(
//                   CameraUpdate.newLatLng(userLoc.latLng),
//                 );
//               }
//             }
//           },
//         ),
//         buildButton(
//           "Request Ride",
//           onTap: () {
//             final pickUp = ref.read(homeScreenPickUpLocationProvider);
//             final dropOff = ref.read(homeScreenDropOffLocationProvider);

//             if (pickUp != null && dropOff != null) {
//               // Navigate to ride request screen or next step
//               context.pushNamed(
//                 Routes().home, // assuming you have a rideRequest route
//                 extra: {"pickup": pickUp, "dropoff": dropOff},
//               );
//             } else {
//               // Show error
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Please select both pickup and destination.'),
//                 ),
//               );
//             }
//           },
//         ),
//       ],
//     );
//   }

//   Widget buildButton(String text, {required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.4,
//         height: 50,
//         decoration: BoxDecoration(
//           color: Colors.yellow, // Yellow buttons
//           borderRadius: BorderRadius.circular(12),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           text,
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:niceapp/View/Routes/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation;

  // Mock vehicle locations (nearby)
  final List<LatLng> nearbyVehicles = [
    LatLng(-1.284, 36.822),
    LatLng(-1.285, 36.820),
    LatLng(-1.286, 36.823),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _navigateToWhereTo() {
    context.pushNamed(Routes().whereTo);
    //Navigator.pushNamed(context, '/whereto');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(center: currentLocation, zoom: 15),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          // Current user location
                          Marker(
                            point: currentLocation!,
                            width: 40,
                            height: 40,
                            builder:
                                (ctx) => const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                          ),
                          // Nearby vehicles
                          ...nearbyVehicles.map(
                            (vehicle) => Marker(
                              point: vehicle,
                              width: 30,
                              height: 30,
                              builder:
                                  (ctx) => const Icon(
                                    Icons.local_taxi,
                                    color: Colors.yellow,
                                    size: 28,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Search bar over the map
                  Positioned(
                    bottom: 20,
                    left: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _navigateToWhereTo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 10),
                            Text(
                              'Where to?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
