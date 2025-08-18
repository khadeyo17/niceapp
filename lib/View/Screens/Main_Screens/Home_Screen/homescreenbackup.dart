// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map/flutter_map.dart' as gmap;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:latlong2/latlong.dart' as ll;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/ride_in_progress.dart';
// import 'package:niceapp/View/Screens/Other_Screens/Splash_Screen/splash_logics.dart';
// import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
// import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
// import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';
// import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   final LatLng? pickup;
//   final LatLng? destination;
//   final List<Map<String, dynamic>>? stops;
//   final VehicleCategory category;
//   final DateTime? scheduledDate;
//   final bool? isScheduled;

//   const HomeScreen({
//     super.key,
//     this.pickup,
//     this.destination,
//     this.stops,
//     required this.category,
//     this.scheduledDate,
//     this.isScheduled,
//   });

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   //final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
//   List<VehicleSubCategory> vehicleCategories = [];
//   List<FareEstimate?> fareEstimates = [];
//   bool isLoadingCategories = true;
//   int selectedIndex = -1;
//   LatLng? currentLocation;
//   //LatLng? pickup;
//   List<LatLng> routePoints = [];
//   double? routeDistance;


//   gmap.GoogleMapController? _mapController;
//   Set<gmap.Marker> _markers = {};
//   Set<gmap.Polyline> _polylines = {};


//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     SplashLogics().handleExistingRide(context);

//     if (widget.pickup != null && widget.destination != null) {
//       getRouteCoordinates(widget.pickup!, widget.destination!, '$mapKey').then((
//         data,
//       ) {
//         setState(() {
//           routePoints = data['route'];
//           routeDistance = data['distance'];
//         });

//         final bounds = LatLngBounds.fromPoints(routePoints);
//         mapController.fitBounds(
//           bounds,
//           options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
//         );
//       });
//     }
//     // Fetch subcategories based on selected vehicle category type
//     fetchVehicleSubCategoriesByType(widget.category.index).then((
//       categories,
//     ) async {
//       setState(() {
//         vehicleCategories = categories;
//         fareEstimates = List<FareEstimate?>.filled(categories.length, null);
//         isLoadingCategories = false;

//         if (categories.isNotEmpty) {
//           selectedIndex = 0;
//           ref.read(selectedCategoryProvider.notifier).state = categories[0];
//         }
//       });
//       if (widget.pickup != null && widget.destination != null) {
//         for (int i = 0; i < categories.length; i++) {
//           final category = categories[i];
//           try {
//             final estimate = await FareService.getFareEstimate(
//               categoryId: category.id,
//               pickupLat: widget.pickup!.latitude,
//               pickupLng: widget.pickup!.longitude,
//               destLat: widget.destination!.latitude,
//               destLng: widget.destination!.longitude,
//               countryCode: "KE",
//             );
//             print('Received estimate for ${category.name}: $estimate');
//             setState(() {
//               fareEstimates[i] = estimate;
//             });
//           } catch (e) {
//             print('Failed to load fare for category ${category.name}: $e');
//           }
//         }
//       }
//       // for (int i = 0; i < categories.length; i++) {
//       //   final category = categories[i];
//       //   try {
//       //     final estimate = await FareService.getFareEstimate(
//       //       categoryId: category.id,
//       //       pickupLat: widget.pickup!.latitude,
//       //       pickupLng: widget.pickup!.longitude,
//       //       destLat: widget.destination!.latitude,
//       //       destLng: widget.destination!.longitude,
//       //       countryCode: "KE",
//       //     );
//       //     print('Received estimate for ${category.name}: $estimate');
//       //     setState(() {
//       //       fareEstimates[i] = estimate;
//       //     });
//       //   } catch (e) {
//       //     print('Failed to load fare for category ${category.name}: $e');
//       //   }
//       // }
//     });

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Optional post-frame logic
//     });
//   }

//   Future<Map<String, dynamic>> getRouteCoordinates(
//     LatLng start,
//     LatLng end,
//     String apiKey, // Pass your Google API key
//   ) async {
//     final url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$apiKey';

//     final res = await http.get(Uri.parse(url));

//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);

//       if (data['status'] != 'OK') {
//         throw Exception('Google Maps API error: ${data['status']}');
//       }

//       final route = data['routes'][0]['overview_polyline']['points'];
//       final distance =
//           data['routes'][0]['legs'][0]['distance']['value']; // in meters

//       // Decode polyline to LatLng list
//       List<LatLng> latLngs = decodePolyline(route);

//       return {
//         'route': latLngs,
//         'distance': distance / 1000, // Convert to KM
//       };
//     } else {
//       throw Exception('Failed to load route');
//     }
//   }

//   /// Decode a Google encoded polyline
//   List<LatLng> decodePolyline(String poly) {
//     List<LatLng> points = [];
//     int index = 0, len = poly.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = poly.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = poly.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lng += dlng;

//       points.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return points;
//   }

//   /////working
//   // Future<Map<String, dynamic>> getRouteCoordinates(
//   //   LatLng start,
//   //   LatLng end,
//   // ) async {
//   //   final url =
//   //       'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
//   //   final res = await http.get(Uri.parse(url));

//   //   if (res.statusCode == 200) {
//   //     final data = jsonDecode(res.body);
//   //     final coords = data['routes'][0]['geometry']['coordinates'] as List;
//   //     final distance = data['routes'][0]['distance']; // in meters

//   //     final List<LatLng> latLngs =
//   //         coords.map((c) => LatLng(c[1], c[0])).toList();

//   //     return {
//   //       'route': latLngs,
//   //       'distance': distance / 1000, // Convert to KM
//   //     };
//   //   } else {
//   //     throw Exception('Failed to load route');
//   //   }
//   // }

//   final mapController = MapController();

//   void fitBounds(LatLng pickup, LatLng destination) {
//     final bounds = LatLngBounds(pickup, destination);
//     bounds.extend(pickup);
//     bounds.extend(destination);
//     mapController.fitBounds(
//       bounds,
//       options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
//     );
//   }
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _getCurrentLocation();
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
//     if (mounted) {
//       setState(() {
//         currentLocation = LatLng(position.latitude, position.longitude);
//       });
//     }
//   }

//   void _initMarkers() {
//     if (widget.pickup != null) {
//       _markers.add(
//         gmap.Marker(
//           markerId: const gmap.MarkerId('pickup'),
//           position: gmap.LatLng(
//             widget.pickup!.latitude,
//             widget.pickup!.longitude,
//           ),
//           icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
//             gmap.BitmapDescriptor.hueGreen,
//           ),
//         ),
//       );
//     }
//     if (widget.destination != null) {
//       _markers.add(
//         gmap.Marker(
//           markerId: const gmap.MarkerId('destination'),
//           position: gmap.LatLng(
//             widget.destination!.latitude,
//             widget.destination!.longitude,
//           ),
//           icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
//             gmap.BitmapDescriptor.hueRed,
//           ),
//         ),
//       );
//     }
//   }

//   void _navigateToWhereTo() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => WhereToScreen(
//               category: VehicleCategory.passenger,
//               initialPickupLocation: currentLocation,
//             ),
//       ),
//     );
//     // context.pushNamed(Routes().whereTo);
//     // //Navigator.pushNamed(context, '/whereto');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final driver = ref.watch(linkedDriverProvider);
//     //final fare = ref.watch(estimatedFareProvider);
//     //final category = ref.watch(selectedCategoryProvider);

//     final rideConfirmed = ref.watch(rideConfirmedProvider);

//     //final pickup = widget.pickup;
//     final pickup = widget.pickup ?? currentLocation;
//     final destination = widget.destination;
//     final dropAddressAsync = ref.watch(dropAddressProvider);
//     final distance = Distance();
//     final selectedFare =
//         (selectedIndex >= 0 && selectedIndex < fareEstimates.length)
//             ? fareEstimates[selectedIndex]?.fare ?? 0.0
//             : 0.0;
//     // final tripDistanceKm = distance.as(
//     //   LengthUnit.Kilometer,
//     //   pickup!,
//     //   destination!,
//     // );

//     double? tripDistanceKm;
//     LatLng? midPoint;

//     if (pickup != null && destination != null) {
//       // tripDistanceKm = distance.as(LengthUnit.Kilometer, pickup, destination);

//       midPoint = LatLng(
//         (pickup.latitude + destination.latitude) / 2,
//         (pickup.longitude + destination.longitude) / 2,
//       );
//     }

//     if (rideConfirmed) {
//       if (driver == null) {
//         return const Center(child: Text('No driver linked'));
//       }

//       return RideInProgressScreen(
//         driverStart: ll.LatLng(
//           driver.location.latitude,
//           driver.location.longitude,
//         ),
//         pickup: widget.pickup!,
//       );
//     }
//     if (midPoint != null) {
//       midPoint = LatLng(
//         (pickup!.latitude + destination!.latitude) / 2,
//         (pickup.longitude + destination.longitude) / 2,
//       );
//     }

//     return Scaffold(
//       //appBar: AppBar(title: const Text("Amini Ride")),
//       body:
//           pickup == null
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   Column(
//                     children: [
//                       Expanded(
//                         child: FlutterMap(
//                           mapController: mapController,
//                           options: MapOptions(
//                             onMapReady: () {
//                               if (pickup != null && destination != null) {
//                                 fitBounds(pickup, destination);
//                               }
//                             },
//                             center: pickup,
//                             zoom: 13,
//                           ),
//                           //options: MapOptions(center: pickup, zoom: 13.0),
//                           children: [
//                             TileLayer(
//                               urlTemplate:
//                                   "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                               userAgentPackageName: 'com.example.niceapp',
//                             ),

//                             MarkerLayer(
//                               markers: [
//                                 if (pickup != null)
//                                   Marker(
//                                     point: pickup,
//                                     width: 40,
//                                     height: 40,
//                                     builder:
//                                         (_) => const Icon(
//                                           Icons.location_pin,
//                                           color: Colors.green,
//                                           size: 40,
//                                         ),
//                                   ),
//                                 if (destination != null)
//                                   Marker(
//                                     point: destination,
//                                     width: 40,
//                                     height: 40,
//                                     builder:
//                                         (_) => const Icon(
//                                           Icons.flag,
//                                           color: Colors.red,
//                                           size: 40,
//                                         ),
//                                   ),

//                                 // if (midPoint != null)
//                                 //   Marker(
//                                 //     point: midPoint,
//                                 //     width: 200,
//                                 //     height: 50,
//                                 //     builder:
//                                 //         (_) => Container(
//                                 //           alignment: Alignment.center,
//                                 //           padding: const EdgeInsets.symmetric(
//                                 //             horizontal: 8,
//                                 //             vertical: 4,
//                                 //           ),
//                                 //           decoration: BoxDecoration(
//                                 //             color: Colors.yellow,
//                                 //             borderRadius: BorderRadius.circular(
//                                 //               8,
//                                 //             ),
//                                 //           ),
//                                 //           child: Text(
//                                 //             '${tripDistanceKm?.toStringAsFixed(2) ?? "0.00"} km',
//                                 //             style: const TextStyle(
//                                 //               color: Colors.white,
//                                 //               fontSize: 14,
//                                 //             ),
//                                 //           ),
//                                 //         ),
//                                 //   ),
//                                 if (routeDistance != null)
//                                   Marker(
//                                     point: routePoints[routePoints.length ~/ 2],
//                                     builder:
//                                         (_) => Container(
//                                           padding: const EdgeInsets.all(6),
//                                           decoration: BoxDecoration(
//                                             color: Colors.black87,
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           child: Text(
//                                             "${routeDistance!.toStringAsFixed(2)} km",
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                   ),
//                               ],
//                             ),

//                             PolylineLayer(
//                               polylines: [
//                                 // Polyline(
//                                 //   //points: [pickup, destination],
//                                 //   points: [
//                                 //     if (pickup != null) pickup,
//                                 //     if (destination != null) destination,
//                                 //   ],
//                                 //   strokeWidth: 4.0,
//                                 //   color: Colors.blueAccent,
//                                 // ),
//                                 if (routePoints.isNotEmpty)
//                                   Polyline(
//                                     points: routePoints,
//                                     strokeWidth: 4.0,
//                                     color: Colors.blueAccent,
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   Positioned(
//                     top: 60,
//                     left: 16,
//                     right: 16,
//                     child: GestureDetector(
//                       onTap: () {
//                         // Navigate to search screen or open modal
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (_) => WhereToScreen(
//                                   category: VehicleCategory.passenger,
//                                   initialPickupLocation: pickup,
//                                 ),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 10,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Colors.black26,
//                               blurRadius: 6,
//                               offset: Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.search, color: Colors.grey),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 // // widget.destination?.toJson().toString(),
//                                 // //widget.destination?.toJson().toString() ??
//                                 // widget.pickupAddressProvider??  'Select Destination',
//                                 dropAddressAsync.when(
//                                   data:
//                                       (address) =>
//                                           address ?? 'Select Destination',
//                                   loading: () => 'Loading...',
//                                   error: (err, _) => 'Error',
//                                 ),
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () {
//                                 // Handle adding a new stop here
//                                 showDialog(
//                                   context: context,
//                                   builder:
//                                       (_) => const AlertDialog(
//                                         title: Text("Add Stop"),
//                                         content: Text(
//                                           "Add stop functionality coming soon.",
//                                         ),
//                                       ),
//                                 );
//                               },
//                               child: const Icon(Icons.add, color: Colors.blue),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
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

//                   if (widget.destination != null)
//                     DraggableScrollableSheet(
//                       initialChildSize: 0.4, // 40% of screen height
//                       minChildSize:
//                           0.25, // Never collapse below 25% (ensures 1 category is visible)
//                       maxChildSize: 0.8, // Optional, can grow up to 80%
//                       builder: (context, scrollController) {
//                         return Container(
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.vertical(
//                               top: Radius.circular(20),
//                             ),
//                             boxShadow: [
//                               BoxShadow(color: Colors.black26, blurRadius: 10),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Expanded(
//                                 child: ListView.builder(
//                                   controller: scrollController,
//                                   //itemCount: vehicleCategories.length,
//                                   itemCount:
//                                       isLoadingCategories
//                                           ? 0
//                                           : vehicleCategories.length,
//                                   padding: const EdgeInsets.all(12),

//                                   itemBuilder: (context, index) {
//                                     final category = vehicleCategories[index];
//                                     final name = category.name;
//                                     final passengers = category.maxPassengers;
//                                     final isSelected = selectedIndex == index;
//                                     //new
//                                     final estimate = fareEstimates[index];

//                                     final fareDisplay =
//                                         estimate != null
//                                             ? "${estimate.currency} ${estimate.fare.toStringAsFixed(2)}"
//                                             : "Loading...";

//                                     final timeAway =
//                                         estimate != null
//                                             ? "${estimate.timeEstimate} mins"
//                                             : "Estimating...";

//                                     return GestureDetector(
//                                       onTap: () {
//                                         setState(() {
//                                           selectedIndex = index;
//                                         });
//                                         ref
//                                             .read(
//                                               selectedCategoryProvider.notifier,
//                                             )
//                                             .state = category;
//                                       },
//                                       child: Container(
//                                         margin: const EdgeInsets.only(
//                                           bottom: 12,
//                                         ),
//                                         padding: const EdgeInsets.all(8),
//                                         decoration: BoxDecoration(
//                                           color: Colors.white,
//                                           border: Border.all(
//                                             color:
//                                                 isSelected
//                                                     ? Colors.grey
//                                                     : Colors.transparent,
//                                             width: 2,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             category.iconUrl != null &&
//                                                     category.iconUrl!.isNotEmpty
//                                                 ? Image.network(
//                                                   "$ImageUrl${category.iconUrl}",
//                                                   //category.iconUrl!,
//                                                   width: 60,
//                                                   height: 60,
//                                                   errorBuilder: (
//                                                     context,
//                                                     error,
//                                                     stackTrace,
//                                                   ) {
//                                                     return Image.asset(
//                                                       'assets/imgs/Sedan2.png', // your fallback image
//                                                       width: 60,
//                                                       height: 60,
//                                                     );
//                                                   },
//                                                 )
//                                                 : Image.asset(
//                                                   'assets/imgs/Sedan2.png',
//                                                   width: 60,
//                                                   height: 60,
//                                                 ),

//                                             const SizedBox(width: 12),
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceBetween,
//                                                     children: [
//                                                       Text(
//                                                         name,
//                                                         style: const TextStyle(
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                           fontSize: 16,
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         fareDisplay,
//                                                         style: const TextStyle(
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                           fontSize: 16,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   const SizedBox(height: 4),
//                                                   // Text(
//                                                   //   "$timeAway",
//                                                   //   style: const TextStyle(
//                                                   //     color: Colors.grey,
//                                                   //     fontSize: 13,
//                                                   //   ),
//                                                   // ),
//                                                   Text(
//                                                     timeAway,
//                                                     style: const TextStyle(
//                                                       color: Colors.grey,
//                                                       fontSize: 13,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 4),
//                                                   Text(
//                                                     "$passengers Passengers",
//                                                     style: const TextStyle(
//                                                       color: Colors.grey,
//                                                       fontSize: 13,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),

//                               // Fixed button at the bottom
//                               Consumer(
//                                 builder: (context, ref, child) {
//                                   final selected = ref.watch(
//                                     selectedCategoryProvider,
//                                   );
//                                   final category = selected?.name ?? 'N/A';
//                                   final categoryId = selected?.id ?? 0;
//                                   // final category = ref.watch(selectedCategoryProvider);
//                                   // final categoryId = category!.id;
//                                   final isEnabled =
//                                       category.toString().isNotEmpty;

//                                   return Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 12,
//                                     ),
//                                     child: SizedBox(
//                                       width: double.infinity,
//                                       child: ElevatedButton(
//                                         onPressed:
//                                             isEnabled
//                                                 ? () {
//                                                   Navigator.push(
//                                                     context,
//                                                     MaterialPageRoute(
//                                                       builder:
//                                                           (
//                                                             _,
//                                                           ) => ConfirmRideScreen(
//                                                             pickup:
//                                                                 widget.pickup!,
//                                                             fare:
//                                                                 selectedFare, // tripDistanceKm,
//                                                             //fare: fareEstimates[selectedIndex]?.fare ?? 0.0, // ✅ Correct fare
//                                                             destination:
//                                                                 widget
//                                                                     .destination!,
//                                                             category:
//                                                                 categoryId,
//                                                             optionSelected:
//                                                                 category,
//                                                             isScheduled:
//                                                                 widget
//                                                                     .isScheduled,
//                                                             scheduledDate:
//                                                                 widget
//                                                                     .scheduledDate,
//                                                           ),
//                                                     ),
//                                                   );
//                                                 }
//                                                 : null,
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.grey[700],
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 16,
//                                           ),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               12,
//                                             ),
//                                           ),
//                                         ),
//                                         child: Text(
//                                           // isEnabled
//                                           //     ? "Select $category"
//                                           //     : "Select Category",
//                                           (widget.isScheduled == true &&
//                                                   isEnabled)
//                                               ? "Book $category"
//                                               : "Select ${category ?? 'Category'}",
//                                           style: const TextStyle(
//                                             fontSize: 18,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                 ],
//               ),
//     );
//   }
// }
