import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/schedule_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Other_Screens/ambulance_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/cargo_transport.dart';
import 'package:niceapp/View/Screens/Other_Screens/movers_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/water_bower_screen.dart';
import 'package:shimmer/shimmer.dart';

class WhereToScreen extends ConsumerStatefulWidget {
  final VehicleCategory category;
  final bool? IsScheduled;
  final LatLng? initialPickupLocation;
  const WhereToScreen({
    super.key,
    required this.category,
    this.initialPickupLocation,
    this.IsScheduled,
  });
  //const WhereToScreen({super.key});

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  //final predictions = data['predictions'] as List;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _selectingPickup = false;
  Map<String, dynamic>? _selectedPlace;
  List<TextEditingController> stopControllers = [];
  List<Map<String, dynamic>>? _cachedPlaces;
  int? _activeStopIndex;

  LatLng? CurrentLocation;

  bool _isPickupLoaded = false;
  bool _isNavigated = false;
  bool _addingStop = false;

  List<Map<String, dynamic>> _commonPlaces = [];
  bool isPlacesLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([_fetchCurrentLocation(), loadNearbyPlaces()]);
      //await _fetchCurrentLocation();
      //await loadNearbyPlaces(); // ✅ ADD THIS
    });

    pickupController.addListener(_onSearchChanged);
    destinationController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();

    for (var c in stopControllers) {
      c.dispose();
    }

    super.dispose();
  }

  // void _onSearchChanged() {
  //   final text =
  //       _selectingPickup ? pickupController.text : destinationController.text;
  //   if (text.trim().isEmpty) return;
  //   _fetchSuggestions(text);
  // }

  // void _onSearchChanged() {
  //   String text;

  //   if (_activeStopIndex != null) {
  //     text = stopControllers[_activeStopIndex!].text;
  //   } else {
  //     text =
  //         _selectingPickup ? pickupController.text : destinationController.text;
  //   }

  //   if (text.trim().isEmpty) return;

  //   _fetchSuggestions(text);
  // }
  void _onSearchChanged() {
    String text;

    if (_activeStopIndex != null) {
      text = stopControllers[_activeStopIndex!].text;
    } else {
      text =
          _selectingPickup ? pickupController.text : destinationController.text;
    }

    if (text.trim().isEmpty) {
      setState(() {
        _suggestions.clear(); // ✅ CLEAR HERE
      });
      return;
    }

    _fetchSuggestions(text);
  }

  void _addStopField() {
    if (stopControllers.length >= 3) {
      _showError("Maximum 3 stops allowed");
      return;
    }

    final controller = TextEditingController();

    // ✅ ADD THIS LISTENER
    controller.addListener(() {
      if (_activeStopIndex != null) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          _fetchSuggestions(text);
        }
      }
    });

    setState(() {
      stopControllers.add(controller);
    });
  }

  Future<void> loadNearbyPlaces() async {
    // ✅ 1. Use cache (instant load)
    if (_cachedPlaces != null && _cachedPlaces!.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _commonPlaces = List.from(_cachedPlaces!); // safe copy
        isPlacesLoading = false;
      });
      return;
    }

    try {
      // ✅ 2. Use existing location if available
      final lat = CurrentLocation?.latitude;
      final lng = CurrentLocation?.longitude;

      final position =
          (lat != null && lng != null)
              ? null
              : await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
              );

      final latitude = lat ?? position!.latitude;
      final longitude = lng ?? position!.longitude;

      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=$latitude,$longitude"
          "&radius=3000"
          "&type=point_of_interest"
          "&key=$mapKey";

      // ✅ 3. Timeout (prevents freezing)
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ 4. Validate response
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

          // ✅ 5. Cache safely
          _cachedPlaces = List.from(places);

          if (!mounted) return;

          setState(() {
            _commonPlaces = places;
            isPlacesLoading = false;
          });
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
  // Future<void> loadNearbyPlaces() async {
  //   if (_cachedPlaces != null && _cachedPlaces!.isNotEmpty) {
  //     setState(() {
  //       _commonPlaces = _cachedPlaces!;
  //       isPlacesLoading = false;
  //     });
  //     return;
  //   }
  //   try {
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.medium,
  //     );

  //     final url =
  //         "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
  //         "?location=${position.latitude},${position.longitude}"
  //         "&radius=3000"
  //         "&type=point_of_interest"
  //         "&key=$mapKey";

  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final results = data["results"] as List;

  //       setState(() {
  //         _commonPlaces =
  //             results.take(5).map((place) {
  //               return {
  //                 "name": place["name"] ?? "Unknown",
  //                 "address": place["vicinity"] ?? "",
  //                 "lat": place["geometry"]["location"]["lat"],
  //                 "lng": place["geometry"]["location"]["lng"],
  //                 "icon": Icons.place,
  //               };
  //             }).toList();
  //             _cachedPlaces = _commonPlaces;

  //         isPlacesLoading = false;
  //       });
  //     } else {
  //       setState(() => isPlacesLoading = false);
  //     }
  //   } catch (e) {
  //     debugPrint("Nearby places error: $e");
  //     setState(() => isPlacesLoading = false);
  //   }
  // }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _suggestions.clear();
    });

    // final apiKey = "YOUR_GOOGLE_API_KEY"; // replace with your key
    // final url = Uri.parse(
    //   "https://maps.googleapis.com/maps/api/place/autocomplete/json"
    //   "?input=$query"
    //   "&key=$mapKey"
    //   "&components=country:ke", // Optional: restrict to Kenya or your country
    // );

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json"
      "?input=${Uri.encodeComponent(query)}"
      "&key=$mapKey"
      "&components=country:ke",
    );
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    // final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['status'] == 'OK') {
        if (mounted) {
          // setState(() {
          //   _suggestions = List<Map<String, dynamic>>.from(data['predictions']);
          //   _isLoading = false;
          // });

          //  final places =
          //     results.take(5).map((place) {
          //       return {
          //         "name": place["name"] ?? "Unknown",
          //         "address": place["vicinity"] ?? "",
          //         "lat": place["geometry"]["location"]["lat"],
          //         "lng": place["geometry"]["location"]["lng"],
          //         "icon": Icons.place,
          //       };
          //     }).toList();
          final predictions = data['predictions'] as List;

          setState(() {
            _suggestions =
                predictions.map((place) {
                  return {
                    "place_id": place["place_id"],
                    "description":
                        place["description"], // full text: "Garden City, Thika Road, Nairobi"
                    "main_text":
                        place["structured_formatting"]?["main_text"] ?? "",
                    "secondary_text":
                        place["structured_formatting"]?["secondary_text"] ?? "",
                    "icon": Icons.place,
                  };
                }).toList();
            _isLoading = false;
          });
        }
      } else {
        // _showError(data['error_message'] ?? "No results found.");
        setState(() => _isLoading = false);
      }
    } else {
      _showError("Suggestion fetch failed");
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _fetchCurrentLocation() async {
  //   try {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       setState(() => pickupController.text = "Location services disabled");
  //       return;
  //     }

  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         setState(() => pickupController.text = "Permission denied");
  //         return;
  //       }
  //     }

  //     if (permission == LocationPermission.deniedForever) {
  //       setState(() => pickupController.text = "Permission permanently denied");
  //       return;
  //     }

  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     CurrentLocation = LatLng(position.latitude, position.longitude);
  //     _getAddressFromLatLng(CurrentLocation!);
  //   } catch (e) {
  //     debugPrint("Error fetching location: $e");
  //     setState(() => pickupController.text = "Unable to fetch location");
  //   }
  // }

  Future<void> _fetchCurrentLocation() async {
    try {
      // ✅ 1. Check service (fast)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => pickupController.text = "Location services disabled");
        return;
      }

      // ✅ 2. Check permission (no delay)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => pickupController.text = "Permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => pickupController.text = "Permission permanently denied");
        return;
      }

      // ✅ 3. FAST LOCATION FIRST (last known)
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        CurrentLocation = LatLng(lastPosition.latitude, lastPosition.longitude);

        _isPickupLoaded = true;

        if (mounted) {
          setState(() {
            pickupController.text = "Fetching location...";
          });
        }

        // 🔥 Don't wait → run in background
        _getPlaceNameFromLatLng(CurrentLocation!);
      }

      // ✅ 4. THEN GET FRESH LOCATION (non-blocking)
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // ⚡ faster
      ).then((position) {
        CurrentLocation = LatLng(position.latitude, position.longitude);

        if (!mounted) return;

        setState(() {
          _isPickupLoaded = true;
        });

        // 🔥 Update address in background
        _getPlaceNameFromLatLng(CurrentLocation!);
      });
    } catch (e) {
      debugPrint("Error fetching location: $e");

      if (!mounted) return;
      setState(() => pickupController.text = "Unable to fetch location");
    }
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
  // Future<void> _fetchCurrentLocation() async {
  //   try {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       setState(() => pickupController.text = "Location services disabled");
  //       return;
  //     }

  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         setState(() => pickupController.text = "Permission denied");
  //         return;
  //       }
  //     }

  //     if (permission == LocationPermission.deniedForever) {
  //       setState(() => pickupController.text = "Permission permanently denied");
  //       return;
  //     }

  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     CurrentLocation = LatLng(position.latitude, position.longitude);

  //     _isPickupLoaded = true;
  //     await _getPlaceNameFromLatLng(CurrentLocation!);

  //     //await _getAddressFromLatLng(CurrentLocation!);

  //     // ✅ Trigger navigation
  //     //  _navigateIfReady();
  //   } catch (e) {
  //     debugPrint("Error fetching location: $e");
  //     setState(() => pickupController.text = "Unable to fetch location");
  //   }
  // }
  // Future<void> _getAddressFromLatLng(LatLng latLng) async {
  //   try {
  //     final placemarks = await placemarkFromCoordinates(
  //       latLng.latitude,
  //       latLng.longitude,
  //     );
  //     String address;
  //     if (placemarks.isNotEmpty) {
  //       final place = placemarks.first;
  //       address =
  //           "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
  //     } else {
  //       address = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
  //     }

  //     setState(() {
  //       if (widget.initialPickupLocation != null) {
  //         pickupController.text = address;
  //       } else {
  //         pickupController.text = address;
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint("Reverse geocoding failed: $e");
  //   }
  // }
  // Future<void> _getAddressFromLatLng(LatLng latLng) async {
  //   try {
  //     final placemarks = await placemarkFromCoordinates(
  //       latLng.latitude,
  //       latLng.longitude,
  //     );

  //     String address;

  //     if (placemarks.isNotEmpty) {
  //       final p = placemarks.first;

  //       // Uber-style dynamic formatting
  //       final parts = [
  //         if (p.name != null && p.name!.isNotEmpty) p.name,
  //         if (p.street != null && p.street!.isNotEmpty) p.street,
  //         if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
  //         if (p.locality != null && p.locality!.isNotEmpty) p.locality,
  //         if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
  //           p.administrativeArea,
  //       ];

  //       address = parts.join(", ");
  //     } else {
  //       address = "Lat: ${latLng.latitude}, Lng: ${latLng.longitude}";
  //     }

  //     setState(() {
  //       pickupController.text = address;
  //     });
  //   } catch (e) {
  //     debugPrint("Reverse geocoding failed: $e");
  //   }
  // }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      String address;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // ✅ CLEAN Uber-style
        address =
            p.name ??
            p.street ??
            p.subLocality ??
            p.locality ??
            "Current Location";
      } else {
        address = "Current Location";
      }

      setState(() {
        pickupController.text = address;
      });
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  Future<void> _getPlaceNameFromLatLng(LatLng latLng) async {
    try {
      final url =
          // "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          // "?location=${latLng.latitude},${latLng.longitude}"
          // "&radius=100"
          // "&type=point_of_interest"
          // "&key=$mapKey";
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&rankby=distance&type=establishment&key=$mapKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].length > 0) {
          final place = data["results"][0];

          setState(() {
            pickupController.text = place["name"];
          });
          return;
        }
      }

      // fallback
      await _getAddressFromLatLng(latLng);
    } catch (e) {
      debugPrint("Place fetch failed: $e");
    }
  }

  Future<void> _onSuggestionTap(Map<String, dynamic> place) async {
    LatLng latLng;
    String name;

    // ✅ STEP 1: Resolve location FIRST
    if (place['place_id'] == null) {
      latLng = LatLng(
        place['geometry']['location']['lat'],
        place['geometry']['location']['lng'],
      );

      name = place['description'] ?? "Selected location";
    } else {
      final placeId = place['place_id'];

      final detailsUrl = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId"
        "&key=$mapKey",
      );

      final res = await http.get(detailsUrl);
      if (res.statusCode != 200) {
        _showError("Failed to get location details");
        return;
      }

      final details = json.decode(res.body);
      if (details['status'] != 'OK') {
        _showError(details['error_message'] ?? "Failed to get details");
        return;
      }

      final location = details['result']['geometry']['location'];
      latLng = LatLng(location['lat'], location['lng']);

      name =
          details['result']['name'] ?? details['result']['formatted_address'];
    }

    // ✅ STEP 2: HANDLE STOP (NOW SAFE)
    // if (_activeStopIndex != null) {
    //   setState(() {
    //     stopControllers[_activeStopIndex!].text = name;
    //   });

    //   _addStop({
    //     "lat": latLng.latitude,
    //     "lng": latLng.longitude,
    //     "description": name,
    //   });

    //   _activeStopIndex = null;
    //   _suggestions.clear();
    //   return;
    // }
    // ✅ STEP 2: HANDLE STOP (NOW SAFE)
    if (_activeStopIndex != null) {
      setState(() {
        // Update the stop text
        stopControllers[_activeStopIndex!].text = name;

        // Add the stop to the state
        _addStop({
          "lat": latLng.latitude,
          "lng": latLng.longitude,
          "description": name,
        });

        // Reset active stop index
        _activeStopIndex = null;

        // Clear suggestions inside setState so UI updates
        _suggestions.clear();
      });
      return;
    }

    // ✅ STEP 3: COMMON STATE
    setState(() {
      _selectedPlace = {
        'lat': latLng.latitude,
        'lng': latLng.longitude,
        'name': name,
      };
      _suggestions.clear();
    });

    // ✅ STEP 4: PICKUP
    if (_selectingPickup) {
      CurrentLocation = latLng;
      pickupController.text = name;
      return;
    }

    // ✅ STEP 5: DESTINATION
    ref.read(destinationLocationProvider.notifier).state = latLng;
    destinationController.text = name;

    final pickup = CurrentLocation;

    if (widget.category == VehicleCategory.waterBowser) {
      Navigator.pop(context, latLng);
      return;
    }

    if (pickup != null ||
        (widget.category == VehicleCategory.waterBowser ||
            widget.category == VehicleCategory.exhauster)) {
      Widget screen;

      if (widget.IsScheduled != true) {
        if (widget.category == VehicleCategory.passenger) {
          screen = HomeScreen(
            pickup: pickup,
            destination: latLng,
            stops: ref.read(stopsProvider),
            category: widget.category,
            isScheduled: widget.IsScheduled,
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else if (widget.category == VehicleCategory.movers) {
          Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
        } else if (widget.category == VehicleCategory.cargo) {
          Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
        } else if (widget.category == VehicleCategory.exhauster) {
          Navigator.pop(context, latLng);
        } else if (widget.category == VehicleCategory.waterBowser) {
          Navigator.pop(context, latLng);
        } else if (widget.category == VehicleCategory.breakdown) {
          Navigator.pop(context, latLng);
        } else if (widget.category == VehicleCategory.ambulance) {
          Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
        }
      } else {
        screen = ScheduleRideScreen(
          pickupLocation: pickup,
          dropLocation: latLng,
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    } else {
      _showError("Please set pickup location first.");
    }
  }

  Future<void> _onSuggestionTapOld(Map<String, dynamic> place) async {
    final placeId = place['place_id'];

    // Fetch place details from Google
    final detailsUrl = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
      "?place_id=$placeId"
      "&key=$mapKey",
    );

    final res = await http.get(detailsUrl);
    if (res.statusCode != 200) {
      _showError("Failed to get location details");
      return;
    }

    final details = json.decode(res.body);
    if (details['status'] != 'OK') {
      _showError(details['error_message'] ?? "Failed to get details");
      return;
    }

    final location = details['result']['geometry']['location'];
    final latLng = LatLng(location['lat'], location['lng']);
    final name =
        details['result']['formatted_address'] ?? details['result']['name'];

    setState(() {
      _selectedPlace = {
        'lat': location['lat'],
        'lng': location['lng'],
        'name': name,
      };
      _suggestions.clear();
    });

    if (_selectingPickup) {
      // Save pickup location
      //ref.read(pickupLocationProvider.notifier).state
      CurrentLocation = latLng;
      pickupController.text = name;
      return;
      // if (widget.category == VehicleCategory.ambulance) {
      //   Navigator.pop(context, latLng);
      //   return;
      // Navigator.pop(
      // context,
      // LatLng(selectedLat!, selectedLng!),
      // );

      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(
      //       builder:
      //           (_) =>
      //               AmbulanceScreen(category: widget.category, pickup: latLng),
      //     ),
      //   );
      //   return; // Exit so it doesn't do anything else
      //}
    } else {
      // Save destination location
      ref.read(destinationLocationProvider.notifier).state = latLng;
      destinationController.text = name;
      final pickup = CurrentLocation; //ref.read(pickupLocationProvider);
      // If pickup is set, navigate
      //final pickup = ref.read(pickupLocationProvider);

      if (widget.category == VehicleCategory.waterBowser) {
        Navigator.pop(context, latLng);
        return;
      }
      if (pickup != null ||
          (widget.category == VehicleCategory.waterBowser ||
              widget.category == VehicleCategory.exhauster)) {
        Widget screen;

        if (widget.IsScheduled != true) {
          // if (widget.category == VehicleCategory.movers) {
          //     screen = MoversScreen(
          //     pickup: pickup,
          //     destination: latLng,
          //     category: VehicleCategory.movers,
          //   );
          //   Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

          // }
          if (widget.category == VehicleCategory.passenger) {
            screen = HomeScreen(
              pickup: pickup,
              destination: latLng,
              stops: ref.read(stopsProvider),
              category: widget.category,
            );
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
          // else if (widget.category == VehicleCategory.cargo) {
          //   screen = CargoTransportScreen(
          //     category: widget.category,
          //     pickup: pickup,
          //     destination: latLng,
          //   );
          //   Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          // }
          // else if (widget.category == VehicleCategory.waterBowser) {
          //   screen = WaterBowerScreen(
          //     category: widget.category,
          //     destination: latLng,
          //   );
          //   Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          // }
          // else if (widget.category == VehicleCategory.movers) {
          //   screen = MoversScreen(
          //     category: widget.category,
          //     destination: latLng,
          //     pickup: pickup,
          //   );
          //   Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          // }
          else if (widget.category == VehicleCategory.movers) {
            Navigator.pop(context, {'destination': latLng, 'pickup': pickup});

            // Navigator.pop(context, latLng,pickup);
          } else if (widget.category == VehicleCategory.cargo) {
            Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
          } else if (widget.category == VehicleCategory.exhauster) {
            Navigator.pop(context, latLng);
          } else if (widget.category == VehicleCategory.waterBowser) {
            Navigator.pop(context, latLng);
          } else if (widget.category == VehicleCategory.breakdown) {
            Navigator.pop(context, latLng);
          } else if (widget.category == VehicleCategory.ambulance) {
            Navigator.pop(context, {'destination': latLng, 'pickup': pickup});

            // screen = AmbulanceScreen(
            //   category: widget.category,
            //   pickup: pickup,
            //   destination: latLng,
            // );
            // Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        } else {
          screen = ScheduleRideScreen(
            pickupLocation: pickup,
            dropLocation: latLng,
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      } else {
        _showError("Please set pickup location first.");
      }
    }
  }

  Future<LatLng?> _fetchPickupFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final refDB = FirebaseDatabase.instance.ref(
        'passengers/${user.uid}/location',
      );

      final snapshot = await refDB.get();
      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return null;

      // Assuming data has 'latitude' and 'longitude' keys
      final lat = data['latitude'];
      final lng = data['longitude'];

      if (lat == null || lng == null) return null;

      return LatLng(lat.toDouble(), lng.toDouble());
    } catch (e) {
      debugPrint('Failed to fetch pickup location from Firebase: $e');
      return null;
    }
  }

  void _addStop(Map<String, dynamic> place) {
    final lat = place['geometry']?['location']?['lat'] ?? place['lat'];
    final lng = place['geometry']?['location']?['lng'] ?? place['lng'];

    final latLng = LatLng(lat, lng);
    final address = place['description'] ?? place['name'] ?? "Stop";

    final currentStops = ref.read(stopsProvider);

    // ✅ LIMIT TO 3
    if (currentStops.length >= 3) {
      _showError("You can only add up to 3 stops.");
      return;
    }

    // ✅ PREVENT DUPLICATES
    final isDuplicate = currentStops.any(
      (stop) =>
          stop['latLng'].latitude == lat && stop['latLng'].longitude == lng,
    );

    if (isDuplicate) {
      _showError("This stop is already added.");
      return;
    }

    ref.read(stopsProvider.notifier).state = [
      ...currentStops,
      {'latLng': latLng, 'address': address},
    ];

    _showMessage("Stop added.");
  }
  // void _addStop(Map<String, dynamic> place) {
  //   final lat = double.parse(place['lat']);
  //   final lon = double.parse(place['lon']);
  //   final latLng = LatLng(lat, lon);
  //   final address = place['display_name'];

  //   final currentStops = ref.read(stopsProvider);

  //   final isDuplicate = currentStops.any(
  //     (stop) =>
  //         stop['latLng'].latitude == lat && stop['latLng'].longitude == lon,
  //   );

  //   if (isDuplicate) {
  //     _showError("This stop is already added.");
  //     return;
  //   }

  //   ref.read(stopsProvider.notifier).state = [
  //     ...currentStops,
  //     {'latLng': latLng, 'address': address},
  //   ];
  //   _showMessage("Stop added.");
  // }

  // void _showError(String msg) {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  // }

  // void _showMessage(String msg) {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  // }

  // Widget _buildSkeleton() {
  //   return Shimmer.fromColors(
  //     baseColor: Colors.grey.shade300,
  //     highlightColor: Colors.grey.shade100,
  //     child: Column(
  //       children: [
  //         Container(height: 50, color: Colors.white),
  //         const SizedBox(height: 20),
  //         Container(height: 60, color: Colors.white),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSuggestionSkeleton() {
  //   return Column(
  //     children: List.generate(3, (index) {
  //       return Shimmer.fromColors(
  //         baseColor: Colors.grey.shade300,
  //         highlightColor: Colors.grey.shade100,
  //         child: ListTile(
  //           leading: Container(height: 30, width: 30, color: Colors.white),
  //           title: Container(height: 12, color: Colors.white),
  //         ),
  //       );
  //     }),
  //   );
  // }

  // Widget _buildFullScreenSkeleton() {
  //   return Shimmer.fromColors(
  //     baseColor: Colors.grey.shade300,
  //     highlightColor: Colors.grey.shade100,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           Container(height: 60, color: Colors.white),
  //           const SizedBox(height: 12),
  //           Container(height: 60, color: Colors.white),
  //           const SizedBox(height: 20),
  //           ...List.generate(5, (index) {
  //             return Container(
  //               margin: const EdgeInsets.only(bottom: 12),
  //               height: 70,
  //               color: Colors.white,
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (!_isPickupLoaded &&
        (widget.category == VehicleCategory.passenger ||
            widget.category == VehicleCategory.exhauster)) {
      return Scaffold(
        body:
            isPlacesLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                )
                : const Center(child: Text("Loading pickup...")),
      );
    }

    final stops = ref.watch(stopsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Enter",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔷 SCROLLABLE INPUT CARD
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 400, // adjust max height as needed
              ),
              child: SingleChildScrollView(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// 🔷 SPECIAL CASE (NO PICKUP)
                      if (widget.category == VehicleCategory.exhauster ||
                          widget.category == VehicleCategory.waterBowser) ...[
                        _buildLocationField(
                          controller: destinationController,
                          icon: Icons.location_on,
                          iconColor: Colors.red,
                          hint:
                              widget.category == VehicleCategory.exhauster
                                  ? "Collection Location"
                                  : "Enter Destination",
                          onTap: () {
                            setState(() {
                              _selectingPickup = false;
                              _suggestions.clear();
                            });
                          },
                        ),
                      ] else ...[
                        /// 🔷 PICKUP
                        _buildLocationField(
                          controller: pickupController,
                          icon: Icons.my_location,
                          iconColor: Colors.green,
                          hint: "Set Pickup Location",
                          onTap: () {
                            setState(() {
                              _selectingPickup = true;
                              _activeStopIndex = null;
                              _suggestions.clear();
                            });
                          },
                        ),
                        const Divider(height: 1, color: Colors.grey),

                        /// 🔷 STOPS
                        ...List.generate(stopControllers.length, (index) {
                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildLocationField(
                                      controller: stopControllers[index],
                                      icon: Icons.trip_origin,
                                      iconColor: Colors.orange,
                                      hint: "Stop ${index + 1}",
                                      onTap: () {
                                        setState(() {
                                          _selectingPickup = false;
                                          _activeStopIndex = index;
                                          _suggestions.clear();
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        stopControllers[index].dispose();
                                        stopControllers.removeAt(index);

                                        if (stops.length > index) {
                                          final updatedStops = [...stops]
                                            ..removeAt(index);
                                          ref
                                              .read(stopsProvider.notifier)
                                              .state = updatedStops;
                                        }

                                        if (_activeStopIndex == index)
                                          _activeStopIndex = null;
                                        _suggestions.clear();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 1, color: Colors.grey),
                            ],
                          );
                        }),

                        /// 🔷 DESTINATION + ADD BUTTON
                        Row(
                          children: [
                            Expanded(
                              child: _buildLocationField(
                                controller: destinationController,
                                icon: Icons.location_on,
                                iconColor: Colors.red,
                                hint: "Enter Destination",
                                onTap: () {
                                  setState(() {
                                    _selectingPickup = false;
                                    _activeStopIndex = null;
                                    _suggestions.clear();
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.black,
                                size: 28,
                              ),
                              onPressed: _addStopField,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔷 EXPANDED CONTENT BELOW (Nearby Places / Search / Stops)
            Expanded(child: _buildExpandedContent(stops)),
          ],
        ),
      ),
    );
  }

  /// 🔷 HELPER METHOD FOR EXPANDED CONTENT
  Widget _buildExpandedContent(List stops) {
    // if (_isLoading) {
    //   return _buildSuggestionSkeleton();
    // }

    if (_suggestions.isNotEmpty) {
      return ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (_, index) {
          final place = _suggestions[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,

            child: ListTile(
              leading: Icon(place['icon'], color: Colors.blue),

              // leading: const Icon(

              //   leading: Icon(place['icon'], color: Colors.blue),
              //   Icons.place_outlined,
              //   color: Colors.blueAccent,
              // ),

              //  title: Text(place['name']),
              //               subtitle: Text(place['address']),
              //               onTap: () {
              //                 _onSuggestionTap({
              //                   "place_id": null,
              //                   "geometry": {
              //                     "location": {"lat": place['lat'], "lng": place['lng']},
              //                   },
              //                   "description": place['name'],
              //                 });
              //               },
              title: Text(
                place['main_text'], // short: Garden City
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                place['secondary_text'], // secondary: Thika Road, Nairobi
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              // title: Text(
              //   place['name'],
              //   style: const TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              onTap: () => _onSuggestionTap(place),
            ),
          );
        },
      );
    }

    if (_suggestions.isEmpty && stops.isNotEmpty) {
      return ListView.builder(
        itemCount: stops.length,
        itemBuilder: (_, index) {
          final stop = stops[index];
          final latLng = stop['latLng'] as LatLng;
          final address = stop['address'] as String;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(address),
              subtitle: Text(
                '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  final updatedStops = List<Map<String, dynamic>>.from(stops)
                    ..removeAt(index);
                  ref.read(stopsProvider.notifier).state = updatedStops;
                },
              ),
            ),
          );
        },
      );
    }

    if (_suggestions.isEmpty &&
        widget.category == VehicleCategory.passenger &&
        !_selectingPickup) {
      return
      // isPlacesLoading
      //     ? _buildSkeleton()
      //     :
      ListView.builder(
        itemCount: _commonPlaces.length,
        itemBuilder: (_, index) {
          final place = _commonPlaces[index];
          return Card(
            child: ListTile(
              leading: Icon(place['icon'], color: Colors.blue),
              title: Text(
                place['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              subtitle: Text(
                place['address'],
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              onTap: () {
                _onSuggestionTap({
                  "place_id": null,
                  "geometry": {
                    "location": {"lat": place['lat'], "lng": place['lng']},
                  },
                  "description": place['name'],
                });
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}

class LocationResult {
  final LatLng pickup;
  final LatLng destination;

  LocationResult({required this.pickup, required this.destination});
}


 //////working
  // Future<void> _fetchSuggestions(String query) async {
  //   setState(() {
  //     _isLoading = true;
  //     _suggestions.clear();
  //   });

  //   final url = Uri.parse(
  //     "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
  //   );
  //   final res = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

  //   if (res.statusCode == 200) {
  //     final List data = json.decode(res.body);
  //     if (mounted) {
  //       setState(() {
  //         _suggestions = data.cast<Map<String, dynamic>>();
  //         _isLoading = false;
  //       });
  //     }
  //     // setState(() {
  //     //   _suggestions = data.cast<Map<String, dynamic>>();
  //     //   _isLoading = false;
  //     // });
  //   } else {
  //     _showError("Suggestion fetch failed");
  //   }
  // }

  /////working
  // void _onSuggestionTap(Map<String, dynamic> place) async {
  //   final lat = double.parse(place['lat']);
  //   final lon = double.parse(place['lon']);
  //   final displayName = place['display_name'];

  //   final latLng = LatLng(lat, lon);

  //   setState(() {
  //     _selectedPlace = place;
  //     _suggestions.clear();
  //   });

  //   final favorite = FavoriteLocation(name: displayName, lat: lat, lon: lon);
  //   await FavoriteLocationService.addFavorite(favorite);
  //   //_showMessage("Added to favorites");

  //   if (_selectingPickup) {
  //     ref.read(pickupLocationProvider.notifier).state = latLng;
  //     pickupController.text = displayName;
  //   } else {
  //     ref.read(destinationLocationProvider.notifier).state = latLng;
  //     destinationController.text = displayName;

  //     final pickup = ref.read(pickupLocationProvider);
  //     if (pickup != null ||
  //         (widget.category == VehicleCategory.waterBowser ||
  //             widget.category == VehicleCategory.exhauster)) {
  //       // Navigator.push(
  //       //   context,
  //       //   MaterialPageRoute(
  //       //     builder:
  //       //         (_) => HomeScreen(
  //       //           pickup: pickup,
  //       //           destination: latLng,
  //       //           stops: ref.read(stopsProvider),
  //       //         ),
  //       //   ),
  //       // );

  //       Widget screen;

  //       // if (widget.category.toUpperCase() == 'MOVERS') {
  //       //   screen = MoversScreen(
  //       //    pickupLocation : pickup,
  //       //     dropLocation: latLng,
  //       //     stops: ref.read(stopsProvider),
  //       //   );
  //       // } else {
  //       //   screen = HomeScreen(
  //       //     pickup: pickup,
  //       //     destination: latLng,
  //       //     stops: ref.read(stopsProvider),
  //       //   );
  //       // }
  //       if (widget.IsScheduled != true) {
  //         if (widget.category == VehicleCategory.movers) {
  //           screen = MoversScreen(
  //             pickupLocation: pickup,
  //             dropLocation: latLng,
  //             category: VehicleCategory.movers,
  //           );
  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //         } else if (widget.category == VehicleCategory.passenger) {
  //           screen = HomeScreen(
  //             pickup: pickup,
  //             destination: latLng,
  //             stops: ref.read(stopsProvider),
  //             category: widget.category,
  //           );
  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //         } else if (widget.category == VehicleCategory.cargo) {
  //           screen = CargoTransportScreen(
  //             category: widget.category,
  //             pickup: pickup,
  //             destination: latLng,
  //           );

  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //         } else if (widget.category == VehicleCategory.waterBowser) {
  //           screen = WaterBowerScreen(
  //             category: widget.category,
  //             //pickup: pickup,
  //             destination: latLng,
  //           );

  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //         } else if (widget.category == VehicleCategory.exhauster) {
  //           // screen = HoneySuckerScreen(
  //           //   category: widget.category,
  //           //   //pickup: pickup,
  //           //   destination: latLng,
  //           // );

  //           // Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //           Navigator.pop(context, latLng);
  //         }
  //       } else {
  //         screen = ScheduleRideScreen(
  //           pickupLocation: pickup,
  //           dropLocation: latLng,
  //           // stops: ref.read(stopsProvider),
  //           // category: widget.category,
  //         );
  //         Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //       }
  //     } else {
  //       _showError("Please set pickup location first.");
  //     }
  //   }
  // }

   // Card(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     children: [
            //       if (widget.category == VehicleCategory.ambulance)
            //         ListTile(
            //           leading: const Icon(
            //             Icons.my_location,
            //             color: Colors.green,
            //           ),
            //           title: TextField(
            //             controller: pickupController,
            //             decoration: const InputDecoration(
            //               border: InputBorder.none,
            //               hintText: "Set Pickup Location",
            //             ),
            //             onTap: () {
            //               setState(() {
            //                 _selectingPickup = true;
            //                 _suggestions.clear();
            //               });
            //             },
            //           ),
            //         ),

            //       // if (widget.category != VehicleCategory.waterBowser &&
            //       //     widget.category != VehicleCategory.exhauster) ...[
            //       //   ListTile(
            //       //     leading: const Icon(
            //       //       Icons.my_location,
            //       //       color: Colors.green,
            //       //     ),
            //       //     title: TextField(
            //       //       controller: pickupController,
            //       //       decoration: const InputDecoration(
            //       //         border: InputBorder.none,
            //       //         hintText: "Set Pickup Location",
            //       //       ),
            //       //       onTap: () {
            //       //         setState(() {
            //       //           _selectingPickup = true;
            //       //           _suggestions.clear();
            //       //         });
            //       //       },
            //       //     ),
            //       //   ),
            //       if (widget.category != VehicleCategory.ambulance &&
            //           widget.category != VehicleCategory.waterBowser &&
            //           widget.category != VehicleCategory.exhauster) ...[
            //         ListTile(
            //           leading: const Icon(
            //             Icons.my_location,
            //             color: Colors.green,
            //           ),
            //           title: TextField(
            //             controller: pickupController,
            //             decoration: const InputDecoration(
            //               border: InputBorder.none,
            //               hintText: "Set Pickup Location",
            //             ),
            //             onTap: () {
            //               setState(() {
            //                 _selectingPickup = true;
            //                 _suggestions.clear();
            //               });
            //             },
            //           ),
            //         ),
            //         const Divider(),
            //       ],
            //       ListTile(
            //         leading: const Icon(Icons.location_on, color: Colors.red),
            //         title: TextField(
            //           controller: destinationController,
            //           decoration: const InputDecoration(
            //             border: InputBorder.none,
            //             hintText: "Enter Destination",
            //           ),
            //           onTap: () {
            //             setState(() {
            //               _selectingPickup = false;
            //               _suggestions.clear();
            //             });
            //           },
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Card(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Column(
            //     children: [
            //       // Ambulance — pickup only
            //       if (widget.category == VehicleCategory.ambulance)
            //         ListTile(
            //           leading: const Icon(
            //             Icons.my_location,
            //             color: Colors.green,
            //           ),
            //           title: TextField(
            //             controller: pickupController,
            //             decoration: const InputDecoration(
            //               border: InputBorder.none,
            //               hintText: "Set Pickup Location",
            //             ),
            //             onTap: () {
            //               setState(() {
            //                 _selectingPickup = true;
            //                 _suggestions.clear();
            //               });
            //             },
            //           ),
            //         ),

            //       // Other categories (except waterBowser & exhauster) — pickup + destination
            //       if (widget.category != VehicleCategory.ambulance &&
            //           widget.category != VehicleCategory.waterBowser &&
            //           widget.category != VehicleCategory.exhauster) ...[
            //         ListTile(
            //           leading: const Icon(
            //             Icons.my_location,
            //             color: Colors.green,
            //           ),
            //           title: TextField(
            //             controller: pickupController,
            //             decoration: const InputDecoration(
            //               border: InputBorder.none,
            //               hintText: "Set Pickup Location",
            //             ),
            //             onTap: () {
            //               setState(() {
            //                 _selectingPickup = true;
            //                 _suggestions.clear();
            //               });
            //             },
            //           ),
            //         ),
            //         const Divider(),
            //         ListTile(
            //           leading: const Icon(Icons.location_on, color: Colors.red),
            //           title: TextField(
            //             controller: destinationController,
            //             decoration: const InputDecoration(
            //               border: InputBorder.none,
            //               hintText: "Enter Destination",
            //             ),
            //             onTap: () {
            //               setState(() {
            //                 _selectingPickup = false;
            //                 _suggestions.clear();
            //               });
            //             },
            //           ),
            //         ),
            //       ],
            //     ],
            //   ),
            // ),

             // Ambulance — pickup only
                  // if (widget.category == VehicleCategory.ambulance) ...[
                  //   ListTile(
                  //     leading: const Icon(
                  //       Icons.my_location,
                  //       color: Colors.green,
                  //     ),
                  //     title: TextField(
                  //       controller: pickupController,
                  //       decoration: const InputDecoration(
                  //         border: InputBorder.none,
                  //         hintText: "Set Pickup Location",
                  //       ),
                  //       onTap: () {
                  //         setState(() {
                  //           _selectingPickup = true;
                  //           _suggestions.clear();
                  //         });
                  //       },
                  //     ),
                  //   ),
                  // ]
                  // Exhauster & WaterBowser — destination only



                   // @override
  // Widget build(BuildContext context) {
  //   // if (!_isPickupLoaded &&
  //   //     (widget.category == VehicleCategory.passenger ||
  //   //         widget.category == VehicleCategory.exhauster)) {
  //   //   return const Scaffold(body: Center(child: CircularProgressIndicator()));
  //   // }
  //   if (!_isPickupLoaded &&
  //       (widget.category == VehicleCategory.passenger ||
  //           widget.category == VehicleCategory.exhauster)) {
  //     return Scaffold(body: _buildFullScreenSkeleton());
  //   }
  //   final stops = ref.watch(stopsProvider);
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF9FAFB), // Light background
  //     appBar: AppBar(
  //       backgroundColor: Colors.white,
  //       elevation: 2,
  //       title: const Text(
  //         "Enter",
  //         style: TextStyle(
  //           color: Colors.black,
  //           fontSize: 24,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       centerTitle: true,
  //       iconTheme: const IconThemeData(color: Colors.black),
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           AnimatedContainer(
  //             duration: const Duration(milliseconds: 300),
  //             curve: Curves.easeInOut,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(16),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.15),
  //                   blurRadius: 8,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               children: [
  //                 if (widget.category == VehicleCategory.exhauster ||
  //                     widget.category == VehicleCategory.waterBowser) ...[
  //                   _buildLocationField(
  //                     controller: destinationController,
  //                     icon: Icons.location_on,
  //                     iconColor: Colors.red,

  //                     // hint: "Enter Destination",
  //                     hint:
  //                         widget.category == VehicleCategory.exhauster
  //                             ? "Collection Location"
  //                             : "Enter Destination",

  //                     onTap: () {
  //                       setState(() {
  //                         _selectingPickup = false;
  //                         _suggestions.clear();
  //                       });
  //                     },
  //                   ),
  //                 ] else ...[
  //                   _buildLocationField(
  //                     controller: pickupController,
  //                     icon: Icons.my_location,
  //                     iconColor: Colors.green,
  //                     hint: "Set Pickup Location",
  //                     onTap: () {
  //                       setState(() {
  //                         _selectingPickup = true;
  //                         _suggestions.clear();
  //                       });
  //                     },
  //                   ),
  //                   const Divider(height: 1, color: Colors.grey),

  //                   //const Divider(),
  //                   // Padding(
  //                   //   padding: const EdgeInsets.symmetric(horizontal: 16),
  //                   //   child: Column(
  //                   //     children: const [
  //                   //       Icon(
  //                   //         Icons.arrow_downward,
  //                   //         color: Colors.grey,
  //                   //         size: 20,
  //                   //       ),
  //                   //     ],
  //                   //   ),
  //                   // ),
  //                   // _buildLocationField(
  //                   //   controller: destinationController,
  //                   //   icon: Icons.location_on,
  //                   //   iconColor: Colors.red,
  //                   //   hint: "Enter Destination",
  //                   //   onTap: () {
  //                   //     setState(() {
  //                   //       _selectingPickup = false;
  //                   //       _suggestions.clear();
  //                   //     });
  //                   //   },
  //                   // ),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: _buildLocationField(
  //                           controller: destinationController,
  //                           icon: Icons.location_on,
  //                           iconColor: Colors.red,
  //                           hint: "Enter Destination",
  //                           onTap: () {
  //                             setState(() {
  //                               _selectingPickup = false;
  //                               _suggestions.clear();
  //                             });
  //                           },
  //                         ),
  //                       ),

  //                       // ➕ ADD STOP BUTTON (RIGHT SIDE)
  //                       IconButton(
  //                         icon: const Icon(
  //                           Icons.add_circle,
  //                           color: Colors.blue,
  //                           size: 28,
  //                         ),
  //                         onPressed: _addStopField,
  //                       ),
  //                     ],
  //                   ),

  //                   _buildLocationField(
  //                     controller: destinationController,
  //                     icon: Icons.location_on,
  //                     iconColor: Colors.red,
  //                     hint:
  //                         widget.category == VehicleCategory.exhauster
  //                             ? "Collection Location"
  //                             : "Enter Destination",
  //                     onTap: () {
  //                       setState(() {
  //                         _selectingPickup = false;
  //                         _suggestions.clear();
  //                       });
  //                     },
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //           // if (_isLoading)
  //           //   const Padding(
  //           //     padding: EdgeInsets.all(8),
  //           //     child: LinearProgressIndicator(),
  //           //   ),
  //           if (_isLoading)
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 10),
  //               child: _buildSuggestionSkeleton(),
  //             ),
  //           const SizedBox(height: 10),

  //           // if (_suggestions.isEmpty && _commonPlaces.isNotEmpty)
  //           //   Expanded(
  //           //     child: ListView.builder(
  //           //       itemCount: _commonPlaces.length,
  //           //       itemBuilder: (_, index) {
  //           //         final place = _commonPlaces[index];
  //           //         return Card(
  //           //           child: ListTile(
  //           //             leading: Icon(place['icon'], color: Colors.blue),
  //           //             title: Text(place['name']),
  //           //             subtitle: Text(place['address']),
  //           //             onTap:
  //           //                 () => _onSuggestionTap({
  //           //                   "place_id": null,
  //           //                   "geometry": {
  //           //                     "location": {
  //           //                       "lat": place['lat'],
  //           //                       "lng": place['lng'],
  //           //                     },
  //           //                   },
  //           //                   "description": place['name'],
  //           //                 }),
  //           //           ),
  //           //         );
  //           //       },
  //           //     ),
  //           //   ),
  //           if (_suggestions.isEmpty &&
  //               widget.category == VehicleCategory.passenger &&
  //               !_selectingPickup)
  //             Expanded(
  //               child:
  //                   isPlacesLoading
  //                       ? _buildSkeleton()
  //                       //const Center(child: CircularProgressIndicator())
  //                       : ListView.builder(
  //                         itemCount: _commonPlaces.length,
  //                         itemBuilder: (_, index) {
  //                           final place = _commonPlaces[index];

  //                           return Card(
  //                             child: ListTile(
  //                               leading: Icon(
  //                                 place['icon'],
  //                                 color: Colors.blue,
  //                               ),
  //                               title: Text(place['name']),
  //                               subtitle: Text(place['address']),
  //                               onTap: () {
  //                                 final latLng = LatLng(
  //                                   place['lat'],
  //                                   place['lng'],
  //                                 );

  //                                 destinationController.text = place['name'];

  //                                 _onSuggestionTap({
  //                                   "place_id": null,
  //                                   "geometry": {
  //                                     "location": {
  //                                       "lat": place['lat'],
  //                                       "lng": place['lng'],
  //                                     },
  //                                   },
  //                                   "description": place['name'],
  //                                 });
  //                               },
  //                             ),
  //                           );
  //                         },
  //                       ),
  //             ),

  //           // if (_suggestions.isNotEmpty)
  //           //   Expanded(
  //           //     child: ListView.builder(
  //           //       itemCount: _suggestions.length,
  //           //       itemBuilder: (_, index) {
  //           //         final place = _suggestions[index];
  //           //         return Card(
  //           //           shape: RoundedRectangleBorder(
  //           //             borderRadius: BorderRadius.circular(12),
  //           //           ),
  //           //           elevation: 2,
  //           //           child: ListTile(
  //           //             leading: const Icon(
  //           //               Icons.place_outlined,
  //           //               color: Colors.blueAccent,
  //           //             ),
  //           //             title: Text(
  //           //               place['description'] ??
  //           //                   place['structured_formatting']?['main_text'] ??
  //           //                   "Unknown",
  //           //               style: const TextStyle(
  //           //                 fontSize: 16,
  //           //                 fontWeight: FontWeight.w500,
  //           //               ),
  //           //             ),
  //           //             onTap: () => _onSuggestionTap(place),
  //           //           ),
  //           //         );
  //           //       },
  //           //     ),
  //           //   ),
  //           if (_suggestions.isNotEmpty)
  //             Expanded(
  //               child: AnimatedList(
  //                 initialItemCount: _suggestions.length,
  //                 itemBuilder: (context, index, animation) {
  //                   final place = _suggestions[index];
  //                   return SlideTransition(
  //                     position: animation.drive(
  //                       Tween(
  //                         begin: const Offset(1, 0),
  //                         end: Offset.zero,
  //                       ).chain(CurveTween(curve: Curves.easeOut)),
  //                     ),
  //                     child: Card(
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                       elevation: 2,
  //                       child: ListTile(
  //                         leading: const Icon(
  //                           Icons.place_outlined,
  //                           color: Colors.blueAccent,
  //                         ),
  //                         title: Text(
  //                           place['description'],
  //                           style: const TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                         onTap: () => _onSuggestionTap(place),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),

  //           if (stops.isNotEmpty)
  //             Expanded(
  //               child: ListView.builder(
  //                 itemCount: stops.length,
  //                 itemBuilder: (_, index) {
  //                   final stop = stops[index];
  //                   final latLng = stop['latLng'] as LatLng;
  //                   final address = stop['address'] as String;

  //                   return Card(
  //                     child: ListTile(
  //                       leading: CircleAvatar(child: Text('${index + 1}')),
  //                       title: Text(address),
  //                       subtitle: Text(
  //                         '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
  //                       ),
  //                       trailing: IconButton(
  //                         icon: const Icon(Icons.close, color: Colors.red),
  //                         onPressed: () {
  //                           final updatedStops = [...stops]..removeAt(index);
  //                           ref.read(stopsProvider.notifier).state =
  //                               updatedStops;
  //                         },
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),

  //           // if (_suggestions.isEmpty)
  //           //   Expanded(
  //           //     child: ListView.builder(
  //           //       itemCount: stops.length,
  //           //       itemBuilder: (_, index) {
  //           //         final stop = stops[index];
  //           //         final latLng = stop['latLng'] as LatLng;
  //           //         final address = stop['address'] as String;

  //           //         return Card(
  //           //           margin: const EdgeInsets.symmetric(vertical: 6),
  //           //           shape: RoundedRectangleBorder(
  //           //             borderRadius: BorderRadius.circular(12),
  //           //           ),
  //           //           elevation: 2,
  //           //           child: ListTile(
  //           //             leading: CircleAvatar(
  //           //               backgroundColor: Colors.blue,
  //           //               child: Text(
  //           //                 '${index + 1}',
  //           //                 style: const TextStyle(
  //           //                   color: Colors.white,
  //           //                   fontWeight: FontWeight.bold,
  //           //                 ),
  //           //               ),
  //           //             ),
  //           //             title: Text(
  //           //               address,
  //           //               style: const TextStyle(
  //           //                 fontSize: 16,
  //           //                 fontWeight: FontWeight.w500,
  //           //               ),
  //           //             ),
  //           //             subtitle: Text(
  //           //               '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
  //           //               style: const TextStyle(fontSize: 14),
  //           //             ),
  //           //             trailing: IconButton(
  //           //               icon: const Icon(
  //           //                 Icons.remove_circle,
  //           //                 color: Colors.redAccent,
  //           //               ),
  //           //               onPressed: () {
  //           //                 final updatedStops = [...stops]..removeAt(index);
  //           //                 ref.read(stopsProvider.notifier).state =
  //           //                     updatedStops;
  //           //               },
  //           //             ),
  //           //           ),
  //           //         );
  //           //       },
  //           //     ),
  //           //   ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

    // Future<void> _onSuggestionTap(Map<String, dynamic> place) async {
  //   LatLng latLng;
  //   String name;

  //   // ✅ HANDLE nearby places (no place_id)
  //   if (place['place_id'] == null) {
  //     latLng = LatLng(
  //       place['geometry']['location']['lat'],
  //       place['geometry']['location']['lng'],
  //     );

  //     name = place['description'] ?? "Selected location";
  //   } else {
  //     // 🔵 Existing Google flow (UNCHANGED)
  //     final placeId = place['place_id'];

  //     final detailsUrl = Uri.parse(
  //       "https://maps.googleapis.com/maps/api/place/details/json"
  //       "?place_id=$placeId"
  //       "&key=$mapKey",
  //     );

  //     final res = await http.get(detailsUrl);
  //     if (res.statusCode != 200) {
  //       _showError("Failed to get location details");
  //       return;
  //     }

  //     final details = json.decode(res.body);
  //     if (details['status'] != 'OK') {
  //       _showError(details['error_message'] ?? "Failed to get details");
  //       return;
  //     }

  //     final location = details['result']['geometry']['location'];
  //     latLng = LatLng(location['lat'], location['lng']);

  //     name =
  //         details['result']['name'] ?? // ✅ shorter (better UX)
  //         details['result']['formatted_address'];
  //   }

  //   // ✅ COMMON STATE (unchanged behavior)
  //   setState(() {
  //     _selectedPlace = {
  //       'lat': latLng.latitude,
  //       'lng': latLng.longitude,
  //       'name': name,
  //     };
  //     _suggestions.clear();
  //   });

  //   if (_selectingPickup) {
  //     CurrentLocation = latLng;
  //     pickupController.text = name;
  //     return;
  //   } else {
  //     ref.read(destinationLocationProvider.notifier).state = latLng;
  //     destinationController.text = name;
  //     final pickup = CurrentLocation;

  //     if (widget.category == VehicleCategory.waterBowser) {
  //       Navigator.pop(context, latLng);
  //       return;
  //     }

  //     if (pickup != null ||
  //         (widget.category == VehicleCategory.waterBowser ||
  //             widget.category == VehicleCategory.exhauster)) {
  //       Widget screen;

  //       if (widget.IsScheduled != true) {
  //         if (widget.category == VehicleCategory.passenger) {
  //           screen = HomeScreen(
  //             pickup: pickup,
  //             destination: latLng,
  //             stops: ref.read(stopsProvider),
  //             category: widget.category,
  //           );
  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //         } else if (widget.category == VehicleCategory.movers) {
  //           Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
  //         } else if (widget.category == VehicleCategory.cargo) {
  //           Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
  //         } else if (widget.category == VehicleCategory.exhauster) {
  //           Navigator.pop(context, latLng);
  //         } else if (widget.category == VehicleCategory.waterBowser) {
  //           Navigator.pop(context, latLng);
  //         } else if (widget.category == VehicleCategory.breakdown) {
  //           Navigator.pop(context, latLng);
  //         } else if (widget.category == VehicleCategory.ambulance) {
  //           Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
  //         }
  //       } else {
  //         screen = ScheduleRideScreen(
  //           pickupLocation: pickup,
  //           dropLocation: latLng,
  //         );
  //         Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //       }
  //     } else {
  //       _showError("Please set pickup location first.");
  //     }
  //   }
  // }

        // body: Padding(
      //   padding: const EdgeInsets.all(16),
      //   child: Column(
      //     children: [
      //       /// 🔷 INPUT CARD
      //       AnimatedContainer(
      //         duration: const Duration(milliseconds: 300),
      //         curve: Curves.easeInOut,
      //         decoration: BoxDecoration(
      //           color: Colors.white,
      //           borderRadius: BorderRadius.circular(16),
      //           boxShadow: [
      //             BoxShadow(
      //               color: Colors.black.withOpacity(0.15),
      //               blurRadius: 8,
      //               offset: const Offset(0, 4),
      //             ),
      //           ],
      //         ),
      //         child: Column(
      //           children: [
      //             /// 🔷 SPECIAL CASE (NO PICKUP)
      //             if (widget.category == VehicleCategory.exhauster ||
      //                 widget.category == VehicleCategory.waterBowser) ...[
      //               _buildLocationField(
      //                 controller: destinationController,
      //                 icon: Icons.location_on,
      //                 iconColor: Colors.red,
      //                 hint:
      //                     widget.category == VehicleCategory.exhauster
      //                         ? "Collection Location"
      //                         : "Enter Destination",
      //                 onTap: () {
      //                   setState(() {
      //                     _selectingPickup = false;
      //                     _suggestions.clear();
      //                   });
      //                 },
      //               ),
      //             ] else ...[
      //               /// 🔷 PICKUP
      //               /// 🔷 PICKUP
      //               _buildLocationField(
      //                 controller: pickupController,
      //                 icon: Icons.my_location,
      //                 iconColor: Colors.green,
      //                 hint: "Set Pickup Location",
      //                 onTap: () {
      //                   setState(() {
      //                     _selectingPickup = true;
      //                     _activeStopIndex = null;
      //                     _suggestions.clear();
      //                   });
      //                 },
      //               ),

      //               const Divider(height: 1, color: Colors.grey),

      //               /// 🔷 STOPS (NOW IN CORRECT POSITION)
      //               // ...List.generate(stopControllers.length, (index) {
      //               //   return Column(
      //               //     children: [
      //               //       _buildLocationField(
      //               //         controller: stopControllers[index],
      //               //         icon: Icons.trip_origin,
      //               //         iconColor: Colors.orange,
      //               //         hint: "Stop ${index + 1}",
      //               //         onTap: () {
      //               //           setState(() {
      //               //             _selectingPickup = false;
      //               //             _activeStopIndex = index; // ✅ VERY IMPORTANT
      //               //             _suggestions.clear();
      //               //           });
      //               //         },
      //               //       ),
      //               //       const Divider(height: 1, color: Colors.grey),
      //               //     ],
      //               //   );
      //               // }),
      //               ...List.generate(stopControllers.length, (index) {
      //                 return Column(
      //                   children: [
      //                     Row(
      //                       crossAxisAlignment: CrossAxisAlignment.center,
      //                       children: [
      //                         Expanded(
      //                           child: _buildLocationField(
      //                             controller: stopControllers[index],
      //                             icon: Icons.trip_origin,
      //                             iconColor: Colors.orange,
      //                             hint: "Stop ${index + 1}",
      //                             onTap: () {
      //                               setState(() {
      //                                 _selectingPickup = false;
      //                                 _activeStopIndex = index;
      //                                 _suggestions
      //                                     .clear(); // ✅ clear old suggestions
      //                               });
      //                             },
      //                           ),
      //                         ),

      //                         /// ❌ REMOVE BUTTON
      //                         if (stopControllers[index].text.isNotEmpty ||
      //                             stops.length > index)
      //                           IconButton(
      //                             icon: const Icon(
      //                               Icons.close,
      //                               color: Colors.red,
      //                             ),
      //                             onPressed: () {
      //                               setState(() {
      //                                 // ✅ Remove controller safely
      //                                 stopControllers[index].dispose();
      //                                 stopControllers.removeAt(index);

      //                                 // ✅ Remove stop safely (avoid crash)
      //                                 if (stops.length > index) {
      //                                   final updatedStops = [...stops]
      //                                     ..removeAt(index);
      //                                   ref.read(stopsProvider.notifier).state =
      //                                       updatedStops;
      //                                 }

      //                                 // ✅ Reset active index if needed
      //                                 if (_activeStopIndex == index) {
      //                                   _activeStopIndex = null;
      //                                 }

      //                                 _suggestions
      //                                     .clear(); // ✅ FIX: clear suggestions
      //                               });
      //                             },
      //                           ),
      //                       ],
      //                     ),

      //                     const Divider(height: 1, color: Colors.grey),
      //                   ],
      //                 );
      //               }),

      //               /// 🔷 DESTINATION + ADD BUTTON
      //               Row(
      //                 children: [
      //                   Expanded(
      //                     child: _buildLocationField(
      //                       controller: destinationController,
      //                       icon: Icons.location_on,
      //                       iconColor: Colors.red,
      //                       hint: "Enter Destination",
      //                       onTap: () {
      //                         setState(() {
      //                           _selectingPickup = false;
      //                           _activeStopIndex = null;
      //                           _suggestions.clear();
      //                         });
      //                       },
      //                     ),
      //                   ),
      //                   IconButton(
      //                     icon: const Icon(
      //                       Icons.add_circle,
      //                       color: Colors.blue,
      //                       size: 28,
      //                     ),
      //                     onPressed: _addStopField,
      //                   ),
      //                 ],
      //               ),
      //             ],
      //           ],
      //         ),
      //       ),

      //       /// 🔷 LOADING SUGGESTIONS
      //       if (_isLoading)
      //         Padding(
      //           padding: const EdgeInsets.symmetric(vertical: 10),
      //           child: _buildSuggestionSkeleton(),
      //         ),

      //       const SizedBox(height: 10),

      //       /// 🔷 NEARBY PLACES (ONLY WHEN NO SEARCH)
      //       if (_suggestions.isEmpty &&
      //           widget.category == VehicleCategory.passenger &&
      //           !_selectingPickup)
      //         Expanded(
      //           child:
      //               isPlacesLoading
      //                   ? _buildSkeleton()
      //                   : ListView.builder(
      //                     itemCount: _commonPlaces.length,
      //                     itemBuilder: (_, index) {
      //                       final place = _commonPlaces[index];

      //                       return Card(
      //                         child: ListTile(
      //                           leading: Icon(
      //                             place['icon'],
      //                             color: Colors.blue,
      //                           ),
      //                           title: Text(place['name']),
      //                           subtitle: Text(place['address']),
      //                           onTap: () {
      //                             _onSuggestionTap({
      //                               "place_id": null,
      //                               "geometry": {
      //                                 "location": {
      //                                   "lat": place['lat'],
      //                                   "lng": place['lng'],
      //                                 },
      //                               },
      //                               "description": place['name'],
      //                             });
      //                           },
      //                         ),
      //                       );
      //                     },
      //                   ),
      //         ),

      //       /// 🔷 SEARCH RESULTS
      //       if (_suggestions.isNotEmpty)
      //         Expanded(
      //           child: ListView.builder(
      //             itemCount: _suggestions.length,
      //             itemBuilder: (_, index) {
      //               final place = _suggestions[index];

      //               return Card(
      //                 shape: RoundedRectangleBorder(
      //                   borderRadius: BorderRadius.circular(12),
      //                 ),
      //                 elevation: 2,
      //                 child: ListTile(
      //                   leading: const Icon(
      //                     Icons.place_outlined,
      //                     color: Colors.blueAccent,
      //                   ),
      //                   title: Text(
      //                     place['description'],
      //                     style: const TextStyle(
      //                       fontSize: 16,
      //                       fontWeight: FontWeight.w500,
      //                     ),
      //                   ),
      //                   onTap: () => _onSuggestionTap(place),
      //                 ),
      //               );
      //             },
      //           ),
      //         ),

      //       /// 🔷 STOPS LIST
      //       if (_suggestions.isEmpty && stops.isNotEmpty)
      //         Expanded(
      //           child: ListView.builder(
      //             itemCount: stops.length,
      //             itemBuilder: (_, index) {
      //               final stop = stops[index];
      //               final latLng = stop['latLng'] as LatLng;
      //               final address = stop['address'] as String;

      //               return Card(
      //                 child: ListTile(
      //                   leading: CircleAvatar(child: Text('${index + 1}')),
      //                   title: Text(address),
      //                   subtitle: Text(
      //                     '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
      //                   ),
      //                   trailing: IconButton(
      //                     icon: const Icon(Icons.close, color: Colors.red),
      //                     onPressed: () {
      //                       final updatedStops = [...stops]..removeAt(index);
      //                       ref.read(stopsProvider.notifier).state =
      //                           updatedStops;
      //                     },
      //                   ),
      //                 ),
      //               );
      //             },
      //           ),
      //         ),
      //     ],
      //   ),

       // @override
  // Widget build(BuildContext context) {
  //   if (!_isPickupLoaded &&
  //       (widget.category == VehicleCategory.passenger ||
  //           widget.category == VehicleCategory.exhauster)) {
  //     return Scaffold(body: _buildFullScreenSkeleton());
  //   }

  //   final stops = ref.watch(stopsProvider);

  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF9FAFB),
  //     appBar: AppBar(
  //       backgroundColor: Colors.white,
  //       elevation: 2,
  //       title: const Text(
  //         "Enter",
  //         style: TextStyle(
  //           color: Colors.black,
  //           fontSize: 24,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       centerTitle: true,
  //       iconTheme: const IconThemeData(color: Colors.black),
  //     ),

  //     body: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           children: [
  //             /// 🔷 INPUT CARD
  //             AnimatedContainer(
  //               duration: const Duration(milliseconds: 300),
  //               curve: Curves.easeInOut,
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(16),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.black.withOpacity(0.15),
  //                     blurRadius: 8,
  //                     offset: const Offset(0, 4),
  //                   ),
  //                 ],
  //               ),
  //               child: Column(
  //                 children: [
  //                   /// 🔷 SPECIAL CASE (NO PICKUP)
  //                   if (widget.category == VehicleCategory.exhauster ||
  //                       widget.category == VehicleCategory.waterBowser) ...[
  //                     _buildLocationField(
  //                       controller: destinationController,
  //                       icon: Icons.location_on,
  //                       iconColor: Colors.red,
  //                       hint:
  //                           widget.category == VehicleCategory.exhauster
  //                               ? "Collection Location"
  //                               : "Enter Destination",
  //                       onTap: () {
  //                         setState(() {
  //                           _selectingPickup = false;
  //                           _suggestions.clear();
  //                         });
  //                       },
  //                     ),
  //                   ] else ...[
  //                     /// 🔷 PICKUP
  //                     _buildLocationField(
  //                       controller: pickupController,
  //                       icon: Icons.my_location,
  //                       iconColor: Colors.green,
  //                       hint: "Set Pickup Location",
  //                       onTap: () {
  //                         setState(() {
  //                           _selectingPickup = true;
  //                           _activeStopIndex = null;
  //                           _suggestions.clear();
  //                         });
  //                       },
  //                     ),
  //                     const Divider(height: 1, color: Colors.grey),

  //                     /// 🔷 STOPS
  //                     ...List.generate(stopControllers.length, (index) {
  //                       return Column(
  //                         children: [
  //                           Row(
  //                             crossAxisAlignment: CrossAxisAlignment.center,
  //                             children: [
  //                               Expanded(
  //                                 child: _buildLocationField(
  //                                   controller: stopControllers[index],
  //                                   icon: Icons.trip_origin,
  //                                   iconColor: Colors.orange,
  //                                   hint: "Stop ${index + 1}",
  //                                   onTap: () {
  //                                     setState(() {
  //                                       _selectingPickup = false;
  //                                       _activeStopIndex = index;
  //                                       _suggestions.clear();
  //                                     });
  //                                   },
  //                                 ),
  //                               ),
  //                               IconButton(
  //                                 icon: const Icon(
  //                                   Icons.close,
  //                                   color: Colors.red,
  //                                 ),
  //                                 onPressed: () {
  //                                   setState(() {
  //                                     stopControllers[index].dispose();
  //                                     stopControllers.removeAt(index);

  //                                     if (stops.length > index) {
  //                                       final updatedStops = [...stops]
  //                                         ..removeAt(index);
  //                                       ref.read(stopsProvider.notifier).state =
  //                                           updatedStops;
  //                                     }

  //                                     if (_activeStopIndex == index)
  //                                       _activeStopIndex = null;
  //                                     _suggestions.clear();
  //                                   });
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                           const Divider(height: 1, color: Colors.grey),
  //                         ],
  //                       );
  //                     }),

  //                     /// 🔷 DESTINATION + ADD BUTTON
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: _buildLocationField(
  //                             controller: destinationController,
  //                             icon: Icons.location_on,
  //                             iconColor: Colors.red,
  //                             hint: "Enter Destination",
  //                             onTap: () {
  //                               setState(() {
  //                                 _selectingPickup = false;
  //                                 _activeStopIndex = null;
  //                                 _suggestions.clear();
  //                               });
  //                             },
  //                           ),
  //                         ),
  //                         IconButton(
  //                           icon: const Icon(
  //                             Icons.add_circle,
  //                             color: Colors.blue,
  //                             size: 28,
  //                           ),
  //                           onPressed: _addStopField,
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ],
  //               ),
  //             ),

  //             /// 🔷 LOADING SUGGESTIONS
  //             if (_isLoading)
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(vertical: 10),
  //                 child: _buildSuggestionSkeleton(),
  //               ),

  //             const SizedBox(height: 10),

  //             /// 🔷 NEARBY PLACES
  //             if (_suggestions.isEmpty &&
  //                 widget.category == VehicleCategory.passenger &&
  //                 !_selectingPickup)
  //               SizedBox(
  //                 height:
  //                     300, // fixed height for scroll inside SingleChildScrollView
  //                 child:
  //                     isPlacesLoading
  //                         ? _buildSkeleton()
  //                         : ListView.builder(
  //                           itemCount: _commonPlaces.length,
  //                           itemBuilder: (_, index) {
  //                             final place = _commonPlaces[index];
  //                             return Card(
  //                               child: ListTile(
  //                                 leading: Icon(
  //                                   place['icon'],
  //                                   color: Colors.blue,
  //                                 ),
  //                                 title: Text(place['name']),
  //                                 subtitle: Text(place['address']),
  //                                 onTap: () {
  //                                   _onSuggestionTap({
  //                                     "place_id": null,
  //                                     "geometry": {
  //                                       "location": {
  //                                         "lat": place['lat'],
  //                                         "lng": place['lng'],
  //                                       },
  //                                     },
  //                                     "description": place['name'],
  //                                   });
  //                                 },
  //                               ),
  //                             );
  //                           },
  //                         ),
  //               ),

  //             /// 🔷 SEARCH RESULTS
  //             if (_suggestions.isNotEmpty)
  //               SizedBox(
  //                 height: 300,
  //                 child: ListView.builder(
  //                   itemCount: _suggestions.length,
  //                   itemBuilder: (_, index) {
  //                     final place = _suggestions[index];
  //                     return Card(
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                       elevation: 2,
  //                       child: ListTile(
  //                         leading: const Icon(
  //                           Icons.place_outlined,
  //                           color: Colors.blueAccent,
  //                         ),
  //                         title: Text(
  //                           place['description'],
  //                           style: const TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                         onTap: () => _onSuggestionTap(place),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),

  //             /// 🔷 STOPS LIST
  //             if (_suggestions.isEmpty && stops.isNotEmpty)
  //               SizedBox(
  //                 height: 300,
  //                 child: ListView.builder(
  //                   itemCount: stops.length,
  //                   itemBuilder: (_, index) {
  //                     final stop = stops[index];
  //                     final latLng = stop['latLng'] as LatLng;
  //                     final address = stop['address'] as String;
  //                     return Card(
  //                       child: ListTile(
  //                         leading: CircleAvatar(child: Text('${index + 1}')),
  //                         title: Text(address),
  //                         subtitle: Text(
  //                           '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
  //                         ),
  //                         trailing: IconButton(
  //                           icon: const Icon(Icons.close, color: Colors.red),
  //                           onPressed: () {
  //                             final updatedStops = [...stops]..removeAt(index);
  //                             ref.read(stopsProvider.notifier).state =
  //                                 updatedStops;
  //                           },
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
