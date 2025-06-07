// // import 'package:flutter/material.dart';

// // class RideBookingScreen extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Confirm Ride')),
// //       body: Center(child: Text('Ride Booking Details Placeholder')),
// //     );
// //   }
// // }
// // import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:geolocator/geolocator.dart';

// // class RideBookingScreen extends StatefulWidget {
// //   @override
// //   _RideBookingScreenState createState() => _RideBookingScreenState();
// // }

// // class _RideBookingScreenState extends State<RideBookingScreen> {
// //   late GoogleMapController _mapController;
// //   LatLng? _currentLocation;
// //   LatLng? _destination;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _getCurrentLocation();
// //   }

// //   // Get user's current location
// //   Future<void> _getCurrentLocation() async {
// //     bool serviceEnabled;
// //     LocationPermission permission;

// //     // Check if location services are enabled
// //     serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     if (!serviceEnabled) {
// //       return;
// //     }

// //     // Request location permissions
// //     permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       if (permission == LocationPermission.denied) {
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       return;
// //     }

// //     // Get current position
// //     Position position = await Geolocator.getCurrentPosition();
// //     setState(() {
// //       _currentLocation = LatLng(position.latitude, position.longitude);
// //     });
// //   }

// //   // Handle map taps to set the destination
// //   void _onMapTapped(LatLng position) {
// //     setState(() {
// //       _destination = position;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Confirm Ride')),
// //       body: _currentLocation == null
// //           ? Center(child: CircularProgressIndicator())
// //           : Column(
// //               children: [
// //                 Expanded(
// //                   child: GoogleMap(
// //                     initialCameraPosition: CameraPosition(
// //                       target: _currentLocation!,
// //                       zoom: 14,
// //                     ),
// //                     myLocationEnabled: true,
// //                     myLocationButtonEnabled: true,
// //                     markers: {
// //                       if (_currentLocation != null)
// //                         Marker(
// //                           markerId: MarkerId("currentLocation"),
// //                           position: _currentLocation!,
// //                           infoWindow: InfoWindow(title: "Your Location"),
// //                         ),
// //                       if (_destination != null)
// //                         Marker(
// //                           markerId: MarkerId("destination"),
// //                           position: _destination!,
// //                           infoWindow: InfoWindow(title: "Destination"),
// //                         ),
// //                     },
// //                     onTap: _onMapTapped, // Set destination on tap
// //                     onMapCreated: (GoogleMapController controller) {
// //                       _mapController = controller;
// //                     },
// //                   ),
// //                 ),
// //                 if (_destination != null)
// //                   Padding(
// //                     padding: const EdgeInsets.all(16.0),
// //                     child: ElevatedButton(
// //                       onPressed: () {
// //                         // TODO: Implement ride request logic
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           SnackBar(content: Text("Ride Confirmed!")),
// //                         );
// //                       },
// //                       child: Text("Confirm Ride"),
// //                     ),
// //                   ),
// //               ],
// //             ),
// //     );
// //   }
// // }
// // import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:geolocator/geolocator.dart';

// // class RideBookingScreen extends StatefulWidget {
// //   @override
// //   _RideBookingScreenState createState() => _RideBookingScreenState();
// // }

// // class _RideBookingScreenState extends State<RideBookingScreen> {
// //   late GoogleMapController _mapController;
// //   LatLng? _pickupLocation;
// //   LatLng? _destination;
// //   double? _estimatedPrice;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _getCurrentLocation();
// //   }

// //   // Get user's current location
// //   Future<void> _getCurrentLocation() async {
// //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     if (!serviceEnabled) {
// //       return;
// //     }

// //     LocationPermission permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       if (permission == LocationPermission.denied) {
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       return;
// //     }

// //     // Get current position
// //     Position position = await Geolocator.getCurrentPosition();
// //     setState(() {
// //       _pickupLocation = LatLng(position.latitude, position.longitude);
// //     });
// //   }

// //   // Handle map taps to set the destination
// //   void _onMapTapped(LatLng position) {
// //     setState(() {
// //       _destination = position;
// //       _calculateEstimatedPrice();
// //     });
// //   }

// //   // Dummy function to calculate price based on distance
// //   void _calculateEstimatedPrice() {
// //     if (_pickupLocation != null && _destination != null) {
// //       double distance = Geolocator.distanceBetween(
// //         _pickupLocation!.latitude,
// //         _pickupLocation!.longitude,
// //         _destination!.latitude,
// //         _destination!.longitude,
// //       );

// //       // Estimate price as Ksh 100 per km (adjust this logic as needed)
// //       _estimatedPrice = (distance / 1000) * 100;
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Confirm Ride')),
// //       body: _pickupLocation == null
// //           ? Center(child: CircularProgressIndicator())
// //           : Column(
// //               children: [
// //                 Expanded(
// //                   child: GoogleMap(
// //                     initialCameraPosition: CameraPosition(
// //                       target: _pickupLocation!,
// //                       zoom: 14,
// //                     ),
// //                     myLocationEnabled: true,
// //                     myLocationButtonEnabled: true,
// //                     markers: {
// //                       if (_pickupLocation != null)
// //                         Marker(
// //                           markerId: MarkerId("pickupLocation"),
// //                           position: _pickupLocation!,
// //                           infoWindow: InfoWindow(title: "Pickup Location"),
// //                         ),
// //                       if (_destination != null)
// //                         Marker(
// //                           markerId: MarkerId("destination"),
// //                           position: _destination!,
// //                           infoWindow: InfoWindow(title: "Destination"),
// //                         ),
// //                     },
// //                     onTap: _onMapTapped, // Set destination on tap
// //                     onMapCreated: (GoogleMapController controller) {
// //                       _mapController = controller;
// //                     },
// //                   ),
// //                 ),
// //                 if (_destination != null)
// //                   Padding(
// //                     padding: const EdgeInsets.all(16.0),
// //                     child: Column(
// //                       children: [
// //                         Text(
// //                           "Pickup: ${_pickupLocation?.latitude.toStringAsFixed(4)}, ${_pickupLocation?.longitude.toStringAsFixed(4)}",
// //                           style: TextStyle(fontSize: 16),
// //                         ),
// //                         Text(
// //                           "Destination: ${_destination?.latitude.toStringAsFixed(4)}, ${_destination?.longitude.toStringAsFixed(4)}",
// //                           style: TextStyle(fontSize: 16),
// //                         ),
// //                         Text(
// //                           "Estimated Price: Ksh ${_estimatedPrice?.toStringAsFixed(2)}",
// //                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                         ),
// //                         SizedBox(height: 10),
// //                         ElevatedButton(
// //                           onPressed: () {
// //                             ScaffoldMessenger.of(context).showSnackBar(
// //                               SnackBar(content: Text("Ride Confirmed!")),
// //                             );
// //                           },
// //                           child: Text("Confirm Ride"),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //               ],
// //             ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:async';

// class RideBookingScreen extends StatefulWidget {
//   @override
//   _RideBookingScreenState createState() => _RideBookingScreenState();
// }

// class _RideBookingScreenState extends State<RideBookingScreen> {
//   late GoogleMapController _mapController;
//   LatLng? _pickupLocation;
//   LatLng? _destination;
//   double? _estimatedPrice;
//   String _rideStatus = "Select Destination";
//   String _selectedRideType = "Economy";
//   final List<String> _rideOptions = ["Economy", "Comfort", "XL"];
//   bool _searchingDriver = false;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return;
//     }

//     if (permission == LocationPermission.deniedForever) return;

//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       _pickupLocation = LatLng(position.latitude, position.longitude);
//     });
//   }

//   void _onMapTapped(LatLng position) {
//     setState(() {
//       _destination = position;
//       _calculateEstimatedPrice();
//       _rideStatus = "Confirm Ride";
//     });
//   }

//   void _calculateEstimatedPrice() {
//     if (_pickupLocation != null && _destination != null) {
//       double distance = Geolocator.distanceBetween(
//         _pickupLocation!.latitude,
//         _pickupLocation!.longitude,
//         _destination!.latitude,
//         _destination!.longitude,
//       );
//       double baseFare = _selectedRideType == "Economy" ? 100 : _selectedRideType == "Comfort" ? 150 : 200;
//       _estimatedPrice = (distance / 1000) * baseFare;
//     }
//   }

//   void _requestRide() {
//     setState(() {
//       _rideStatus = "Searching for a driver...";
//       _searchingDriver = true;
//     });

//     Future.delayed(Duration(seconds: 5), () {
//       setState(() {
//         _rideStatus = "Driver Assigned: John Doe, Toyota Prius, KDB 123A";
//         _searchingDriver = false;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Book a Ride')),
//       body: _pickupLocation == null
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: GoogleMap(
//                     initialCameraPosition: CameraPosition(
//                       target: _pickupLocation!,
//                       zoom: 14,
//                     ),
//                     myLocationEnabled: true,
//                     myLocationButtonEnabled: true,
//                     markers: {
//                       if (_pickupLocation != null)
//                         Marker(
//                           markerId: MarkerId("pickup"),
//                           position: _pickupLocation!,
//                           infoWindow: InfoWindow(title: "Pickup Location"),
//                         ),
//                       if (_destination != null)
//                         Marker(
//                           markerId: MarkerId("destination"),
//                           position: _destination!,
//                           infoWindow: InfoWindow(title: "Destination"),
//                         ),
//                     },
//                     onTap: _onMapTapped,
//                     onMapCreated: (controller) => _mapController = controller,
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Status: $_rideStatus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       if (_destination != null) ...[
//                         SizedBox(height: 10),
//                         DropdownButton<String>(
//                           value: _selectedRideType,
//                           onChanged: (value) {
//                             setState(() {
//                               _selectedRideType = value!;
//                               _calculateEstimatedPrice();
//                             });
//                           },
//                           items: _rideOptions.map((option) {
//                             return DropdownMenuItem(
//                               value: option,
//                               child: Text(option),
//                             );
//                           }).toList(),
//                         ),
//                         SizedBox(height: 10),
//                         Text("Estimated Fare: Ksh ${_estimatedPrice?.toStringAsFixed(2) ?? '0.00'}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         SizedBox(height: 10),
//                         _searchingDriver
//                             ? CircularProgressIndicator()
//                             : ElevatedButton(
//                                 onPressed: _requestRide,
//                                 child: Text("Request Ride"),
//                               ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }
