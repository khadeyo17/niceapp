// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:niceapp/Container/utils/firebase_messaging.dart';
// import 'package:niceapp/Container/utils/set_blackmap.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   final TextEditingController whereToController = TextEditingController();
//   CameraPosition initpos = const CameraPosition(
//     target: LatLng(0.0, 0.0),
//     zoom: 14,
//   );

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

//     /// Watch providers
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
//                 mapType: MapType.normal,
//                 myLocationButtonEnabled: true,
//                 trafficEnabled: true,
//                 compassEnabled: true,
//                 buildingsEnabled: true,
//                 myLocationEnabled: true,
//                 zoomControlsEnabled: false,
//                 zoomGesturesEnabled: true,
//                 initialCameraPosition: CameraPosition(
//                   target: userLocation?.latLng ?? const LatLng(0.0, 0.0),
//                   zoom: 14,
//                 ),
//                 polylines: polylines.isNotEmpty ? polylines : {},
//                 markers: markers.isNotEmpty ? markers : {},
//                 circles: circles.isNotEmpty ? circles : {},
//                 onMapCreated: (GoogleMapController mapController) async {
//                   completer.complete(mapController);
//                   controller = await completer.future;
//                   SetBlackMap().setBlackMapTheme(controller!);
//                   HomeScreenLogics().getUserLoc(context, ref, controller!);
//                 },
//                 onCameraMove: (CameraPosition pos) {
//                   if (ref.watch(homeScreenDropOffLocationProvider) != null) {
//                     return;
//                   }
//                   if (ref.watch(homeScreenCameraMovementProvider) !=
//                       pos.target) {
//                     ref
//                         .watch(homeScreenCameraMovementProvider.notifier)
//                         .update((state) => pos.target);
//                   }
//                 },
//                 onCameraIdle: () {
//                   if (ref.watch(homeScreenDropOffLocationProvider) != null) {
//                     return;
//                   }
//                   HomeScreenLogics().getAddressfromCordinates(context, ref);
//                 },
//               ),
//               ref.watch(homeScreenDropOffLocationProvider) != null
//                   ? Container()
//                   : const Align(
//                     alignment: Alignment.center,
//                     child: Icon(
//                       Icons.location_on,
//                       size: 50,
//                       color: Colors.white,
//                     ),
//                   ),
//               Positioned(
//                 bottom: 0,
//                 child: Container(
//                   height: 320,
//                   width: size.width,
//                   decoration: const BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       children: [
//                         buildLocationField(
//                           context,
//                           "From",
//                           Icons.start_outlined,
//                           ref
//                                   .watch(homeScreenPickUpLocationProvider)
//                                   ?.humanReadableAddress ??
//                               "Loading ...",
//                         ),
//                         buildLocationField(
//                           context,
//                           "To",
//                           Icons.pin_drop_outlined,
//                           ref
//                                   .watch(homeScreenDropOffLocationProvider)
//                                   ?.locationName ??
//                               "Where To",
//                           isDestination: true,
//                         ),
//                         buildBottomButtons(context, size),
//                       ],
//                     ),
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
//     bool isDestination = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10.0),
//           child: Text(label, style: Theme.of(context).textTheme.bodySmall),
//         ),
//         InkWell(
//           onTap:
//               isDestination
//                   ? () async {
//                     await context.pushNamed(
//                       Routes().whereTo,
//                       extra: controller,
//                     );
//                     if (context.mounted) {
//                       HomeScreenLogics().openWhereToScreen(
//                         context,
//                         ref,
//                         controller!,
//                       );
//                     }
//                   }
//                   : null,
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: const BoxDecoration(
//               border: Border(bottom: BorderSide(color: Colors.blue)),
//             ),
//             child: Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(right: 10.0),
//                   child: Icon(icon, color: Colors.blue),
//                 ),
//                 Expanded(
//                   child: Text(
//                     text,
//                     style: Theme.of(context).textTheme.bodySmall,
//                     maxLines: 2,
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
//     return Padding(
//       padding: const EdgeInsets.only(top: 20.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           buildButton(
//             "Change Pickup Location",
//             Colors.blue,
//             () => HomeScreenLogics().changePickUpLoc(context, ref, controller!),
//           ),
//           buildButton(
//             "Request a Ride",
//             Colors.orange,
//             () => HomeScreenLogics().requestARide(
//               size,
//               context,
//               ref,
//               controller!,
//             ),
//           ),
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
//         width: MediaQuery.sizeOf(context).width * 0.4,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14.0),
//           color: color,
//         ),
//         child: Text(text, style: Theme.of(context).textTheme.bodySmall),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:niceapp/Container/utils/firebase_messaging.dart';
// import 'package:niceapp/Container/utils/set_blackmap.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   final TextEditingController whereToController = TextEditingController();
//   final Completer<GoogleMapController> completer = Completer();
//   GoogleMapController? controller;

//   @override
//   void initState() {
//     super.initState();
//     requestPermissions();
//     MessagingService().init(context, ref);
//   }

//   Future<void> requestPermissions() async {
//     await Permission.location.request();
//     await Permission.locationWhenInUse.request();
//     await Permission.locationAlways.request();
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final textColor = isDark ? Colors.white : Colors.black;
//     final containerColor = Colors.blue;
//     final buttonColor = Colors.yellow;

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
//                 mapType: MapType.normal,
//                 myLocationButtonEnabled: true,
//                 trafficEnabled: true,
//                 compassEnabled: true,
//                 buildingsEnabled: true,
//                 myLocationEnabled: true,
//                 zoomControlsEnabled: false,
//                 zoomGesturesEnabled: true,
//                 initialCameraPosition: CameraPosition(
//                   target: userLocation?.latLng ?? const LatLng(0.0, 0.0),
//                   zoom: 14,
//                 ),
//                 polylines: polylines.isNotEmpty ? polylines : {},
//                 markers: markers.isNotEmpty ? markers : {},
//                 circles: circles.isNotEmpty ? circles : {},
//                 onMapCreated: (GoogleMapController mapController) async {
//                   completer.complete(mapController);
//                   controller = await completer.future;
//                   SetBlackMap().setBlackMapTheme(
//                     controller!,
//                   ); // Set dark map style
//                   HomeScreenLogics().getUserLoc(context, ref, controller!);
//                 },
//                 onCameraMove: (CameraPosition pos) {
//                   if (ref.watch(homeScreenDropOffLocationProvider) != null)
//                     return;
//                   if (ref.watch(homeScreenCameraMovementProvider) !=
//                       pos.target) {
//                     ref
//                         .watch(homeScreenCameraMovementProvider.notifier)
//                         .update((state) => pos.target);
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
//                       color: Colors.blue,
//                     ),
//                   ),
//               Positioned(
//                 bottom: 0,
//                 child: Container(
//                   height: 320,
//                   width: size.width,
//                   decoration: BoxDecoration(
//                     color: containerColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       children: [
//                         buildLocationField(
//                           context,
//                           "From",
//                           Icons.start_outlined,
//                           ref
//                                   .watch(homeScreenPickUpLocationProvider)
//                                   ?.humanReadableAddress ??
//                               "Loading ...",
//                           textColor,
//                         ),
//                         buildLocationField(
//                           context,
//                           "To",
//                           Icons.pin_drop_outlined,
//                           ref
//                                   .watch(homeScreenDropOffLocationProvider)
//                                   ?.locationName ??
//                               "Where To",
//                           textColor,
//                           isDestination: true,
//                         ),
//                         buildBottomButtons(
//                           context,
//                           size,
//                           buttonColor,
//                           textColor,
//                         ),
//                       ],
//                     ),
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
//     String text,
//     Color textColor, {
//     bool isDestination = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10.0),
//           child: Text(
//             label,
//             style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
//           ),
//         ),
//         InkWell(
//           onTap:
//               isDestination
//                   ? () async {
//                     await context.pushNamed(
//                       Routes().whereTo,
//                       extra: controller,
//                     );
//                     if (context.mounted) {
//                       HomeScreenLogics().openWhereToScreen(
//                         context,
//                         ref,
//                         controller!,
//                       );
//                     }
//                   }
//                   : null,
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               border: Border(bottom: BorderSide(color: textColor)),
//             ),
//             child: Row(
//               children: [
//                 Icon(icon, color: textColor),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     text,
//                     style: TextStyle(color: textColor),
//                     maxLines: 2,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildBottomButtons(
//     BuildContext context,
//     Size size,
//     Color buttonColor,
//     Color textColor,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 20.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           buildButton("Change Pickup", buttonColor, textColor, () {
//             HomeScreenLogics().changePickUpLoc(context, ref, controller!);
//           }),
//           buildButton("Request Ride", buttonColor, textColor, () {
//             HomeScreenLogics().requestARide(size, context, ref, controller!);
//           }),
//         ],
//       ),
//     );
//   }

//   Widget buildButton(
//     String text,
//     Color buttonColor,
//     Color textColor,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         alignment: Alignment.center,
//         height: 50,
//         width: MediaQuery.sizeOf(context).width * 0.4,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14.0),
//           color: buttonColor,
//         ),
//         child: Text(
//           text,
//           style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:niceapp/Container/utils/firebase_messaging.dart';
// import 'package:niceapp/Container/utils/set_blackmap.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_logics.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_providers.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
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

//     final theme = Theme.of(context);
//     final bool isDark = theme.brightness == Brightness.dark;

//     return Scaffold(
//       body: SafeArea(
//         child: SizedBox(
//           width: size.width,
//           height: size.height,
//           child: Stack(
//             children: [
//               GoogleMap(
//                 mapType: MapType.normal,
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
//                   SetBlackMap().setBlackMapTheme(controller!);
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
//                       color: Colors.white, // Only black/white
//                     ),
//                   ),
//               Positioned(
//                 bottom: 0,
//                 child: Container(
//                   width: size.width,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.blue, // Blue background
//                     borderRadius: const BorderRadius.only(
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
//                         Icons.start_outlined,
//                         ref
//                                 .watch(homeScreenPickUpLocationProvider)
//                                 ?.humanReadableAddress ??
//                             "Loading...",
//                         textColor: Colors.white,
//                       ),
//                       buildLocationField(
//                         context,
//                         "To",
//                         Icons.pin_drop_outlined,
//                         ref
//                                 .watch(homeScreenDropOffLocationProvider)
//                                 ?.locationName ??
//                             "Where To",
//                         textColor: Colors.white,
//                         isDestination: true,
//                       ),
//                       const SizedBox(height: 20),
//                       buildBottomButtons(context, size),
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
//           onTap:
//               isDestination
//                   ? () async {
//                     await context.pushNamed(
//                       Routes().whereTo,
//                       extra: controller,
//                     );
//                     if (context.mounted) {
//                       HomeScreenLogics().openWhereToScreen(
//                         context,
//                         ref,
//                         controller!,
//                       );
//                     }
//                   }
//                   : null,
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
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   LatLng? currentLocation;
//   LatLng? destination;

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

//   Future<void> _navigateToWhereTo() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const WhereToScreen(),
//       ), // Replace with your actual screen
//     );

//     //Navigator.pushNamed(context, '/whereto');
//     if (result is LatLng) {
//       setState(() {
//         destination = result;
//       });
//     }
//   }

//   List<LatLng> _getRoute() {
//     if (currentLocation == null || destination == null) return [];
//     return [currentLocation!, destination!];
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
//                     options: MapOptions(
//                       center: destination ?? currentLocation,
//                       zoom: 15,
//                     ),
//                     children: [
//                       TileLayer(
//                         urlTemplate:
//                             'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                         subdomains: const ['a', 'b', 'c'],
//                       ),
//                       MarkerLayer(
//                         markers: [
//                           Marker(
//                             point: currentLocation!,
//                             width: 40,
//                             height: 40,
//                             builder:
//                                 (_) => const Icon(
//                                   Icons.my_location,
//                                   color: Colors.blue,
//                                   size: 32,
//                                 ),
//                           ),
//                           ...nearbyVehicles.map(
//                             (vehicle) => Marker(
//                               point: vehicle,
//                               width: 30,
//                               height: 30,
//                               builder:
//                                   (_) => const Icon(
//                                     Icons.local_taxi,
//                                     color: Colors.yellow,
//                                     size: 28,
//                                   ),
//                             ),
//                           ),
//                           if (destination != null)
//                             Marker(
//                               point: destination!,
//                               width: 40,
//                               height: 40,
//                               builder:
//                                   (_) => const Icon(
//                                     Icons.location_on,
//                                     color: Colors.red,
//                                     size: 32,
//                                   ),
//                             ),
//                         ],
//                       ),
//                       if (destination != null)
//                         PolylineLayer(
//                           polylines: [
//                             Polyline(
//                               points: _getRoute(),
//                               strokeWidth: 4,
//                               color: Colors.green,
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                   // "Where to?" search bar
//                   Positioned(
//                     top: 60,
//                     left: 20,
//                     right: 20,
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
//                                 fontSize: 16,
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   // "Request Ride" button
//                   if (destination != null)
//                     Positioned(
//                       bottom: 30,
//                       left: 30,
//                       right: 30,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           // TODO: handle ride request
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("Ride Requested")),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           "Request Ride",
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   LatLng? currentLocation;

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

//   Future<void> _navigateToWhereTo() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const WhereToScreen()),
//     );
//   }

//   List<LatLng> _getRoute(LatLng? destination) {
//     if (currentLocation == null || destination == null) return [];
//     return [currentLocation!, destination];
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pickup = ref.watch(pickupLocationProvider);
//     final destination = ref.watch(destinationLocationProvider);
//     final stops = ref.watch(stopsProvider);

//     return Scaffold(
//       body:
//           currentLocation == null
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   FlutterMap(
//                     options: MapOptions(
//                       center: destination ?? currentLocation,
//                       zoom: 15,
//                     ),
//                     children: [
//                       TileLayer(
//                         urlTemplate:
//                             'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                         subdomains: const ['a', 'b', 'c'],
//                       ),
//                       MarkerLayer(
//                         markers: [
//                           Marker(
//                             point: currentLocation!,
//                             width: 40,
//                             height: 40,
//                             builder:
//                                 (_) => const Icon(
//                                   Icons.my_location,
//                                   color: Colors.blue,
//                                   size: 32,
//                                 ),
//                           ),
//                           ...nearbyVehicles.map(
//                             (vehicle) => Marker(
//                               point: vehicle,
//                               width: 30,
//                               height: 30,
//                               builder:
//                                   (_) => const Icon(
//                                     Icons.local_taxi,
//                                     color: Colors.yellow,
//                                     size: 28,
//                                   ),
//                             ),
//                           ),
//                           if (destination != null)
//                             Marker(
//                               point: destination,
//                               width: 40,
//                               height: 40,
//                               builder:
//                                   (_) => const Icon(
//                                     Icons.location_on,
//                                     color: Colors.red,
//                                     size: 32,
//                                   ),
//                             ),
//                           if (pickup != null)
//                             Marker(
//                               point: pickup,
//                               width: 35,
//                               height: 35,
//                               builder:
//                                   (_) => const Icon(
//                                     Icons.location_searching,
//                                     color: Colors.green,
//                                     size: 30,
//                                   ),
//                             ),
//                           ...stops.map(
//                             (stop) => Marker(
//                               point: stop,
//                               width: 30,
//                               height: 30,
//                               builder:
//                                   (_) => const Icon(
//                                     Icons.stop_circle,
//                                     color: Colors.orange,
//                                     size: 26,
//                                   ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (destination != null)
//                         PolylineLayer(
//                           polylines: [
//                             Polyline(
//                               points: _getRoute(destination),
//                               strokeWidth: 4,
//                               color: Colors.green,
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                   // "Where to?" search bar
//                   Positioned(
//                     top: 60,
//                     left: 20,
//                     right: 20,
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
//                                 fontSize: 16,
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   // Request Ride Button
//                   if (destination != null)
//                     Positioned(
//                       bottom: 30,
//                       left: 30,
//                       right: 30,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("Ride Requested")),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           "Request Ride",
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//     );
//   }
// }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';

// class HomeScreen extends StatefulWidget {
//   final LatLng pickup;
//   final LatLng destination;

//   const HomeScreen({
//     super.key,
//     required this.pickup,
//     required this.destination,
//   });

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<String> vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
//   List<Map<String, dynamic>> availableDrivers = [];
//   String? selectedCategory;

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration.zero, _showVehicleCategoryOverlay);
//   }

//   final mockDrivers = [
//     {"name": "James", "vehicle": "Toyota Sedan"},
//     {"name": "Aisha", "vehicle": "Nissan SUV"},
//   ];

//   void _showVehicleCategoryOverlay() async {
//     await showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       builder: (context) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               vehicleCategories.map((category) {
//                 return ListTile(
//                   leading: const Icon(Icons.directions_car),
//                   title: Text(category),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _fetchAvailableDrivers(category);
//                   },
//                 );
//               }).toList(),
//         );
//       },
//     );
//   }

//   Future<void> _fetchAvailableDrivers(String category) async {
//     setState(() {
//       selectedCategory = category;
//       availableDrivers = mockDrivers;
//     });

//     final pickup = widget.pickup;
//     final url = Uri.parse(
//       "https://your-api-url.com/api/drivers?lat=${pickup.latitude}&lng=${pickup.longitude}&category=$category",
//     );

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         setState(() {
//           availableDrivers = List<Map<String, dynamic>>.from(
//             json.decode(response.body),
//           );
//         });
//       } else {
//         _showError("Failed to load drivers");
//       }
//     } catch (e) {
//       _showError("Network error");
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Home")),
//       body:
//           availableDrivers.isEmpty
//               ? const Center(child: Text("No drivers found"))
//               : ListView.builder(
//                 itemCount: availableDrivers.length,
//                 itemBuilder: (context, index) {
//                   final driver = availableDrivers[index];
//                   return ListTile(
//                     leading: const Icon(Icons.person),
//                     title: Text("Driver: ${driver['name']}"),
//                     subtitle: Text("Vehicle: ${driver['vehicle']}"),
//                     trailing: ElevatedButton(
//                       onPressed: () {
//                         // Navigate to ride screen or confirm ride
//                       },
//                       child: const Text("Request"),
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   final LatLng pickup;
//   final LatLng destination;

//   const HomeScreen({
//     super.key,
//     required this.pickup,
//     required this.destination,
//   });

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showVehicleSelectionOverlay();
//     });
//   }

//   void _showVehicleSelectionOverlay() async {
//     await showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       builder: (context) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               vehicleCategories.map((category) {
//                 return ListTile(
//                   leading: const Icon(Icons.directions_car),
//                   title: Text(category),
//                   onTap: () {
//                     Navigator.pop(context);
//                     ref.read(selectedCategoryProvider.notifier).state =
//                         category;
//                     _loadAndLinkNearestDriver(category);
//                   },
//                 );
//               }).toList(),
//         );
//       },
//     );
//   }

//   void _loadAndLinkNearestDriver(String selectedCategory) {
//     final pickup = widget.pickup;

//     // Mock driver list with categories
//     final mockDrivers = [
//       Driver(
//         name: "James",
//         vehicle: "Toyota Axio",
//         category: "Sedan",
//         location: LatLng(-1.2921, 36.8219),
//       ),
//       Driver(
//         name: "Aisha",
//         vehicle: "Nissan Xtrail",
//         category: "SUV",
//         location: LatLng(-1.3000, 36.8100),
//       ),
//       Driver(
//         name: "Otieno",
//         vehicle: "Bajaj Boxer",
//         category: "Bike",
//         location: LatLng(-1.2950, 36.8000),
//       ),
//     ];

//     // Filter by category
//     final filtered =
//         mockDrivers.where((d) => d.category == selectedCategory).toList();

//     // Find nearest
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

//   @override
//   Widget build(BuildContext context) {
//     final linkedDriver = ref.watch(linkedDriverProvider);
//     final selectedCategory = ref.watch(selectedCategoryProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text("Home")),
//       body:
//           selectedCategory == null
//               ? const Center(child: Text("Please select a vehicle category..."))
//               : linkedDriver == null
//               ? const Center(child: CircularProgressIndicator())
//               : Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Linked to Driver: ${linkedDriver.name}",
//                       style: const TextStyle(fontSize: 20),
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Vehicle: ${linkedDriver.vehicle}"),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Proceed to ride or driver tracking
//                       },
//                       child: const Text("Start Ride"),
//                     ),
//                   ],
//                 ),
//               ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:latlong2/latlong.dart' as ll;
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/ride_in_progress.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   final LatLng pickup;
//   final LatLng destination;

//   const HomeScreen({
//     super.key,
//     required this.pickup,
//     required this.destination,
//     required List<Map<String, dynamic>> stops,
//   });

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showVehicleSelectionOverlay();
//     });
//   }

//   void _showVehicleSelectionOverlay() async {
//     await showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       builder: (context) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               vehicleCategories.map((category) {
//                 return ListTile(
//                   leading: const Icon(Icons.directions_car),
//                   title: Text(category),
//                   onTap: () {
//                     Navigator.pop(context);
//                     ref.read(selectedCategoryProvider.notifier).state =
//                         category;
//                     _linkNearestDriverAndEstimateFare(category);
//                   },
//                 );
//               }).toList(),
//         );
//       },
//     );
//   }

//   void _linkNearestDriverAndEstimateFare(String category) {
//     final pickup = widget.pickup;
//     final destination = widget.destination;

//     final mockDrivers = [
//       Driver(
//         name: "James",
//         vehicle: "Toyota Axio",
//         category: "Sedan",
//         location: LatLng(-1.2921, 36.8219),
//       ),
//       Driver(
//         name: "Aisha",
//         vehicle: "Nissan Xtrail",
//         category: "SUV",
//         location: LatLng(-1.3000, 36.8100),
//       ),
//       Driver(
//         name: "Otieno",
//         vehicle: "Bajaj Boxer",
//         category: "Bike",
//         location: LatLng(-1.2950, 36.8000),
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

//     // Estimate Fare
//     double km = distance.as(LengthUnit.Kilometer, pickup, destination);
//     final baseRates = {"Sedan": 50.0, "SUV": 80.0, "Van": 100.0, "Bike": 30.0};
//     double ratePerKm = 25.0;
//     double fare = (baseRates[category] ?? 50) + (km * ratePerKm);
//     ref.read(estimatedFareProvider.notifier).state = fare;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final driver = ref.watch(linkedDriverProvider);
//     final fare = ref.watch(estimatedFareProvider);
//     final category = ref.watch(selectedCategoryProvider);
//     final rideConfirmed = ref.watch(rideConfirmedProvider);

//     if (rideConfirmed) {
//       final driver = ref.watch(linkedDriverProvider);
//       if (driver == null) {
//         return const Center(child: Text('No driver linked'));
//       }
//       return RideInProgressScreen(
//         driverStart: ll.LatLng(
//           driver.location.latitude,
//           driver.location.longitude,
//         ),
//         pickup: widget.pickup,
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text("Home")),
//       body:
//           driver == null
//               ? const Center(child: Text("Finding nearest driver..."))
//               : Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "🚗 Driver: ${driver.name}",
//                       style: const TextStyle(fontSize: 20),
//                     ),
//                     Text("Vehicle: ${driver.vehicle} (${driver.category})"),
//                     const SizedBox(height: 10),
//                     Text("💰 Estimated Fare: KES ${fare?.toStringAsFixed(2)}"),
//                     const SizedBox(height: 20),
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         ref.read(rideConfirmedProvider.notifier).state = true;

//                         final driver = ref.read(linkedDriverProvider)!;

//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (context) => RideInProgressScreen(
//                                   driverStart: ll.LatLng(
//                                     driver.location.latitude,
//                                     driver.location.longitude,
//                                   ),
//                                   pickup: ll.LatLng(
//                                     widget.pickup.latitude,
//                                     widget.pickup.longitude,
//                                   ),
//                                 ),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.check_circle),
//                       label: const Text("Confirm Ride"),
//                     ),
//                   ],
//                 ),
//               ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:latlong2/latlong.dart' as ll;
// import 'package:latlong2/latlong.dart' as latLng;
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/ride_in_progress.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   final LatLng pickup;
//   final LatLng destination;
//   final List<Map<String, dynamic>> stops;

//   const HomeScreen({
//     super.key,
//     required this.pickup,
//     required this.destination,
//     required this.stops,
//   });

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showVehicleSelectionOverlay();
//     });
//   }

//   // void _showVehicleSelectionOverlay() async {
//   //   await showModalBottomSheet(
//   //     context: context,
//   //     isDismissible: false,
//   //     builder: (context) {
//   //       return Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children:
//   //             vehicleCategories.map((category) {
//   //               return ListTile(
//   //                 leading: const Icon(Icons.directions_car),
//   //                 title: Text(category),
//   //                 onTap: () {
//   //                   Navigator.pop(context);
//   //                   ref.read(selectedCategoryProvider.notifier).state =
//   //                       category;
//   //                   _linkNearestDriverAndEstimateFare(category);
//   //                 },
//   //               );
//   //             }).toList(),
//   //       );
//   //     },
//   //   );
//   // }
//   void _showVehicleSelectionOverlay() async {
//     final pickup = widget.pickup;
//     final destination = widget.destination;

//     final baseRates = {"Sedan": 50.0, "SUV": 80.0, "Van": 100.0, "Bike": 30.0};
//     final ratePerKm = 25.0;
//     final averageSpeeds = {
//       "Sedan": 40.0,
//       "SUV": 35.0,
//       "Van": 30.0,
//       "Bike": 50.0,
//     };

//     final distance = Distance();
//     final tripDistanceKm = distance.as(
//       LengthUnit.Kilometer,
//       pickup,
//       destination,
//     );

//     final mockDrivers = [
//       Driver(
//         name: "James",
//         vehicle: "Toyota Axio",
//         category: "Sedan",
//         location: LatLng(-1.2921, 36.8219),
//       ),
//       Driver(
//         name: "Aisha",
//         vehicle: "Nissan Xtrail",
//         category: "SUV",
//         location: LatLng(-1.3000, 36.8100),
//       ),
//       Driver(
//         name: "Otieno",
//         vehicle: "Bajaj Boxer",
//         category: "Bike",
//         location: LatLng(-1.2950, 36.8000),
//       ),
//     ];

//     await showModalBottomSheet(
//       context: context,
//       isDismissible: false,
//       enableDrag: false, // Prevent swipe down to dismiss
//       builder: (context) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children:
//               vehicleCategories.map((category) {
//                 final driversForCategory =
//                     mockDrivers
//                         .where((driver) => driver.category == category)
//                         .toList();

//                 Driver? nearest;
//                 double? minDist;
//                 for (var driver in driversForCategory) {
//                   final d = distance.as(
//                     LengthUnit.Kilometer,
//                     pickup,
//                     driver.location,
//                   );
//                   if (minDist == null || d < minDist) {
//                     nearest = driver;
//                     minDist = d;
//                   }
//                 }

//                 final fare =
//                     (baseRates[category] ?? 50) + (tripDistanceKm * ratePerKm);
//                 final etaToPickupMin =
//                     minDist != null && averageSpeeds[category] != null
//                         ? (minDist! / averageSpeeds[category]!) * 60
//                         : null;

//                 final estTripTimeMin =
//                     (tripDistanceKm / (averageSpeeds[category]!)) * 60;

//                 return Container(
//                   decoration: BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//                     ),
//                   ),
//                   child: ListTile(
//                     leading: const Icon(Icons.directions_car),
//                     title: Text(
//                       "$category - KES ${fare.toStringAsFixed(2)}",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       "ETA to pickup: ${etaToPickupMin?.toStringAsFixed(1) ?? 'N/A'} mins\n"
//                       "Trip time: ${estTripTimeMin.toStringAsFixed(1)} mins",
//                     ),
//                     onTap: () {
//                       Navigator.pop(context);
//                       ref.read(selectedCategoryProvider.notifier).state =
//                           category;
//                       ref.read(estimatedFareProvider.notifier).state = fare;
//                       _linkNearestDriver(category);
//                     },
//                   ),
//                 );
//               }).toList(),
//         );
//       },
//     );
//   }

//   // void _linkNearestDriverAndEstimateFare(String category) {
//   //   final pickup = widget.pickup;
//   //   final destination = widget.destination;
//   //   final stops = widget.stops;

//   //   final mockDrivers = [
//   //     Driver(
//   //       name: "James",
//   //       vehicle: "Toyota Axio",
//   //       category: "Sedan",
//   //       location: LatLng(-1.2921, 36.8219),
//   //     ),
//   //     Driver(
//   //       name: "Aisha",
//   //       vehicle: "Nissan Xtrail",
//   //       category: "SUV",
//   //       location: LatLng(-1.3000, 36.8100),
//   //     ),
//   //     Driver(
//   //       name: "Otieno",
//   //       vehicle: "Bajaj Boxer",
//   //       category: "Bike",
//   //       location: LatLng(-1.2950, 36.8000),
//   //     ),
//   //   ];

//   //   final filtered = mockDrivers.where((d) => d.category == category).toList();

//   //   final Distance distance = Distance();
//   //   Driver? nearest;
//   //   double? minDist;

//   //   for (var driver in filtered) {
//   //     final d = distance(pickup, driver.location);
//   //     if (minDist == null || d < minDist) {
//   //       nearest = driver;
//   //       minDist = d;
//   //     }
//   //   }

//   //   ref.read(availableDriversProvider.notifier).state = filtered;
//   //   ref.read(linkedDriverProvider.notifier).state = nearest;

//   //   // Calculate total trip distance (pickup → stop1 → stop2 → ... → destination)
//   //   double totalDistance = 0.0;
//   //   LatLng prev = pickup;
//   //   for (var stop in stops) {
//   //     final next = LatLng(stop['lat'], stop['lng']);
//   //     totalDistance += distance.as(LengthUnit.Kilometer, prev, next);
//   //     prev = next;
//   //   }
//   //   totalDistance += distance.as(LengthUnit.Kilometer, prev, destination);

//   //   // Estimate Fare
//   //   final baseRates = {"Sedan": 50.0, "SUV": 80.0, "Van": 100.0, "Bike": 30.0};
//   //   double ratePerKm = 25.0;
//   //   double fare = (baseRates[category] ?? 50) + (totalDistance * ratePerKm);
//   //   ref.read(estimatedFareProvider.notifier).state = fare;
//   // }

//   void _linkNearestDriver(String category) {
//     final pickup = widget.pickup;

//     final mockDrivers = [
//       Driver(
//         name: "James",
//         vehicle: "Toyota Axio",
//         category: "Sedan",
//         location: LatLng(-1.2921, 36.8219),
//       ),
//       Driver(
//         name: "Aisha",
//         vehicle: "Nissan Xtrail",
//         category: "SUV",
//         location: LatLng(-1.3000, 36.8100),
//       ),
//       Driver(
//         name: "Otieno",
//         vehicle: "Bajaj Boxer",
//         category: "Bike",
//         location: LatLng(-1.2950, 36.8000),
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

//   @override
//   Widget build(BuildContext context) {
//     final driver = ref.watch(linkedDriverProvider);
//     final fare = ref.watch(estimatedFareProvider);
//     final category = ref.watch(selectedCategoryProvider);
//     final rideConfirmed = ref.watch(rideConfirmedProvider);
//     final pickup = widget.pickup;
//     final destination = widget.destination;
//     final distance = Distance();
//     final tripDistanceKm = distance.as(
//       LengthUnit.Kilometer,
//       pickup,
//       destination,
//     );

//     if (rideConfirmed) {
//       if (driver == null) {
//         return const Center(child: Text('No driver linked'));
//       }

//       return RideInProgressScreen(
//         driverStart: ll.LatLng(
//           driver.location.latitude,
//           driver.location.longitude,
//         ),
//         pickup: widget.pickup,
//         // You may want to pass destination and stops here too
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text("Uber-like Ride")),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               "Estimated Distance: ${tripDistanceKm.toStringAsFixed(2)} km",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: FlutterMap(
//               options: MapOptions(center: pickup, zoom: 13.0),
//               children: [
//                 TileLayer(
//                   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   userAgentPackageName: 'com.example.app',
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: pickup,
//                       width: 60,
//                       height: 60,
//                       builder:
//                           (ctx) => const Icon(
//                             Icons.location_on,
//                             color: Colors.green,
//                             size: 30,
//                           ),
//                     ),
//                     Marker(
//                       point: destination,
//                       width: 60,
//                       height: 60,
//                       builder:
//                           (ctx) => const Icon(
//                             Icons.flag,
//                             color: Colors.red,
//                             size: 30,
//                           ),
//                     ),
//                   ],
//                 ),
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: [pickup, destination],
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           if (driver != null)
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "🚗 Driver: ${driver.name}",
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                   Text("Vehicle: ${driver.vehicle} (${driver.category})"),
//                   const SizedBox(height: 10),
//                   Text("💰 Estimated Fare: KES ${fare?.toStringAsFixed(2)}"),
//                 ],
//               ),
//             )
//           else
//             const Padding(
//               padding: EdgeInsets.all(20),
//               child: Text("Finding nearest driver..."),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:latlong2/latlong.dart' as ll;
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/ride_in_progress.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   final LatLng pickup;
//   final LatLng destination;
//   final List<Map<String, dynamic>> stops;

//   const HomeScreen({
//     super.key,
//     required this.pickup,
//     required this.destination,
//     required this.stops,
//   });

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
//   int selectedIndex = -1;

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Optional: run any logic after first frame renders
//       // _showVehicleSelectionOverlay();
//     });
//   }

//   // void _linkNearestDriver(String category) {
//   //   final pickup = widget.pickup;

//   //   final mockDrivers = [
//   //     Driver(
//   //       name: "James",
//   //       vehicle: "Toyota Axio",
//   //       category: "Sedan",
//   //       location: LatLng(-1.2921, 36.8219),
//   //       registrationNumber: "KDA 123A",
//   //       color: "Silver",
//   //       photoUrl: "https://example.com/james.jpg",
//   //     ),
//   //     Driver(
//   //       name: "Aisha",
//   //       vehicle: "Nissan Xtrail",
//   //       category: "SUV",
//   //       location: LatLng(-1.3000, 36.8100),
//   //       registrationNumber: "KBX 456B",
//   //       color: "White",
//   //       photoUrl: "https://example.com/aisha.jpg",
//   //     ),
//   //     Driver(
//   //       name: "Otieno",
//   //       vehicle: "Bajaj Boxer",
//   //       category: "Bike",
//   //       location: LatLng(-1.2950, 36.8000),
//   //       registrationNumber: "KBG 456B",
//   //       color: "White",
//   //       photoUrl: "https://example.com/Otieno.jpg",
//   //     ),
//   //   ];

//   //   final filtered = mockDrivers.where((d) => d.category == category).toList();

//   //   final Distance distance = Distance();
//   //   Driver? nearest;
//   //   double? minDist;

//   //   for (var driver in filtered) {
//   //     final d = distance(pickup, driver.location);
//   //     if (minDist == null || d < minDist) {
//   //       nearest = driver;
//   //       minDist = d;
//   //     }
//   //   }

//   //   ref.read(availableDriversProvider.notifier).state = filtered;
//   //   ref.read(linkedDriverProvider.notifier).state = nearest;
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final driver = ref.watch(linkedDriverProvider);
//     final fare = ref.watch(estimatedFareProvider);
//     final category = ref.watch(selectedCategoryProvider);
//     final rideConfirmed = ref.watch(rideConfirmedProvider);
//     final pickup = widget.pickup;
//     final destination = widget.destination;
//     final distance = Distance();
//     final tripDistanceKm = distance.as(
//       LengthUnit.Kilometer,
//       pickup,
//       destination,
//     );

//     // if (driver != null) {
//     //   rideConfirmed = true;
//     // }

//     if (rideConfirmed) {
//       if (driver == null) {
//         return const Center(child: Text('No driver linked'));
//       }

//       return RideInProgressScreen(
//         driverStart: ll.LatLng(
//           driver.location.latitude,
//           driver.location.longitude,
//         ),
//         pickup: widget.pickup,
//       );
//     }
//     final midPoint = LatLng(
//       (pickup.latitude + destination.latitude) / 2,
//       (pickup.longitude + destination.longitude) / 2,
//     );

//     return Scaffold(
//       appBar: AppBar(title: const Text("Amini Ride")),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   "Estimated Distance: ${tripDistanceKm.toStringAsFixed(2)} km",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child:
//                 //  FlutterMap(
//                 //   options: MapOptions(center: pickup, zoom: 13.0),
//                 //   children: [
//                 //     TileLayer(
//                 //       urlTemplate:
//                 //           "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                 //       userAgentPackageName: 'com.example.app',
//                 //     ),
//                 //   ],
//                 // ),
//                 FlutterMap(
//                   options: MapOptions(center: pickup, zoom: 13.0),
//                   children: [
//                     TileLayer(
//                       urlTemplate:
//                           "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                       userAgentPackageName: 'com.example.niceapp',
//                     ),
//                     MarkerLayer(
//                       markers: [
//                         Marker(
//                           point: pickup,
//                           width: 40,
//                           height: 40,
//                           builder:
//                               (_) => const Icon(
//                                 Icons.location_pin,
//                                 color: Colors.green,
//                                 size: 40,
//                               ),
//                         ),
//                         Marker(
//                           point: destination,
//                           width: 40,
//                           height: 40,
//                           builder:
//                               (_) => const Icon(
//                                 Icons.flag,
//                                 color: Colors.red,
//                                 size: 40,
//                               ),
//                         ),
//                         Marker(
//                           point: midPoint,
//                           width: 200,
//                           height: 50,
//                           builder:
//                               (_) => Container(
//                                 alignment: Alignment.center,
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.yellow,
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Text(
//                                   '${tripDistanceKm.toStringAsFixed(2)} km',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),
//                         ),
//                       ],
//                     ),
//                     PolylineLayer(
//                       polylines: [
//                         Polyline(
//                           points: [pickup, destination],
//                           strokeWidth: 4.0,
//                           color: Colors.blueAccent,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // //Overlay selector
//           // Positioned(
//           //   left: 0,
//           //   right: 0,
//           //   bottom: 0,
//           //   child: Container(
//           //     height: 300,
//           //     decoration: const BoxDecoration(
//           //       color: Colors.white,
//           //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           //       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
//           //     ),
//           //     child: ListView.builder(
//           //       padding: const EdgeInsets.all(12),
//           //       itemCount: vehicleCategories.length,
//           //       itemBuilder: (context, index) {
//           //         final category = vehicleCategories[index];
//           //         final baseRates = {
//           //           "Sedan": 50.0,
//           //           "SUV": 80.0,
//           //           "Van": 100.0,
//           //           "Bike": 30.0,
//           //         };
//           //         final averageSpeeds = {
//           //           "Sedan": 40.0,
//           //           "SUV": 35.0,
//           //           "Van": 30.0,
//           //           "Bike": 50.0,
//           //         };
//           //         final ratePerKm = 25.0;

//           //         // final mockDrivers = [
//           //         //   Driver(
//           //         //     name: "James",
//           //         //     vehicle: "Toyota Axio",
//           //         //     category: "Sedan",
//           //         //     location: LatLng(-1.2921, 36.8219),
//           //         //     registrationNumber: "KDA 123A",
//           //         //     color: "Silver",
//           //         //     photoUrl: "https://example.com/james.jpg",
//           //         //   ),
//           //         //   Driver(
//           //         //     name: "Aisha",
//           //         //     vehicle: "Nissan Xtrail",
//           //         //     category: "SUV",
//           //         //     location: LatLng(-1.3000, 36.8100),
//           //         //     registrationNumber: "KBX 456B",
//           //         //     color: "White",
//           //         //     photoUrl: "https://example.com/aisha.jpg",
//           //         //   ),
//           //         //   Driver(
//           //         //     name: "Otieno",
//           //         //     vehicle: "Bajaj Boxer",
//           //         //     category: "Bike",
//           //         //     location: LatLng(-1.2950, 36.8000),
//           //         //     registrationNumber: "KBG 456B",
//           //         //     color: "White",
//           //         //     photoUrl: "https://example.com/Otieno.jpg",
//           //         //   ),
//           //         // ];

//           //         // final driversForCategory =
//           //         //     mockDrivers.where((d) => d.category == category).toList();

//           //         // Driver? nearest;
//           //         // double? minDist;
//           //         // for (var driver in driversForCategory) {
//           //         //   final d = distance.as(
//           //         //     LengthUnit.Kilometer,
//           //         //     pickup,
//           //         //     driver.location,
//           //         //   );
//           //         //   if (minDist == null || d < minDist) {
//           //         //     nearest = driver;
//           //         //     minDist = d;
//           //         //   }
//           //         // }
//           //         double? minDist;
//           //         final fare =
//           //             (baseRates[category] ?? 50) +
//           //             (tripDistanceKm * ratePerKm);
//           //         final etaToPickupMin =
//           //             minDist != null && averageSpeeds[category] != null
//           //                 ? (minDist! / averageSpeeds[category]!) * 60
//           //                 : null;
//           //         final estTripTimeMin =
//           //             (tripDistanceKm / (averageSpeeds[category]!)) * 60;

//           //         return Card(
//           //           child: ListTile(
//           //             leading: const Icon(Icons.directions_car),
//           //             title: Text("$category - KES ${fare.toStringAsFixed(2)}"),
//           //             subtitle: Text(
//           //               "ETA to pickup: ${etaToPickupMin?.toStringAsFixed(1) ?? 'N/A'} mins\n"
//           //               "Trip time: ${estTripTimeMin.toStringAsFixed(1)} mins",
//           //             ),
//           //             onTap: () {
//           //               setState(() {
//           //                 selectedIndex = index;
//           //               });
//           //               ref.read(selectedCategoryProvider.notifier).state =
//           //                   category;
//           //             },

//           //             // Optionally, uncomment these if you want to update providers here:
//           //             // ref.read(selectedCategoryProvider.notifier).state = category;
//           //             // ref.read(estimatedFareProvider.notifier).state = fare;
//           //             // _linkNearestDriver(category);

//           //             // Navigator.push(
//           //             //   context,
//           //             //   MaterialPageRoute(
//           //             //     builder:
//           //             //         (_) => ConfirmRideScreen(
//           //             //           category: category,
//           //             //           fare: fare,
//           //             //           pickup: pickup,
//           //             //           destination: destination,
//           //             //         ),
//           //             //   ),
//           //             // );
//           //           ),
//           //         );
//           //       },
//           //     ),
//           //   ),
//           // ),

//           // Consumer(
//           //   builder: (context, ref, child) {
//           //     final category = ref.watch(selectedCategoryProvider);
//           //     final isEnabled = category.toString().isNotEmpty;

//           //     return Align(
//           //       alignment: Alignment.bottomCenter,
//           //       child: Padding(
//           //         padding: const EdgeInsets.only(bottom: 20),
//           //         child: ElevatedButton(
//           //           onPressed:
//           //               isEnabled
//           //                   ? () {
//           //                     Navigator.push(
//           //                       context,
//           //                       MaterialPageRoute(
//           //                         builder:
//           //                             (_) => ConfirmRideScreen(
//           //                               pickup: widget.pickup,
//           //                               fare: tripDistanceKm,
//           //                               destination: widget.destination,
//           //                               category: category.toString(),
//           //                             ),
//           //                       ),
//           //                     );
//           //                   }
//           //                   : null,
//           //           style: ElevatedButton.styleFrom(
//           //             backgroundColor: Colors.blue,
//           //             padding: const EdgeInsets.symmetric(
//           //               horizontal: 32,
//           //               vertical: 16,
//           //             ),
//           //             shape: RoundedRectangleBorder(
//           //               borderRadius: BorderRadius.circular(12),
//           //             ),
//           //             elevation: isEnabled ? 4 : 0,
//           //           ),
//           //           child: Text(
//           //             isEnabled ? "Select $category" : "Select Category",
//           //             style: const TextStyle(fontSize: 18, color: Colors.white),
//           //           ),
//           //         ),
//           //       ),
//           //     );
//           //   },
//           // ),
//           // Positioned(
//           //   left: 0,
//           //   right: 0,
//           //   bottom: 0,
//           //   child: Container(
//           //     height: 300,
//           //     decoration: const BoxDecoration(
//           //       color: Colors.white,
//           //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           //       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
//           //     ),
//           //     child: Column(
//           //       children: [
//           //         // Scrollable list
//           //         Expanded(
//           //           child: ListView.builder(
//           //             padding: const EdgeInsets.all(12),
//           //             itemCount: vehicleCategories.length,
//           //             itemBuilder: (context, index) {
//           //               final category = vehicleCategories[index];
//           //               final baseRates = {
//           //                 "Sedan": 50.0,
//           //                 "SUV": 80.0,
//           //                 "Van": 100.0,
//           //                 "Bike": 30.0,
//           //               };
//           //               final averageSpeeds = {
//           //                 "Sedan": 40.0,
//           //                 "SUV": 35.0,
//           //                 "Van": 30.0,
//           //                 "Bike": 50.0,
//           //               };
//           //               final ratePerKm = 25.0;

//           //               final fare =
//           //                   (baseRates[category] ?? 50) +
//           //                   (tripDistanceKm * ratePerKm);
//           //               final estTripTimeMin =
//           //                   (tripDistanceKm / (averageSpeeds[category]!)) * 60;

//           //               return Card(
//           //                 child: ListTile(
//           //                   leading: const Icon(Icons.directions_car),
//           //                   title: Text(
//           //                     "$category - KES ${fare.toStringAsFixed(2)}",
//           //                   ),
//           //                   subtitle: Text(
//           //                     "Trip time: ${estTripTimeMin.toStringAsFixed(1)} mins",
//           //                   ),
//           //                   onTap: () {
//           //                     setState(() {
//           //                       selectedIndex = index;
//           //                     });
//           //                     ref
//           //                         .read(selectedCategoryProvider.notifier)
//           //                         .state = category;
//           //                   },
//           //                 ),
//           //               );
//           //             },
//           //           ),
//           //         ),

//           //         // Fixed "Select Category" button
//           //         Consumer(
//           //           builder: (context, ref, child) {
//           //             final category = ref.watch(selectedCategoryProvider);
//           //             final isEnabled = category.toString().isNotEmpty;

//           //             return Padding(
//           //               padding: const EdgeInsets.symmetric(
//           //                 horizontal: 12,
//           //                 vertical: 12,
//           //               ),
//           //               child: SizedBox(
//           //                 width: double.infinity,
//           //                 child: ElevatedButton(
//           //                   onPressed:
//           //                       isEnabled
//           //                           ? () {
//           //                             Navigator.push(
//           //                               context,
//           //                               MaterialPageRoute(
//           //                                 builder:
//           //                                     (_) => ConfirmRideScreen(
//           //                                       pickup: widget.pickup,
//           //                                       fare: tripDistanceKm,
//           //                                       destination: widget.destination,
//           //                                       category: category.toString(),
//           //                                     ),
//           //                               ),
//           //                             );
//           //                           }
//           //                           : null,
//           //                   style: ElevatedButton.styleFrom(
//           //                     backgroundColor: Colors.blue,
//           //                     padding: const EdgeInsets.symmetric(vertical: 16),
//           //                     shape: RoundedRectangleBorder(
//           //                       borderRadius: BorderRadius.circular(12),
//           //                     ),
//           //                   ),
//           //                   child: Text(
//           //                     isEnabled
//           //                         ? "Select $category"
//           //                         : "Select Category",
//           //                     style: const TextStyle(
//           //                       fontSize: 18,
//           //                       color: Colors.white,
//           //                     ),
//           //                   ),
//           //                 ),
//           //               ),
//           //             );
//           //           },
//           //         ),
//           //       ],
//           //     ),
//           //   ),
//           // ),
//           DraggableScrollableSheet(
//             initialChildSize: 0.4, // 40% of screen height
//             minChildSize:
//                 0.25, // Never collapse below 25% (ensures 1 category is visible)
//             maxChildSize: 0.8, // Optional, can grow up to 80%
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                   boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: ListView.builder(
//                         controller: scrollController,
//                         itemCount: vehicleCategories.length,
//                         padding: const EdgeInsets.all(12),
//                         itemBuilder: (context, index) {
//                           final category = vehicleCategories[index];
//                           final baseRates = {
//                             "Sedan": 50.0,
//                             "SUV": 80.0,
//                             "Van": 100.0,
//                             "Bike": 30.0,
//                           };
//                           final averageSpeeds = {
//                             "Sedan": 40.0,
//                             "SUV": 35.0,
//                             "Van": 30.0,
//                             "Bike": 50.0,
//                           };
//                           final ratePerKm = 25.0;

//                           final fare =
//                               (baseRates[category] ?? 50) +
//                               (tripDistanceKm * ratePerKm);
//                           final estTripTimeMin =
//                               (tripDistanceKm / (averageSpeeds[category]!)) *
//                               60;

//                           return Card(
//                             child: ListTile(
//                               leading: const Icon(Icons.directions_car),
//                               title: Text(
//                                 "$category - KES ${fare.toStringAsFixed(2)}",
//                               ),
//                               subtitle: Text(
//                                 "Trip time: ${estTripTimeMin.toStringAsFixed(1)} mins",
//                               ),
//                               onTap: () {
//                                 setState(() {
//                                   selectedIndex = index;
//                                 });
//                                 ref
//                                     .read(selectedCategoryProvider.notifier)
//                                     .state = category;
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),

//                     // Fixed button at the bottom
//                     Consumer(
//                       builder: (context, ref, child) {
//                         final category = ref.watch(selectedCategoryProvider);
//                         final isEnabled = category.toString().isNotEmpty;

//                         return Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 12,
//                           ),
//                           child: SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed:
//                                   isEnabled
//                                       ? () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder:
//                                                 (_) => ConfirmRideScreen(
//                                                   pickup: widget.pickup,
//                                                   fare: tripDistanceKm,
//                                                   destination:
//                                                       widget.destination,
//                                                   category: category.toString(),
//                                                 ),
//                                           ),
//                                         );
//                                       }
//                                       : null,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue,
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: Text(
//                                 isEnabled
//                                     ? "Select $category"
//                                     : "Select Category",
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),

//           // ),
//           // Positioned(
//           //   left: 0,
//           //   right: 0,
//           //   bottom: 0,
//           //   child: Container(
//           //     height: 360,
//           //     decoration: const BoxDecoration(
//           //       color: Colors.white,
//           //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           //       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
//           //     ),
//           //     child: Column(
//           //       children: [
//           //         Expanded(
//           //           child: ListView.builder(
//           //             padding: const EdgeInsets.all(12),
//           //             itemCount: vehicleCategories.length,
//           //             itemBuilder: (context, index) {
//           //               final vehicle = vehicleCategories[index];
//           //               final isSelected = index == selectedIndex;

//           //               return Card(
//           //                 color: isSelected ? Colors.blue.shade100 : null,
//           //                 child: ListTile(
//           //                   leading: const Icon(Icons.directions_car),
//           //                   title: Text(vehicle),
//           //                   onTap: () {
//           //                     setState(() {
//           //                       selectedIndex = index;
//           //                     });
//           //                     ref
//           //                         .read(selectedCategoryProvider.notifier)
//           //                         .state = vehicle;
//           //                   },
//           //                 ),
//           //               );
//           //             },
//           //           ),
//           //         ),
//           //         Padding(
//           //           padding: const EdgeInsets.symmetric(
//           //             horizontal: 20,
//           //             vertical: 12,
//           //           ),
//           //           child: ElevatedButton(
//           //             style: ElevatedButton.styleFrom(
//           //               backgroundColor: Colors.blue,
//           //               minimumSize: const Size.fromHeight(50),
//           //             ),
//           //             onPressed:
//           //                 selectedIndex == -1
//           //                     ? null
//           //                     : () {
//           //                       final selectedVehicle =
//           //                           vehicleCategories[selectedIndex];
//           //                       // Implement logic for selecting vehicle category
//           //                       ScaffoldMessenger.of(context).showSnackBar(
//           //                         SnackBar(
//           //                           content: Text("Selected $selectedVehicle"),
//           //                         ),
//           //                       );
//           //                       // Example: Navigate to confirmation screen
//           //                       // Navigator.push(...);
//           //                     },
//           //             child: Text(
//           //               selectedIndex == -1
//           //                   ? "Select Vehicle"
//           //                   : "Select ${vehicleCategories[selectedIndex]}",
//           //               style: const TextStyle(
//           //                 color: Colors.white,
//           //                 fontSize: 16,
//           //               ),
//           //             ),
//           //           ),
//           //         ),
//           //       ],
//           //     ),
//           //   ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/ride_in_progress.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final List<Map<String, dynamic>> stops;

  const HomeScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.stops,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Optional: run any logic after first frame renders
      // _showVehicleSelectionOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(linkedDriverProvider);
    final fare = ref.watch(estimatedFareProvider);
    final category = ref.watch(selectedCategoryProvider);
    final rideConfirmed = ref.watch(rideConfirmedProvider);
    final pickup = widget.pickup;
    final destination = widget.destination;
    final distance = Distance();
    final tripDistanceKm = distance.as(
      LengthUnit.Kilometer,
      pickup,
      destination,
    );

    // if (driver != null) {
    //   rideConfirmed = true;
    // }

    if (rideConfirmed) {
      if (driver == null) {
        return const Center(child: Text('No driver linked'));
      }

      return RideInProgressScreen(
        driverStart: ll.LatLng(
          driver.location.latitude,
          driver.location.longitude,
        ),
        pickup: widget.pickup,
      );
    }
    final midPoint = LatLng(
      (pickup.latitude + destination.latitude) / 2,
      (pickup.longitude + destination.longitude) / 2,
    );

    return Scaffold(
      //appBar: AppBar(title: const Text("Amini Ride")),
      body: Stack(
        children: [
          Column(
            children: [
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Text(
              //     "Estimated Distance: ${tripDistanceKm.toStringAsFixed(2)} km",
              //     style: const TextStyle(
              //       fontSize: 18,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(center: pickup, zoom: 13.0),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.niceapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickup,
                          width: 40,
                          height: 40,
                          builder:
                              (_) => const Icon(
                                Icons.location_pin,
                                color: Colors.green,
                                size: 40,
                              ),
                        ),
                        Marker(
                          point: destination,
                          width: 40,
                          height: 40,
                          builder:
                              (_) => const Icon(
                                Icons.flag,
                                color: Colors.red,
                                size: 40,
                              ),
                        ),
                        Marker(
                          point: midPoint,
                          width: 200,
                          height: 50,
                          builder:
                              (_) => Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${tripDistanceKm.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [pickup, destination],
                          strokeWidth: 4.0,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                // Navigate to search screen or open modal
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WhereToScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.destination.toJson().toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Handle adding a new stop here
                        showDialog(
                          context: context,
                          builder:
                              (_) => const AlertDialog(
                                title: Text("Add Stop"),
                                content: Text(
                                  "Add stop functionality coming soon.",
                                ),
                              ),
                        );
                      },
                      child: const Icon(Icons.add, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.4, // 40% of screen height
            minChildSize:
                0.25, // Never collapse below 25% (ensures 1 category is visible)
            maxChildSize: 0.8, // Optional, can grow up to 80%
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: vehicleCategories.length,
                        padding: const EdgeInsets.all(12),

                        //   itemBuilder: (context, index) {
                        //     final category = vehicleCategories[index];
                        //     final baseRates = {
                        //       "Sedan": 50.0,
                        //       "SUV": 80.0,
                        //       "Van": 100.0,
                        //       "Bike": 30.0,
                        //     };
                        //     final averageSpeeds = {
                        //       "Sedan": 40.0,
                        //       "SUV": 35.0,
                        //       "Van": 30.0,
                        //       "Bike": 50.0,
                        //     };
                        //     final iconAssets = {
                        //       "Sedan": "assets/imgs/Sedan2.png",
                        //       "SUV": "assets/imgs/Sedan2.png",
                        //       "Van": "assets/imgs/van2.png",
                        //       "Bike": "assets/imgs/motorbike.png",
                        //     };
                        //     final passengerCounts = {
                        //       "Sedan": 4,
                        //       "SUV": 6,
                        //       "Van": 8,
                        //       "Bike": 1,
                        //     };
                        //     final ratePerKm = 25.0;

                        //     final fare =
                        //         (baseRates[category] ?? 50) +
                        //         (tripDistanceKm * ratePerKm);
                        //     final estTripTimeMin =
                        //         (tripDistanceKm / (averageSpeeds[category]!)) *
                        //         60;
                        //     final iconAsset = iconAssets[category]!;
                        //     final name = category;
                        //     final passengers = passengerCounts[category]!;

                        //     // return Card(
                        //     //   child: ListTile(
                        //     //     leading: const Icon(Icons.directions_car),
                        //     //     title: Text(
                        //     //       "$category - KES ${fare.toStringAsFixed(2)}",
                        //     //     ),
                        //     //     subtitle: Text(
                        //     //       "Trip time: ${estTripTimeMin.toStringAsFixed(1)} mins",
                        //     //     ),
                        //     //     onTap: () {
                        //     //       setState(() {
                        //     //         selectedIndex = index;
                        //     //       });
                        //     //       ref
                        //     //           .read(selectedCategoryProvider.notifier)
                        //     //           .state = category;
                        //     //     },
                        //     //   ),
                        //     // );

                        //    return Container(
                        //       decoration: BoxDecoration(
                        //         border: Border.all(
                        //           color:
                        //               isSelected
                        //                   ? Colors.blue
                        //                   : Colors.transparent,
                        //           width: 2,
                        //         ),
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       child: ListTile(
                        //         leading: Image.asset(
                        //           iconAsset,
                        //           width: 60, // increased size
                        //           height: 60,
                        //         ),
                        //         title: Row(
                        //           mainAxisAlignment:
                        //               MainAxisAlignment.spaceBetween,
                        //           children: [
                        //             Text(
                        //               name,
                        //               style: const TextStyle(
                        //                 fontWeight: FontWeight.bold,
                        //                 fontSize: 16,
                        //               ),
                        //             ),
                        //             Text(
                        //               "KES ${fare.toStringAsFixed(2)}",
                        //               style: const TextStyle(
                        //                 fontWeight: FontWeight.bold,
                        //                 fontSize: 16,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //         subtitle: Text(
                        //           "$timeAway away",
                        //           style: const TextStyle(color: Colors.grey),
                        //         ),
                        //         onTap: onTap,
                        //       ),

                        //       // child: ListTile(
                        //       //   leading: Image.asset(
                        //       //     iconAsset,
                        //       //     width: 70,
                        //       //     height: 70,
                        //       //   ),
                        //       //   title: Text(
                        //       //     "$name - KES ${fare.toStringAsFixed(2)}",
                        //       //   ),
                        //       //   subtitle: Text(
                        //       //     "Trip time: ${estTripTimeMin.toStringAsFixed(1)} mins\n"
                        //       //     "Passengers: $passengers",
                        //       //   ),
                        //       //   onTap: () {
                        //       //     setState(() {
                        //       //       selectedIndex = index;
                        //       //     });
                        //       //     ref
                        //       //         .read(selectedCategoryProvider.notifier)
                        //       //         .state = name;
                        //       //   },
                        //       // ),
                        //     );
                        //   },
                        // ),
                        itemBuilder: (context, index) {
                          final category = vehicleCategories[index];
                          final baseRates = {
                            "Sedan": 50.0,
                            "SUV": 80.0,
                            "Van": 100.0,
                            "Bike": 30.0,
                          };
                          final averageSpeeds = {
                            "Sedan": 40.0,
                            "SUV": 35.0,
                            "Van": 30.0,
                            "Bike": 50.0,
                          };
                          final iconAssets = {
                            "Sedan": "assets/imgs/Sedan2.png",
                            "SUV": "assets/imgs/Sedan2.png",
                            "Van": "assets/imgs/van2.png",
                            "Bike": "assets/imgs/motorbike.png",
                          };
                          final passengerCounts = {
                            "Sedan": 4,
                            "SUV": 6,
                            "Van": 8,
                            "Bike": 1,
                          };
                          final ratePerKm = 25.0;

                          final fare =
                              (baseRates[category] ?? 50) +
                              (tripDistanceKm * ratePerKm);
                          final estTripTimeMin =
                              (tripDistanceKm / (averageSpeeds[category]!)) *
                              60;
                          final iconAsset = iconAssets[category]!;
                          final name = category;
                          final passengers = passengerCounts[category]!;

                          final isSelected =
                              selectedIndex ==
                              index; // You must define this above
                          final timeAway =
                              "${estTripTimeMin.toStringAsFixed(0)} mins";

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                              ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = category;
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.blue
                                          : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(iconAsset, width: 60, height: 60),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "KES ${fare.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$timeAway ",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$passengers Pass",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Fixed button at the bottom
                    Consumer(
                      builder: (context, ref, child) {
                        final category = ref.watch(selectedCategoryProvider);
                        final isEnabled = category.toString().isNotEmpty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isEnabled
                                      ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ConfirmRideScreen(
                                                  pickup: widget.pickup,
                                                  fare: tripDistanceKm,
                                                  destination:
                                                      widget.destination,
                                                  category: category.toString(),
                                                ),
                                          ),
                                        );
                                      }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEnabled
                                    ? "Select $category"
                                    : "Select Category",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
