// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

// class RideInProgressScreen extends ConsumerStatefulWidget {
//   final LatLng driverStart;
//   final LatLng pickup;

//   const RideInProgressScreen({
//     super.key,
//     required this.driverStart,
//     required this.pickup,
//   });

//   @override
//   ConsumerState<RideInProgressScreen> createState() =>
//       _RideInProgressScreenState();
// }

// class _RideInProgressScreenState extends ConsumerState<RideInProgressScreen> {
//   GoogleMapController? mapController;
//   StreamSubscription<LatLng>? movementSub;

//   Stream<LatLng> simulateDriverMovement({
//     required LatLng from,
//     required LatLng to,
//     int steps = 20,
//     Duration interval = const Duration(seconds: 2),
//   }) async* {
//     double latStep = (to.latitude - from.latitude) / steps;
//     double lngStep = (to.longitude - from.longitude) / steps;

//     for (int i = 0; i <= steps; i++) {
//       yield LatLng(
//         from.latitude + (i * latStep),
//         from.longitude + (i * lngStep),
//       );
//       await Future.delayed(interval);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     movementSub = simulateDriverMovement(
//       from: widget.driverStart,
//       to: widget.pickup,
//     ).listen((position) {
//       ref.read(driverPositionProvider.notifier).state = position;

//       // Move camera to follow driver
//       mapController?.animateCamera(CameraUpdate.newLatLng(position));
//     });
//   }

//   @override
//   void dispose() {
//     movementSub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final driverPosition = ref.watch(driverPositionProvider);

//     Set<Marker> markers = {
//       Marker(
//         markerId: const MarkerId('pickup'),
//         position: widget.pickup,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//       ),
//     };

//     if (driverPosition != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('driver'),
//           position: driverPosition,
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueGreen,
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text("Driver En Route")),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: widget.pickup,
//           zoom: 14.0,
//         ),
//         markers: markers,
//         onMapCreated: (GoogleMapController controller) {
//           mapController = controller;
//         },
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';

// // TODO: replace with your key import or constant
// // import 'package:yourapp/utils/keys.dart';
// const String googleMapsKey = mapKey;

// class RideInProgressLiveScreen extends StatefulWidget {
//   final int rideId;
//   final String driverId;
//   final LatLng pickup;
//   final LatLng destination;
//   final double? baseFare; // e.g., 100
//   final double? perKmFare; // e.g., 50

//   const RideInProgressLiveScreen({
//     super.key,
//     required this.rideId,
//     required this.driverId,
//     required this.pickup,
//     required this.destination,
//     this.baseFare,
//     this.perKmFare,
//   });

//   @override
//   State<RideInProgressLiveScreen> createState() =>
//       _RideInProgressLiveScreenState();
// }

// class _RideInProgressLiveScreenState extends State<RideInProgressLiveScreen> {
//   final _db = FirebaseDatabase.instance;
//   DatabaseReference? _driverLocRef;
//   DatabaseReference? _rideRef;

//   GoogleMapController? _mapController;
//   Marker? _driverMarker;
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};
//   List<LatLng> _fullRoute = []; // full route polyline from Directions API

//   LatLng? _driverLocation;
//   LatLng? _lastDriverLocation; // for segment distance calc
//   double _distanceTraveledKm = 0;

//   int _etaMinutes = 0;
//   double _remainingKm = 0;

//   bool _ending = false;
//   bool _ended = false;
//   double? _finalFare;

//   StreamSubscription<DatabaseEvent>? _driverSub;

//   @override
//   void initState() {
//     super.initState();
//     //  _rideRef = _db.ref('rides/${widget.rideId}');
//     _driverLocRef = _db.ref('drivers/${widget.driverId}/location');

//     _initMarkers();
//     _subscribeDriverLocation();
//   }

//   @override
//   void dispose() {
//     _driverSub?.cancel();
//     super.dispose();
//   }

//   void _initMarkers() {
//     _markers = {
//       Marker(
//         markerId: const MarkerId('pickup'),
//         position: widget.pickup,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         infoWindow: const InfoWindow(title: 'Pickup'),
//       ),
//       Marker(
//         markerId: const MarkerId('destination'),
//         position: widget.destination,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         infoWindow: const InfoWindow(title: 'Destination'),
//       ),
//     };
//   }

//   void _subscribeDriverLocation() {
//     _driverSub = _driverLocRef!.onValue.listen((event) async {
//       final data = event.snapshot.value;
//       if (data == null || data is! Map) return;

//       final latVal = data['lat'];
//       final lngVal = data['lng'];
//       if (latVal == null || lngVal == null) return;

//       final lat = double.tryParse(latVal.toString());
//       final lng = double.tryParse(lngVal.toString());
//       if (lat == null || lng == null) return;

//       final newPos = LatLng(lat, lng);

//       // update distance traveled (segment from last to new)
//       if (_driverLocation != null) {
//         _distanceTraveledKm += _haversineKm(_driverLocation!, newPos);
//       }
//       _lastDriverLocation = _driverLocation;
//       _driverLocation = newPos;

//       _updateDriverMarkerAnimated(_lastDriverLocation ?? newPos, newPos);

//       // re-fetch route & ETA from current driver position to destination
//       _fetchRouteAndEta(newPos, widget.destination);

//       // keep both markers visible when we get first location
//       if (_mapController != null) {
//         _fitBoundsToDriverAndDestination();
//       }
//     });
//   }

//   // Smoothly move driver marker from `from` to `to`
//   Future<void> _updateDriverMarkerAnimated(LatLng from, LatLng to) async {
//     const steps = 20;
//     final latStep = (to.latitude - from.latitude) / steps;
//     final lngStep = (to.longitude - from.longitude) / steps;

//     for (int i = 1; i <= steps; i++) {
//       final pos = LatLng(
//         from.latitude + latStep * i,
//         from.longitude + lngStep * i,
//       );

//       _driverMarker =
//           (_driverMarker == null)
//               ? Marker(
//                 markerId: const MarkerId('driver'),
//                 position: pos,
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueAzure,
//                 ),
//                 infoWindow: const InfoWindow(title: 'Driver'),
//               )
//               : _driverMarker!.copyWith(positionParam: pos);

//       setState(() {
//         _markers = {
//           ..._markers.where((m) => m.markerId.value != 'driver'),
//           _driverMarker!,
//         };
//       });

//       await Future.delayed(const Duration(milliseconds: 30));
//     }

//     // Optionally keep camera following
//     _mapController?.animateCamera(CameraUpdate.newLatLng(to));
//   }

//   Future<void> _fetchRouteAndEta(LatLng origin, LatLng dest) async {
//     final url =
//         'https://maps.googleapis.com/maps/api/directions/json'
//         '?origin=${origin.latitude},${origin.longitude}'
//         '&destination=${dest.latitude},${dest.longitude}'
//         '&key=$googleMapsKey';

//     try {
//       final res = await http.get(Uri.parse(url));
//       if (res.statusCode != 200) return;
//       final json = jsonDecode(res.body);

//       if ((json['routes'] as List).isEmpty) return;
//       final route = json['routes'][0];
//       final leg = (route['legs'] as List).first;

//       final points = route['overview_polyline']['points'];
//       final decoded = _decodePolyline(points);

//       setState(() {
//         _fullRoute = decoded;
//         _remainingKm = (leg['distance']['value'] as num).toDouble() / 1000.0;
//         _etaMinutes =
//             ((leg['duration']['value'] as num).toDouble() / 60.0).round();

//         _polylines = {
//           Polyline(
//             polylineId: const PolylineId('live-route'),
//             width: 5,
//             color: Colors.blue,
//             points: _remainingRouteFromCurrent(decoded, origin),
//           ),
//         };
//       });
//     } catch (_) {}
//   }

//   // Keep only remaining portion of the polyline ahead of current driver position
//   List<LatLng> _remainingRouteFromCurrent(List<LatLng> full, LatLng cur) {
//     if (full.isEmpty) return [];
//     // Find nearest index in the full route to current position
//     int bestIdx = 0;
//     double bestDist = double.infinity;
//     for (int i = 0; i < full.length; i++) {
//       final d = _haversineKm(full[i], cur);
//       if (d < bestDist) {
//         bestDist = d;
//         bestIdx = i;
//       }
//     }
//     return full.sublist(bestIdx);
//     // You could also prepend current position to make the line start exactly at the marker:
//     // return [cur, ...full.sublist(bestIdx)];
//   }

//   // End trip, compute fare, persist, and show
//   Future<void> _endTrip() async {
//     if (_ending) return;
//     _ending = true;

//     // Add the last small segment (if any) to destination
//     if (_driverLocation != null) {
//       _distanceTraveledKm += _haversineKm(_driverLocation!, widget.destination);
//     }

//     final fare = _computeFare(
//       _distanceTraveledKm,
//       base: widget.baseFare,
//       perKm: widget.perKmFare,
//     );

//     // Persist to DB (you can adapt fields to your backend)
//     await _rideRef!.update({
//       'status': 'completed',
//       'distanceKm': double.parse(_distanceTraveledKm.toStringAsFixed(3)),
//       'fare': double.parse(fare.toStringAsFixed(2)),
//       'endedAt': ServerValue.timestamp,
//     });

//     setState(() {
//       _ended = true;
//       _finalFare = fare;
//     });

//     _ending = false;
//   }

//   double _computeFare(
//     double traveledKm, {
//     required double base,
//     required double perKm,
//   }) {
//     return base + max(0, traveledKm) * perKm;
//   }

//   // --- Map helpers ---

//   void _fitBoundsToDriverAndDestination() {
//     if (_driverLocation == null) return;
//     final sw = LatLng(
//       min(_driverLocation!.latitude, widget.destination.latitude),
//       min(_driverLocation!.longitude, widget.destination.longitude),
//     );
//     final ne = LatLng(
//       max(_driverLocation!.latitude, widget.destination.latitude),
//       max(_driverLocation!.longitude, widget.destination.longitude),
//     );
//     _mapController!.animateCamera(
//       CameraUpdate.newLatLngBounds(
//         LatLngBounds(southwest: sw, northeast: ne),
//         80, // padding
//       ),
//     );
//   }

//   // Polyline decoder
//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> points = [];
//     int index = 0, lat = 0, lng = 0;

//     while (index < encoded.length) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dlng;

//       points.add(LatLng(lat / 1e5, lng / 1e5));
//     }
//     return points;
//   }

//   // Haversine distance in KM
//   double _haversineKm(LatLng a, LatLng b) {
//     const R = 6371.0;
//     final dLat = _degToRad(b.latitude - a.latitude);
//     final dLng = _degToRad(b.longitude - a.longitude);
//     final s1 = sin(dLat / 2);
//     final s2 = sin(dLng / 2);
//     final aa =
//         s1 * s1 +
//         cos(_degToRad(a.latitude)) * cos(_degToRad(b.latitude)) * s2 * s2;
//     return R * 2 * atan2(sqrt(aa), sqrt(1 - aa));
//   }

//   double _degToRad(double d) => d * pi / 180.0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_ended ? 'Trip Completed' : 'Ride In Progress'),
//         actions: [
//           if (!_ended)
//             TextButton(
//               onPressed: _endTrip,
//               child: const Text(
//                 'End Trip',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: widget.pickup,
//               zoom: 14,
//             ),
//             onMapCreated: (c) => _mapController = c,
//             markers: _markers,
//             polylines: _polylines,
//             myLocationButtonEnabled: false,
//             myLocationEnabled: false,
//             compassEnabled: true,
//           ),

//           // Top Info Card
//           Positioned(
//             top: 12,
//             left: 12,
//             right: 12,
//             child: Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.local_taxi, size: 28),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _ended
//                                 ? 'Trip Completed'
//                                 : 'En route to destination',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           if (!_ended)
//                             Text(
//                               'ETA: $_etaMinutes min • ${_remainingKm.toStringAsFixed(1)} km',
//                             ),
//                           Text(
//                             'Traveled: ${_distanceTraveledKm.toStringAsFixed(2)} km',
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Bottom Fare Panel after end
//           if (_ended && _finalFare != null)
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: Container(
//                 padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 8,
//                       offset: Offset(0, -3),
//                     ),
//                   ],
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.check_circle,
//                       color: Colors.green,
//                       size: 40,
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Trip Finished',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Distance: ${_distanceTraveledKm.toStringAsFixed(2)} km',
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Amount to Pay',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                     Text(
//                       'KES ${_finalFare!.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.arrow_back),
//                       label: const Text('Back'),
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 24,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
