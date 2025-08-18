// ignore_for_file: file_names
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

class AmbulanceScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? pickup;
  final LatLng? destination;
  const AmbulanceScreen({
    super.key,
    required this.category,
    this.pickup,
    this.destination,
  });

  @override
  _AmbulanceScreenState createState() => _AmbulanceScreenState();
}

//class _AmbulanceScreenState extends State<AmbulanceScreen> {
class _AmbulanceScreenState extends State<AmbulanceScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController detailsController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  final String googleApiKey = mapKey;
  String pickuplocationName = "Loading...";
  String destinationlocationName = "Tap to select hospital";
  LatLng? currentLatLng;
  GoogleMapController? mapController;

  List<VehicleSubCategory> vehicleCategories = [];
  List<FareEstimate?> fareEstimates = [];
  bool isLoadingCategories = true;
  int selectedIndex = -1;
  double distanceInKm = 0;
  int durationInMinutes = 0;
  List<LatLng> routePoints = [];
  int? rideId2;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    detailsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.pickup != null) {
      // Use passed pickup location immediately
      currentLatLng = widget.pickup;
      // _getpickupAddressFromGoogle(
      //   widget.pickup!.latitude,
      //   widget.pickup!.longitude,
      // );
    } else {
      // Fallback to Firebase location
      _fetchLocationFromFirebase();
    }
    // if (widget.destination != null) {
    //   _getdestinationAddressFromGoogle(
    //     widget.destination!.latitude,
    //     widget.destination!.longitude,
    //   );
    // }

    // If pickup is null, fallback to fetching from Firebase or your location logic
    if (currentLatLng == null) {
      _fetchLocationFromFirebase();
    }
    _setupMarkers();
    _fetchRoute();

    /// _fetchLocationFromFirebase();
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

  Future<void> pollForDriverAssignment(int rideId) async {
    final url = '$baseUrl/rides/myrides/$rideId';
    const maxAttempts = 20;
    const interval = Duration(seconds: 3);

    for (int i = 0; i < maxAttempts; i++) {
      if (!mounted) return;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final rideData = jsonDecode(response.body);

        if (rideData['driver'] != null) {
          final driverData = rideData['driver'];

          if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
            Navigator.pop(_dialogContext!);
          }

          await Future.delayed(const Duration(milliseconds: 100));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DriverConfirmationScreen(
                    rideId: rideId,
                    pickup: widget.pickup!,
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
      await Future.delayed(interval);
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No driver accepted your ride. Try again later."),
      ),
    );
  }

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("User is not authenticated");
      return null;
    }

    final idToken = await user.getIdToken();
    final url = '$baseUrl/rides/ambulance/book';
    final pickup = currentLatLng;

    final pickupLat = pickup!.latitude; // widget.pickup!.latitude;
    final pickupLng = pickup.longitude; //widget.pickup.longitude;
    final subCategoryId = 1038; //widget.category;

    final pickupAddress = await ReverseGeocodingService.getAddressFromLatLng(
      LatLng(pickupLat, pickupLng),
    );

    final body = {
      "firebaseIdToken": idToken,
      "pickupLocation": pickupAddress,
      "pickupLat": pickupLat,
      "pickupLng": pickupLng,
      "subCategoryId": subCategoryId,
    };

    if (!mounted) return;
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final rideId = responseData['rideId'];
      //rideId2 = responseData['rideId'];

      showFindingDriverDialog(context);
      await pollForDriverAssignment(rideId);

      // if (scheduledTime == null) {
      //   showFindingDriverDialog(context);
      //   await pollForDriverAssignment(rideId);
      // } else {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => RideHistoryScreen()),
      //   );
      // }
    } else {
      print('Failed to book ride: ${response.statusCode}');
      print(response.body);
    }
  }

  Future<List<VehicleSubCategory>> fetchVehicleSubCategories(int type) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/rides/categories?type=$type',
      ), // e.g., type=0 for RideBooking
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      // Flatten all subCategories from all categories
      final List<dynamic> allSubCategories =
          jsonList
              .expand((category) => category['subCategories'] ?? [])
              .toList();

      return allSubCategories
          .map((e) => VehicleSubCategory.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load vehicle categories');
    }
  }

  Future<void> _fetchLocationFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final refDB = FirebaseDatabase.instance.ref(
        'passengers/${user.uid}/location',
      );

      final snapshot = await refDB.get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat == null || lng == null) return;

      setState(() {
        currentLatLng = widget.pickup ?? LatLng(lat.toDouble(), lng.toDouble());
      });

      // Now fetch address
      _fetchRoute();
      // _getpickupAddressFromGoogle(lat.toDouble(), lng.toDouble());
    } catch (e) {
      debugPrint('Failed to fetch pickup location from Firebase: $e');
    }
  }

  void _setupMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickup ?? LatLng(-1.2921, 36.8219),
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination ?? LatLng(-1.0333, 37.0693),
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Future<void> _fetchRoute() async {
    final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
    final destination =
        '${widget.destination!.latitude},${widget.destination!.longitude}';
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
        if (mapController != null) {
          _moveCameraToBounds(
            widget.pickup ?? LatLng(-1.2921, 36.8219),
            widget.destination ?? LatLng(-1.0333, 37.0693),
          );
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
    await mapController?.animateCamera(cameraUpdate);
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

  // Future<void> _getpickupAddressFromGoogle(double lat, double lng) async {
  //   final url = Uri.parse(
  //     "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey",
  //   );

  //   try {
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body);
  //       if (jsonData["results"] != null && jsonData["results"].isNotEmpty) {
  //         setState(() {
  //           pickuplocationName = jsonData["results"][0]["formatted_address"];
  //         });
  //       } else {
  //         setState(() {
  //           pickuplocationName = "Address not found";
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         pickuplocationName = "Error getting address";
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       pickuplocationName = "Failed to fetch address";
  //     });
  //   }
  // }

  // Future<void> _getdestinationAddressFromGoogle(double lat, double lng) async {
  //   final url = Uri.parse(
  //     "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey",
  //   );

  //   try {
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body);
  //       if (jsonData["results"] != null && jsonData["results"].isNotEmpty) {
  //         setState(() {
  //           destinationlocationName =
  //               jsonData["results"][0]["formatted_address"];
  //         });
  //       } else {
  //         setState(() {
  //           destinationlocationName = "Address not found";
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         destinationlocationName = "Error getting address";
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       destinationlocationName = "Failed to fetch address";
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ambulance Services'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tapable current location bar
          InkWell(
            // onTap: () async {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder:
            //           (_) => WhereToScreen(
            //             category: VehicleCategory.ambulance,
            //             // initialPickupLocation: pickup ?? currentLocation,
            //           ),
            //     ),
            //   );
            // },
            onTap: () async {
              final result = await Navigator.push<LocationResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => WhereToScreen(category: widget.category),
                ),
              );

              if (result != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => AmbulanceScreen(
                          category: widget.category,
                          pickup: result.pickup,
                          destination: result.destination,
                        ),
                  ),
                );
              }
            },

            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hostpital",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    destinationlocationName,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // Map
          SizedBox(
            height: 250,
            child:
                currentLatLng == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: currentLatLng!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('currentLocation'),
                          position: currentLatLng!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                      },
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                    ),
          ),

          // Details input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Emergency Details'),
              maxLines: 3,
            ),
          ),

          // Full-width horizontal cards stacked vertically
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                SizedBox(
                  height: 80,
                  child: Card(
                    color: Colors.green[200],
                    child: InkWell(
                      onTap: () => bookRide(),
                      child: const Center(
                        child: Text(
                          "Gender Based Violence",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: Card(
                    color: Colors.green[600],
                    child: InkWell(
                      onTap: () => bookRide(),
                      child: const Center(
                        child: Text(
                          "Medical Emergency",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
