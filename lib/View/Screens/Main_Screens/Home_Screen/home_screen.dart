import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
//import 'package:flutter_map/flutter_map.dart';
///import 'package:flutter_map/flutter_map.dart' as gmap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/ride_map.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/ride_in_progress.dart';
import 'package:niceapp/View/Screens/Other_Screens/Splash_Screen/splash_logics.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
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
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
  List<VehicleSubCategory> vehicleCategories = [];
  List<FareEstimate?> fareEstimates = [];
  bool isLoadingCategories = true;
  int selectedIndex = -1;
  LatLng? currentLocation;
  //LatLng? pickup;
  List<LatLng> routePoints = [];
  double? routeDistance;
  int durationInMinutes = 0;
  LatLng _initialFallback = const LatLng(-1.286389, 36.817223);
  //GoogleMapController? mapController;
  //late ScrollController _scrollController;
  GoogleMapController? _mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  double _mapOffsetY = 0;
  final double maxUpOffset = -150; // adjust as needed
  late ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    //_getCurrentLocation();
    _setCurrentLocation();

    if (widget.destination != null) {
      fetchVehicleSubCategoriesByType(widget.category.index).then((
        categories,
      ) async {
        setState(() {
          vehicleCategories = categories;
          fareEstimates = List<FareEstimate?>.filled(categories.length, null);
          isLoadingCategories = false;

          if (categories.isNotEmpty) {
            selectedIndex = 0;
            ref.read(selectedCategoryProvider.notifier).state = categories[0];
          }
        });
        if (widget.pickup != null && widget.destination != null) {
          for (int i = 0; i < categories.length; i++) {
            final category = categories[i];
            try {
              final estimate = await FareService.getFareEstimate(
                categoryId: category.id,
                pickupLat: widget.pickup!.latitude,
                pickupLng: widget.pickup!.longitude,
                destLat: widget.destination!.latitude,
                destLng: widget.destination!.longitude,
                countryCode: "KE",
              );
              print('Received estimate for ${category.name}: $estimate');
              setState(() {
                fareEstimates[i] = estimate;
              });
            } catch (e) {
              print('Failed to load fare for category ${category.name}: $e');
            }
          }
        }
      });
      _setupMarkers();
      _fetchRoute();
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickup!,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination!,
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
          routeDistance = leg['distance']['value'] / 1000.0; // meters to km
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
          _moveCameraToBounds(widget.pickup!, widget.destination!);
        }
      } else {
        print('Google Directions API error: ${data['status']}');
      }
    } else {
      print('Failed to fetch directions. Status: ${response.statusCode}');
    }
  }

  // void _moveCameraToBounds(LatLng pos1, LatLng pos2) async {
  //   final southWest = LatLng(
  //     min(pos1.latitude, pos2.latitude),
  //     min(pos1.longitude, pos2.longitude),
  //   );
  //   final northEast = LatLng(
  //     max(pos1.latitude, pos2.latitude),
  //     max(pos1.longitude, pos2.longitude),
  //   );

  //   final bounds = LatLngBounds(southwest: southWest, northeast: northEast);

  //   final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
  //   await _mapController?.animateCamera(cameraUpdate);
  // }

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
      tripDistanceKm = _calculateDistanceKm(pickup, destination);
      midPoint = LatLng(
        (pickup.latitude + destination.latitude) / 2,
        (pickup.longitude + destination.longitude) / 2,
      );
    }
    if (rideConfirmed) {
      if (driver == null) {
        return const Center(child: Text('No driver linked'));
      }

      // return RideInProgressLiveScreen(
      //   driverStart: LatLng(
      //     driver.location.latitude,
      //     driver.location.longitude,
      //   ),
      //   pickup: widget.pickup!,
      // );
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

          if (widget.destination != null)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                // final sheetSize =
                //     notification
                //         .extent; // fractional size between minChildSize and maxChildSize
                // final bottomPadding =
                //     MediaQuery.of(context).size.height * (1 - sheetSize) + 20;
                // final topPadding =
                //     MediaQuery.of(context).size.height * (1 - sheetSize) + 20;
                // final leftPadding =
                //     MediaQuery.of(context).size.height * (1 - sheetSize) + 20;
                // final rightPadding =
                //     MediaQuery.of(context).size.height * (1 - sheetSize) + 20;

                // _moveCameraToBounds(
                //   context,
                //   pickup!,
                //   destination!,
                //   bottomPadding: bottomPadding,
                //   topPadding: topPadding,
                //   //leftPadding: leftPadding,
                //   // rightPadding: rightPadding,
                // );
                final sheetExtent =
                    notification.extent; // 0.25 to 0.8 for example
                // Map extent to 0-1 scrollFraction (or invert as needed)
                final scrollFraction =
                    1 - ((sheetExtent - 0.25) / (0.8 - 0.25));
                // onDraggableScroll(scrollFraction);
                return true; // consume the notification
              },

              child: DraggableScrollableSheet(
                //controller: _scrollController,
                initialChildSize: 0.4, // 40% of screen height
                minChildSize:
                    0.25, // Never collapse below 25% (ensures 1 category is visible)
                maxChildSize: 0.8, // Optional, can grow up to 80%
                builder: (context, scrollController) {
                  if (_scrollController.hasClients &&
                      _scrollController != scrollController) {
                    _scrollController = scrollController;
                  }
                  if (widget.pickup != null && widget.destination != null) {
                    _moveCameraToBounds(widget.pickup!, widget.destination!);
                  } else if (widget.pickup != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(widget.pickup!, 13),
                    );
                  }

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller:
                                scrollController, // _scrollController, //
                            //itemCount: vehicleCategories.length,
                            itemCount:
                                isLoadingCategories
                                    ? 0
                                    : vehicleCategories.length,
                            padding: const EdgeInsets.all(12),

                            itemBuilder: (context, index) {
                              final category = vehicleCategories[index];
                              final name = category.name;
                              final passengers = category.maxPassengers;
                              final isSelected = selectedIndex == index;
                              //new
                              final estimate = fareEstimates[index];

                              final fareDisplay =
                                  estimate != null
                                      ? "${estimate.currency} ${estimate.fare.toStringAsFixed(2)}"
                                      : "Loading...";

                              final timeAway =
                                  estimate != null
                                      ? "${estimate.timeEstimate} mins"
                                      : "Estimating...";

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
                                    color: Colors.white,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.grey
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      category.iconUrl != null &&
                                              category.iconUrl!.isNotEmpty
                                          ? Image.network(
                                            "$ImageUrl${category.iconUrl}",
                                            //category.iconUrl!,
                                            width: 60,
                                            height: 60,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Image.asset(
                                                'assets/imgs/Sedan2.png', // your fallback image
                                                width: 60,
                                                height: 60,
                                              );
                                            },
                                          )
                                          : Image.asset(
                                            'assets/imgs/Sedan2.png',
                                            width: 60,
                                            height: 60,
                                          ),

                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  fareDisplay,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Text(
                                            //   "$timeAway",
                                            //   style: const TextStyle(
                                            //     color: Colors.grey,
                                            //     fontSize: 13,
                                            //   ),
                                            // ),
                                            Text(
                                              timeAway,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "$passengers Passengers",
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
                            final selected = ref.watch(
                              selectedCategoryProvider,
                            );
                            final category = selected?.name ?? 'N/A';
                            final categoryId = selected?.id ?? 0;
                            // final category = ref.watch(selectedCategoryProvider);
                            // final categoryId = category!.id;
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
                                                      pickup: widget.pickup!,
                                                      fare:
                                                          selectedFare, // tripDistanceKm,
                                                      //fare: fareEstimates[selectedIndex]?.fare ?? 0.0, // ✅ Correct fare
                                                      destination:
                                                          widget.destination!,
                                                      category: categoryId,
                                                      optionSelected: category,
                                                      isScheduled:
                                                          widget.isScheduled,
                                                      scheduledDate:
                                                          widget.scheduledDate,
                                                    ),
                                              ),
                                            );
                                          }
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[700],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    // isEnabled
                                    //     ? "Select $category"
                                    //     : "Select Category",
                                    (widget.isScheduled == true && isEnabled)
                                        ? "Book $category"
                                        : "Select ${category ?? 'Category'}",
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
            ),
        ],
      ),
    );
  }

  double _calculateDistanceKm(LatLng start, LatLng end) {
    const double R = 6371; // Earth radius in KM
    final dLat = _deg2rad(end.latitude - start.latitude);
    final dLon = _deg2rad(end.longitude - start.longitude);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(start.latitude)) *
            cos(_deg2rad(end.latitude)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // Future<void> _moveCameraToBounds(
  //   BuildContext context,
  //   LatLng pickup,
  //   LatLng destination, {
  //   double? bottomPadding,
  // }) async {
  //   if (_mapController == null) return;

  //   final bounds = LatLngBounds(
  //     southwest: LatLng(
  //       min(pickup.latitude, destination.latitude),
  //       min(pickup.longitude, destination.longitude),
  //     ),
  //     northeast: LatLng(
  //       max(pickup.latitude, destination.latitude),
  //       max(pickup.longitude, destination.longitude),
  //     ),
  //   );

  //   const sidePadding = 50.0;
  //   final topPadding = 20.0;
  //   final padding =
  //       bottomPadding != null
  //           ? max(max(sidePadding, topPadding), bottomPadding)
  //           : max(sidePadding, topPadding);
  //   if (mounted) {
  //     await _mapController!.animateCamera(
  //       CameraUpdate.newLatLngBounds(bounds, padding),
  //     );
  //   }

  // Future<void> _moveCameraToBounds(
  //   BuildContext context,
  //   LatLng pickup,
  //   LatLng destination, {
  //   double? bottomPadding,
  //   double? topPadding,
  // }) async {
  //   if (_mapController == null) return;

  //   final bounds = LatLngBounds(
  //     southwest: LatLng(
  //       min(pickup.latitude, destination.latitude),
  //       min(pickup.longitude, destination.longitude),
  //     ),
  //     northeast: LatLng(
  //       max(pickup.latitude, destination.latitude),
  //       max(pickup.longitude, destination.longitude),
  //     ),
  //   );

  //   final mediaQuery = MediaQuery.of(context);
  //   final screenWidth = mediaQuery.size.width;
  //   final screenHeight = mediaQuery.size.height;

  //   // Fixed horizontal padding so pickup/destination always on screen edges horizontally
  //   const horizontalPadding = 50.0;

  //   // Vertical padding based on draggable sheet or fixed defaults
  //   final topPad = (topPadding ?? 20).clamp(0, screenHeight / 2 - 1);
  //   final bottomPad = (bottomPadding ?? 20).clamp(0, screenHeight / 2 - 1);

  //   // Max vertical padding needed
  //   final verticalPadding = max(topPad, bottomPad);

  //   // Final padding is max(horizontalPadding, verticalPadding)
  //   // This makes sure horizontal padding is respected and vertical padding adjusts for draggable sheet height
  //   final padding = max(horizontalPadding, verticalPadding).toDouble();

  //   if (mounted) {
  //     await _mapController!.animateCamera(
  //       CameraUpdate.newLatLngBounds(bounds, padding),
  //     );
  //   }
  // }

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

  // When draggable sheet scrolls
  void onDraggableScroll(double scrollFraction) {
    if (_mapController == null || _bounds == null) return;

    // scrollFraction: 0 = fully expanded sheet, 1 = minimized sheet (you can invert as needed)

    // Calculate how much to pan vertically on the map in pixels (experiment with this)
    final screenHeight = MediaQuery.of(context).size.height;

    // dy in pixels; positive = pan map down (so markers appear to move up)
    final dy = screenHeight * (scrollFraction - 0.5); // tweak multiplier

    _mapController!.animateCamera(CameraUpdate.scrollBy(0, dy));
  }
}
