import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/finding_driver_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';

class ConfirmRideScreen extends ConsumerStatefulWidget {
  final int category;
  final String? optionSelected;
  final double fare;
  final LatLng pickup;
  final LatLng destination;
  final DateTime? scheduledDate;
  final bool? isScheduled;

  const ConfirmRideScreen({
    super.key,
    required this.category,
    this.optionSelected,
    required this.fare,
    required this.pickup,
    required this.destination,
    this.scheduledDate,
    this.isScheduled,
  });

  @override
  ConsumerState<ConfirmRideScreen> createState() => _ConfirmRideScreenState();
}

class _ConfirmRideScreenState extends ConsumerState<ConfirmRideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _panelController;
  late Animation<Offset> _panelOffset;

  final StreamController<bool> _driverLinkedController =
      StreamController<bool>.broadcast();
  StreamSubscription<DatabaseEvent>? _rideSub;
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _commonPlaces = [];
  bool isPlacesLoading = false;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> routePoints = [];
  double distanceInKm = 0;
  int durationInMinutes = 0;
  String? newRideId;

  String? pickupAddress;
  String? destinationAddress;

  @override
  void initState() {
    super.initState();

    // Slide panel animation
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
    );

    // Setup markers & fetch route
    _setupMarkers();
    _fetchAddressesAndRoute();
    //loadNearbyPlaces(location: widget.destination);
  }

  @override
  void dispose() {
    _panelController.dispose();
    _rideSub?.cancel();
    _driverLinkedController.close();
    super.dispose();
  }

  Future<void> loadNearbyPlaces({required LatLng location}) async {
    setState(() => isPlacesLoading = true);

    try {
      final latitude = location.latitude;
      final longitude = location.longitude;

      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=$latitude,$longitude"
          "&radius=3000"
          "&type=point_of_interest"
          "&key=$mapKey";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["status"] == "OK" && data["results"] != null) {
          final results = data["results"] as List;

          final places =
              results.take(5).map((place) {
                return {
                  "name": place["name"] ?? "Unknown",
                  "address": place["vicinity"] ?? "",
                  "lat": place["geometry"]["location"]["lat"],
                  "lng": place["geometry"]["location"]["lng"],
                  "icon": Icons.place,
                };
              }).toList();

          if (!mounted) return;

          setState(() {
            _commonPlaces = places;
            isPlacesLoading = false;
          });

          // ✅ After fetching places, fetch route
          await _fetchRoute();
        } else {
          if (!mounted) return;
          setState(() => isPlacesLoading = false);
        }
      } else {
        if (!mounted) return;
        setState(() => isPlacesLoading = false);
      }
    } catch (e) {
      debugPrint("Nearby places error: $e");
      if (!mounted) return;
      setState(() => isPlacesLoading = false);
    }
  }

  void _setupMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickup,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Future<void> _fetchAddressesAndRoute() async {
    // Fetch human-readable names for pickup & destination
    final pickupName = await ReverseGeocodingService.getNameFromLatLng(
      widget.pickup,
    );
    final destinationName = await ReverseGeocodingService.getNameFromLatLng(
      widget.destination,
    );

    if (!mounted) return;

    setState(() {
      pickupAddress = pickupName;
      destinationAddress = destinationName;
    });

    await _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final origin = '${widget.pickup.latitude},${widget.pickup.longitude}';
    final destination =
        '${widget.destination.latitude},${widget.destination.longitude}';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$mapKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final overviewPolyline = route['overview_polyline']['points'];
        final points = _decodePolyline(overviewPolyline);

        setState(() {
          routePoints = points;
          distanceInKm = leg['distance']['value'] / 1000;
          durationInMinutes = (leg['duration']['value'] / 60).round();
          polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: routePoints,
            ),
          };
        });

        // Move camera to bounds
        if (_mapController != null) {
          _moveCameraToBounds(widget.pickup, widget.destination);
        }
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _moveCameraToBounds(LatLng pos1, LatLng pos2) {
    final southWest = LatLng(
      min(pos1.latitude, pos2.latitude),
      min(pos1.longitude, pos2.longitude),
    );
    final northEast = LatLng(
      max(pos1.latitude, pos2.latitude),
      max(pos1.longitude, pos2.longitude),
    );

    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken(true);
    final pickupAddr = pickupAddress ?? "Unknown Pickup";
    final destAddr = destinationAddress ?? "Unknown Destination";

    final body = {
      "firebaseIdToken": idToken,
      "pickupLocation": pickupAddr,
      "destination": destAddr,
      "pickupLat": widget.pickup.latitude,
      "pickupLng": widget.pickup.longitude,
      "destLat": widget.destination.latitude,
      "destLng": widget.destination.longitude,
      "subCategoryId": widget.category,
      "scheduledTime": widget.scheduledDate?.toIso8601String(),
      "fare": widget.fare.toStringAsFixed(2),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/rides/passenger/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final rideId = jsonDecode(response.body)['rideId'];
      newRideId = rideId.toString();
      if (widget.scheduledDate == null) {
        listenForDriverAssignment(rideId);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RideHistoryScreen()),
        );
      }
    }
  }

  void listenForDriverAssignment(int requestId) {
    final dbRef = FirebaseDatabase.instance.ref("rideRequests/$requestId");
    _rideSub = dbRef.onValue.listen((event) async {
      if (!mounted || event.snapshot.value == null) return;

      final requestData = event.snapshot.value as Map;
      final realRideId = requestData['rideId'];
      if (realRideId == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/rides/myrides/$realRideId'),
      );
      if (response.statusCode == 200) {
        final rideData = jsonDecode(response.body);
        if (rideData['driver'] != null) {
          final driverData = rideData['driver'];
          _driverLinkedController.add(true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DriverConfirmationScreen(
                    rideId: realRideId,
                    pickup: widget.pickup,
                    destination: widget.destination,
                    driverId: driverData['firebaseId'],
                    Phone: driverData['phoneNumber'],
                    regnumber: driverData['registrationNumber'],
                    vehicleMake: driverData['vehicleMake'],
                    vehicleModel: driverData['vehicleModel'],
                    colour: driverData['vehicleColour'],
                    drivername: driverData['firstName'],
                    photoUrl: driverData['photoUrl'],
                  ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickup,
              zoom: 12,
            ),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCameraToBounds(widget.pickup, widget.destination);
              Future.delayed(const Duration(milliseconds: 300), () {
                _panelController.forward();
              });
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _panelOffset,
              builder: (context, child) {
                return AnimatedSlide(
                  offset: _panelOffset.value,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: child,
                );
              },
              child: _buildBottomPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   pickupAddress ?? "Loading Pickup...",
          //   style: const TextStyle(fontSize: 18),
          // ),
          //const SizedBox(height: 4),
          Text(
            destinationAddress ?? "Loading Destination...",
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            widget.optionSelected ?? "",
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 8),
          Text(
            "KES ${widget.fare.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder:
                          (_) => FindingDriverScreen(
                            rideId: newRideId,
                            onCancel:
                                () async => print("Ride canceled by passenger"),
                            driverLinkedStream: _driverLinkedController.stream,
                          ),
                    ),
                  );
                  await bookRide();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isScheduled == true
                    ? "📅 Confirm Booking"
                    : "✅ Confirm Ride",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  // Future<void> bookRide() async {
  //   final user = FirebaseAuth.instance.currentUser;

  //   if (user == null) {
  //     print("User is not authenticated");
  //     return null;
  //   }

  //   final idToken = await user.getIdToken();
  //   final url = '$baseUrl/rides/passenger/book';

  //   final pickupLat = widget.pickup.latitude;
  //   final pickupLng = widget.pickup.longitude;
  //   final destLat = widget.destination.latitude;
  //   final destLng = widget.destination.longitude;
  //   final subCategoryId = widget.category;
  //   final scheduledTime = widget.scheduledDate;

  //   final pickupAddress = await ReverseGeocodingService.getAddressFromLatLng(
  //     LatLng(pickupLat, pickupLng),
  //   );
  //   final destinationAddress =
  //       await ReverseGeocodingService.getAddressFromLatLng(
  //         LatLng(destLat, destLng),
  //       );

  //   final body = {
  //     "firebaseIdToken": idToken,
  //     "pickupLocation": pickupAddress,
  //     "destination": destinationAddress,
  //     "pickupLat": pickupLat,
  //     "pickupLng": pickupLng,
  //     "destLat": destLat,
  //     "destLng": destLng,
  //     "subCategoryId": subCategoryId,
  //     "scheduledTime": scheduledTime?.toIso8601String(),
  //   };

  //   if (!mounted) return;
  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(body),
  //   );

  //   if (response.statusCode == 200) {
  //     final responseData = jsonDecode(response.body);
  //     final rideId = responseData['rideId'];
  //     rideId2 = responseData['rideId'];

  //     if (scheduledTime == null) {
  //       // showFindingDriverDialog(context);
  //       await pollForDriverAssignment(rideId);
  //     } else {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => RideHistoryScreen()),
  //       );
  //     }
  //   } else {
  //     print('Failed to book ride: ${response.statusCode}');
  //     print(response.body);
  //   }
  // }
    // Future<void> pollForDriverAssignment(int rideId) async {
  //   final url = '$baseUrl/rides/myrides/$rideId';
  //   const maxAttempts = 20;
  //   const interval = Duration(seconds: 5);

  //   for (int i = 0; i < maxAttempts; i++) {
  //     if (!mounted) return;
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final rideData = jsonDecode(response.body);

  //       if (rideData['driver'] != null) {
  //         final driverData = rideData['driver'];

  //         if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
  //           Navigator.pop(_dialogContext!);
  //         }

  //         await Future.delayed(const Duration(milliseconds: 100));

  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder:
  //                 (context) => DriverConfirmationScreen(
  //                   rideId: rideId,
  //                   pickup: widget.pickup,
  //                   driverId: driverData['firebaseId'],
  //                   Phone: driverData['phoneNumber'],
  //                   regnumber: driverData['registrationNumber'],
  //                   vehicleMake: driverData['vehicleMake'],
  //                   vehicleModel: driverData['vehicleModel'],
  //                   colour: driverData['vehicleColour'],
  //                   drivername: driverData['firstName'],
  //                 ),
  //             // (context) => RideInProgressLiveScreen(
  //             //   rideId: rideId,
  //             //   pickup: widget.pickup,
  //             //   destination: widget.destination,
  //             //   driverId: driverData['firebaseId'],
  //             //   baseFare: widget.fare,
  //             //   // Phone: driverData['phoneNumber'],
  //             //   // regnumber: driverData['registrationNumber'],
  //             //   // vehicleMake: driverData['vehicleMake'],
  //             //   // vehicleModel: driverData['vehicleModel'],
  //             //   // colour: driverData['vehicleColour'],
  //             //   // drivername: driverData['firstName'],
  //             // ),
  //           ),
  //         );
  //         return;
  //       }
  //     }
  //     await Future.delayed(interval);
  //   }

  //   if (Navigator.canPop(context)) {
  //     Navigator.pop(context);
  //   }

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text("No driver accepted your ride. Try again later."),
  //     ),
  //   );
  // }

  // Future<void> pollForDriverAssignment(int rideId) async {
  //   final url = '$baseUrl/rides/myrides/$rideId';
  //   const maxAttempts = 20;
  //   const interval = Duration(seconds: 5);

  //   for (int i = 0; i < maxAttempts; i++) {
  //     if (!mounted) return;
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final rideData = jsonDecode(response.body);

  //       if (rideData['driver'] != null) {
  //         final driverData = rideData['driver'];

  //         // ✅ notify FindingDriverScreen to close
  //         _driverLinkedController.add(true);

  //         // ✅ then navigate to DriverConfirmation
  //         await Future.delayed(const Duration(milliseconds: 200));

  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder:
  //                 (_) => DriverConfirmationScreen(
  //                   rideId: rideId,
  //                   pickup: widget.pickup,
  //                   driverId: driverData['firebaseId'],
  //                   Phone: driverData['phoneNumber'],
  //                   regnumber: driverData['registrationNumber'],
  //                   vehicleMake: driverData['vehicleMake'],
  //                   vehicleModel: driverData['vehicleModel'],
  //                   colour: driverData['vehicleColour'],
  //                   drivername: driverData['firstName'],
  //                 ),
  //           ),
  //         );
  //         return;
  //       }
  //     }
  //     await Future.delayed(interval);
  //   }

  //   // No driver
  //   _driverLinkedController.add(false);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text("No driver accepted your ride. Try again later."),
  //     ),
  //   );
  // }
  // Future<void> pollForDriverAssignment(int rideId) async {
  //   final url = '$baseUrl/rides/myrides/$rideId';
  //   const maxAttempts = 20;
  //   const interval = Duration(seconds: 5);

  //   for (int i = 0; i < maxAttempts; i++) {
  //     if (!mounted) return;

  //     try {
  //       // Step 1: Check backend ride
  //       final response = await http.get(Uri.parse(url));

  //       if (response.statusCode == 200) {
  //         final rideData = jsonDecode(response.body);

  //         if (rideData['driver'] != null) {
  //           final driverData = rideData['driver'];

  //           // Step 2: Fetch from Firebase Realtime DB
  //           final dbRef = FirebaseDatabase.instance.ref("rides/$rideId");
  //           final dbSnapshot = await dbRef.get();

  //           if (dbSnapshot.exists) {
  //             final firebaseData = dbSnapshot.value as Map;

  //             // Step 3: Compare rideIds
  //             if (firebaseData['rideId'] == rideId) {
  //               // ✅ notify FindingDriverScreen to close
  //               _driverLinkedController.add(true);

  //               // ✅ then navigate to DriverConfirmation
  //               await Future.delayed(const Duration(milliseconds: 200));

  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (_) => DriverConfirmationScreen(
  //                         rideId: rideId,
  //                         pickup: widget.pickup,
  //                         driverId: driverData['firebaseId'],
  //                         Phone: driverData['phoneNumber'],
  //                         regnumber: driverData['registrationNumber'],
  //                         vehicleMake: driverData['vehicleMake'],
  //                         vehicleModel: driverData['vehicleModel'],
  //                         colour: driverData['vehicleColour'],
  //                         drivername: driverData['firstName'],
  //                       ),
  //                 ),
  //               );
  //               return;
  //             }
  //           }
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint("Error checking driver assignment: $e");
  //     }

  //     await Future.delayed(interval);
  //   }

  //   // No driver
  //   _driverLinkedController.add(false);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text("No driver accepted your ride. Try again later."),
  //     ),
  //   );
  //  }