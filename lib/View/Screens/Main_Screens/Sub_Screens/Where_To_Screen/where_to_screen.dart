// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:niceapp/Container/Repositories/predicted_places_repo.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_logics.dart';

// import 'where_to_providers.dart';

// class WhereToScreen extends StatefulWidget {
//   const WhereToScreen({super.key, required this.controller});

//   final GoogleMapController controller;

//   @override
//   State<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends State<WhereToScreen> {
//   final TextEditingController whereToController = TextEditingController();

//   late NavigatorState _navigator;

//   @override
//   void didChangeDependencies() {
//     _navigator = Navigator.of(context);
//     super.didChangeDependencies();
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     return Scaffold(
//       appBar: AppBar(
//         foregroundColor: const Color(0xff1a3646),
//         backgroundColor: const Color(0xff1a3646),
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: Text(
//           "Where To Go",
//           style: Theme.of(
//             context,
//           ).textTheme.bodySmall!.copyWith(fontFamily: "bold"),
//         ),
//       ),
//       body: SafeArea(
//         child: SizedBox(
//           width: size.width,
//           height: size.height,
//           child: Padding(
//             padding: const EdgeInsets.only(top: 20.0),
//             child: Consumer(
//               builder: (context, ref, child) {
//                 return Column(
//                   children: [
//                     SizedBox(
//                       width: size.width * 0.9,
//                       child: TextField(
//                         onChanged: (e) {
//                           if (e.length < 2) {
//                             ref
//                                 .watch(whereToPredictedPlacesProvider.notifier)
//                                 .update((state) => null);
//                           }
//                           ref
//                               .watch(globalPredictedPlacesRepoProvider)
//                               .getAllPredictedPlaces(e, context, ref);
//                         },
//                         controller: whereToController,
//                         cursorColor: Colors.red,
//                         keyboardType: TextInputType.emailAddress,
//                         style: Theme.of(
//                           context,
//                         ).textTheme.bodySmall!.copyWith(fontSize: 14),
//                         decoration: InputDecoration(
//                           hintText: "Search Location",
//                           hintStyle: Theme.of(context).textTheme.bodySmall!
//                               .copyWith(fontSize: 14, color: Colors.white),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: const BorderSide(
//                               color: Colors.red,
//                               width: 1,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: const BorderSide(
//                               color: Colors.red,
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child:
//                           ref.watch(whereToPredictedPlacesProvider) == null
//                               ? Container(
//                                 alignment: Alignment.center,
//                                 child: const Text(
//                                   "Please Write Something to start the search",
//                                 ),
//                               )
//                               : Container(
//                                 alignment: Alignment.center,
//                                 margin: const EdgeInsets.only(top: 15.0),
//                                 child:
//                                     ref.watch(whereToLoadingProvider)
//                                         ? const CircularProgressIndicator.adaptive(
//                                           backgroundColor: Colors.red,
//                                         )
//                                         : ListView.separated(
//                                           itemCount:
//                                               ref
//                                                   .watch(
//                                                     whereToPredictedPlacesProvider,
//                                                   )!
//                                                   .length,
//                                           separatorBuilder: (context, index) {
//                                             return const Divider(
//                                               height: 20,
//                                               color: Colors.red,
//                                             );
//                                           },
//                                           itemBuilder: (context, index) {
//                                             return InkWell(
//                                               onTap: () async {
//                                                 try {
//                                                   await WhereToLogics()
//                                                       .setDropOffLocation(
//                                                         context,
//                                                         ref,
//                                                         widget.controller,
//                                                         index,
//                                                       );

//                                                   _navigator.pop();
//                                                 } catch (e) {
//                                                   print(e);
//                                                 }
//                                               },
//                                               child: Padding(
//                                                 padding: const EdgeInsets.all(
//                                                   15.0,
//                                                 ),
//                                                 child: Text(
//                                                   ref
//                                                           .watch(
//                                                             whereToPredictedPlacesProvider,
//                                                           )![index]
//                                                           .mainText ??
//                                                       "Loading ...",
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                               ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:niceapp/Container/Repositories/predicted_places_repo.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_logics.dart';
// import 'where_to_providers.dart';

// class WhereToScreen extends StatefulWidget {
//   const WhereToScreen({super.key, this.controller});

//   final GoogleMapController? controller;

//   @override
//   State<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends State<WhereToScreen> {
//   final TextEditingController whereToController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     return Scaffold(
//       appBar: AppBar(
//         foregroundColor: Colors.white,
//         backgroundColor: Theme.of(context).primaryColor,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: Text(
//           "Where To Go",
//           style: Theme.of(
//             context,
//           ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: SafeArea(
//         child: SizedBox(
//           width: size.width,
//           height: size.height,
//           child: Padding(
//             padding: const EdgeInsets.only(top: 20.0),
//             child: Consumer(
//               builder: (context, ref, child) {
//                 return Column(
//                   children: [
//                     buildSearchField(context, ref),
//                     Expanded(child: buildResultsList(context, ref)),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildSearchField(BuildContext context, WidgetRef ref) {
//     return SizedBox(
//       width: MediaQuery.sizeOf(context).width * 0.9,
//       child: TextField(
//         onChanged: (text) {
//           if (text.length < 2) {
//             ref
//                 .watch(whereToPredictedPlacesProvider.notifier)
//                 .update((state) => null);
//           } else {
//             ref
//                 .watch(globalPredictedPlacesRepoProvider)
//                 .getAllPredictedPlaces(text, context, ref);
//           }
//         },
//         controller: whereToController,
//         cursorColor: Theme.of(context).primaryColor,
//         style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
//         decoration: InputDecoration(
//           hintText: "Search Location",
//           hintStyle: Theme.of(
//             context,
//           ).textTheme.bodySmall!.copyWith(fontSize: 14, color: Colors.grey),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide(
//               color: Theme.of(context).primaryColor,
//               width: 1,
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide(
//               color: Theme.of(context).primaryColor,
//               width: 1,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildResultsList(BuildContext context, WidgetRef ref) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     if (predictedPlaces == null) {
//       return const Center(
//         child: Text("Please write something to start the search"),
//       );
//     }

//     return isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : ListView.separated(
//           itemCount: predictedPlaces.length,
//           separatorBuilder:
//               (context, index) =>
//                   Divider(height: 20, color: Theme.of(context).primaryColor),
//           itemBuilder: (context, index) {
//             return ListTile(
//               title: Text(predictedPlaces[index].mainText ?? "Loading ..."),
//               onTap: () async {
//                 try {
//                   if (widget.controller != null) {
//                     await WhereToLogics().setDropOffLocation(
//                       context,
//                       ref,
//                       widget.controller!,
//                       index,
//                     );
//                   }

//                   if (mounted) Navigator.pop(context);
//                 } catch (e) {
//                   print("Error: $e");
//                 }
//               },
//             );
//           },
//         );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart'; // Assuming you have this file for providers

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   late GoogleMapController _mapController;
//   LatLng? _selectedLocation;

//   void _searchLocation() async {
//     String query = whereToController.text.trim();
//     if (query.isNotEmpty) {
//       try {
//         // Start the search via the StateNotifier
//         await ref
//             .read(predictedPlacesNotifierProvider.notifier)
//             .searchLocation(query);

//         final result = ref.read(predictedPlacesNotifierProvider);
//         if (result != null && result.isNotEmpty) {
//           // Define firstResult by accessing the first item in the list
//           final firstResult = result[0];

//           setState(() {
//             _selectedLocation = LatLng(
//               double.parse(
//                 firstResult.lat ?? "0.0",
//               ), // Default to "0.0" if lat is null
//               double.parse(
//                 firstResult.lon ?? "0.0",
//               ), // Default to "0.0" if lon is null
//             );
//             _mapController.animateCamera(
//               CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
//             );
//           });
//         } else {
//           _showError("Location not found. Try a more specific address.");
//         }
//       } catch (e) {
//         _showError("Error searching for location: $e");
//       }
//     } else {
//       _showError("Please enter a location.");
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 // Pick Up Location Field
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 // Where To (Destination) Field
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: whereToController,
//                         decoration: InputDecoration(
//                           hintText: "Search for a destination",
//                           prefixIcon: const Icon(Icons.search),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _searchLocation,
//                       child: const Text("Search"),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           if (isLoading) const CircularProgressIndicator(),

//           // Google Map
//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: _selectedLocation ?? LatLng(-1.2921, 36.8219),
//                 zoom: 15.0,
//               ),
//               onMapCreated: (controller) => _mapController = controller,
//               markers:
//                   _selectedLocation != null
//                       ? {
//                         Marker(
//                           markerId: const MarkerId('selectedLocation'),
//                           position: _selectedLocation!,
//                           infoWindow: const InfoWindow(
//                             title: 'Selected Location',
//                           ),
//                         ),
//                       }
//                       : {},
//               onTap: (LatLng latLng) {
//                 setState(() {
//                   _selectedLocation = latLng;
//                 });
//               },
//             ),
//           ),

//           // Predicted Results
//           if (predictedPlaces != null && predictedPlaces.isNotEmpty) ...[
//             Expanded(
//               child: ListView.builder(
//                 itemCount: predictedPlaces.length,
//                 itemBuilder: (context, index) {
//                   final place = predictedPlaces[index];
//                   return ListTile(
//                     title: Text(place.mainText ?? "No name"),
//                     onTap: () {
//                       setState(() {
//                         _selectedLocation = LatLng(
//                           double.parse(place.lat ?? "0.0"),
//                           double.parse(place.lon ?? "0.0"),
//                         );
//                         _mapController.animateCamera(
//                           CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
//                         );
//                       });
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   final List<LatLng> _stops = [];

//   late GoogleMapController _mapController;
//   LatLng? _selectedLocation;
//   LatLng? _pickupLocation;

//   Future<void> _setCurrentLocationAsPickup() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     setState(() {
//       _pickupLocation = LatLng(position.latitude, position.longitude);
//       pickupLocationController.text =
//           "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
//     });

//     _mapController.animateCamera(
//       CameraUpdate.newLatLngZoom(_pickupLocation!, 15.0),
//     );
//   }

//   void _searchLocation() async {
//     String query = whereToController.text.trim();
//     if (query.isNotEmpty) {
//       try {
//         await ref
//             .read(predictedPlacesNotifierProvider.notifier)
//             .searchLocation(query);
//         final result = ref.read(predictedPlacesNotifierProvider);
//         if (result != null && result.isNotEmpty) {
//           final firstResult = result[0];
//           setState(() {
//             _selectedLocation = LatLng(
//               double.parse(firstResult.lat ?? "0.0"),
//               double.parse(firstResult.lon ?? "0.0"),
//             );
//             _mapController.animateCamera(
//               CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
//             );
//           });
//         } else {
//           _showError("Location not found. Try a more specific address.");
//         }
//       } catch (e) {
//         _showError("Error searching for location: $e");
//       }
//     } else {
//       _showError("Please enter a location.");
//     }
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//          _setCurrentLocationAsPickup();
//       });
//     } else {
//       _showError("Please select a location before adding a stop.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: whereToController,
//                         decoration: InputDecoration(
//                           hintText: "Search for a destination or stop",
//                           prefixIcon: const Icon(Icons.search),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _searchLocation,
//                       child: const Text("Search"),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (isLoading) const CircularProgressIndicator(),

//           // Map View
//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: _selectedLocation ?? const LatLng(-1.2921, 36.8219),
//                 zoom: 15.0,
//               ),
//               onMapCreated: (controller) => _mapController = controller,
//               markers: {
//                 if (_selectedLocation != null)
//                   Marker(
//                     markerId: const MarkerId('selectedLocation'),
//                     position: _selectedLocation!,
//                     infoWindow: const InfoWindow(title: 'Selected Location'),
//                   ),
//                 for (int i = 0; i < _stops.length; i++)
//                   Marker(
//                     markerId: MarkerId('stop_$i'),
//                     position: _stops[i],
//                     infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueOrange,
//                     ),
//                   ),
//               },
//               onTap: (latLng) {
//                 setState(() {
//                   _selectedLocation = latLng;
//                 });
//               },
//             ),
//           ),

//           // List of Stops
//           if (_stops.isNotEmpty)
//             Container(
//               height: 150,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     leading: const Icon(
//                       Icons.location_on,
//                       color: Colors.orange,
//                     ),
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),

//           // Prediction List
//           if (predictedPlaces != null && predictedPlaces.isNotEmpty)
//             Expanded(
//               child: ListView.builder(
//                 itemCount: predictedPlaces.length,
//                 itemBuilder: (context, index) {
//                   final place = predictedPlaces[index];
//                   return ListTile(
//                     title: Text(place.mainText ?? "Unnamed"),
//                     onTap: () {
//                       setState(() {
//                         _selectedLocation = LatLng(
//                           double.parse(place.lat ?? "0.0"),
//                           double.parse(place.lon ?? "0.0"),
//                         );
//                         _mapController.animateCamera(
//                           CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
//                         );
//                       });
//                     },
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart';
// import 'package:geolocator/geolocator.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   final List<LatLng> _stops = [];

//   late GoogleMapController _mapController;
//   LatLng? _selectedLocation;
//   LatLng? _pickupLocation;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _setCurrentLocationAsPickup();
//     });
//   }

//   Future<void> _setCurrentLocationAsPickup() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     setState(() {
//       _pickupLocation = LatLng(position.latitude, position.longitude);
//       pickupLocationController.text =
//           "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
//     });

//     if (_mapController != null) {
//       _mapController.animateCamera(
//         CameraUpdate.newLatLngZoom(_pickupLocation!, 15.0),
//       );
//     }
//   }

//   void _searchLocation() async {
//     String query = whereToController.text.trim();
//     if (query.isNotEmpty) {
//       try {
//         await ref
//             .read(predictedPlacesNotifierProvider.notifier)
//             .searchLocation(query);
//         final result = ref.read(predictedPlacesNotifierProvider);
//         if (result != null && result.isNotEmpty) {
//           final firstResult = result[0];
//           setState(() {
//             _selectedLocation = LatLng(
//               double.parse(firstResult.lat ?? "0.0"),
//               double.parse(firstResult.lon ?? "0.0"),
//             );
//             _mapController.animateCamera(
//               CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
//             );
//           });
//         } else {
//           _showError("Location not found. Try a more specific address.");
//         }
//       } catch (e) {
//         _showError("Error searching for location: $e");
//       }
//     } else {
//       _showError("Please enter a location.");
//     }
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//     } else {
//       _showError("Please select a location before adding a stop.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   readOnly: true,
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: whereToController,
//                         decoration: InputDecoration(
//                           hintText: "Search for a destination or stop",
//                           prefixIcon: const Icon(Icons.search),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _searchLocation,
//                       child: const Text("Search"),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (isLoading) const CircularProgressIndicator(),

//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: _pickupLocation ?? const LatLng(-1.2921, 36.8219),
//                 zoom: 15.0,
//               ),
//               onMapCreated: (controller) => _mapController = controller,
//               markers: {
//                 if (_pickupLocation != null)
//                   Marker(
//                     markerId: const MarkerId('pickupLocation'),
//                     position: _pickupLocation!,
//                     infoWindow: const InfoWindow(title: 'Pickup Location'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueAzure,
//                     ),
//                   ),
//                 if (_selectedLocation != null)
//                   Marker(
//                     markerId: const MarkerId('selectedLocation'),
//                     position: _selectedLocation!,
//                     infoWindow: const InfoWindow(title: 'Selected Location'),
//                   ),
//                 for (int i = 0; i < _stops.length; i++)
//                   Marker(
//                     markerId: MarkerId('stop_$i'),
//                     position: _stops[i],
//                     infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueOrange,
//                     ),
//                   ),
//               },
//               onTap: (latLng) {
//                 setState(() {
//                   _selectedLocation = latLng;
//                 });
//               },
//             ),
//           ),

//           if (_stops.isNotEmpty)
//             Container(
//               height: 150,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     leading: const Icon(
//                       Icons.location_on,
//                       color: Colors.orange,
//                     ),
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),

//           if (predictedPlaces != null && predictedPlaces.isNotEmpty)
//             Expanded(
//               child: ListView.builder(
//                 itemCount: predictedPlaces.length,
//                 itemBuilder: (context, index) {
//                   final place = predictedPlaces[index];
//                   return ListTile(
//                     title: Text(place.mainText ?? "Unnamed"),
//                     onTap: () {
//                       setState(() {
//                         _selectedLocation = LatLng(
//                           double.parse(place.lat ?? "0.0"),
//                           double.parse(place.lon ?? "0.0"),
//                         );
//                         _mapController.animateCamera(
//                           CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
//                         );
//                       });
//                     },
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   final List<LatLng> _stops = [];

//   late GoogleMapController _mapController;
//   LatLng? _selectedLocation;
//   LatLng? _pickupLocation;

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _initializePickupLocation();
//   //   whereToController.addListener(_onDestinationInputChanged);
//   // }
//   @override
//   void initState() {
//     super.initState();

//     // Auto trigger destination prediction
//     whereToController.addListener(() {
//       final input = whereToController.text.trim();
//       if (input.isNotEmpty) {
//         _autocompleteDestination(input);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     pickupLocationController.dispose();
//     whereToController.removeListener(_onDestinationInputChanged);
//     whereToController.dispose();
//     super.dispose();
//   }

//   void _autocompleteDestination(String input) async {
//     try {
//       await ref
//           .read(predictedPlacesNotifierProvider.notifier)
//           .searchLocation(input);
//     } catch (e) {
//       _showError("Failed to fetch location suggestions: $e");
//     }
//   }

//   Future<void> _initializePickupLocation() async {
//     try {
//       final permission = await _checkAndRequestLocationPermission();
//       if (!permission) return;

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       _pickupLocation = LatLng(position.latitude, position.longitude);
//       final address = await _getAddressFromLatLng(_pickupLocation!);

//       setState(() {
//         pickupLocationController.text = address;
//       });

//       if (_mapController != null) {
//         _mapController.animateCamera(
//           CameraUpdate.newLatLngZoom(_pickupLocation!, 15),
//         );
//       }
//     } catch (e) {
//       _showError("Failed to get location: $e");
//     }
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(LatLng location) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         return "${place.name?.isNotEmpty == true ? place.name : "Unnamed Location"}, ${place.locality ?? ''}, ${place.country ?? ''}";
//       }
//     } catch (_) {}
//     return "Unnamed Location";
//   }

//   void _onDestinationInputChanged() {
//     final query = whereToController.text.trim();
//     if (query.isNotEmpty) {
//       ref.read(predictedPlacesNotifierProvider.notifier).searchLocation(query);
//     }
//   }

//   void _onSuggestionTap(LatLng location, String name) {
//     setState(() {
//       _selectedLocation = location;
//       whereToController.text = name;
//     });
//     _mapController.animateCamera(CameraUpdate.newLatLngZoom(location, 15.0));
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//     } else {
//       _showError("Select a location first.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   onChanged: (value) {
//                     // Optional: allow editing pickup name
//                   },
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: whereToController,
//                   decoration: InputDecoration(
//                     hintText: "Search for destination...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (isLoading) const CircularProgressIndicator(),

//           if (predictedPlaces != null && predictedPlaces.isNotEmpty)
//             SizedBox(
//               height: 150,
//               child: ListView.builder(
//                 itemCount: predictedPlaces.length,
//                 itemBuilder: (context, index) {
//                   final place = predictedPlaces[index];
//                   final lat = double.tryParse(place.lat ?? "") ?? 0.0;
//                   final lon = double.tryParse(place.lon ?? "") ?? 0.0;
//                   return ListTile(
//                     title: Text(place.display_name ?? "Unnamed"),
//                     onTap:
//                         () => _onSuggestionTap(
//                           LatLng(lat, lon),
//                           place.display_name ?? "Unnamed",
//                         ),
//                   );
//                 },
//               ),
//             ),

//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: _pickupLocation ?? const LatLng(-1.2921, 36.8219),
//                 zoom: 15,
//               ),
//               onMapCreated: (controller) => _mapController = controller,
//               markers: {
//                 if (_pickupLocation != null)
//                   Marker(
//                     markerId: const MarkerId('pickup'),
//                     position: _pickupLocation!,
//                     infoWindow: const InfoWindow(title: 'Pickup Location'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueAzure,
//                     ),
//                   ),
//                 if (_selectedLocation != null)
//                   Marker(
//                     markerId: const MarkerId('destination'),
//                     position: _selectedLocation!,
//                     infoWindow: const InfoWindow(title: 'Destination'),
//                   ),
//                 for (int i = 0; i < _stops.length; i++)
//                   Marker(
//                     markerId: MarkerId('stop_$i'),
//                     position: _stops[i],
//                     infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueOrange,
//                     ),
//                   ),
//               },
//               onTap: (latLng) async {
//                 setState(() {
//                   _selectedLocation = latLng;
//                 });
//                 final address = await _getAddressFromLatLng(latLng);
//                 whereToController.text = address;
//               },
//             ),
//           ),

//           if (_stops.isNotEmpty)
//             Container(
//               height: 130,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

//////GOOGLEMAPS
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_providers.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   final List<LatLng> _stops = [];

//   late GoogleMapController _mapController;
//   LatLng? _selectedLocation;
//   LatLng? _pickupLocation;

//   @override
//   void initState() {
//     super.initState();
//     _initializePickupLocation();
//     whereToController.addListener(_onDestinationInputChanged);
//   }

//   @override
//   void dispose() {
//     pickupLocationController.dispose();
//     whereToController.removeListener(_onDestinationInputChanged);
//     whereToController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializePickupLocation() async {
//     try {
//       final permission = await _checkAndRequestLocationPermission();
//       if (!permission) return;

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       _pickupLocation = LatLng(position.latitude, position.longitude);
//       final address = await _getAddressFromLatLng(_pickupLocation!);

//       setState(() {
//         pickupLocationController.text = address;
//       });

//       if (_mapController != null) {
//         _mapController.animateCamera(
//           CameraUpdate.newLatLngZoom(_pickupLocation!, 15),
//         );
//       }
//     } catch (e) {
//       _showError("Failed to get location: $e");
//     }
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(LatLng location) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         return "${place.name?.isNotEmpty == true ? place.name : "Unnamed Location"}, ${place.locality ?? ''}, ${place.country ?? ''}";
//       }
//     } catch (_) {}
//     return "Unnamed Location";
//   }

//   void _onDestinationInputChanged() {
//     final query = whereToController.text.trim();
//     if (query.isNotEmpty) {
//       ref.read(predictedPlacesNotifierProvider.notifier).searchLocation(query);
//     }
//   }

//   void _onSuggestionTap(LatLng location, String name) {
//     setState(() {
//       _selectedLocation = location;
//       whereToController.text = name;
//     });
//     _mapController.animateCamera(CameraUpdate.newLatLngZoom(location, 15.0));
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//     } else {
//       _showError("Select a location first.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   onChanged: (value) {
//                     // Optional: allow editing pickup name
//                   },
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: whereToController,
//                   decoration: InputDecoration(
//                     hintText: "Search for destination...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (isLoading) const CircularProgressIndicator(),

//           if (predictedPlaces != null && predictedPlaces.isNotEmpty)
//             SizedBox(
//               height: 150,
//               child: ListView.builder(
//                 itemCount: predictedPlaces.length,
//                 itemBuilder: (context, index) {
//                   final place = predictedPlaces[index];
//                   final lat = double.tryParse(place.lat ?? "") ?? 0.0;
//                   final lon = double.tryParse(place.lon ?? "") ?? 0.0;
//                   return ListTile(
//                     title: Text(place.displayName ?? "Unnamed"),
//                     onTap:
//                         () => _onSuggestionTap(
//                           LatLng(lat, lon),
//                           place.displayName ?? "Unnamed",
//                         ),
//                   );
//                 },
//               ),
//             ),

//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: _pickupLocation ?? const LatLng(-1.2921, 36.8219),
//                 zoom: 15,
//               ),
//               onMapCreated: (controller) => _mapController = controller,
//               markers: {
//                 if (_pickupLocation != null)
//                   Marker(
//                     markerId: const MarkerId('pickup'),
//                     position: _pickupLocation!,
//                     infoWindow: const InfoWindow(title: 'Pickup Location'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueAzure,
//                     ),
//                   ),
//                 if (_selectedLocation != null)
//                   Marker(
//                     markerId: const MarkerId('destination'),
//                     position: _selectedLocation!,
//                     infoWindow: const InfoWindow(title: 'Destination'),
//                   ),
//                 for (int i = 0; i < _stops.length; i++)
//                   Marker(
//                     markerId: MarkerId('stop_$i'),
//                     position: _stops[i],
//                     infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                       BitmapDescriptor.hueOrange,
//                     ),
//                   ),
//               },
//               onTap: (latLng) async {
//                 setState(() {
//                   _selectedLocation = latLng;
//                 });
//                 final address = await _getAddressFromLatLng(latLng);
//                 whereToController.text = address;
//               },
//             ),
//           ),

//           if (_stops.isNotEmpty)
//             Container(
//               height: 130,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
////OpenStreetMap
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'where_to_providers.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   final List<LatLng> _stops = [];

//   LatLng? _pickupLocation;
//   LatLng? _selectedLocation;

//   final MapController _mapController = MapController();

//   @override
//   void initState() {
//     super.initState();
//     _initializePickupLocation();
//     whereToController.addListener(_onDestinationInputChanged);
//   }

//   @override
//   void dispose() {
//     pickupLocationController.dispose();
//     whereToController.removeListener(_onDestinationInputChanged);
//     whereToController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializePickupLocation() async {
//     try {
//       final permission = await _checkAndRequestLocationPermission();
//       if (!permission) return;

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       final pickup = LatLng(position.latitude, position.longitude);
//       _pickupLocation = pickup;
//       final address = await _getAddressFromLatLng(pickup);

//       setState(() {
//         pickupLocationController.text = address;
//       });

//       _mapController.move(pickup, 15);
//     } catch (e) {
//       _showError("Failed to get location: $e");
//     }
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(LatLng location) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         return "${place.subLocality ?? "Unnamed"}, ${place.locality ?? ''}, ${place.country ?? ''}";
//       }
//     } catch (_) {}
//     return "Unnamed Location";
//   }

//   void _onDestinationInputChanged() {
//     final query = whereToController.text.trim();
//     if (query.isNotEmpty) {
//       ref.read(predictedPlacesNotifierProvider.notifier).searchLocation(query);
//     }
//   }

//   void _onSuggestionTap(LatLng location, String name) async {
//     setState(() {
//       _selectedLocation = location;
//       whereToController.text = name;
//     });

//     // Optional: resolve and display readable address
//     final resolvedAddress = await _getAddressFromLatLng(location);
//     String? _destinationName;
//     setState(() {
//       // You can store the destination name/address here
//       _destinationName = resolvedAddress; // Add this variable if needed
//       //_selectedLocation = resolvedAddress;
//     });

//     _mapController.move(location, 15);
//   }

//   // void _onSuggestionTap(LatLng location, String name) {
//   //   setState(() {
//   //     _selectedLocation = location;
//   //     whereToController.text = name;
//   //   });
//   //   _mapController.move(location, 15);
//   // }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//     } else {
//       _showError("Select a location first.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final predictedPlaces = ref.watch(whereToPredictedPlacesProvider);
//     final isLoading = ref.watch(whereToLoadingProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: whereToController,
//                   decoration: InputDecoration(
//                     hintText: "Search for destination...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (isLoading) const CircularProgressIndicator(),

//           if (predictedPlaces != null && predictedPlaces.isNotEmpty)
//             SizedBox(
//               height: 150,
//               child: ListView.builder(
//                 itemCount: predictedPlaces.length,
//                 itemBuilder: (context, index) {
//                   final place = predictedPlaces[index];
//                   final lat = double.tryParse(place.lat ?? "") ?? 0.0;
//                   final lon = double.tryParse(place.lon ?? "") ?? 0.0;
//                   return ListTile(
//                     title: Text(place.displayName ?? "Unnamed"),
//                     onTap:
//                         () => _onSuggestionTap(
//                           LatLng(lat, lon),
//                           place.displayName ?? "Unnamed",
//                         ),
//                   );
//                 },
//               ),
//             ),

//           Expanded(
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 center: _pickupLocation ?? LatLng(-1.2921, 36.8219),
//                 zoom: 15,
//                 onTap: (tapPos, latLng) async {
//                   setState(() {
//                     _selectedLocation = latLng;
//                   });
//                   final address = await _getAddressFromLatLng(latLng);
//                   whereToController.text = address;
//                 },
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   subdomains: ['a', 'b', 'c'],
//                   userAgentPackageName: 'com.example.niceapp',
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     if (_pickupLocation != null)
//                       Marker(
//                         point: _pickupLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.location_pin,
//                               color: Colors.blue,
//                               size: 35,
//                             ),
//                       ),
//                     if (_selectedLocation != null)
//                       Marker(
//                         point: _selectedLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.flag,
//                               color: Colors.red,
//                               size: 35,
//                             ),
//                       ),
//                     for (int i = 0; i < _stops.length; i++)
//                       Marker(
//                         point: _stops[i],
//                         builder:
//                             (_) => const Icon(
//                               Icons.place,
//                               color: Colors.orange,
//                               size: 30,
//                             ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           if (_stops.isNotEmpty)
//             Container(
//               height: 130,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:http/http.dart' as http;

// class WhereToScreen extends StatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   State<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends State<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();
//   final List<LatLng> _stops = [];

//   LatLng? _pickupLocation;
//   LatLng? _selectedLocation;

//   final MapController _mapController = MapController();
//   List<Map<String, dynamic>> _suggestions = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializePickupLocation();
//     whereToController.addListener(_onDestinationInputChanged);
//   }

//   @override
//   void dispose() {
//     pickupLocationController.dispose();
//     whereToController.removeListener(_onDestinationInputChanged);
//     whereToController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializePickupLocation() async {
//     try {
//       final permission = await _checkAndRequestLocationPermission();
//       if (!permission) return;

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       final pickup = LatLng(position.latitude, position.longitude);
//       _pickupLocation = pickup;
//       final address = await _getAddressFromLatLng(pickup);

//       setState(() {
//         pickupLocationController.text = address;
//       });

//       _mapController.move(pickup, 15);
//     } catch (e) {
//       _showError("Failed to get location: $e");
//     }
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(LatLng location) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         return "${place.subLocality ?? "Unnamed"}, ${place.locality ?? ''}, ${place.country ?? ''}";
//       }
//     } catch (_) {}
//     return "Unnamed Location";
//   }

//   void _onDestinationInputChanged() async {
//     final query = whereToController.text.trim();
//     if (query.isEmpty) return;

//     setState(() {
//       _isLoading = true;
//       _suggestions.clear();
//     });

//     final url =
//         'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'User-Agent': 'FlutterApp', // Required by Nominatim
//       },
//     );

//     if (response.statusCode == 200) {
//       final List results = json.decode(response.body);
//       setState(() {
//         _suggestions = results.map((e) => e as Map<String, dynamic>).toList();
//         _isLoading = false;
//       });
//     } else {
//       _showError("Failed to fetch locations.");
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _onSuggestionTap(Map<String, dynamic> place) async {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final location = LatLng(lat, lon);
//     final address = await _getAddressFromLatLng(location);

//     setState(() {
//       _selectedLocation = location;
//       whereToController.text = address;
//       _suggestions.clear();
//     });

//     _mapController.move(location, 15);
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//     } else {
//       _showError("Select a location first.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: whereToController,
//                   decoration: InputDecoration(
//                     hintText: "Search for destination...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (_isLoading) const CircularProgressIndicator(),

//           if (_suggestions.isNotEmpty)
//             SizedBox(
//               height: 150,
//               child: ListView.builder(
//                 itemCount: _suggestions.length,
//                 itemBuilder: (context, index) {
//                   final place = _suggestions[index];
//                   return ListTile(
//                     title: Text(place['display_name']),
//                     onTap: () => _onSuggestionTap(place),
//                   );
//                 },
//               ),
//             ),

//           Expanded(
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 center: _pickupLocation ?? LatLng(-1.2921, 36.8219),
//                 zoom: 15,
//                 onTap: (tapPos, latLng) async {
//                   setState(() {
//                     _selectedLocation = latLng;
//                   });
//                   final address = await _getAddressFromLatLng(latLng);
//                   whereToController.text = address;
//                 },
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   subdomains: ['a', 'b', 'c'],
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     if (_pickupLocation != null)
//                       Marker(
//                         point: _pickupLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.location_pin,
//                               color: Colors.blue,
//                               size: 35,
//                             ),
//                       ),
//                     if (_selectedLocation != null)
//                       Marker(
//                         point: _selectedLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.flag,
//                               color: Colors.red,
//                               size: 35,
//                             ),
//                       ),
//                     for (int i = 0; i < _stops.length; i++)
//                       Marker(
//                         point: _stops[i],
//                         builder:
//                             (_) => const Icon(
//                               Icons.place,
//                               color: Colors.orange,
//                               size: 30,
//                             ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           if (_stops.isNotEmpty)
//             Container(
//               height: 130,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:http/http.dart' as http;

// class WhereToScreen extends StatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   State<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends State<WhereToScreen> {
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController whereToController = TextEditingController();

//   final MapController _mapController = MapController();

//   LatLng? _pickupLocation;
//   LatLng? _selectedLocation;

//   final List<LatLng> _stops = [];
//   List<Map<String, dynamic>> _suggestions = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializePickupLocation();
//     whereToController.addListener(_onDestinationInputChanged);
//   }

//   @override
//   void dispose() {
//     pickupLocationController.dispose();
//     whereToController.removeListener(_onDestinationInputChanged);
//     whereToController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializePickupLocation() async {
//     try {
//       final permissionGranted = await _checkAndRequestLocationPermission();
//       if (!permissionGranted) return;

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       final location = LatLng(position.latitude, position.longitude);
//       _pickupLocation = location;

//       final address = await _getAddressFromLatLng(location);

//       setState(() {
//         pickupLocationController.text = address;
//         _mapController.move(location, 15);
//       });
//     } catch (e) {
//       _showError("Failed to get location: $e");
//     }
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Location services are disabled.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permissions are denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permissions are permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(LatLng location) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(
//         location.latitude,
//         location.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         return "${place.subLocality ?? 'Unnamed'}, ${place.locality ?? ''}, ${place.country ?? ''}";
//       }
//     } catch (_) {}
//     return "Unnamed Location";
//   }

//   void _onDestinationInputChanged() async {
//     final query = whereToController.text.trim();
//     if (query.isEmpty) return;

//     setState(() {
//       _isLoading = true;
//       _suggestions.clear();
//     });

//     final url =
//         'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {'User-Agent': 'FlutterApp'},
//     );

//     if (response.statusCode == 200) {
//       final List data = json.decode(response.body);
//       setState(() {
//         _suggestions = data.cast<Map<String, dynamic>>();
//         _isLoading = false;
//       });
//     } else {
//       _showError("Failed to fetch location suggestions.");
//       setState(() => _isLoading = false);
//     }
//   }

//   void _onSuggestionTap(Map<String, dynamic> place) async {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final location = LatLng(lat, lon);
//     final address = await _getAddressFromLatLng(location);

//     setState(() {
//       _selectedLocation = location;
//       whereToController.text = address;
//       _suggestions.clear();
//     });

//     _mapController.move(location, 15);
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//     } else {
//       _showError("Select a destination first.");
//     }
//   }

//   void _removeStop(int index) {
//     setState(() {
//       _stops.removeAt(index);
//     });
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: pickupLocationController,
//                   readOnly: true,
//                   decoration: InputDecoration(
//                     labelText: "Pick Up Location",
//                     prefixIcon: const Icon(Icons.my_location),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: whereToController,
//                   decoration: InputDecoration(
//                     hintText: "Search destination...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (_isLoading) const CircularProgressIndicator(),

//           if (_suggestions.isNotEmpty)
//             SizedBox(
//               height: 150,
//               child: ListView.builder(
//                 itemCount: _suggestions.length,
//                 itemBuilder: (context, index) {
//                   final place = _suggestions[index];
//                   return ListTile(
//                     title: Text(place['display_name']),
//                     onTap: () => _onSuggestionTap(place),
//                   );
//                 },
//               ),
//             ),

//           Expanded(
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 center:
//                     _pickupLocation ??
//                     LatLng(-1.2921, 36.8219), // Default to Nairobi
//                 zoom: 15,
//                 onTap: (tapPosition, latLng) async {
//                   final address = await _getAddressFromLatLng(latLng);
//                   setState(() {
//                     _selectedLocation = latLng;
//                     whereToController.text = address;
//                   });
//                 },
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   subdomains: ['a', 'b', 'c'],
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     if (_pickupLocation != null)
//                       Marker(
//                         point: _pickupLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.location_pin,
//                               color: Colors.blue,
//                               size: 35,
//                             ),
//                       ),
//                     if (_selectedLocation != null)
//                       Marker(
//                         point: _selectedLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.flag,
//                               color: Colors.red,
//                               size: 35,
//                             ),
//                       ),
//                     for (int i = 0; i < _stops.length; i++)
//                       Marker(
//                         point: _stops[i],
//                         builder:
//                             (_) => const Icon(
//                               Icons.place,
//                               color: Colors.orange,
//                               size: 30,
//                             ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           if (_stops.isNotEmpty)
//             Container(
//               height: 120,
//               color: Colors.grey.shade100,
//               child: ListView.builder(
//                 itemCount: _stops.length,
//                 itemBuilder: (context, index) {
//                   final stop = _stops[index];
//                   return ListTile(
//                     title: Text(
//                       "Stop ${index + 1}: ${stop.latitude}, ${stop.longitude}",
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () => _removeStop(index),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:http/http.dart' as http;
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';

// class WhereToScreen extends StatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   State<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends State<WhereToScreen> {
//   final TextEditingController pickupController = TextEditingController();
//   final TextEditingController destinationController = TextEditingController();

//   final MapController _mapController = MapController();

//   LatLng? _pickupLocation;
//   LatLng? _selectedLocation;
//   bool _selectingPickup = false;

//   final List<LatLng> _stops = [];
//   List<Map<String, dynamic>> _suggestions = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializePickup();
//     destinationController.addListener(_onSearchChanged);
//     pickupController.addListener(_onSearchChanged);
//   }

//   Future<void> _initializePickup() async {
//     final permission = await _checkAndRequestLocationPermission();
//     if (!permission) return;

//     final pos = await Geolocator.getCurrentPosition();
//     final latLng = LatLng(pos.latitude, pos.longitude);
//     _pickupLocation = latLng;

//     final address = await _getAddressFromLatLng(latLng);
//     setState(() {
//       pickupController.text = address;
//       _mapController.move(latLng, 15);
//     });
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Enable location services.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permission denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permission permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(LatLng latLng) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(
//         latLng.latitude,
//         latLng.longitude,
//       );
//       final place = placemarks.first;
//       return "${place.name ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
//     } catch (e) {
//       return "Unnamed Location";
//     }
//   }

//   void _onSearchChanged() {
//     final text =
//         _selectingPickup ? pickupController.text : destinationController.text;
//     if (text.trim().isEmpty) return;
//     _fetchSuggestions(text);
//   }

//   Future<void> _fetchSuggestions(String query) async {
//     setState(() {
//       _isLoading = true;
//       _suggestions.clear();
//     });

//     final url = Uri.parse(
//       "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
//     );
//     final res = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       setState(() {
//         _suggestions = data.cast<Map<String, dynamic>>();
//         _isLoading = false;
//       });
//     } else {
//       _showError("Suggestion fetch failed");
//     }
//   }

//   void _onSuggestionTap(Map<String, dynamic> place) async {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final latLng = LatLng(lat, lon);
//     final address = await _getAddressFromLatLng(latLng);

//     setState(() {
//       if (_selectingPickup) {
//         _pickupLocation = latLng;
//         pickupController.text = address;
//       } else {
//         _selectedLocation = latLng;
//         destinationController.text = address;
//       }
//       _suggestions.clear();
//     });

//     _mapController.move(latLng, 15);
//   }

//   void _addStop() {
//     if (_selectedLocation != null) {
//       setState(() {
//         _stops.add(_selectedLocation!);
//       });
//       _showMessage("Stop added.");
//     } else {
//       _showError("Select destination first.");
//     }
//   }

//   void _confirmRouteAndGoToHome() {
//     if (_pickupLocation == null || _selectedLocation == null) {
//       _showError("Please select both pickup and destination.");
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const HomeScreen(),
//       ), // Replace with your actual screen
//     );
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }

//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectingPickup = true;
//                       _suggestions.clear();
//                     });
//                   },
//                   child: TextField(
//                     controller: pickupController,
//                     decoration: const InputDecoration(
//                       labelText: "Pickup Location",
//                       prefixIcon: Icon(Icons.my_location),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectingPickup = false;
//                       _suggestions.clear();
//                     });
//                   },
//                   child: TextField(
//                     controller: destinationController,
//                     decoration: const InputDecoration(
//                       labelText: "Where To?",
//                       prefixIcon: Icon(Icons.location_on),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton.icon(
//                   onPressed: _addStop,
//                   icon: const Icon(Icons.add_location_alt),
//                   label: const Text("Add Stop"),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _confirmRouteAndGoToHome,
//                   icon: const Icon(Icons.check_circle),
//                   label: const Text("Confirm & Go"),
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//                 ),
//               ],
//             ),
//           ),
//           if (_isLoading) const CircularProgressIndicator(),
//           if (_suggestions.isNotEmpty)
//             SizedBox(
//               height: 150,
//               child: ListView.builder(
//                 itemCount: _suggestions.length,
//                 itemBuilder: (_, index) {
//                   final place = _suggestions[index];
//                   return ListTile(
//                     title: Text(place['display_name']),
//                     onTap: () => _onSuggestionTap(place),
//                   );
//                 },
//               ),
//             ),
//           Expanded(
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 center: _pickupLocation ?? LatLng(-1.2921, 36.8219),
//                 zoom: 15,
//               ),
//               children: [
//                 // TileLayer(
//                 //   urlTemplate:
//                 //       "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//                 //   subdomains: ['a', 'b', 'c'],
//                 // ),
//                 MarkerLayer(
//                   markers: [
//                     if (_pickupLocation != null)
//                       Marker(
//                         point: _pickupLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.circle,
//                               color: Colors.green,
//                               size: 30,
//                             ),
//                       ),
//                     if (_selectedLocation != null)
//                       Marker(
//                         point: _selectedLocation!,
//                         builder:
//                             (_) => const Icon(
//                               Icons.location_pin,
//                               color: Colors.red,
//                               size: 35,
//                             ),
//                       ),
//                     for (var stop in _stops)
//                       Marker(
//                         point: stop,
//                         builder:
//                             (_) => const Icon(
//                               Icons.place,
//                               color: Colors.orange,
//                               size: 30,
//                             ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // // Dummy HomeScreen for navigation example
// // class HomeScreen extends StatelessWidget {
// //   const HomeScreen({super.key});
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Home')),
// //       body: const Center(child: Text('Welcome Home!')),
// //     );
// //   }
// // }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:http/http.dart' as http;
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';

// class WhereToScreen extends StatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   State<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends State<WhereToScreen> {
//   final TextEditingController pickupController = TextEditingController();
//   final TextEditingController destinationController = TextEditingController();

//   bool _selectingPickup = false;
//   List<Map<String, dynamic>> _suggestions = [];
//   bool _isLoading = false;
//   final List<String> _stops = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializePickup();
//     pickupController.addListener(_onSearchChanged);
//     destinationController.addListener(_onSearchChanged);
//   }

//   Future<void> _initializePickup() async {
//     final permission = await _checkAndRequestLocationPermission();
//     if (!permission) return;

//     final pos = await Geolocator.getCurrentPosition();
//     final address = await _getAddressFromLatLng(pos.latitude, pos.longitude);
//     setState(() {
//       pickupController.text = address;
//     });
//   }

//   Future<bool> _checkAndRequestLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showError("Enable location services.");
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showError("Location permission denied.");
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showError("Location permission permanently denied.");
//       return false;
//     }

//     return true;
//   }

//   Future<String> _getAddressFromLatLng(double lat, double lon) async {
//     try {
//       final placemarks = await geocoding.placemarkFromCoordinates(lat, lon);
//       final place = placemarks.first;
//       return "${place.name ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
//     } catch (_) {
//       return "Unnamed Location";
//     }
//   }

//   void _onSearchChanged() {
//     final text =
//         _selectingPickup ? pickupController.text : destinationController.text;
//     if (text.trim().isEmpty) return;
//     _fetchSuggestions(text);
//   }

//   Future<void> _fetchSuggestions(String query) async {
//     setState(() {
//       _isLoading = true;
//       _suggestions.clear();
//     });

//     final url = Uri.parse(
//       "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
//     );
//     final res = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       setState(() {
//         _suggestions = data.cast<Map<String, dynamic>>();
//         _isLoading = false;
//       });
//     } else {
//       _showError("Suggestion fetch failed");
//     }
//   }

//   void _onSuggestionTap(Map<String, dynamic> place) async {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final address = await _getAddressFromLatLng(lat, lon);

//     setState(() {
//       if (_selectingPickup) {
//         pickupController.text = address;
//       } else {
//         destinationController.text = address;
//       }
//       _suggestions.clear();
//     });
//   }

//   void _addStop() {
//     final stop = destinationController.text.trim();
//     if (stop.isNotEmpty) {
//       setState(() {
//         _stops.add(stop);
//       });
//       _showMessage("Stop added: $stop");
//     } else {
//       _showError("Please enter destination first.");
//     }
//   }

//   void _confirmRouteAndGoToHome() {
//     if (pickupController.text.isEmpty || destinationController.text.isEmpty) {
//       _showError("Select both pickup and destination.");
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//     );
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }

//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Where To?"),
//         backgroundColor: Colors.blue,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             children: [
//               TextField(
//                 controller: pickupController,
//                 onTap: () {
//                   setState(() {
//                     _selectingPickup = true;
//                     _suggestions.clear();
//                   });
//                 },
//                 decoration: const InputDecoration(
//                   labelText: "Pickup Location",
//                   prefixIcon: Icon(Icons.my_location),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: destinationController,
//                 onTap: () {
//                   setState(() {
//                     _selectingPickup = false;
//                     _suggestions.clear();
//                   });
//                 },
//                 decoration: const InputDecoration(
//                   labelText: "Where To?",
//                   prefixIcon: Icon(Icons.location_on),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton.icon(
//                 onPressed: _addStop,
//                 icon: const Icon(Icons.add_location_alt),
//                 label: const Text("Add Stop"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _confirmRouteAndGoToHome,
//                 icon: const Icon(Icons.check_circle),
//                 label: const Text("Confirm & Go"),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//               ),
//               if (_isLoading)
//                 const Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: CircularProgressIndicator(),
//                 ),
//               if (_suggestions.isNotEmpty)
//                 ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _suggestions.length,
//                   itemBuilder: (_, index) {
//                     final place = _suggestions[index];
//                     return ListTile(
//                       title: Text(place['display_name']),
//                       onTap: () => _onSuggestionTap(place),
//                     );
//                   },
//                 ),
//               if (_stops.isNotEmpty)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Stops Added:"),
//                     for (var stop in _stops) ListTile(title: Text(stop)),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

class WhereToScreen extends ConsumerStatefulWidget {
  const WhereToScreen({super.key});

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _selectingPickup = false;

  // Note: remove MapController and map code since you said no map display

  @override
  void initState() {
    super.initState();
    // Initialize pickupController text from global state if any
    final pickup = ref.read(pickupLocationProvider);
    if (pickup != null) {
      pickupController.text =
          "Pickup location set"; // Or fetch address string from your own state if saved
    }

    pickupController.addListener(_onSearchChanged);
    destinationController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text =
        _selectingPickup ? pickupController.text : destinationController.text;
    if (text.trim().isEmpty) return;
    _fetchSuggestions(text);
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoading = true;
      _suggestions.clear();
    });

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
    );
    final res = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() {
        _suggestions = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      _showError("Suggestion fetch failed");
    }
  }

  void _onSuggestionTap(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final latLng = LatLng(lat, lon);

    setState(() {
      if (_selectingPickup) {
        // Update global state pickup location
        ref.read(pickupLocationProvider.notifier).state = latLng;
        pickupController.text = place['display_name'];
      } else {
        // Update global state destination location
        ref.read(destinationLocationProvider.notifier).state = latLng;
        destinationController.text = place['display_name'];
      }
      _suggestions.clear();
    });
  }

  void _addStop() {
    final destination = ref.read(destinationLocationProvider);
    if (destination == null) {
      _showError("Select destination first.");
      return;
    }
    final stops = ref.read(stopsProvider);
    if (!stops.contains(destination)) {
      ref.read(stopsProvider.notifier).state = [...stops, destination];
      _showMessage("Stop added.");
    } else {
      _showError("This stop is already added.");
    }
  }

  // void _confirmRouteAndGoToHome() {
  //   final pickup = ref.read(pickupLocationProvider);
  //   final destination = ref.read(destinationLocationProvider);

  //   if (pickup == null || destination == null) {
  //     _showError("Please select both pickup and destination.");
  //     return;
  //   }

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const HomeScreen()),
  //   );
  // }

  void _confirmRouteAndGoToHome() {
    final pickup = ref.read(pickupLocationProvider);
    final destination = ref.read(destinationLocationProvider);

    if (pickup == null || destination == null) {
      _showError("Please select both pickup and destination.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(pickup: pickup, destination: destination),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final stops = ref.watch(stopsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Where To?")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                labelText: "Pickup Location",
                prefixIcon: Icon(Icons.my_location),
              ),
              onTap: () {
                setState(() {
                  _selectingPickup = true;
                  _suggestions.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                labelText: "Where To?",
                prefixIcon: Icon(Icons.location_on),
              ),
              onTap: () {
                setState(() {
                  _selectingPickup = false;
                  _suggestions.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt),
              label: const Text("Add Stop"),
            ),
            ElevatedButton.icon(
              onPressed: _confirmRouteAndGoToHome,
              icon: const Icon(Icons.check_circle),
              label: const Text("Confirm & Go"),
            ),
            if (_isLoading) const CircularProgressIndicator(),
            if (_suggestions.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (_, index) {
                    final place = _suggestions[index];
                    return ListTile(
                      title: Text(place['display_name']),
                      onTap: () => _onSuggestionTap(place),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: stops.length,
                itemBuilder: (_, index) {
                  final stop = stops[index];
                  return ListTile(
                    leading: const Icon(Icons.place, color: Colors.orange),
                    title: Text(
                      'Stop #${index + 1}: ${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
