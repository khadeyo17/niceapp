import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Other_Screens/visa_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart' as FareService;
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // as gmaps;

class HomeScreen extends ConsumerStatefulWidget {
  final LatLng? pickup;
  final LatLng? destination;
  final List<Map<String, dynamic>>? stops;
  final VehicleCategory category;
  final DateTime? scheduledDate;
  final bool? isScheduled;

  const HomeScreen({
    super.key,
    this.pickup,
    this.destination,
    this.stops,
    required this.category,
    this.scheduledDate,
    this.isScheduled,
    //this.stops
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
  Set<Marker> _markers = {};
  List<VehicleSubCategory> vehicleCategories = [];
  List<FareEstimate?> fareEstimates = [];
  bool isLoadingCategories = true;
  int selectedIndex = -1;
  LatLng? currentLocation;
  String? pickupAddress;
  String? destinationAddress;
  //LatLng? pickup;
  List<LatLng> routePoints = [];
  double? routeDistance;
  double durationInMinutes = 0;
  bool isSwiped = false;
  LatLng _initialFallback = const LatLng(-1.286389, 36.817223);
  //GoogleMapController? mapController;
  //late ScrollController _scrollController;
  GoogleMapController? _mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  double _mapOffsetY = 0;
  final double maxUpOffset = -150; // adjust as needed
  late ScrollController _scrollController = ScrollController();
  List<bool> driverAvailability = [];
  // final formatCurrency = NumberFormat.simpleCurrency(
  //   locale: Localizations.localeOf(context).toString(),
  // );

  List<Map<String, dynamic>> stops = [];

  @override
  void initState() {
    super.initState();
    //_getCurrentLocation();
    //_setCurrentLocation();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      canStartRide(userId).then((allowed) {
        if (!allowed) {
          _listenToActiveRide(userId);
        }
      });
    }
    ////working
    // if (widget.destination != null) {
    //   fetchVehicleSubCategoriesByType(widget.category.index).then((
    //     categories,
    //   ) async {
    //     setState(() {
    //       vehicleCategories = categories;
    //       fareEstimates = List<FareEstimate?>.filled(categories.length, null);
    //       isLoadingCategories = false;

    //       if (categories.isNotEmpty) {
    //         selectedIndex = 0;
    //         ref.read(selectedCategoryProvider.notifier).state = categories[0];
    //       }
    //     });
    //     if (widget.pickup != null && widget.destination != null) {
    //       await _fetchRoute();
    //       //for (int i = 0; i < categories.length; i++) {
    //       // final category = categories[i];
    //       // try {
    //       //   final estimate = await FareService.getFareEstimate(
    //       //     categoryId: category.id,
    //       //     pickupLat: widget.pickup!.latitude,
    //       //     pickupLng: widget.pickup!.longitude,
    //       //     destLat: widget.destination!.latitude,
    //       //     destLng: widget.destination!.longitude,
    //       //     distanceKm: ,
    //       //     countryCode: "KE",
    //       //   );
    //       //   print('Received estimate for ${category.name}: $estimate');
    //       //   setState(() {
    //       //     fareEstimates[i] = estimate;
    //       //   });
    //       // } catch (e) {
    //       //   print('Failed to load fare for category ${category.name}: $e');
    //       // }
    //       // }
    //     }
    //   });
    //   _setupMarkers();
    //   // _fetchRoute();

    if (widget.stops != null) {
      stops = widget.stops ?? [];
    }

    if (widget.destination != null) {
      fetchVehicleSubCategoriesByType(widget.category.index).then((
        categories,
      ) async {
        // Extract availability info directly from backend
        List<bool> availabilityList =
            categories.map((category) => category.isAvailable).toList();

        setState(() {
          vehicleCategories = categories;
          fareEstimates = List<FareEstimate?>.filled(categories.length, null);
          isLoadingCategories = false;
          driverAvailability = availabilityList;

          if (categories.isNotEmpty) {
            selectedIndex = 0;
            ref.read(selectedCategoryProvider.notifier).state = categories[0];
          }
        });

        if (widget.pickup != null && widget.destination != null) {
          await _fetchRoute();
        }
      });

      _setupMarkers();
    }

    // _scrollController = ScrollController();

    // Add scroll listener to update map camera when the sheet scrolls

    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      // Map moves up as offset grows, but clamp so it never moves beyond maxUpOffset
      final newMapOffset = (-offset).clamp(maxUpOffset, 0).toDouble();

      setState(() {
        _mapOffsetY = newMapOffset;
      });
    });
    // canStartRide();
    // _scrollController.addListener(() {
    //   if (widget.pickup != null && widget.destination != null) {
    //     _moveCameraToBounds(context, widget.pickup!, widget.destination!);
    //   } else if (widget.pickup != null) {
    //     _mapController?.animateCamera(
    //       CameraUpdate.newLatLngZoom(widget.pickup!, 14),
    //     );
    //   }
    // });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Optional post-frame logic
    // });
  }

  Future<bool> checkDriverAvailability(int categoryId) async {
    final uri = Uri.parse(
      '$baseUrl/drivers/availability?categoryId=$categoryId',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] ?? false;
    } else {
      return false;
    }
  }

  bool _isRideScreenOpen = false;

  // void _listenToActiveRide(String userId) {
  //   final ridesRef = FirebaseDatabase.instance.ref("rides");

  //   ridesRef.orderByChild("riderId").equalTo(userId).onValue.listen((event) {
  //     if (!event.snapshot.exists) return;

  //     final rides = Map<String, dynamic>.from(
  //       event.snapshot.value as Map<dynamic, dynamic>,
  //     );

  //     // Find all active rides
  //     final activeRides =
  //         rides.entries.where((entry) {
  //           final status = entry.value['status']?.toString();
  //           return status == 'assigned' || status == 'in-progress';
  //         }).toList();

  //     if (activeRides.isEmpty) {
  //       // 🚪 No active rides → close if screen open
  //       if (_isRideScreenOpen) {
  //         Navigator.of(context).pop();
  //         _isRideScreenOpen = false;
  //       }
  //       return;
  //     }

  //     // 🚀 Always take the last active ride
  //     final activeRide = activeRides.last;
  //     final rideData = Map<String, dynamic>.from(activeRide.value);
  //     final rideId = rideData['rideId'] ?? activeRide.key;

  //     if (!_isRideScreenOpen) {
  //       _isRideScreenOpen = true;

  //       Navigator.of(context)
  //           .push(
  //             MaterialPageRoute(
  //               builder: (_) => RideInProgressLiveScreen(rideId: rideId),
  //             ),
  //           )
  //           .then((_) {
  //             // Reset when screen is popped
  //             _isRideScreenOpen = false;
  //           });
  //     }
  //   });
  // }
  bool _hasActiveRide = false;

  void _listenToActiveRide(String userId) {
    final ridesRef = FirebaseDatabase.instance.ref("rides");

    ridesRef.orderByChild("riderId").equalTo(userId).onValue.listen((event) {
      if (!event.snapshot.exists) {
        _hasActiveRide = false;
        return;
      }

      final rides = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      // Find all active rides
      final activeRides =
          rides.entries.where((entry) {
            final status = entry.value['status']?.toString();
            return status == 'assigned' || status == 'in-progress';
          }).toList();

      if (activeRides.isEmpty) {
        // ✅ No active rides
        _hasActiveRide = false;
        return;
      }

      // ✅ At least one active ride → block new booking
      _hasActiveRide = true;
    });
  }

  Future<bool> canStartRide(String userId) async {
    final snap =
        await FirebaseDatabase.instance
            .ref("rides")
            .orderByChild("riderId")
            .equalTo(userId)
            .get();

    if (snap.exists) {
      final rides = snap.value as Map;
      return !rides.values.any(
        (ride) =>
            ride['status'] == 'assigned' || ride['status'] == 'in-progress',
      );
    }
    return true; // no rides → allow
  }

  // Future<bool> driverHasActiveRide(String driverId) async {
  //   final snap =
  //       await passengerDb
  //           .ref("rides")
  //           .orderByChild("driverId")
  //           .equalTo(driverId)
  //           .get();

  //   if (!snap.exists) return false;

  //   final rides = (snap.value as Map).values;
  //   return rides.any(
  //     (ride) => ride['status'] == 'assigned' || ride['status'] == 'in-progress',
  //   );
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // void _setupMarkers() {
  //   markers = {
  //     Marker(
  //       markerId: const MarkerId('pickup'),
  //       position: widget.pickup!,
  //       infoWindow: const InfoWindow(title: 'Pickup'),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  //     ),
  //     Marker(
  //       markerId: const MarkerId('destination'),
  //       position: widget.destination!,
  //       infoWindow: const InfoWindow(title: 'Destination'),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  //     ),
  //   };
  // }

  void _setupMarkers() {
    final newMarkers = <Marker>{};

    // Pickup Marker
    if (widget.pickup != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickup!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Destination Marker
    if (widget.destination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Intermediate Stops (only those in widget.stops)
    // stops = widget.stops ?? [];
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final LatLng stopLatLng = stop['latLng'] as LatLng;

      newMarkers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: stopLatLng,
          infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }

  Future<String> _getPlaceName(LatLng position) async {
    final apiKey = mapKey; // Google API key
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    }
    return "Unknown location";
  }

  Future<void> _fetchRoute() async {
    final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
    final destination =
        '${widget.destination!.latitude},${widget.destination!.longitude}';
    final apiKey = mapKey;

    // Build waypoints string if there are stops
    String waypoints = '';
    if (stops.isNotEmpty) {
      waypoints = stops
          .map(
            (s) =>
                '${(s['latLng'] as LatLng).latitude},${(s['latLng'] as LatLng).longitude}',
          )
          .join('|');
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$origin&destination=$destination'
      '${waypoints.isNotEmpty ? "&waypoints=$waypoints" : ""}'
      '&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      print('Failed to fetch directions. Status: ${response.statusCode}');
      return;
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      print('Google Directions API error: ${data['status']}');
      return;
    }

    final route = data['routes'][0];
    final overviewPolyline = route['overview_polyline']['points'];
    final points = _decodePolyline(overviewPolyline);

    // Calculate total distance and duration including stops
    double distanceKm = 0;
    double durationMinutes = 0;
    for (var leg in route['legs']) {
      distanceKm += leg['distance']['value'] / 1000.0;
      durationMinutes += leg['duration']['value'] / 60.0;
    }

    // Midpoint of route
    LatLng? midPoint;
    if (points.isNotEmpty) {
      final midIndex = (points.length / 2).floor();
      midPoint = LatLng(points[midIndex].latitude, points[midIndex].longitude);
    }

    // Resolve addresses
    pickupAddress = await _getPlaceName(widget.pickup!);
    destinationAddress = await _getPlaceName(widget.destination!);

    // Add stops addresses
    for (int i = 0; i < stops.length; i++) {
      stops[i]['address'] = await _getPlaceName(stops[i]['latLng']);
    }

    if (!mounted) return;
    setState(() {
      routePoints = points;
      routeDistance = distanceKm;
      this.durationInMinutes = durationMinutes;

      polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: routePoints,
        ),
      };

      // Update markers for pickup, destination, and stops
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: widget.pickup!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(title: pickupAddress ?? "Pickup"),
          ),
        )
        ..add(
          Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: destinationAddress ?? "Destination"),
          ),
        );

      for (int i = 0; i < stops.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: stops[i]['latLng'],
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: stops[i]['address'] ?? "Stop ${i + 1}",
            ),
          ),
        );
      }

      if (midPoint != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('route_center'),
            position: midPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: "${distanceKm.toStringAsFixed(1)} km",
              snippet: "${durationMinutes.toStringAsFixed(0)} min",
            ),
          ),
        );
      }
    });

    // Send stops to backend
    //_sendStopsToBackend(stops);

    // Update fare estimates per vehicle category
    await _fetchFareEstimates(distanceKm, durationMinutes);
  }

  Future<void> _fetchFareEstimates(
    double distanceKm,
    double durationMinutes,
  ) async {
    // Prepare stops for the API
    List<Map<String, double>>? fareStops;

    if (stops.isNotEmpty) {
      fareStops =
          stops.where((s) => s["latLng"] != null).map((s) {
            final LatLng latLng = s["latLng"];
            return {"lat": latLng.latitude, "lng": latLng.longitude};
          }).toList();
    } else {
      fareStops = null;
    }

    // Loop through vehicle categories
    for (int i = 0; i < vehicleCategories.length; i++) {
      final category = vehicleCategories[i];
      try {
        final estimate = await FareService.getFareEstimate(
          categoryId: category.id,
          pickupLat: widget.pickup!.latitude,
          pickupLng: widget.pickup!.longitude,
          destLat: widget.destination!.latitude,
          destLng: widget.destination!.longitude,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          waitingMinutes: 0,
          countryCode: "KE",
          stops: fareStops, // Pass the stops here
        );

        if (!mounted) return;
        setState(() => fareEstimates[i] = estimate);
      } catch (e) {
        print('❌ Failed to load fare for ${category.name}: $e');
        if (!mounted) return;
        setState(() {
          fareEstimates[i] = FareEstimate(
            fare: 0,
            currency: "KES",
            timeEstimate: durationMinutes,
            categoryName: category.name,
            distanceKm: distanceKm,
          );
        });
      }
    }
  }

  // Helper method to calculate midpoint
  LatLng _getMidPoint(LatLng p1, LatLng p2) {
    final midLat = (p1.latitude + p2.latitude) / 2;
    final midLng = (p1.longitude + p2.longitude) / 2;
    return LatLng(midLat, midLng);
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

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _navigateToWhereTo() {
    if (_hasActiveRide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already have an active ride. Complete or cancel it before booking a new one.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // ❌ Prevent booking
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => WhereToScreen(
              category: VehicleCategory.passenger,
              initialPickupLocation: currentLocation,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(linkedDriverProvider);
    final rideConfirmed = ref.watch(rideConfirmedProvider);

    //final pickup = widget.pickup;
    final pickup = widget.pickup ?? currentLocation;
    final destination = widget.destination;
    final dropAddressAsync = ref.watch(dropAddressProvider);

    //final distance = Distance();
    final selectedFare =
        (selectedIndex >= 0 && selectedIndex < fareEstimates.length)
            ? fareEstimates[selectedIndex]?.fare ?? 0.0
            : 0.0;
    // final tripDistanceKm = distance.as(
    //   LengthUnit.Kilometer,
    //   pickup!,
    //   destination!,
    // );

    double? tripDistanceKm;
    LatLng? midPoint;

    // if (pickup != null && destination != null) {
    //   // tripDistanceKm = distance.as(LengthUnit.Kilometer, pickup, destination);

    //   midPoint = LatLng(
    //     (pickup.latitude + destination.latitude) / 2,
    //     (pickup.longitude + destination.longitude) / 2,
    //   );
    // }
    if (pickup != null && destination != null) {
      tripDistanceKm = routeDistance;

      final tripDuration = durationInMinutes;

      //_calculateDistanceKm(pickup, destination);
      midPoint = LatLng(
        (pickup.latitude + destination.latitude) / 2,
        (pickup.longitude + destination.longitude) / 2,
      );
    }
    if (rideConfirmed) {
      if (driver == null) {
        return const Center(child: Text('No driver linked'));
      }
    }
    if (midPoint != null) {
      midPoint = LatLng(
        (pickup!.latitude + destination!.latitude) / 2,
        (pickup.longitude + destination.longitude) / 2,
      );
    }

    return Scaffold(
      //appBar: AppBar(title: const Text("Amini Ride")),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        widget.pickup ??
                        _initialFallback, // fallback only on pickup just to avoid null
                    zoom: 12,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;

                    if (widget.destination != null) {
                      _initMap(widget.pickup!, widget.destination!);
                      //      _moveCameraToBounds(
                      //   pickup,
                      //   destination,
                      // );
                      _moveCameraToBounds(widget.pickup!, widget.destination!);
                    } else if (widget.pickup != null) {
                      // Move camera to just pickup location without destination
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          widget.pickup!,
                          14,
                        ), // adjust zoom as needed
                      );
                    }
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),

              if (routeDistance != null && durationInMinutes > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 6),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${pickupAddress ?? 'Pickup'} → ${destinationAddress ?? 'Destination'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${routeDistance!.toStringAsFixed(1)} km • ${durationInMinutes.toStringAsFixed(0)} min",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                // Navigate to search screen or open modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => WhereToScreen(
                          category: VehicleCategory.passenger,
                          initialPickupLocation: pickup ?? currentLocation,
                        ),
                  ),
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
                        dropAddressAsync.when(
                          data: (address) => address ?? 'Select Destination',
                          loading: () => 'Loading...',
                          error: (err, _) => 'Error',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (tripDistanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Distance: ${tripDistanceKm.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
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
                    Icon(Icons.search, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.destination != null)
            // NotificationListener<DraggableScrollableNotification>(
            //   onNotification: (notification) {
            //     final sheetExtent =
            //         notification.extent; // 0.25 to 0.8 for example
            //     // Map extent to 0-1 scrollFraction (or invert as needed)
            //     final scrollFraction =
            //         1 - ((sheetExtent - 0.25) / (0.8 - 0.25));
            //     // onDraggableScroll(scrollFraction);
            //     return true; // consume the notification
            //   },
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final sheetExtent = notification.extent; // 0.35 - 0.8
                final scrollFraction = (sheetExtent - 0.35) / (0.8 - 0.35);
                // 0 = sheet minimized, 1 = sheet fully expanded
                onDraggableScroll(scrollFraction);
                return true;
              },

              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.35,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  if (_scrollController.hasClients &&
                      _scrollController != scrollController) {
                    _scrollController = scrollController;
                  }

                  if (widget.pickup != null && widget.destination != null) {
                    _moveCameraToBounds(widget.pickup!, widget.destination!);
                  }

                  final validEstimates =
                      fareEstimates.where((e) => e != null).toList();

                  // final double minFare =
                  //     validEstimates.isNotEmpty
                  //         ? validEstimates
                  //             .map((e) => e!.fare)
                  //             .reduce((a, b) => a < b ? a : b)
                  //         : 0;

                  // final int minTime =
                  //     validEstimates.isNotEmpty
                  //         ? validEstimates
                  //             .map((e) => e!.timeEstimate)
                  //             .reduce((a, b) => a < b ? a : b)
                  //             .toInt()
                  //         : 0;

                  final availableCategories = <Map<String, dynamic>>[];

                  for (int i = 0; i < vehicleCategories.length; i++) {
                    final isAvailable =
                        driverAvailability.isNotEmpty && driverAvailability[i];

                    if (isAvailable) {
                      availableCategories.add({
                        "category": vehicleCategories[i],
                        "estimate": fareEstimates[i],
                        "index": i,
                      });
                    }
                  }

                  // compute min fare/time only from available categories
                  final double minFare =
                      availableCategories.isNotEmpty
                          ? availableCategories
                              .map(
                                (e) =>
                                    (e["estimate"] as FareEstimate?)?.fare ??
                                    double.infinity,
                              )
                              .reduce((a, b) => a < b ? a : b)
                          : 0;

                  final validTimes =
                      availableCategories
                          .map(
                            (e) =>
                                (e["estimate"] as FareEstimate?)?.timeEstimate,
                          )
                          .where((e) => e != null)
                          .cast<double>()
                          .toList();

                  final int minTime =
                      validTimes.isNotEmpty
                          ? validTimes.reduce((a, b) => a < b ? a : b).toInt()
                          : 0; // fallback if no estimates
                  //  : 0;

                  String selectedPayment = 'Cash';
                  double appBalance = 50;
                  bool hasVisaCard = false;

                  // final availableCategories = <Map<String, dynamic>>[];

                  // for (int i = 0; i < vehicleCategories.length; i++) {
                  //   final isAvailable =
                  //       driverAvailability.isNotEmpty && driverAvailability[i];

                  //   if (isAvailable) {
                  //     availableCategories.add({
                  //       "category": vehicleCategories[i],
                  //       "estimate": fareEstimates[i],
                  //       "index": i,
                  //     });
                  //   }
                  // }

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🚀 CATEGORY LIST
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(12),
                            //itemCount: vehicleCategories.length,
                            itemCount: availableCategories.length,

                            itemBuilder: (context, index) {
                              final item = availableCategories[index];
                              final category = item["category"];
                              final estimate = item["estimate"];
                              final originalIndex = item["index"];

                              final isSelected = selectedIndex == originalIndex;

                              // final category = vehicleCategories[index];
                              //final estimate = fareEstimates[index];

                              // final isSelected = selectedIndex == index;
                              final isAvailable =
                                  driverAvailability.isNotEmpty &&
                                  driverAvailability[index];

                              final isCheapest = estimate?.fare == minFare;
                              final isFastest =
                                  estimate?.timeEstimate == minTime;

                              final name = category.name;
                              final passengers = category.maxPassengers;

                              final timeAway =
                                  estimate != null
                                      ? "${estimate.timeEstimate.round()} min"
                                      : "--";

                              // ✅ DISCOUNT LOGIC (NO % SHOWN)
                              final hasDiscount = index == 0 || index == 2;
                              final originalFare = estimate?.fare ?? 0;
                              final discountedFare =
                                  hasDiscount
                                      ? originalFare * 0.85
                                      : originalFare;

                              final currency = estimate?.currency ?? "";

                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap:
                                        isAvailable
                                            ? () {
                                              setState(
                                                () => selectedIndex = index,
                                              );
                                              ref
                                                  .read(
                                                    selectedCategoryProvider
                                                        .notifier,
                                                  )
                                                  .state = category;
                                            }
                                            : null,
                                    child: Opacity(
                                      opacity: isAvailable ? 1 : 0.5,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Colors.blue,
                                                    width: 2.5,
                                                  )
                                                  : null,
                                        ),
                                        child: Row(
                                          children: [
                                            // 🚗 IMAGE
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child:
                                                  category.iconUrl != null &&
                                                          category
                                                              .iconUrl!
                                                              .isNotEmpty
                                                      ? Image.network(
                                                        "$ImageUrl${category.iconUrl}",
                                                        width: 60,
                                                        height: 60,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Image.asset(
                                                        'assets/imgs/Sedan2.png',
                                                        width: 60,
                                                        height: 60,
                                                      ),
                                            ),

                                            const SizedBox(width: 12),

                                            // 📊 DETAILS
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 🔥 NAME + PRICE
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),

                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              if (hasDiscount)
                                                                Text(
                                                                  "$currency ${originalFare.toStringAsFixed(0)}",
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough,
                                                                  ),
                                                                ),
                                                              if (hasDiscount)
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),

                                                              Text(
                                                                "$currency ${discountedFare.toStringAsFixed(0)}",
                                                                style: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 6),

                                                  // 🏷 BADGES
                                                  Row(
                                                    children: [
                                                      if (isCheapest)
                                                        _badge("Cheapest"),
                                                      if (isFastest)
                                                        _badge("Fastest"),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 6),

                                                  // ⏱ TIME + 👥 PASSENGERS
                                                  Row(
                                                    children: [
                                                      Text(
                                                        timeAway,
                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        "$passengers seats",
                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  if (!isAvailable)
                                                    const Text(
                                                      "No drivers nearby",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 🔥 DIVIDER BETWEEN CARDS
                                  Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 50,

                                // elevation: 12, // creates shadow separation
                                //color: Colors.white., // solid background
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                  //foreground: Color.white
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedPayment,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                      items:
                                          ['Cash', 'Visa', 'AMiNi'].map((
                                            method,
                                          ) {
                                            Icon methodIcon;
                                            switch (method) {
                                              case 'Cash':
                                                methodIcon = const Icon(
                                                  Icons.money,
                                                  size: 18,
                                                );
                                                break;
                                              case 'Visa':
                                                methodIcon = const Icon(
                                                  Icons.credit_card,
                                                  size: 18,
                                                );
                                                break;
                                              case 'AMiNi':
                                                methodIcon = const Icon(
                                                  Icons.account_balance_wallet,
                                                  size: 18,
                                                );
                                                break;
                                              default:
                                                methodIcon = const Icon(
                                                  Icons.payment,
                                                  size: 18,
                                                );
                                            }
                                            return DropdownMenuItem<String>(
                                              value: method,
                                              child: Row(
                                                children: [
                                                  methodIcon,
                                                  const SizedBox(
                                                    width: 2,
                                                  ), // reduce spacing
                                                  Text(
                                                    method,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        if (value != null)
                                          setState(
                                            () => selectedPayment = value,
                                          );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6), // small spacing
                              // 🔹 Expanded Select/Book Button
                              Consumer(
                                builder: (context, ref, child) {
                                  final selected = ref.watch(
                                    selectedCategoryProvider,
                                  );
                                  final category = selected?.name ?? 'N/A';
                                  final categoryId = selected?.id ?? 0;
                                  final isEnabled =
                                      category.toString().isNotEmpty;

                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          isEnabled
                                              ? () {
                                                // Payment validations
                                                if (selectedPayment ==
                                                        'AMiNi' &&
                                                    appBalance < selectedFare) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          _,
                                                        ) => const AlertDialog(
                                                          title: Text(
                                                            'Insufficient Balance',
                                                          ),
                                                          content: Text(
                                                            'You do not have enough funds in your AMiNi wallet. Please top up.',
                                                          ),
                                                        ),
                                                  );
                                                  return;
                                                }

                                                if (selectedPayment == 'Visa' &&
                                                    !hasVisaCard) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          _,
                                                        ) => const AlertDialog(
                                                          title: Text(
                                                            'No Visa Card Added',
                                                          ),
                                                          content: Text(
                                                            'You have not added a Visa card. Please add one to continue.',
                                                          ),
                                                        ),
                                                  );
                                                  return;
                                                }

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          _,
                                                        ) => ConfirmRideScreen(
                                                          pickup:
                                                              widget.pickup!,
                                                          fare: selectedFare,
                                                          destination:
                                                              widget
                                                                  .destination!,
                                                          category: categoryId,
                                                          optionSelected:
                                                              category,
                                                          isScheduled:
                                                              widget
                                                                  .isScheduled,
                                                          scheduledDate:
                                                              widget
                                                                  .scheduledDate,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        (widget.isScheduled == true &&
                                                isEnabled)
                                            ? "Book $category"
                                            : "Select ${category ?? 'Category'}",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // double _calculateDistanceKm(LatLng start, LatLng end) {
  //   const double R = 6371; // Earth radius in KM
  //   final dLat = _deg2rad(end.latitude - start.latitude);
  //   final dLon = _deg2rad(end.longitude - start.longitude);
  //   final a =
  //       (sin(dLat / 2) * sin(dLat / 2)) +
  //       cos(_deg2rad(start.latitude)) *
  //           cos(_deg2rad(end.latitude)) *
  //           (sin(dLon / 2) * sin(dLon / 2));
  //   final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  //   return R * c;
  // }

  double _deg2rad(double deg) => deg * (pi / 180);

  void _moveCameraToBounds(LatLng pickup, LatLng destination) {
    final southwest = LatLng(
      min(pickup.latitude, destination.latitude),
      min(pickup.longitude, destination.longitude),
    );
    final northeast = LatLng(
      max(pickup.latitude, destination.latitude),
      max(pickup.longitude, destination.longitude),
    );

    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    ); // padding of 100
  }

  double _initialZoom = 14.0; // your fixed zoom
  LatLngBounds? _bounds;

  void _initMap(LatLng pickup, LatLng destination) async {
    if (_mapController == null) return;

    // Calculate bounds with small horizontal padding to keep from/to fully visible horizontally
    final bounds = LatLngBounds(
      southwest: LatLng(
        min(pickup.latitude, destination.latitude),
        min(pickup.longitude, destination.longitude),
      ),
      northeast: LatLng(
        max(pickup.latitude, destination.latitude),
        max(pickup.longitude, destination.longitude),
      ),
    );

    _bounds = bounds;

    // Move camera to show bounds with fixed padding once
    await _mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds, 50));

    // Fix zoom level
    await _mapController!.moveCamera(CameraUpdate.zoomTo(_initialZoom));
  }

  // Call this during map created event or after pickup/destination set
  //_initMap(pickup, destination);

  // // When draggable sheet scrolls
  // void onDraggableScroll(double scrollFraction) {
  //   if (_mapController == null || _bounds == null) return;

  //   // scrollFraction: 0 = fully expanded sheet, 1 = minimized sheet (you can invert as needed)

  //   // Calculate how much to pan vertically on the map in pixels (experiment with this)
  //   final screenHeight = MediaQuery.of(context).size.height;

  //   // dy in pixels; positive = pan map down (so markers appear to move up)
  //   final dy = screenHeight * (scrollFraction - 0.5); // tweak multiplier

  //   _mapController!.animateCamera(CameraUpdate.scrollBy(0, dy));
  // }

  double _lastScrollFraction = 0;

  void onDraggableScroll(double scrollFraction) {
    if (_mapController == null || _bounds == null) return;

    // Only update if fraction changes meaningfully
    if ((_lastScrollFraction - scrollFraction).abs() < 0.01) return;
    _lastScrollFraction = scrollFraction;

    // Map visible area adjusts with bottom sheet
    // fraction = 0 minimized, 1 fully expanded
    final bottomPadding =
        100 + 250 * scrollFraction; // tweak 250 to sheet height range

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(_bounds!, bottomPadding),
    );
  }

  Widget _badge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue, // ⬅️ blue background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white, // ⬅️ white text
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


                        // 🔹 Payment method dropdown with wallet icon, white background
                        // Container(
                        //   // padding: const EdgeInsets.symmetric(
                        //   //   horizontal: 8,
                        //   //   vertical: 4,
                        //   // ),
                        //   width: 90, // small width
                        //   height: 60, // adjust height if needed
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 4,
                        //   ),

                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(8),
                        //     border: Border.all(
                        //       color: Colors.grey.shade300,
                        //     ),
                        //   ),
                        //   child: DropdownButtonHideUnderline(
                        //     child: DropdownButton<String>(
                        //       value: selectedPayment,
                        //       isExpanded: true,
                        //       icon: const Icon(
                        //         Icons.arrow_drop_down,
                        //         size: 20,
                        //       ),
                        //       items:
                        //           ['Cash', 'Visa', 'AMiNi'].map((method) {
                        //             Icon methodIcon;
                        //             switch (method) {
                        //               case 'Cash':
                        //                 methodIcon = const Icon(
                        //                   Icons.money,
                        //                   size: 18,
                        //                 );
                        //                 break;
                        //               case 'Visa':
                        //                 methodIcon = const Icon(
                        //                   Icons.credit_card,
                        //                   size: 18,
                        //                 );
                        //                 break;
                        //               case 'AMiNi':
                        //                 methodIcon = const Icon(
                        //                   Icons.account_balance_wallet,
                        //                   size: 18,
                        //                 );
                        //                 break;
                        //               default:
                        //                 methodIcon = const Icon(
                        //                   Icons.payment,
                        //                   size: 18,
                        //                 );
                        //             }
                        //             return DropdownMenuItem<String>(
                        //               value: method,
                        //               child: Row(
                        //                 children: [
                        //                   methodIcon,
                        //                   const SizedBox(width: 6),
                        //                   Text(
                        //                     method,
                        //                     style: TextStyle(
                        //                       fontWeight:
                        //                           selectedPayment ==
                        //                                   method
                        //                               ? FontWeight.bold
                        //                               : FontWeight.normal,
                        //                       color: Colors.black87,
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //             );
                        //           }).toList(),
                        //       onChanged: (value) {
                        //         if (value != null)
                        //           setState(() => selectedPayment = value);
                        //       },
                        //     ),
                        //   ),
                        // ),
  // Widget _badge(String text, Color color) {
  //   return Container(
  //     margin: const EdgeInsets.only(right: 6, top: 4),
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Text(
  //       text,
  //       style: TextStyle(
  //         color: color,
  //         fontSize: 10,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //   );
  // }

  // decoration: BoxDecoration(
  //   color:
  //       isSelected
  //           ? Colors.orange.shade50
  //           : Colors
  //               .white, //Colors.grey.shade100,
  //   borderRadius: BorderRadius.circular(16),
  //   border: Border.all(
  //     color:
  //         isSelected
  //             ? Colors.orange
  //             : Colors
  //                 .grey
  //                 .shade500, //Colors.grey.shade300,
  //     width: isSelected ? 2 : 1,
  //   ),
  //   boxShadow:
  //       isSelected
  //           ? [
  //             const BoxShadow(
  //               color: Colors.black12,
  //               blurRadius: 6,
  //               offset: Offset(0, 2),
  //             ),
  //           ]
  //           : [],
  // ),

  // Widget _buildSkeleton() {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     padding: const EdgeInsets.all(10),
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade200,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(width: 60, height: 60, color: Colors.grey.shade300),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             children: [
  //               Container(height: 12, color: Colors.grey.shade300),
  //               const SizedBox(height: 6),
  //               Container(height: 10, color: Colors.grey.shade300),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
//}

 // 💳 PAYMENT METHOD (ABOVE BUTTON)
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 12,
                        //     vertical: 8,
                        //   ),
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       // 🔹 Wallet icon only, white background
                        //       Container(
                        //         padding: const EdgeInsets.all(6),
                        //         decoration: BoxDecoration(
                        //           color: Colors.white,
                        //           borderRadius: BorderRadius.circular(8),
                        //           border: Border.all(
                        //             color: Colors.grey.shade300,
                        //           ),
                        //         ),
                        //         child: const Icon(
                        //           Icons.account_balance_wallet,
                        //           size: 20,
                        //           color: Colors.blue,
                        //         ),
                        //       ),

                        //       const SizedBox(
                        //         height: 6,
                        //       ), // small spacing between icon and button
                        //       // 🔹 Expanded Select/Book Button
                        //       Consumer(
                        //         builder: (context, ref, child) {
                        //           final selected = ref.watch(
                        //             selectedCategoryProvider,
                        //           );
                        //           final category = selected?.name ?? 'N/A';
                        //           final categoryId = selected?.id ?? 0;
                        //           final isEnabled =
                        //               category.toString().isNotEmpty;

                        //           return SizedBox(
                        //             width: double.infinity,
                        //             child: ElevatedButton(
                        //               onPressed:
                        //                   isEnabled
                        //                       ? () {
                        //                         // Payment validations
                        //                         if (selectedPayment ==
                        //                                 'AMiNi' &&
                        //                             appBalance < selectedFare) {
                        //                           showDialog(
                        //                             context: context,
                        //                             builder:
                        //                                 (
                        //                                   _,
                        //                                 ) => const AlertDialog(
                        //                                   title: Text(
                        //                                     'Insufficient Balance',
                        //                                   ),
                        //                                   content: Text(
                        //                                     'You do not have enough funds in your AMiNi wallet. Please top up.',
                        //                                   ),
                        //                                 ),
                        //                           );
                        //                           return;
                        //                         }

                        //                         if (selectedPayment == 'Visa' &&
                        //                             !hasVisaCard) {
                        //                           showDialog(
                        //                             context: context,
                        //                             builder:
                        //                                 (
                        //                                   _,
                        //                                 ) => const AlertDialog(
                        //                                   title: Text(
                        //                                     'No Visa Card Added',
                        //                                   ),
                        //                                   content: Text(
                        //                                     'You have not added a Visa card. Please add one to continue.',
                        //                                   ),
                        //                                 ),
                        //                           );
                        //                           return;
                        //                         }

                        //                         Navigator.push(
                        //                           context,
                        //                           MaterialPageRoute(
                        //                             builder:
                        //                                 (
                        //                                   _,
                        //                                 ) => ConfirmRideScreen(
                        //                                   pickup:
                        //                                       widget.pickup!,
                        //                                   fare: selectedFare,
                        //                                   destination:
                        //                                       widget
                        //                                           .destination!,
                        //                                   category: categoryId,
                        //                                   optionSelected:
                        //                                       category,
                        //                                   isScheduled:
                        //                                       widget
                        //                                           .isScheduled,
                        //                                   scheduledDate:
                        //                                       widget
                        //                                           .scheduledDate,
                        //                                 ),
                        //                           ),
                        //                         );
                        //                       }
                        //                       : null,
                        //               style: ElevatedButton.styleFrom(
                        //                 backgroundColor: Colors.blue,
                        //                 padding: const EdgeInsets.symmetric(
                        //                   vertical: 16,
                        //                 ),
                        //                 shape: RoundedRectangleBorder(
                        //                   borderRadius: BorderRadius.circular(
                        //                     12,
                        //                   ),
                        //                 ),
                        //               ),
                        //               child: Text(
                        //                 (widget.isScheduled == true &&
                        //                         isEnabled)
                        //                     ? "Book $category"
                        //                     : "Select ${category ?? 'Category'}",
                        //                 style: const TextStyle(
                        //                   fontSize: 16,
                        //                   color: Colors.white,
                        //                 ),
                        //               ),
                        //             ),
                        //           );
                        //         },
                        //       ),
                        //     ],
                        //   ),

// Future<void> _fetchRoute() async {
  //   final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
  //   final destination =
  //       '${widget.destination!.latitude},${widget.destination!.longitude}';
  //   final apiKey = mapKey; // Your Google Maps API Key

  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
  //   );

  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);

  //     if (data['status'] == 'OK') {
  //       final route = data['routes'][0];
  //       final leg = route['legs'][0];

  //       final overviewPolyline = route['overview_polyline']['points'];
  //       final points = _decodePolyline(overviewPolyline);

  //       setState(() {
  //         routePoints = points;
  //         routeDistance = leg['distance']['value'] / 1000.0; // meters to km
  //         durationInMinutes = (leg['duration']['value'] / 60).round();

  //         polylines = {
  //           Polyline(
  //             polylineId: const PolylineId('route'),
  //             color: Colors.blue,
  //             width: 5,
  //             points: routePoints,
  //           ),
  //         };
  //       });

  //       // Move camera to show both points + route
  //       if (_mapController != null) {
  //         _moveCameraToBounds(widget.pickup!, widget.destination!);
  //       }
  //     } else {
  //       print('Google Directions API error: ${data['status']}');
  //     }
  //   } else {
  //     print('Failed to fetch directions. Status: ${response.statusCode}');
  //   }
  // }
  // Future<void> _fetchRoute() async {
  //   final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
  //   final destination =
  //       '${widget.destination!.latitude},${widget.destination!.longitude}';
  //   final apiKey = mapKey;

  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/directions/json'
  //     '?origin=$origin&destination=$destination&key=$apiKey',
  //   );

  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);

  //     if (data['status'] == 'OK') {
  //       final route = data['routes'][0];
  //       final leg = route['legs'][0];

  //       final overviewPolyline = route['overview_polyline']['points'];
  //       final points = _decodePolyline(overviewPolyline);

  //       final double distanceKm = leg['distance']['value'] / 1000.0;
  //       final double durationMinutes = leg['duration']['value'] / 60.0;

  //       // Get route midpoint for info marker
  //       LatLng? midPoint;
  //       if (points.isNotEmpty) {
  //         final midIndex = (points.length / 2).floor();
  //         midPoint = LatLng(
  //           points[midIndex].latitude,
  //           points[midIndex].longitude,
  //         );
  //       }

  //       // Resolve addresses
  //       pickupAddress = await _getPlaceName(widget.pickup!);
  //       destinationAddress = await _getPlaceName(widget.destination!);
  //       if (!mounted) return;
  //       setState(() {
  //         routePoints = points;
  //         routeDistance = distanceKm;
  //         this.durationInMinutes = durationMinutes;

  //         /// ✅ Update polylines
  //         polylines = {
  //           Polyline(
  //             polylineId: const PolylineId('route'),
  //             color: Colors.blue,
  //             width: 5,
  //             points: routePoints,
  //           ),
  //         };

  //         /// ✅ Update markers
  //         _markers
  //           ..clear()
  //           ..add(
  //             Marker(
  //               markerId: const MarkerId('pickup'),
  //               position: widget.pickup!,
  //               icon: BitmapDescriptor.defaultMarkerWithHue(
  //                 BitmapDescriptor.hueGreen,
  //               ),
  //               infoWindow: InfoWindow(title: pickupAddress ?? "Pickup"),
  //             ),
  //           )
  //           ..add(
  //             Marker(
  //               markerId: const MarkerId('destination'),
  //               position: widget.destination!,
  //               icon: BitmapDescriptor.defaultMarkerWithHue(
  //                 BitmapDescriptor.hueRed,
  //               ),
  //               infoWindow: InfoWindow(
  //                 title: destinationAddress ?? "Destination",
  //               ),
  //             ),
  //           );

  //         // ✅ Distance & duration marker at center
  //         if (midPoint != null) {
  //           _markers.add(
  //             Marker(
  //               markerId: const MarkerId('route_center'),
  //               position: midPoint,
  //               icon: BitmapDescriptor.defaultMarkerWithHue(
  //                 BitmapDescriptor.hueBlue,
  //               ),
  //               infoWindow: InfoWindow(
  //                 title: "${distanceKm.toStringAsFixed(1)} km",
  //                 snippet: "${durationMinutes.toStringAsFixed(0)} min",
  //               ),
  //             ),
  //           );
  //         }
  //       });

  //       // Fetch fares per category
  //       for (int i = 0; i < vehicleCategories.length; i++) {
  //         final category = vehicleCategories[i];
  //         try {
  //           final estimate = await FareService.getFareEstimate(
  //             categoryId: category.id,
  //             pickupLat: widget.pickup!.latitude,
  //             pickupLng: widget.pickup!.longitude,
  //             destLat: widget.destination!.latitude,
  //             destLng: widget.destination!.longitude,
  //             distanceKm: distanceKm,
  //             durationMinutes: durationMinutes,
  //             waitingMinutes: 0,
  //             countryCode: "KE",
  //           );

  //           if (!mounted) return;
  //           setState(() {
  //             fareEstimates[i] = estimate;
  //           });
  //         } catch (e) {
  //           print('❌ Failed to load fare for ${category.name}: $e');

  //           if (!mounted) return;
  //           setState(() {
  //             fareEstimates[i] = FareEstimate(
  //               fare: 0,
  //               currency: "KES",
  //               timeEstimate: durationMinutes,
  //               categoryName: category.name,
  //               distanceKm: distanceKm,
  //             );
  //           });
  //         }
  //       }

  //       // Move camera to fit route
  //       if (_mapController != null) {
  //         _moveCameraToBounds(widget.pickup!, widget.destination!);
  //       }
  //     } else {
  //       print('Google Directions API error: ${data['status']}');
  //     }
  //   } else {
  //     print('Failed to fetch directions. Status: ${response.statusCode}');
  //   }
  // }




// import 'dart:convert';
// import 'dart:math';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
// import 'package:niceapp/View/Screens/Other_Screens/visa_screen.dart';
// import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';
// import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
// import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
// import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';
// import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // as gmaps;

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
//   Set<Marker> _markers = {};
//   List<VehicleSubCategory> vehicleCategories = [];
//   List<FareEstimate?> fareEstimates = [];
//   bool isLoadingCategories = true;
//   int selectedIndex = -1;
//   LatLng? currentLocation;
//   String? pickupAddress;
//   String? destinationAddress;
//   //LatLng? pickup;
//   List<LatLng> routePoints = [];
//   double? routeDistance;
//   double durationInMinutes = 0;
//   bool isSwiped = false;
//   LatLng _initialFallback = const LatLng(-1.286389, 36.817223);
//   //GoogleMapController? mapController;
//   //late ScrollController _scrollController;
//   GoogleMapController? _mapController;
//   Set<Marker> markers = {};
//   Set<Polyline> polylines = {};
//   double _mapOffsetY = 0;
//   final double maxUpOffset = -150; // adjust as needed
//   late ScrollController _scrollController = ScrollController();
//   List<bool> driverAvailability = [];

//   @override
//   void initState() {
//     super.initState();
//     //_getCurrentLocation();
//     //_setCurrentLocation();

//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId != null) {
//       canStartRide(userId).then((allowed) {
//         if (!allowed) {
//           _listenToActiveRide(userId);
//         }
//       });
//     }
//     ////working
//     // if (widget.destination != null) {
//     //   fetchVehicleSubCategoriesByType(widget.category.index).then((
//     //     categories,
//     //   ) async {
//     //     setState(() {
//     //       vehicleCategories = categories;
//     //       fareEstimates = List<FareEstimate?>.filled(categories.length, null);
//     //       isLoadingCategories = false;

//     //       if (categories.isNotEmpty) {
//     //         selectedIndex = 0;
//     //         ref.read(selectedCategoryProvider.notifier).state = categories[0];
//     //       }
//     //     });
//     //     if (widget.pickup != null && widget.destination != null) {
//     //       await _fetchRoute();
//     //       //for (int i = 0; i < categories.length; i++) {
//     //       // final category = categories[i];
//     //       // try {
//     //       //   final estimate = await FareService.getFareEstimate(
//     //       //     categoryId: category.id,
//     //       //     pickupLat: widget.pickup!.latitude,
//     //       //     pickupLng: widget.pickup!.longitude,
//     //       //     destLat: widget.destination!.latitude,
//     //       //     destLng: widget.destination!.longitude,
//     //       //     distanceKm: ,
//     //       //     countryCode: "KE",
//     //       //   );
//     //       //   print('Received estimate for ${category.name}: $estimate');
//     //       //   setState(() {
//     //       //     fareEstimates[i] = estimate;
//     //       //   });
//     //       // } catch (e) {
//     //       //   print('Failed to load fare for category ${category.name}: $e');
//     //       // }
//     //       // }
//     //     }
//     //   });
//     //   _setupMarkers();
//     //   // _fetchRoute();

//     if (widget.destination != null) {
//       fetchVehicleSubCategoriesByType(widget.category.index).then((
//         categories,
//       ) async {
//         // Extract availability info directly from backend
//         List<bool> availabilityList =
//             categories.map((category) => category.isAvailable).toList();

//         setState(() {
//           vehicleCategories = categories;
//           fareEstimates = List<FareEstimate?>.filled(categories.length, null);
//           isLoadingCategories = false;
//           driverAvailability = availabilityList;

//           if (categories.isNotEmpty) {
//             selectedIndex = 0;
//             ref.read(selectedCategoryProvider.notifier).state = categories[0];
//           }
//         });

//         if (widget.pickup != null && widget.destination != null) {
//           await _fetchRoute();
//         }
//       });

//       _setupMarkers();
//     }

//     // _scrollController = ScrollController();

//     // Add scroll listener to update map camera when the sheet scrolls

//     _scrollController.addListener(() {
//       final offset = _scrollController.offset;

//       // Map moves up as offset grows, but clamp so it never moves beyond maxUpOffset
//       final newMapOffset = (-offset).clamp(maxUpOffset, 0).toDouble();

//       setState(() {
//         _mapOffsetY = newMapOffset;
//       });
//     });
//     // canStartRide();
//     // _scrollController.addListener(() {
//     //   if (widget.pickup != null && widget.destination != null) {
//     //     _moveCameraToBounds(context, widget.pickup!, widget.destination!);
//     //   } else if (widget.pickup != null) {
//     //     _mapController?.animateCamera(
//     //       CameraUpdate.newLatLngZoom(widget.pickup!, 14),
//     //     );
//     //   }
//     // });
//     // WidgetsBinding.instance.addPostFrameCallback((_) {
//     //   // Optional post-frame logic
//     // });
//   }

//   Future<bool> checkDriverAvailability(int categoryId) async {
//     final uri = Uri.parse(
//       '$baseUrl/drivers/availability?categoryId=$categoryId',
//     );
//     final response = await http.get(uri);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['available'] ?? false;
//     } else {
//       return false;
//     }
//   }

//   bool _isRideScreenOpen = false;

//   // void _listenToActiveRide(String userId) {
//   //   final ridesRef = FirebaseDatabase.instance.ref("rides");

//   //   ridesRef.orderByChild("riderId").equalTo(userId).onValue.listen((event) {
//   //     if (!event.snapshot.exists) return;

//   //     final rides = Map<String, dynamic>.from(
//   //       event.snapshot.value as Map<dynamic, dynamic>,
//   //     );

//   //     // Find all active rides
//   //     final activeRides =
//   //         rides.entries.where((entry) {
//   //           final status = entry.value['status']?.toString();
//   //           return status == 'assigned' || status == 'in-progress';
//   //         }).toList();

//   //     if (activeRides.isEmpty) {
//   //       // 🚪 No active rides → close if screen open
//   //       if (_isRideScreenOpen) {
//   //         Navigator.of(context).pop();
//   //         _isRideScreenOpen = false;
//   //       }
//   //       return;
//   //     }

//   //     // 🚀 Always take the last active ride
//   //     final activeRide = activeRides.last;
//   //     final rideData = Map<String, dynamic>.from(activeRide.value);
//   //     final rideId = rideData['rideId'] ?? activeRide.key;

//   //     if (!_isRideScreenOpen) {
//   //       _isRideScreenOpen = true;

//   //       Navigator.of(context)
//   //           .push(
//   //             MaterialPageRoute(
//   //               builder: (_) => RideInProgressLiveScreen(rideId: rideId),
//   //             ),
//   //           )
//   //           .then((_) {
//   //             // Reset when screen is popped
//   //             _isRideScreenOpen = false;
//   //           });
//   //     }
//   //   });
//   // }
//   bool _hasActiveRide = false;

//   void _listenToActiveRide(String userId) {
//     final ridesRef = FirebaseDatabase.instance.ref("rides");

//     ridesRef.orderByChild("riderId").equalTo(userId).onValue.listen((event) {
//       if (!event.snapshot.exists) {
//         _hasActiveRide = false;
//         return;
//       }

//       final rides = Map<String, dynamic>.from(
//         event.snapshot.value as Map<dynamic, dynamic>,
//       );

//       // Find all active rides
//       final activeRides =
//           rides.entries.where((entry) {
//             final status = entry.value['status']?.toString();
//             return status == 'assigned' || status == 'in-progress';
//           }).toList();

//       if (activeRides.isEmpty) {
//         // ✅ No active rides
//         _hasActiveRide = false;
//         return;
//       }

//       // ✅ At least one active ride → block new booking
//       _hasActiveRide = true;
//     });
//   }

//   Future<bool> canStartRide(String userId) async {
//     final snap =
//         await FirebaseDatabase.instance
//             .ref("rides")
//             .orderByChild("riderId")
//             .equalTo(userId)
//             .get();

//     if (snap.exists) {
//       final rides = snap.value as Map;
//       return !rides.values.any(
//         (ride) =>
//             ride['status'] == 'assigned' || ride['status'] == 'in-progress',
//       );
//     }
//     return true; // no rides → allow
//   }

//   // Future<bool> driverHasActiveRide(String driverId) async {
//   //   final snap =
//   //       await passengerDb
//   //           .ref("rides")
//   //           .orderByChild("driverId")
//   //           .equalTo(driverId)
//   //           .get();

//   //   if (!snap.exists) return false;

//   //   final rides = (snap.value as Map).values;
//   //   return rides.any(
//   //     (ride) => ride['status'] == 'assigned' || ride['status'] == 'in-progress',
//   //   );
//   // }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _setupMarkers() {
//     markers = {
//       Marker(
//         markerId: const MarkerId('pickup'),
//         position: widget.pickup!,
//         infoWindow: const InfoWindow(title: 'Pickup'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ),
//       Marker(
//         markerId: const MarkerId('destination'),
//         position: widget.destination!,
//         infoWindow: const InfoWindow(title: 'Destination'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ),
//     };
//   }

//   // Future<void> _fetchRoute() async {
//   //   final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
//   //   final destination =
//   //       '${widget.destination!.latitude},${widget.destination!.longitude}';
//   //   final apiKey = mapKey; // Your Google Maps API Key

//   //   final url = Uri.parse(
//   //     'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
//   //   );

//   //   final response = await http.get(url);

//   //   if (response.statusCode == 200) {
//   //     final data = jsonDecode(response.body);

//   //     if (data['status'] == 'OK') {
//   //       final route = data['routes'][0];
//   //       final leg = route['legs'][0];

//   //       final overviewPolyline = route['overview_polyline']['points'];
//   //       final points = _decodePolyline(overviewPolyline);

//   //       setState(() {
//   //         routePoints = points;
//   //         routeDistance = leg['distance']['value'] / 1000.0; // meters to km
//   //         durationInMinutes = (leg['duration']['value'] / 60).round();

//   //         polylines = {
//   //           Polyline(
//   //             polylineId: const PolylineId('route'),
//   //             color: Colors.blue,
//   //             width: 5,
//   //             points: routePoints,
//   //           ),
//   //         };
//   //       });

//   //       // Move camera to show both points + route
//   //       if (_mapController != null) {
//   //         _moveCameraToBounds(widget.pickup!, widget.destination!);
//   //       }
//   //     } else {
//   //       print('Google Directions API error: ${data['status']}');
//   //     }
//   //   } else {
//   //     print('Failed to fetch directions. Status: ${response.statusCode}');
//   //   }
//   // }

//   Future<String> _getPlaceName(LatLng position) async {
//     final apiKey = mapKey; // Google API key
//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey',
//     );

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'OK' && data['results'].isNotEmpty) {
//         return data['results'][0]['formatted_address'];
//       }
//     }
//     return "Unknown location";
//   }

//   Future<void> _fetchRoute() async {
//     final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
//     final destination =
//         '${widget.destination!.latitude},${widget.destination!.longitude}';
//     final apiKey = mapKey;

//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/directions/json'
//       '?origin=$origin&destination=$destination&key=$apiKey',
//     );

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       if (data['status'] == 'OK') {
//         final route = data['routes'][0];
//         final leg = route['legs'][0];

//         final overviewPolyline = route['overview_polyline']['points'];
//         final points = _decodePolyline(overviewPolyline);

//         final double distanceKm = leg['distance']['value'] / 1000.0;
//         final double durationMinutes = leg['duration']['value'] / 60.0;

//         // Get route midpoint for info marker
//         LatLng? midPoint;
//         if (points.isNotEmpty) {
//           final midIndex = (points.length / 2).floor();
//           midPoint = LatLng(
//             points[midIndex].latitude,
//             points[midIndex].longitude,
//           );
//         }

//         // Resolve addresses
//         pickupAddress = await _getPlaceName(widget.pickup!);
//         destinationAddress = await _getPlaceName(widget.destination!);
//         if (!mounted) return;
//         setState(() {
//           routePoints = points;
//           routeDistance = distanceKm;
//           this.durationInMinutes = durationMinutes;

//           /// ✅ Update polylines
//           polylines = {
//             Polyline(
//               polylineId: const PolylineId('route'),
//               color: Colors.blue,
//               width: 5,
//               points: routePoints,
//             ),
//           };

//           /// ✅ Update markers
//           _markers
//             ..clear()
//             ..add(
//               Marker(
//                 markerId: const MarkerId('pickup'),
//                 position: widget.pickup!,
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueGreen,
//                 ),
//                 infoWindow: InfoWindow(title: pickupAddress ?? "Pickup"),
//               ),
//             )
//             ..add(
//               Marker(
//                 markerId: const MarkerId('destination'),
//                 position: widget.destination!,
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueRed,
//                 ),
//                 infoWindow: InfoWindow(
//                   title: destinationAddress ?? "Destination",
//                 ),
//               ),
//             );

//           // ✅ Distance & duration marker at center
//           if (midPoint != null) {
//             _markers.add(
//               Marker(
//                 markerId: const MarkerId('route_center'),
//                 position: midPoint,
//                 icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue,
//                 ),
//                 infoWindow: InfoWindow(
//                   title: "${distanceKm.toStringAsFixed(1)} km",
//                   snippet: "${durationMinutes.toStringAsFixed(0)} min",
//                 ),
//               ),
//             );
//           }
//         });

//         // Fetch fares per category
//         for (int i = 0; i < vehicleCategories.length; i++) {
//           final category = vehicleCategories[i];
//           try {
//             final estimate = await FareService.getFareEstimate(
//               categoryId: category.id,
//               pickupLat: widget.pickup!.latitude,
//               pickupLng: widget.pickup!.longitude,
//               destLat: widget.destination!.latitude,
//               destLng: widget.destination!.longitude,
//               distanceKm: distanceKm,
//               durationMinutes: durationMinutes,
//               waitingMinutes: 0,
//               countryCode: "KE",
//             );

//             if (!mounted) return;
//             setState(() {
//               fareEstimates[i] = estimate;
//             });
//           } catch (e) {
//             print('❌ Failed to load fare for ${category.name}: $e');

//             if (!mounted) return;
//             setState(() {
//               fareEstimates[i] = FareEstimate(
//                 fare: 0,
//                 currency: "KES",
//                 timeEstimate: durationMinutes,
//                 categoryName: category.name,
//                 distanceKm: distanceKm,
//               );
//             });
//           }
//         }

//         // Move camera to fit route
//         if (_mapController != null) {
//           _moveCameraToBounds(widget.pickup!, widget.destination!);
//         }
//       } else {
//         print('Google Directions API error: ${data['status']}');
//       }
//     } else {
//       print('Failed to fetch directions. Status: ${response.statusCode}');
//     }
//   }

//   // Helper method to calculate midpoint
//   LatLng _getMidPoint(LatLng p1, LatLng p2) {
//     final midLat = (p1.latitude + p2.latitude) / 2;
//     final midLng = (p1.longitude + p2.longitude) / 2;
//     return LatLng(midLat, midLng);
//   }

//   // Decode encoded polyline from Google Directions API
//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> poly = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lng += dlng;

//       poly.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return poly;
//   }

//   Future<void> _setCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       await Geolocator.openLocationSettings();
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return;
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     if (!mounted) return;
//     setState(() {
//       currentLocation = LatLng(position.latitude, position.longitude);
//     });
//   }

//   void _navigateToWhereTo() {
//     if (_hasActiveRide) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "You already have an active ride. Complete or cancel it before booking a new one.",
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return; // ❌ Prevent booking
//     }

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
//   }

//   @override
//   Widget build(BuildContext context) {
//     final driver = ref.watch(linkedDriverProvider);
//     final rideConfirmed = ref.watch(rideConfirmedProvider);

//     //final pickup = widget.pickup;
//     final pickup = widget.pickup ?? currentLocation;
//     final destination = widget.destination;
//     final dropAddressAsync = ref.watch(dropAddressProvider);

//     //final distance = Distance();
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

//     // if (pickup != null && destination != null) {
//     //   // tripDistanceKm = distance.as(LengthUnit.Kilometer, pickup, destination);

//     //   midPoint = LatLng(
//     //     (pickup.latitude + destination.latitude) / 2,
//     //     (pickup.longitude + destination.longitude) / 2,
//     //   );
//     // }
//     if (pickup != null && destination != null) {
//       tripDistanceKm = routeDistance;

//       final tripDuration = durationInMinutes;

//       //_calculateDistanceKm(pickup, destination);
//       midPoint = LatLng(
//         (pickup.latitude + destination.latitude) / 2,
//         (pickup.longitude + destination.longitude) / 2,
//       );
//     }
//     if (rideConfirmed) {
//       if (driver == null) {
//         return const Center(child: Text('No driver linked'));
//       }
//     }
//     if (midPoint != null) {
//       midPoint = LatLng(
//         (pickup!.latitude + destination!.latitude) / 2,
//         (pickup.longitude + destination.longitude) / 2,
//       );
//     }

//     return Scaffold(
//       //appBar: AppBar(title: const Text("Amini Ride")),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: GoogleMap(
//                   initialCameraPosition: CameraPosition(
//                     target:
//                         widget.pickup ??
//                         _initialFallback, // fallback only on pickup just to avoid null
//                     zoom: 12,
//                   ),
//                   markers: markers,
//                   polylines: polylines,
//                   onMapCreated: (controller) {
//                     _mapController = controller;

//                     if (widget.destination != null) {
//                       _initMap(widget.pickup!, widget.destination!);
//                       //      _moveCameraToBounds(
//                       //   pickup,
//                       //   destination,
//                       // );
//                       _moveCameraToBounds(widget.pickup!, widget.destination!);
//                     } else if (widget.pickup != null) {
//                       // Move camera to just pickup location without destination
//                       _mapController?.animateCamera(
//                         CameraUpdate.newLatLngZoom(
//                           widget.pickup!,
//                           14,
//                         ), // adjust zoom as needed
//                       );
//                     }
//                   },
//                   myLocationEnabled: false,
//                   myLocationButtonEnabled: false,
//                 ),
//               ),

//               if (routeDistance != null && durationInMinutes > 0)
//                 Center(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black87,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: const [
//                         BoxShadow(color: Colors.black38, blurRadius: 6),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           "${pickupAddress ?? 'Pickup'} → ${destinationAddress ?? 'Destination'}",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "${routeDistance!.toStringAsFixed(1)} km • ${durationInMinutes.toStringAsFixed(0)} min",
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           Positioned(
//             top: 40,
//             left: 16,
//             right: 16,
//             child: GestureDetector(
//               onTap: () {
//                 // Navigate to search screen or open modal
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (_) => WhereToScreen(
//                           category: VehicleCategory.passenger,
//                           initialPickupLocation: pickup ?? currentLocation,
//                         ),
//                   ),
//                 );
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 6,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),

//                 child: Row(
//                   children: [
//                     const Icon(Icons.search, color: Colors.grey),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Text(
//                         dropAddressAsync.when(
//                           data: (address) => address ?? 'Select Destination',
//                           loading: () => 'Loading...',
//                           error: (err, _) => 'Error',
//                         ),
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                     if (tripDistanceKm != null)
//                       Padding(
//                         padding: const EdgeInsets.only(left: 8),
//                         child: Text(
//                           'Distance: ${tripDistanceKm.toStringAsFixed(2)} km',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     const SizedBox(width: 10),
//                     GestureDetector(
//                       onTap: () {
//                         showDialog(
//                           context: context,
//                           builder:
//                               (_) => const AlertDialog(
//                                 title: Text("Add Stop"),
//                                 content: Text(
//                                   "Add stop functionality coming soon.",
//                                 ),
//                               ),
//                         );
//                       },
//                       child: const Icon(Icons.add, color: Colors.blue),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           Positioned(
//             bottom: 20,
//             left: 10,
//             right: 10,
//             child: GestureDetector(
//               onTap: _navigateToWhereTo,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 14,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: const [
//                     BoxShadow(color: Colors.black26, blurRadius: 4),
//                   ],
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(Icons.search, color: Colors.black),
//                     SizedBox(width: 10),
//                     Text(
//                       'Where to?',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           if (widget.destination != null)
//             NotificationListener<DraggableScrollableNotification>(
//               onNotification: (notification) {
//                 final sheetExtent =
//                     notification.extent; // 0.25 to 0.8 for example
//                 // Map extent to 0-1 scrollFraction (or invert as needed)
//                 final scrollFraction =
//                     1 - ((sheetExtent - 0.25) / (0.8 - 0.25));
//                 // onDraggableScroll(scrollFraction);
//                 return true; // consume the notification
//               },

//               child: DraggableScrollableSheet(
//                 initialChildSize: 0.4,
//                 minChildSize: 0.25,
//                 maxChildSize: 0.8,
//                 builder: (context, scrollController) {
//                   if (_scrollController.hasClients &&
//                       _scrollController != scrollController) {
//                     _scrollController = scrollController;
//                   }

//                   if (widget.pickup != null && widget.destination != null) {
//                     _moveCameraToBounds(widget.pickup!, widget.destination!);
//                   } else if (widget.pickup != null) {
//                     _mapController?.animateCamera(
//                       CameraUpdate.newLatLngZoom(widget.pickup!, 13),
//                     );
//                   }

//                   // Compute cheapest & fastest
//                   final validEstimates =
//                       fareEstimates.where((e) => e != null).toList();
//                   final double minFare =
//                       validEstimates.isNotEmpty
//                           ? validEstimates
//                               .map((e) => e!.fare)
//                               .reduce((a, b) => a < b ? a : b)
//                           : 0;
//                   final int minTime =
//                       validEstimates.isNotEmpty
//                           ? validEstimates
//                               .map((e) => e!.timeEstimate)
//                               .reduce((a, b) => a < b ? a : b)
//                               .toInt()
//                           : 0;

//                   String selectedPayment = 'Cash'; // default
//                   double appBalance = 50; // user's AMiNi wallet balance
//                   double selectedFare = 100; // fare for the selected ride
//                   bool hasVisaCard =
//                       false; // whether the user has a Visa card added

//                   return Container(
//                     decoration: BoxDecoration(
//                       borderRadius: const BorderRadius.vertical(
//                         top: Radius.circular(28),
//                       ),
//                       gradient: LinearGradient(
//                         colors: [Colors.white, Colors.grey.shade50],
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                       ),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black26,
//                           blurRadius: 12,
//                           offset: Offset(0, -4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         // Drag handle
//                         const SizedBox(height: 8),
//                         Center(
//                           child: Container(
//                             width: 40,
//                             height: 5,
//                             decoration: BoxDecoration(
//                               color: Colors.grey,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),

//                         // List of categories
//                         Expanded(
//                           child: ListView.builder(
//                             controller: scrollController,
//                             padding: const EdgeInsets.all(12),
//                             itemCount:
//                                 isLoadingCategories
//                                     ? 3
//                                     : vehicleCategories.length,
//                             itemBuilder: (context, index) {
//                               if (isLoadingCategories) return _buildSkeleton();

//                               final category = vehicleCategories[index];
//                               final name = category.name;
//                               final passengers = category.maxPassengers;
//                               final isSelected = selectedIndex == index;

//                               final estimate = fareEstimates[index];
//                               final timeAway =
//                                   estimate != null
//                                       ? "${estimate.timeEstimate.round()} min"
//                                       : "--";

//                               final isAvailable =
//                                   driverAvailability.isNotEmpty &&
//                                   driverAvailability[index];

//                               final isCheapest = estimate?.fare == minFare;
//                               final isFastest =
//                                   estimate?.timeEstimate == minTime;

//                               // Discount logic
//                               final hasDiscount =
//                                   index == 0 ||
//                                   index == 2; // simulate discounts
//                               final originalFare = estimate?.fare ?? 0;
//                               final discountPercent = hasDiscount ? 15 : 0;
//                               final discountedFare =
//                                   hasDiscount
//                                       ? originalFare *
//                                           (1 - discountPercent / 100)
//                                       : originalFare;
//                               final fareDisplay =
//                                   estimate != null
//                                       ? "${estimate.currency} ${discountedFare.toStringAsFixed(0)}"
//                                       : "--";

//                               return GestureDetector(
//                                 onTap:
//                                     isAvailable
//                                         ? () {
//                                           setState(() => selectedIndex = index);
//                                           ref
//                                               .read(
//                                                 selectedCategoryProvider
//                                                     .notifier,
//                                               )
//                                               .state = category;
//                                         }
//                                         : null,
//                                 child: Opacity(
//                                   opacity: isAvailable ? 1.0 : 0.5,
//                                   child: AnimatedContainer(
//                                     duration: const Duration(milliseconds: 250),
//                                     margin: const EdgeInsets.only(bottom: 12),
//                                     padding: const EdgeInsets.all(10),

//                                     decoration: BoxDecoration(
//                                       color:
//                                           isSelected
//                                               ? Colors.orange.shade50
//                                               : Colors
//                                                   .white, //Colors.grey.shade100,
//                                       borderRadius: BorderRadius.circular(16),
//                                       border: Border.all(
//                                         color:
//                                             isSelected
//                                                 ? Colors.orange
//                                                 : Colors
//                                                     .grey
//                                                     .shade500, //Colors.grey.shade300,
//                                         width: isSelected ? 2 : 1,
//                                       ),
//                                       boxShadow:
//                                           isSelected
//                                               ? [
//                                                 const BoxShadow(
//                                                   color: Colors.black12,
//                                                   blurRadius: 6,
//                                                   offset: Offset(0, 2),
//                                                 ),
//                                               ]
//                                               : [],
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         // Vehicle Image
//                                         ClipRRect(
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                           child:
//                                               category.iconUrl != null &&
//                                                       category
//                                                           .iconUrl!
//                                                           .isNotEmpty
//                                                   ? Image.network(
//                                                     "$ImageUrl${category.iconUrl}",
//                                                     width: 60,
//                                                     height: 60,
//                                                     fit: BoxFit.cover,
//                                                   )
//                                                   : Image.asset(
//                                                     'assets/imgs/Sedan2.png',
//                                                     width: 60,
//                                                     height: 60,
//                                                   ),
//                                         ),
//                                         const SizedBox(width: 12),

//                                         // Details
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               // Name + Price
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: [
//                                                   Text(
//                                                     name,
//                                                     style: const TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                       fontSize: 16,
//                                                     ),
//                                                   ),
//                                                   Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment.end,
//                                                     children: [
//                                                       if (hasDiscount)
//                                                         Container(
//                                                           padding:
//                                                               const EdgeInsets.symmetric(
//                                                                 horizontal: 6,
//                                                                 vertical: 2,
//                                                               ),
//                                                           margin:
//                                                               const EdgeInsets.only(
//                                                                 bottom: 2,
//                                                               ),
//                                                           decoration: BoxDecoration(
//                                                             color:
//                                                                 Colors
//                                                                     .green
//                                                                     .shade600,
//                                                             borderRadius:
//                                                                 BorderRadius.circular(
//                                                                   6,
//                                                                 ),
//                                                           ),
//                                                           child: Text(
//                                                             "-$discountPercent%",
//                                                             style:
//                                                                 const TextStyle(
//                                                                   color:
//                                                                       Colors
//                                                                           .white,
//                                                                   fontSize: 10,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                 ),
//                                                           ),
//                                                         ),
//                                                       Row(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: [
//                                                           if (hasDiscount)
//                                                             Text(
//                                                               "${estimate?.currency} ${originalFare.toStringAsFixed(0)}",
//                                                               style: const TextStyle(
//                                                                 fontSize: 12,
//                                                                 color:
//                                                                     Colors.grey,
//                                                                 decoration:
//                                                                     TextDecoration
//                                                                         .lineThrough,
//                                                               ),
//                                                             ),
//                                                           if (hasDiscount)
//                                                             const SizedBox(
//                                                               width: 6,
//                                                             ),
//                                                           Text(
//                                                             fareDisplay,
//                                                             style:
//                                                                 const TextStyle(
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                   fontSize: 16,
//                                                                   color:
//                                                                       Colors
//                                                                           .black,
//                                                                 ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),

//                                               const SizedBox(height: 4),

//                                               // Badges
//                                               Row(
//                                                 children: [
//                                                   if (isCheapest)
//                                                     _badge(
//                                                       "Cheapest",
//                                                       Colors.green,
//                                                     ),
//                                                   if (isFastest)
//                                                     _badge(
//                                                       "Fastest",
//                                                       Colors.blue,
//                                                     ),
//                                                 ],
//                                               ),
//                                               const SizedBox(height: 4),

//                                               // Time & Passengers
//                                               Text(
//                                                 timeAway,
//                                                 style: TextStyle(
//                                                   color: Colors.grey.shade500,
//                                                   fontSize: 12,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 4),
//                                               Text(
//                                                 "$passengers pass",
//                                                 style: TextStyle(
//                                                   color: Colors.grey.shade600,
//                                                   fontSize: 13,
//                                                 ),
//                                               ),

//                                               if (!isAvailable)
//                                                 const Text(
//                                                   "No drivers nearby",
//                                                   style: TextStyle(
//                                                     color: Colors.redAccent,
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),

//                         // Payment dropdown above the select/book button
//                         // Column(
//                         //   children: [
//                         //     const SizedBox(height: 12),

//                         //     // 🔹 Payment Dropdown
//                         //     // 🔹 Payment selector (Uber-style)
//                         //     Container(
//                         //       padding: const EdgeInsets.symmetric(
//                         //         horizontal: 12,
//                         //       ),
//                         //       decoration: BoxDecoration(
//                         //         color: Colors.grey.shade100,
//                         //         borderRadius: BorderRadius.circular(12),
//                         //         border: Border.all(color: Colors.grey.shade300),
//                         //       ),
//                         //       child: DropdownButtonHideUnderline(
//                         //         child: DropdownButton<String>(
//                         //           value: selectedPayment,
//                         //           isExpanded: true,
//                         //           icon: const Icon(
//                         //             Icons.arrow_drop_down,
//                         //             size: 28,
//                         //           ),
//                         //           items:
//                         //               ['Cash', 'Visa', 'AMiNi'].map((method) {
//                         //                 Icon methodIcon;
//                         //                 Color iconColor = Colors.black87;

//                         //                 switch (method) {
//                         //                   case 'Cash':
//                         //                     methodIcon = const Icon(
//                         //                       Icons.money,
//                         //                       size: 22,
//                         //                     );
//                         //                     break;
//                         //                   case 'Visa':
//                         //                     methodIcon = const Icon(
//                         //                       Icons.credit_card,
//                         //                       size: 22,
//                         //                     );
//                         //                     break;
//                         //                   case 'AMiNi':
//                         //                     methodIcon = const Icon(
//                         //                       Icons.account_balance_wallet,
//                         //                       size: 22,
//                         //                     );
//                         //                     iconColor =
//                         //                         appBalance > 0
//                         //                             ? Colors.green
//                         //                             : Colors.red;
//                         //                     break;
//                         //                   default:
//                         //                     methodIcon = const Icon(
//                         //                       Icons.payment,
//                         //                       size: 22,
//                         //                     );
//                         //                 }

//                         //                 return DropdownMenuItem<String>(
//                         //                   value: method,
//                         //                   child: Row(
//                         //                     children: [
//                         //                       methodIcon,
//                         //                       const SizedBox(width: 10),
//                         //                       Text(
//                         //                         method,
//                         //                         style: TextStyle(
//                         //                           fontWeight:
//                         //                               selectedPayment == method
//                         //                                   ? FontWeight.bold
//                         //                                   : FontWeight.normal,
//                         //                           color:
//                         //                               selectedPayment == method
//                         //                                   ? Colors.black
//                         //                                   : Colors.black87,
//                         //                         ),
//                         //                       ),
//                         //                       if (method == 'AMiNi')
//                         //                         Padding(
//                         //                           padding:
//                         //                               const EdgeInsets.only(
//                         //                                 left: 8,
//                         //                               ),
//                         //                           child: Text(
//                         //                             "Balance: \$${appBalance.toStringAsFixed(2)}",
//                         //                             style: TextStyle(
//                         //                               fontSize: 12,
//                         //                               color:
//                         //                                   appBalance > 0
//                         //                                       ? Colors.green
//                         //                                       : Colors.red,
//                         //                             ),
//                         //                           ),
//                         //                         ),
//                         //                     ],
//                         //                   ),
//                         //                 );
//                         //               }).toList(),
//                         //           onChanged: (value) async {
//                         //             if (value == null) return;

//                         //             // Visa check
//                         //             if (value == 'Visa' && !hasVisaCard) {
//                         //               await Navigator.push(
//                         //                 context,
//                         //                 MaterialPageRoute(
//                         //                   builder: (_) => const AddVisaScreen(),
//                         //                 ),
//                         //               );
//                         //               // return; // don't change selectedPayment yet
//                         //             }

//                         //             // AMiNi wallet check
//                         //             if (value == 'AMiNi' && appBalance <= 0) {
//                         //               await Navigator.push(
//                         //                 context,
//                         //                 MaterialPageRoute(
//                         //                   builder: (_) => const WalletScreen(),
//                         //                 ),
//                         //               );
//                         //               //return; // don't change selectedPayment yet
//                         //             }

//                         //             // ✅ Update selectedPayment only after validations
//                         //             setState(() {
//                         //               selectedPayment = value;
//                         //             });
//                         //           },
//                         //         ),
//                         //       ),
//                         //     ),
//                         //     const SizedBox(height: 12),

//                         //     // 🔹 Consumer Select/Book Button (unchanged)
//                         //     Consumer(
//                         //       builder: (context, ref, child) {
//                         //         final selected = ref.watch(
//                         //           selectedCategoryProvider,
//                         //         );
//                         //         final category = selected?.name ?? 'N/A';
//                         //         final categoryId = selected?.id ?? 0;
//                         //         final isEnabled =
//                         //             category.toString().isNotEmpty;

//                         //         return Padding(
//                         //           padding: const EdgeInsets.symmetric(
//                         //             horizontal: 12,
//                         //             vertical: 12,
//                         //           ),
//                         //           child: SizedBox(
//                         //             width: double.infinity,
//                         //             child: ElevatedButton(
//                         //               onPressed:
//                         //                   isEnabled
//                         //                       ? () {
//                         //                         // Payment validations
//                         //                         if (selectedPayment ==
//                         //                                 'AMiNi' &&
//                         //                             appBalance < selectedFare) {
//                         //                           showDialog(
//                         //                             context: context,
//                         //                             builder:
//                         //                                 (_) => AlertDialog(
//                         //                                   title: const Text(
//                         //                                     'Insufficient Balance',
//                         //                                   ),
//                         //                                   content: const Text(
//                         //                                     'You do not have enough funds in your AMiNi wallet. Please top up.',
//                         //                                   ),
//                         //                                   actions: [
//                         //                                     TextButton(
//                         //                                       onPressed:
//                         //                                           () =>
//                         //                                               Navigator.pop(
//                         //                                                 context,
//                         //                                               ),
//                         //                                       child: const Text(
//                         //                                         'OK',
//                         //                                       ),
//                         //                                     ),
//                         //                                   ],
//                         //                                 ),
//                         //                           );
//                         //                           return;
//                         //                         }

//                         //                         if (selectedPayment == 'Visa' &&
//                         //                             !hasVisaCard) {
//                         //                           showDialog(
//                         //                             context: context,
//                         //                             builder:
//                         //                                 (_) => AlertDialog(
//                         //                                   title: const Text(
//                         //                                     'No Visa Card Added',
//                         //                                   ),
//                         //                                   content: const Text(
//                         //                                     'You have not added a Visa card. Please add one to continue.',
//                         //                                   ),
//                         //                                   actions: [
//                         //                                     TextButton(
//                         //                                       onPressed:
//                         //                                           () =>
//                         //                                               Navigator.pop(
//                         //                                                 context,
//                         //                                               ),
//                         //                                       child: const Text(
//                         //                                         'OK',
//                         //                                       ),
//                         //                                     ),
//                         //                                   ],
//                         //                                 ),
//                         //                           );
//                         //                           return;
//                         //                         }

//                         //                         // Proceed to ConfirmRideScreen
//                         //                         Navigator.push(
//                         //                           context,
//                         //                           MaterialPageRoute(
//                         //                             builder:
//                         //                                 (
//                         //                                   _,
//                         //                                 ) => ConfirmRideScreen(
//                         //                                   pickup:
//                         //                                       widget.pickup!,
//                         //                                   fare: selectedFare,
//                         //                                   destination:
//                         //                                       widget
//                         //                                           .destination!,
//                         //                                   category: categoryId,
//                         //                                   optionSelected:
//                         //                                       category,
//                         //                                   isScheduled:
//                         //                                       widget
//                         //                                           .isScheduled,
//                         //                                   scheduledDate:
//                         //                                       widget
//                         //                                           .scheduledDate,
//                         //                                   // paymentMethod:
//                         //                                   //     selectedPayment,
//                         //                                 ),
//                         //                           ),
//                         //                         );
//                         //                       }
//                         //                       : null,
//                         //               style: ElevatedButton.styleFrom(
//                         //                 backgroundColor: Colors.black,
//                         //                 padding: const EdgeInsets.symmetric(
//                         //                   vertical: 16,
//                         //                 ),
//                         //                 shape: RoundedRectangleBorder(
//                         //                   borderRadius: BorderRadius.circular(
//                         //                     12,
//                         //                   ),
//                         //                 ),
//                         //               ),
//                         //               child: Text(
//                         //                 (widget.isScheduled == true &&
//                         //                         isEnabled)
//                         //                     ? "Book $category"
//                         //                     : "Select ${category ?? 'Category'}",
//                         //                 style: const TextStyle(
//                         //                   fontSize: 18,
//                         //                   color: Colors.white,
//                         //                 ),
//                         //               ),
//                         //             ),
//                         //           ),
//                         //         );
//                         //       },
//                         //     ),
//                         //   ],
//                         // ),

//                         // Row containing Select/Book button and Payment Dropdown
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 12,
//                           ),
//                           child: Row(
//                             children: [
//                               // Expanded Select/Book Button
//                               Expanded(
//                                 child: Consumer(
//                                   builder: (context, ref, child) {
//                                     final selected = ref.watch(
//                                       selectedCategoryProvider,
//                                     );
//                                     final category = selected?.name ?? 'N/A';
//                                     final categoryId = selected?.id ?? 0;
//                                     final isEnabled =
//                                         category.toString().isNotEmpty;

//                                     return ElevatedButton(
//                                       onPressed:
//                                           isEnabled
//                                               ? () {
//                                                 // Payment validations
//                                                 if (selectedPayment ==
//                                                         'AMiNi' &&
//                                                     appBalance < selectedFare) {
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (
//                                                           _,
//                                                         ) => const AlertDialog(
//                                                           title: Text(
//                                                             'Insufficient Balance',
//                                                           ),
//                                                           content: Text(
//                                                             'You do not have enough funds in your AMiNi wallet. Please top up.',
//                                                           ),
//                                                         ),
//                                                   );
//                                                   return;
//                                                 }

//                                                 if (selectedPayment == 'Visa' &&
//                                                     !hasVisaCard) {
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (
//                                                           _,
//                                                         ) => const AlertDialog(
//                                                           title: Text(
//                                                             'No Visa Card Added',
//                                                           ),
//                                                           content: Text(
//                                                             'You have not added a Visa card. Please add one to continue.',
//                                                           ),
//                                                         ),
//                                                   );
//                                                   return;
//                                                 }

//                                                 Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder:
//                                                         (
//                                                           _,
//                                                         ) => ConfirmRideScreen(
//                                                           pickup:
//                                                               widget.pickup!,
//                                                           fare: selectedFare,
//                                                           destination:
//                                                               widget
//                                                                   .destination!,
//                                                           category: categoryId,
//                                                           optionSelected:
//                                                               category,
//                                                           isScheduled:
//                                                               widget
//                                                                   .isScheduled,
//                                                           scheduledDate:
//                                                               widget
//                                                                   .scheduledDate,
//                                                         ),
//                                                   ),
//                                                 );
//                                               }
//                                               : null,
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.black,
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 16,
//                                         ),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                       ),
//                                       child: Text(
//                                         (widget.isScheduled == true &&
//                                                 isEnabled)
//                                             ? "Book $category"
//                                             : "Select ${category ?? 'Category'}",
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),

//                               const SizedBox(width: 10),

//                               // Payment Dropdown (smaller, fixed width)
//                               Container(
//                                 width: 130, // adjust as needed
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade100,
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.grey.shade300,
//                                   ),
//                                 ),
//                                 child: DropdownButtonHideUnderline(
//                                   child: DropdownButton<String>(
//                                     value: selectedPayment,
//                                     isExpanded: true,
//                                     icon: const Icon(
//                                       Icons.arrow_drop_down,
//                                       size: 28,
//                                     ),
//                                     items:
//                                         ['Cash', 'Visa', 'AMiNi'].map((method) {
//                                           Icon methodIcon;
//                                           Color iconColor = Colors.black87;

//                                           switch (method) {
//                                             case 'Cash':
//                                               methodIcon = const Icon(
//                                                 Icons.money,
//                                                 size: 22,
//                                               );
//                                               break;
//                                             case 'Visa':
//                                               methodIcon = const Icon(
//                                                 Icons.credit_card,
//                                                 size: 22,
//                                               );
//                                               break;
//                                             case 'AMiNi':
//                                               methodIcon = const Icon(
//                                                 Icons.account_balance_wallet,
//                                                 size: 22,
//                                               );
//                                               iconColor =
//                                                   appBalance > 0
//                                                       ? Colors.green
//                                                       : Colors.red;
//                                               break;
//                                             default:
//                                               methodIcon = const Icon(
//                                                 Icons.payment,
//                                                 size: 22,
//                                               );
//                                           }

//                                           return DropdownMenuItem<String>(
//                                             value: method,
//                                             child: Row(
//                                               children: [
//                                                 methodIcon,
//                                                 const SizedBox(width: 6),
//                                                 Flexible(
//                                                   child: Text(
//                                                     method,
//                                                     style: TextStyle(
//                                                       fontWeight:
//                                                           selectedPayment ==
//                                                                   method
//                                                               ? FontWeight.bold
//                                                               : FontWeight
//                                                                   .normal,
//                                                       color:
//                                                           selectedPayment ==
//                                                                   method
//                                                               ? Colors.black
//                                                               : Colors.black87,
//                                                     ),
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         }).toList(),
//                                     onChanged: (value) {
//                                       if (value == null) return;
//                                       setState(() => selectedPayment = value);
//                                     },
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // double _calculateDistanceKm(LatLng start, LatLng end) {
//   //   const double R = 6371; // Earth radius in KM
//   //   final dLat = _deg2rad(end.latitude - start.latitude);
//   //   final dLon = _deg2rad(end.longitude - start.longitude);
//   //   final a =
//   //       (sin(dLat / 2) * sin(dLat / 2)) +
//   //       cos(_deg2rad(start.latitude)) *
//   //           cos(_deg2rad(end.latitude)) *
//   //           (sin(dLon / 2) * sin(dLon / 2));
//   //   final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//   //   return R * c;
//   // }

//   double _deg2rad(double deg) => deg * (pi / 180);

//   void _moveCameraToBounds(LatLng pickup, LatLng destination) {
//     final southwest = LatLng(
//       min(pickup.latitude, destination.latitude),
//       min(pickup.longitude, destination.longitude),
//     );
//     final northeast = LatLng(
//       max(pickup.latitude, destination.latitude),
//       max(pickup.longitude, destination.longitude),
//     );

//     final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngBounds(bounds, 50),
//     ); // padding of 100
//   }

//   double _initialZoom = 14.0; // your fixed zoom
//   LatLngBounds? _bounds;

//   void _initMap(LatLng pickup, LatLng destination) async {
//     if (_mapController == null) return;

//     // Calculate bounds with small horizontal padding to keep from/to fully visible horizontally
//     final bounds = LatLngBounds(
//       southwest: LatLng(
//         min(pickup.latitude, destination.latitude),
//         min(pickup.longitude, destination.longitude),
//       ),
//       northeast: LatLng(
//         max(pickup.latitude, destination.latitude),
//         max(pickup.longitude, destination.longitude),
//       ),
//     );

//     _bounds = bounds;

//     // Move camera to show bounds with fixed padding once
//     await _mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds, 50));

//     // Fix zoom level
//     await _mapController!.moveCamera(CameraUpdate.zoomTo(_initialZoom));
//   }

//   // Call this during map created event or after pickup/destination set
//   //_initMap(pickup, destination);

//   // When draggable sheet scrolls
//   void onDraggableScroll(double scrollFraction) {
//     if (_mapController == null || _bounds == null) return;

//     // scrollFraction: 0 = fully expanded sheet, 1 = minimized sheet (you can invert as needed)

//     // Calculate how much to pan vertically on the map in pixels (experiment with this)
//     final screenHeight = MediaQuery.of(context).size.height;

//     // dy in pixels; positive = pan map down (so markers appear to move up)
//     final dy = screenHeight * (scrollFraction - 0.5); // tweak multiplier

//     _mapController!.animateCamera(CameraUpdate.scrollBy(0, dy));
//   }

//   Widget _badge(String text, Color color) {
//     return Container(
//       margin: const EdgeInsets.only(right: 6, top: 4),
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildSkeleton() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           Container(width: 60, height: 60, color: Colors.grey.shade300),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               children: [
//                 Container(height: 12, color: Colors.grey.shade300),
//                 const SizedBox(height: 6),
//                 Container(height: 10, color: Colors.grey.shade300),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// // Future<void> _fetchRoute() async {
//   //   final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
//   //   final destination =
//   //       '${widget.destination!.latitude},${widget.destination!.longitude}';
//   //   final apiKey = mapKey; // Your Google Maps API Key

//   //   final url = Uri.parse(
//   //     'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey',
//   //   );

//   //   final response = await http.get(url);

//   //   if (response.statusCode == 200) {
//   //     final data = jsonDecode(response.body);

//   //     if (data['status'] == 'OK') {
//   //       final route = data['routes'][0];
//   //       final leg = route['legs'][0];

//   //       final overviewPolyline = route['overview_polyline']['points'];
//   //       final points = _decodePolyline(overviewPolyline);

//   //       final double distanceKm =
//   //           leg['distance']['value'] / 1000.0; // meters → km
//   //       final double durationMinutes =
//   //           leg['duration']['value'] / 60.0; // sec → min

//   //       setState(() {
//   //         routePoints = points;
//   //         routeDistance = distanceKm;
//   //         durationInMinutes = durationMinutes;

//   //         polylines = {
//   //           Polyline(
//   //             polylineId: const PolylineId('route'),
//   //             color: Colors.blue,
//   //             width: 5,
//   //             points: routePoints,
//   //           ),
//   //         };

//   //         /// ✅ Update markers
//   //         _markers
//   //           ..clear()
//   //           ..add(
//   //             Marker(
//   //               markerId: const MarkerId('pickup'),
//   //               position: widget.pickup!,
//   //               icon: BitmapDescriptor.defaultMarkerWithHue(
//   //                 BitmapDescriptor.hueGreen,
//   //               ),
//   //               infoWindow: InfoWindow(title: pickupAddress ?? "Pickup"),
//   //             ),
//   //           )
//   //           ..add(
//   //             Marker(
//   //               markerId: const MarkerId('destination'),
//   //               position: widget.destination!,
//   //               icon: BitmapDescriptor.defaultMarkerWithHue(
//   //                 BitmapDescriptor.hueRed,
//   //               ),
//   //               infoWindow: InfoWindow(
//   //                 title: destinationAddress ?? "Destination",
//   //               ),
//   //             ),
//   //           );

//   //         // ✅ Distance & duration marker at center
//   //         if (midPoint != null) {
//   //           _markers.add(
//   //             Marker(
//   //               markerId: const MarkerId('route_center'),
//   //               position: midPoint,
//   //               icon: BitmapDescriptor.defaultMarkerWithHue(
//   //                 BitmapDescriptor.hueBlue,
//   //               ),
//   //               infoWindow: InfoWindow(
//   //                 title: "${distanceKm.toStringAsFixed(1)} km",
//   //                 snippet: "${durationMinutes.toStringAsFixed(0)} min",
//   //               ),
//   //             ),
//   //           );
//   //         }
//   //       });
//   //       pickupAddress = await _getPlaceName(widget.pickup!);
//   //       destinationAddress = await _getPlaceName(widget.destination!);
//   //       final midPoint = _getMidPoint(widget.pickup!, widget.destination!);

//   //       for (int i = 0; i < vehicleCategories.length; i++) {
//   //         final category = vehicleCategories[i];
//   //         try {
//   //           final estimate = await FareService.getFareEstimate(
//   //             categoryId: category.id,
//   //             pickupLat: widget.pickup!.latitude,
//   //             pickupLng: widget.pickup!.longitude,
//   //             destLat: widget.destination!.latitude,
//   //             destLng: widget.destination!.longitude,
//   //             distanceKm: distanceKm,
//   //             durationMinutes: durationMinutes,
//   //             waitingMinutes: 0,
//   //             countryCode: "KE",
//   //           );

//   //           if (!mounted) return;
//   //           setState(() {
//   //             fareEstimates[i] = estimate; // ✅ update this index
//   //           });
//   //         } catch (e) {
//   //           print('❌ Failed to load fare for ${category.name}: $e');

//   //           if (!mounted) return;
//   //           setState(() {
//   //             fareEstimates[i] = FareEstimate(
//   //               fare: 0,
//   //               currency: "KES",
//   //               timeEstimate: durationInMinutes,
//   //               categoryName: category.name,
//   //               distanceKm: distanceKm,
//   //             ); // ✅ fallback instead of keeping null
//   //           });
//   //         }
//   //       }

//   //       // Move camera to show both points + route
//   //       if (_mapController != null) {
//   //         _moveCameraToBounds(widget.pickup!, widget.destination!);
//   //       }
//   //     } else {
//   //       print('Google Directions API error: ${data['status']}');
//   //     }
//   //   } else {
//   //     print('Failed to fetch directions. Status: ${response.statusCode}');
//   //   }
//   // }