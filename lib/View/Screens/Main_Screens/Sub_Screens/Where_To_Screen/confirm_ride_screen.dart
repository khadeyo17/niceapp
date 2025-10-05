import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// class _ConfirmRideScreenState extends ConsumerState<ConfirmRideScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _panelController;
//   // late Animation<Offset> _panelOffset;
//   late Animation<Offset> _panelOffset;
//   final StreamController<bool> _driverLinkedController =
//       StreamController<bool>.broadcast();
class _ConfirmRideScreenState extends ConsumerState<ConfirmRideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _panelController;
  late Animation<Offset> _panelOffset;
  final StreamController<bool> _driverLinkedController =
      StreamController<bool>.broadcast();

  StreamSubscription<DatabaseEvent>? _rideSub;

  //Offset _panelOffset = const Offset(0, 1);
  double distanceInKm = 0;
  int durationInMinutes = 0;
  List<LatLng> routePoints = [];
  int? rideId2;
  //late StreamSubscription<DatabaseEvent> _rideSub;
  GoogleMapController? _mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  void initState() {
    super.initState();
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

    // Start animation
    _panelController.forward();
    _setupMarkers();
    _fetchRoute();
  }

  // @override
  // void dispose() {
  //   _panelController.dispose();
  //   super.dispose();
  // }
  @override
  void dispose() {
    _panelController.dispose();
    _rideSub?.cancel(); // cancel listener when screen is disposed
    super.dispose();
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

  Future<void> _fetchRoute() async {
    final origin = '${widget.pickup.latitude},${widget.pickup.longitude}';
    final destination =
        '${widget.destination.latitude},${widget.destination.longitude}';
    final apiKey = mapKey; // Your Google Maps API Key

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
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
          distanceInKm = leg['distance']['value'] / 1000.0; // meters to km
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

        // Move camera to show both points + route
        if (_mapController != null) {
          _moveCameraToBounds(widget.pickup, widget.destination);
        }
      } else {
        print('Google Directions API error: ${data['status']}');
      }
    } else {
      print('Failed to fetch directions. Status: ${response.statusCode}');
    }
  }

  void _moveCameraToBounds(LatLng pos1, LatLng pos2) async {
    final southWest = LatLng(
      min(pos1.latitude, pos2.latitude),
      min(pos1.longitude, pos2.longitude),
    );
    final northEast = LatLng(
      max(pos1.latitude, pos2.latitude),
      max(pos1.longitude, pos2.longitude),
    );

    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);

    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    await _mapController?.animateCamera(cameraUpdate);
  }

  // Decode encoded polyline from Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

  // Future<void> bookRide() async {
  //   final user = FirebaseAuth.instance.currentUser;

  //   if (user == null) {
  //     _closeFindingDriverDialog();
  //     print("User is not authenticated");
  //     return;
  //   }

  //   try {
  //     final idToken = await user.getIdToken();
  //     final url = '$baseUrl/rides/passenger/request';

  //     final pickupLat = widget.pickup.latitude;
  //     final pickupLng = widget.pickup.longitude;
  //     final destLat = widget.destination.latitude;
  //     final destLng = widget.destination.longitude;
  //     final subCategoryId = widget.category;
  //     final scheduledTime = widget.scheduledDate;

  //     final pickupAddress = await ReverseGeocodingService.getAddressFromLatLng(
  //       LatLng(pickupLat, pickupLng),
  //     );
  //     final destinationAddress =
  //         await ReverseGeocodingService.getAddressFromLatLng(
  //           LatLng(destLat, destLng),
  //         );

  //     final body = {
  //       "firebaseIdToken": user.uid,
  //       "pickupLocation": pickupAddress,
  //       "destination": destinationAddress,
  //       "pickupLat": pickupLat,
  //       "pickupLng": pickupLng,
  //       "destLat": destLat,
  //       "destLng": destLng,
  //       "subCategoryId": subCategoryId,
  //       "scheduledTime": scheduledTime?.toIso8601String(),
  //       "fare": widget.fare.toStringAsFixed(2),
  //     };

  //     if (!mounted) return;

  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);
  //       final rideId = responseData['rideId'];
  //       rideId2 = responseData['rideId'];

  //       if (scheduledTime == null) {
  //         await pollForDriverAssignment(rideId);
  //       } else {
  //         _closeFindingDriverDialog();
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => RideHistoryScreen()),
  //         );
  //       }
  //     } else {
  //       _closeFindingDriverDialog();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to book ride: ${response.statusCode}'),
  //         ),
  //       );
  //       print('Failed to book ride: ${response.statusCode}');
  //       print(response.body);
  //     }
  //   } catch (e) {
  //     _closeFindingDriverDialog();
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
  //     print('Error booking ride: $e');
  //   }
  // }

  void _closeFindingDriverDialog() {
    if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
      Navigator.pop(_dialogContext!);
    }
  }

  //late StreamSubscription<DatabaseEvent> _rideSub;

  /// Start listening to Firebase for driver assignment
  void listenForDriverAssignment(int requestId) {
    final dbRef = FirebaseDatabase.instance.ref("rideRequests/$requestId");

    _rideSub = dbRef.onValue.listen((event) async {
      if (!mounted || event.snapshot.value == null) return;

      final requestData = event.snapshot.value as Map;

      // Check if rideId is present
      if (requestData['rideId'] == null) return;
      final realRideId = requestData['rideId'];

      try {
        // Fetch ride from backend (optional if Firebase contains driver info)
        final url = '$baseUrl/rides/myrides/$realRideId';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final rideData = jsonDecode(response.body);

          if (rideData['driver'] != null) {
            final driverData = rideData['driver'];

            // Notify "Finding Driver" screen
            _driverLinkedController.add(true);

            // Cancel the listener after driver is found
            await _rideSub?.cancel();

            // Navigate instantly
            if (!mounted) return;
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
      } catch (e) {
        debugPrint("Error in listener: $e");
      }
    });
  }

  /// Call this instead of pollForDriverAssignment()
  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _closeFindingDriverDialog();
      print("User not authenticated");
      return;
    }

    try {
      final url = '$baseUrl/rides/passenger/request';
      final pickupLat = widget.pickup.latitude;
      final pickupLng = widget.pickup.longitude;
      final destLat = widget.destination.latitude;
      final destLng = widget.destination.longitude;
      final subCategoryId = widget.category;
      final scheduledTime = widget.scheduledDate;

      final pickupAddress = await ReverseGeocodingService.getAddressFromLatLng(
        LatLng(pickupLat, pickupLng),
      );
      final destinationAddress =
          await ReverseGeocodingService.getAddressFromLatLng(
            LatLng(destLat, destLng),
          );

      final body = {
        "firebaseIdToken": user.uid,
        "pickupLocation": pickupAddress,
        "destination": destinationAddress,
        "pickupLat": pickupLat,
        "pickupLng": pickupLng,
        "destLat": destLat,
        "destLng": destLng,
        "subCategoryId": subCategoryId,
        "scheduledTime": scheduledTime?.toIso8601String(),
        "fare": widget.fare.toStringAsFixed(2),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final rideId = responseData['rideId'];

        if (scheduledTime == null) {
          // 👇 Start realtime listener instead of polling
          listenForDriverAssignment(rideId);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RideHistoryScreen()),
          );
        }
      } else {
        _closeFindingDriverDialog();
        print('Failed to book ride: ${response.body}');
      }
    } catch (e) {
      _closeFindingDriverDialog();
      print("Error booking ride: $e");
    }
  }

  // void listenForDriverAssignment(int requestId) {
  //   final dbRef = FirebaseDatabase.instance.ref("rideRequests/$requestId");

  //   _rideSub = dbRef.onValue.listen((event) async {
  //     if (!mounted || event.snapshot.value == null) return;

  //     final requestData = event.snapshot.value as Map;
  //     if (requestData['rideId'] == null) return;

  //     final realRideId = requestData['rideId'];

  //     // 🔥 Option A: If Firebase already has driver info, navigate immediately.
  //     // 🔥 Option B: If not, still call backend but no need to poll repeatedly.
  //     final url = '$baseUrl/rides/myrides/$realRideId';
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final rideData = jsonDecode(response.body);

  //       if (rideData['driver'] != null) {
  //         final driverData = rideData['driver'];

  //         if (!mounted) return;
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (_) => DriverConfirmationScreen(
  //               rideId: realRideId,
  //               pickup: widget.pickup,
  //               driverId: driverData['firebaseId'],
  //               Phone: driverData['phoneNumber'],
  //               regnumber: driverData['registrationNumber'],
  //               vehicleMake: driverData['vehicleMake'],
  //               vehicleModel: driverData['vehicleModel'],
  //               colour: driverData['vehicleColour'],
  //               drivername: driverData['firstName'],
  //               photoUrl: driverData['photoUrl'],
  //             ),
  //           ),
  //         );
  //       }
  //     }
  //   });
  // }

  // @override
  // void dispose() {
  //   _rideSub.cancel();
  //   super.dispose();
  // }

  Future<bool> checkForExistingRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final idToken = await user.getIdToken();
    final url = '$baseUrl/rides/passenger/current';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final currentRide = jsonDecode(response.body);
      return true;
    }

    return false;
  }

  BuildContext? _dialogContext;

  void showFindingDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _dialogContext = dialogContext;
        return AlertDialog(
          title: const Text("Finding you a driver..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Please wait while we assign a driver."),
            ],
          ),
        );
      },
    );
  }

  Future<void> pollForDriverAssignment(int requestId) async {
    const maxAttempts = 20;
    const interval = Duration(seconds: 5);

    for (int i = 0; i < maxAttempts; i++) {
      if (!mounted) return;

      try {
        // 1. Check Firebase first
        //final dbRef = FirebaseDatabase.instance.ref("rideRequests/$requestId");
        final dbRef = FirebaseDatabase.instance.ref(
          "rideRequests/${requestId.toString()}",
        );

        final dbSnapshot = await dbRef.get();

        if (dbSnapshot.exists) {
          final requestData = dbSnapshot.value as Map;

          if (requestData['rideId'] != null) {
            final realRideId = requestData['rideId'];

            // 2. Now check backend ride
            final url = '$baseUrl/rides/myrides/$realRideId';
            final response = await http.get(Uri.parse(url));

            if (response.statusCode == 200) {
              final rideData = jsonDecode(response.body);

              if (rideData['driver'] != null) {
                final driverData = rideData['driver'];

                _driverLinkedController.add(true);

                await Future.delayed(const Duration(milliseconds: 200));

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DriverConfirmationScreen(
                          rideId: realRideId,
                          pickup: widget.pickup,
                          driverId: driverData['firebaseId'],
                          Phone: driverData['phoneNumber'],
                          regnumber: driverData['registrationNumber'],
                          vehicleMake: driverData['vehicleMake'],
                          vehicleModel: driverData['vehicleModel'],
                          colour: driverData['vehicleColour'],
                          drivername: driverData['firstName'],
                        ),
                  ),
                );
                return;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking driver assignment: $e");
      }

      await Future.delayed(interval);
    }

    _driverLinkedController.add(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No driver accepted your ride. Try again later."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickupAddressAsync = ref.watch(pickupAddressProvider);
    final fare = widget.fare;

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
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

              // Trigger slide-up animation after map loads
              Future.delayed(const Duration(milliseconds: 300), () {
                _panelController.forward();
              });
            },
          ),

          // Sliding Bottom Panel
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
              child: _buildBottomPanel(pickupAddressAsync, fare),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom panel widget
  Widget _buildBottomPanel(
    AsyncValue<String?> pickupAddressAsync,
    double fare,
  ) {
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
          pickupAddressAsync.when(
            data:
                (address) => Text(
                  "${address ?? 'Unknown'}",
                  style: const TextStyle(
                    fontSize: 18,
                    // fontWeight: FontWeight.w600,
                  ),
                ),
            loading:
                () => const Text(
                  "Pickup: Loading...",
                  style: TextStyle(fontSize: 18), // fontWeight: FontWeight.w600
                ),
            error:
                (err, _) => const Text(
                  "Pickup: Error",
                  style: TextStyle(
                    fontSize: 18,
                    //fontWeight: FontWeight.w600,
                    //color: Colors.red,
                  ),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.optionSelected}",
            style: const TextStyle(fontSize: 18), // fontWeight: FontWeight.bold
          ),
          const SizedBox(height: 8),
          Text(
            "KES ${fare.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 20,
              //fontWeight: FontWeight.bold,
              //color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),

          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () async {
          //       if (mounted) {
          //         showFindingDriverDialog(context);
          //         await bookRide();
          //       }
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.grey[700],
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 14),
          //       textStyle: const TextStyle(fontSize: 18),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //     ),
          //     child: Text(
          //       widget.isScheduled == true
          //           ? "📅 Confirm Booking"
          //           : "✅ Confirm Ride",
          //     ),
          //   ),
          // ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (mounted) {
                  // Instead of dialog, push full screen
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder:
                  //         (_) => FindingDriverScreen(
                  //           onCancel: () async {
                  //             // TODO: cancel ride request via API
                  //             print("Ride canceled by passenger");
                  //           },
                  //         ),
                  //   ),
                  // );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder:
                          (_) => FindingDriverScreen(
                            onCancel: () async {
                              // Call cancel API
                              print("Ride canceled by passenger");
                            },
                            driverLinkedStream: _driverLinkedController.stream,
                          ),
                    ),
                  );

                  await bookRide();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
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