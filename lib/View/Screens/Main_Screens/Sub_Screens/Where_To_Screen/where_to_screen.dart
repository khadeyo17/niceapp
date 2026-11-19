import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/schedule_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/Services/location_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Other_Screens/cargo_transport.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/machinery.dart';
import 'package:niceapp/View/Screens/Other_Screens/movers_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/water_bower_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

class WhereToScreen extends ConsumerStatefulWidget {
  final VehicleCategory category;
  final bool? IsScheduled;
  final LatLng? initialPickupLocation;
  final bool isLocationPicker;

  const WhereToScreen({
    super.key,
    required this.category,
    this.initialPickupLocation,
    this.IsScheduled,
    this.isLocationPicker = false,
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
  final Uuid _uuid = const Uuid();

//   bool get isPassenger =>
//     widget.category == VehicleCategory.passenger;

// bool get isExhauster =>
//     widget.category == VehicleCategory.exhauster;

// bool get isWaterBowser =>
//     widget.category == VehicleCategory.waterBowser;

// bool get isMachinery =>
//     widget.category == VehicleCategory.machinery;

// /// Categories where the current location should become pickup
// bool get usesCurrentLocationAsPickup =>
//     isPassenger || isExhauster;

// /// Categories where the current location should become destination
// bool get usesCurrentLocationAsDestination =>
//     isWaterBowser || isMachinery;



// bool get _usesCurrentLocationAsPickup {
//   return widget.category == VehicleCategory.passenger ||
//       widget.category == VehicleCategory.exhauster||
//       widget.category == VehicleCategory.waterBowser||
//       widget.category == VehicleCategory.machinery;
// }

// bool get _usesCurrentLocationAsDestination {
//   return widget.category == VehicleCategory.waterBowser ||
//       widget.category == VehicleCategory.machinery;
// }

bool get _usesCurrentLocationAsPickup {
  return widget.category == VehicleCategory.passenger;
}

bool get _usesCurrentLocationAsDestination {
  return widget.category == VehicleCategory.waterBowser ||
      widget.category == VehicleCategory.machinery||widget.category == VehicleCategory.exhauster;

}

String get _pickupLabel {
  switch (widget.category) {
    case VehicleCategory.exhauster:
      return "Collection Location";

    case VehicleCategory.passenger:
      return "Pickup Location";

    default:
      return "Pickup Location";
  }
}
Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
  try {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
      "?place_id=${Uri.encodeComponent(placeId)}"
      "&fields=geometry,formatted_address,name"
      "&key=$mapKey",
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint("Place details HTTP error: ${response.statusCode}");
      return null;
    }

    final data = json.decode(response.body);

    if (data["status"] != "OK") {
      debugPrint(
        "Place details error: ${data["status"]} "
        "${data["error_message"] ?? ""}",
      );
      return null;
    }

    final result = data["result"];

    if (result == null ||
        result["geometry"] == null ||
        result["geometry"]["location"] == null) {
      return null;
    }

    final location = result["geometry"]["location"];

    return {
      "placeId": placeId,
      "name": result["name"] ?? "",
      "address": result["formatted_address"] ?? "",
      "lat": (location["lat"] as num).toDouble(),
      "lng": (location["lng"] as num).toDouble(),
    };
  } catch (e) {
    debugPrint("Place details error: $e");
    return null;
  }
}
String get _destinationLabel {
  switch (widget.category) {
    case VehicleCategory.waterBowser:
      return "Delivery Location";

    case VehicleCategory.machinery:
      return "Site Location";

    case VehicleCategory.passenger:
      return "Destination";

    case VehicleCategory.exhauster:
      return "Disposal Location";

    default:
      return "Destination";
  }
}
final LocationService _locationService = LocationService();


String? _sessionToken;

  LatLng? CurrentLocation;

  bool _isPickupLoaded = false;
  bool _isNavigated = false;
  bool _addingStop = false;

  List<Map<String, dynamic>> _commonPlaces = [];
  bool isPlacesLoading = true;

  // @override
  // void initState() {
  //   super.initState();

  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     await Future.wait([_fetchCurrentLocation(), loadNearbyPlaces()]);
  //     //await _fetchCurrentLocation();
  //     //await loadNearbyPlaces(); // ✅ ADD THIS
  //   });

  //   pickupController.addListener(_onSearchChanged);
  //   destinationController.addListener(_onSearchChanged);
  // }

  @override
void initState() {
  super.initState();

  pickupController.addListener(_onSearchChanged);
  destinationController.addListener(_onSearchChanged);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _fetchCurrentLocation();

    if (!mounted) return;

   // await _initializeLocationForCategory();

    if (!mounted) return;

    await loadNearbyPlaces();
  });
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
  // 1. Use cache for instant loading
  if (_cachedPlaces != null && _cachedPlaces!.isNotEmpty) {
    if (!mounted) return;

    setState(() {
      _commonPlaces = List.from(_cachedPlaces!);
      isPlacesLoading = false;
    });
    return;
  }

  if (mounted) {
    setState(() => isPlacesLoading = true);
  }

  try {
    // 2. Reuse existing location if available
    final lat = CurrentLocation?.latitude;
    final lng = CurrentLocation?.longitude;

    final position =
        (lat != null && lng != null)
            ? null
            : await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
              );

    if (!mounted) return;

    final latitude = lat ?? position!.latitude;
    final longitude = lng ?? position!.longitude;

    // 3. Places API (New) Nearby Search
    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:searchNearby',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': mapKey,
        'X-Goog-FieldMask':
            'places.id,'
            'places.displayName,'
            'places.formattedAddress,'
            'places.location,'
            'places.primaryType',
      },
      body: jsonEncode({
        'maxResultCount': 5,
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 3000.0,
          },
        },
      }),
    ).timeout(const Duration(seconds: 15));

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final results = data['places'] as List? ?? [];

      final places = results.map((place) {
        return {
          'place_id': place['id'] ?? '',
          'name': place['displayName']?['text'] ?? 'Unknown',
          'address': place['formattedAddress'] ?? '',
          'lat': place['location']?['latitude'],
          'lng': place['location']?['longitude'],
          'icon': Icons.place,
        };
      }).toList();

      // 4. Cache results
      _cachedPlaces = List.from(places);

      setState(() {
        _commonPlaces = places;
        isPlacesLoading = false;
      });
    } else {
      debugPrint(
        'Nearby Places API Error: ${response.statusCode}',
      );
      debugPrint(response.body);

      setState(() {
        isPlacesLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Nearby places error: $e');

    if (!mounted) return;

    setState(() {
      isPlacesLoading = false;
    });
  }
}

  //google old

  // Future<void> loadNearbyPlaces() async {
  //   // ✅ 1. Use cache (instant load)
  //   if (_cachedPlaces != null && _cachedPlaces!.isNotEmpty) {
  //     if (!mounted) return;
  //     setState(() {
  //       _commonPlaces = List.from(_cachedPlaces!); // safe copy
  //       isPlacesLoading = false;
  //     });
  //     return;
  //   }

  //   try {
  //     // ✅ 2. Use existing location if available
  //     final lat = CurrentLocation?.latitude;
  //     final lng = CurrentLocation?.longitude;

  //     final position =
  //         (lat != null && lng != null)
  //             ? null
  //             : await Geolocator.getCurrentPosition(
  //               desiredAccuracy: LocationAccuracy.medium,
  //             );

  //     final latitude = lat ?? position!.latitude;
  //     final longitude = lng ?? position!.longitude;

  //     final url =
  //         "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
  //         "?location=$latitude,$longitude"
  //         "&radius=3000"
  //         "&type=point_of_interest"
  //         "&key=$mapKey";

  //     // ✅ 3. Timeout (prevents freezing)
  //     final response = await http
  //         .get(Uri.parse(url))
  //         .timeout(const Duration(seconds: 5));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       // ✅ 4. Validate response
  //       if (data["status"] == "OK" && data["results"] != null) {
  //         final results = data["results"] as List;

  //         final places =
  //             results.take(5).map((place) {
  //               return {
  //                 "name": place["name"] ?? "Unknown",
  //                 "address": place["vicinity"] ?? "",
  //                 "lat": place["geometry"]["location"]["lat"],
  //                 "lng": place["geometry"]["location"]["lng"],
  //                 "icon": Icons.place,
  //               };
  //             }).toList();

  //         // ✅ 5. Cache safely
  //         _cachedPlaces = List.from(places);

  //         if (!mounted) return;

  //         setState(() {
  //           _commonPlaces = places;
  //           isPlacesLoading = false;
  //         });
  //       } else {
  //         if (!mounted) return;
  //         setState(() => isPlacesLoading = false);
  //       }
  //     } else {
  //       if (!mounted) return;
  //       setState(() => isPlacesLoading = false);
  //     }
  //   } catch (e) {
  //     debugPrint("Nearby places error: $e");

  //     if (!mounted) return;
  //     setState(() => isPlacesLoading = false);
  //   }
  // }


  
Future<void> _fetchSuggestions(String query) async {
  if (query.trim().length < 2) {
    if (!mounted) return;

    setState(() {
      _suggestions.clear();
      _isLoading = false;
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _suggestions.clear();
  });

  try {
    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:autocomplete',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': mapKey,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.placeId,'
            'suggestions.placePrediction.text.text,'
            'suggestions.placePrediction.structuredFormat.mainText.text,'
            'suggestions.placePrediction.structuredFormat.secondaryText.text',
      },
      body: jsonEncode({
        'input': query.trim(),
        'includedRegionCodes': ['ke'],
        'languageCode': 'en',
      }),
    ).timeout(const Duration(seconds: 20));

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final suggestions =
          data['suggestions'] as List? ?? [];

      final results = suggestions
          .where((item) => item['placePrediction'] != null)
          .map((item) {
        final prediction = item['placePrediction'];
        final format = prediction['structuredFormat'] ?? {};

        return {
          'place_id': prediction['placeId'] ?? '',
          'description': prediction['text']?['text'] ?? '',
          'main_text': format['mainText']?['text'] ?? '',
          'secondary_text':
              format['secondaryText']?['text'] ?? '',
          'icon': Icons.place,
        };
      }).toList();

      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } else {
      debugPrint('Places API Error: ${response.statusCode}');
      debugPrint(response.body);

      setState(() {
        _suggestions.clear();
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Suggestion fetch exception: $e');

    if (!mounted) return;

    setState(() {
      _suggestions.clear();
      _isLoading = false;
    });
  }
}

//google old
  // Future<void> _fetchSuggestions(String query) async {
  //   if (query.trim().isEmpty) return;

  //   setState(() {
  //     _isLoading = true;
  //     _suggestions.clear();
  //   });

  //   // final apiKey = "YOUR_GOOGLE_API_KEY"; // replace with your key
  //   // final url = Uri.parse(
  //   //   "https://maps.googleapis.com/maps/api/place/autocomplete/json"
  //   //   "?input=$query"
  //   //   "&key=$mapKey"
  //   //   "&components=country:ke", // Optional: restrict to Kenya or your country
  //   // );

  //   final url = Uri.parse(
  //     "https://maps.googleapis.com/maps/api/place/autocomplete/json"
  //     "?input=${Uri.encodeComponent(query)}"
  //     "&key=$mapKey"
  //     "&components=country:ke",
  //   );
  //   final res = await http.get(url).timeout(const Duration(seconds: 20));
  //   // final res = await http.get(url);
  //   if (res.statusCode == 200) {
  //     final data = json.decode(res.body);
  //     if (data['status'] == 'OK') {
  //       if (mounted) {
  //         // setState(() {
  //         //   _suggestions = List<Map<String, dynamic>>.from(data['predictions']);
  //         //   _isLoading = false;
  //         // });

  //         //  final places =
  //         //     results.take(5).map((place) {
  //         //       return {
  //         //         "name": place["name"] ?? "Unknown",
  //         //         "address": place["vicinity"] ?? "",
  //         //         "lat": place["geometry"]["location"]["lat"],
  //         //         "lng": place["geometry"]["location"]["lng"],
  //         //         "icon": Icons.place,
  //         //       };
  //         //     }).toList();
  //         final predictions = data['predictions'] as List;

  //         setState(() {
  //           _suggestions =
  //               predictions.map((place) {
  //                 return {
  //                   "place_id": place["place_id"],
  //                   "description":
  //                       place["description"], // full text: "Garden City, Thika Road, Nairobi"
  //                   "main_text":
  //                       place["structured_formatting"]?["main_text"] ?? "",
  //                   "secondary_text":
  //                       place["structured_formatting"]?["secondary_text"] ?? "",
  //                   "icon": Icons.place,
  //                 };
  //               }).toList();
  //           _isLoading = false;
  //         });
  //       }
  //     } else {
  //       // _showError(data['error_message'] ?? "No results found.");
  //       setState(() => _isLoading = false);
  //     }
  //   } else {
  //     _showError("Suggestion fetch failed");
  //     setState(() => _isLoading = false);
  //   }
  // }

  //mbox
// Future<void> _fetchSuggestions(String query) async {
//   if (query.trim().isEmpty) return;

//   setState(() {
//     _isLoading = true;
//     _suggestions.clear();
//   });

//   try {
//     final url = Uri.parse(
//       "https://api.mapbox.com/geocoding/v5/mapbox.places/"
//       "${Uri.encodeComponent(query)}.json"
//       "?autocomplete=true"
//       "&limit=10"
//       //"&country=KE"
//       "&access_token=$mapboxAccessToken",
//     );

//     final res = await http.get(url);

//     if (res.statusCode != 200) {
//       _showError("Search failed");
//       setState(() => _isLoading = false);
//       return;
//     }

//     final data = jsonDecode(res.body);

//     final features = data["features"] as List? ?? [];

//     if (!mounted) return;

//     setState(() {
//       _suggestions = features.map((feature) {
//         final coords = feature["center"];

//         return {
//           "lat": coords[1],
//           "lng": coords[0],
//           "name": feature["text"],
//           "description": feature["place_name"],
//           "icon": Icons.place,
//         };
//       }).toList();

//       _isLoading = false;
//     });
//   } catch (e) {
//     debugPrint(e.toString());

//     if (!mounted) return;

//     setState(() {
//       _isLoading = false;
//     });
//   }
// }
//   Future<void> _fetchSuggestions(String query) async {
//   if (query.trim().isEmpty) return;

//   // Create one session token for this search session
//   _sessionToken ??= _uuid.v4();

//   setState(() {
//     _isLoading = true;
//     _suggestions.clear();
//   });

//   try {
//     final url = Uri.parse(
//       "https://api.mapbox.com/search/searchbox/v1/suggest"
//       "?q=${Uri.encodeComponent(query)}"
//       "&language=en"
//       "&country=KE"
//       "&limit=10"
//       "&session_token=$_sessionToken"
//       "&access_token=$mapboxAccessToken",
//     );

//     final res = await http.get(url).timeout(const Duration(seconds: 10));

//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);

//       if (data["suggestions"] != null) {
//         final suggestions = data["suggestions"] as List;

//         if (!mounted) return;

//         setState(() {
//           _suggestions = suggestions.map((place) {
//             return {
//               "mapbox_id": place["mapbox_id"],
//               "main_text": place["name"] ?? "",
//               "description": place["full_address"] ?? "",
//               "secondary_text": place["place_formatted"] ?? "",
//               "icon": Icons.place,
//             };
//           }).toList();

//           _isLoading = false;
//         });
//       } else {
//         if (!mounted) return;
//         setState(() => _isLoading = false);
//       }
//     } else {
//       debugPrint(res.body);

//       _showError("Failed to fetch suggestions");

//       if (!mounted) return;
//       setState(() => _isLoading = false);
//     }
//   } catch (e) {
//     _showError(e.toString());

//     if (!mounted) return;
//     setState(() => _isLoading = false);
//   }
// }

//   Future<void> _fetchSuggestions(String query) async {
//   if (query.trim().isEmpty) return;

//   setState(() {
//     _isLoading = true;
//     _suggestions.clear();
//   });

//   try {

//     String? _sessionToken;
//    _sessionToken ??= _uuid.v4();
//     final url = Uri.parse(
//       "https://api.mapbox.com/search/searchbox/v1/suggest"
//       "?q=${Uri.encodeComponent(query)}"
//       "&language=en"
//       "&country=KE"
//       "&limit=10"
//       "&session_token=$_sessionToken"
//       "&access_token=$mapboxAccessToken",
//     );

//     final res = await http
//         .get(url)
//         .timeout(const Duration(seconds: 10));

//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);

//       if (data["suggestions"] != null) {
//         final suggestions = data["suggestions"] as List;

//         if (!mounted) return;

//         setState(() {
//           _suggestions =
//               suggestions.map((place) {
//                 return {
//                   // Save the mapbox id
//                   "mapbox_id": place["mapbox_id"],

//                   // Main display text
//                   "main_text": place["name"] ?? "",

//                   // Full address
//                   "description": place["full_address"] ?? "",

//                   // Secondary text
//                   "secondary_text":
//                       place["place_formatted"] ?? "",

//                   "icon": Icons.place,
//                 };
//               }).toList();

//           _isLoading = false;
//         });
//       } else {
//         if (!mounted) return;

//         setState(() => _isLoading = false);
//       }
//     } else {
//       _showError("Failed to fetch suggestions");

//       if (!mounted) return;

//       setState(() => _isLoading = false);
//     }
//   } catch (e) {
//     _showError(e.toString());

//     if (!mounted) return;

//     setState(() => _isLoading = false);
//   }
// }

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
/////working
  // Future<void> _fetchCurrentLocation() async {
  //   try {
  //     // ✅ 1. Check service (fast)
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     // if (!serviceEnabled) {
  //     //   if (!mounted) return;
  //     //   setState(() => pickupController.text = "Location services disabled");
  //     //   return;
  //     // }
  //     if (!serviceEnabled) {
  //     if (!mounted) return;

  //     setState(() {
  //       if (_usesCurrentLocationAsPickup) {
  //         pickupController.text = "Location services disabled";
  //       } else {
  //         destinationController.text = "Location services disabled";
  //       }
  //     });

  //     return;
  //   }

  //     // ✅ 2. Check permission (no delay)
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         if (!mounted) return;
  //         setState(() => pickupController.text = "Permission denied");
  //         return;
  //       }
  //     }

  //     if (permission == LocationPermission.deniedForever) {
  //       if (!mounted) return;
  //      // setState(() => pickupController.text = "Permission permanently denied");
  //      setState(() {
  //         if (_usesCurrentLocationAsPickup) {
  //           pickupController.text = "Permission denied";
  //         } else {
  //           destinationController.text = "Permission denied";
  //         }
  //       });
  //       return;
  //     }

  //     // ✅ 3. FAST LOCATION FIRST (last known)
  //     Position? lastPosition = await Geolocator.getLastKnownPosition();

  //     if (lastPosition != null) {
  //       CurrentLocation = LatLng(lastPosition.latitude, lastPosition.longitude);

  //       _isPickupLoaded = true;

  //       if (mounted) {
  //         setState(() {
  //           pickupController.text = "Fetching location...";
  //         });
  //       }

  //       // 🔥 Don't wait → run in background
  //       _getPlaceNameFromLatLng(CurrentLocation!);
  //     }

  //     // ✅ 4. THEN GET FRESH LOCATION (non-blocking)
  //     Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.medium, // ⚡ faster
  //     ).then((position) {
  //       CurrentLocation = LatLng(position.latitude, position.longitude);

  //       if (!mounted) return;

  //       setState(() {
  //         _isPickupLoaded = true;
  //       });

  //       // 🔥 Update address in background
  //       _getPlaceNameFromLatLng(CurrentLocation!);
  //     });
  //   } catch (e) {
  //     debugPrint("Error fetching location: $e");

  //     if (!mounted) return;
  //     setState(() => pickupController.text = "Unable to fetch location");
  //   }
  // }


// Future<void> _fetchCurrentLocation() async {
//   try {
//     // ---------------------------------------------------------
//     // 1. Check location service
//     // ---------------------------------------------------------
//     final serviceEnabled = await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       if (!mounted) return;

//       setState(() {
//         if (_usesCurrentLocationAsPickup) {
//           pickupController.text = "Location services disabled";
//         } else {
//           destinationController.text = "Location services disabled";
//         }
//       });

//       return;
//     }

//     // ---------------------------------------------------------
//     // 2. Check permission
//     // ---------------------------------------------------------
//     LocationPermission permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();

//       if (permission == LocationPermission.denied) {
//         if (!mounted) return;

//         setState(() {
//           if (_usesCurrentLocationAsPickup) {
//             pickupController.text = "Permission denied";
//           } else {
//             destinationController.text = "Permission denied";
//           }
//         });

//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       if (!mounted) return;

//       setState(() {
//         if (_usesCurrentLocationAsPickup) {
//           pickupController.text = "Permission permanently denied";
//         } else {
//           destinationController.text = "Permission permanently denied";
//         }
//       });

//       return;
//     }

//     // ---------------------------------------------------------
//     // 3. Show loading while getting FRESH GPS location
//     // ---------------------------------------------------------
//     if (mounted) {
//       setState(() {
//         if (_usesCurrentLocationAsPickup) {
//           pickupController.text = "Getting your current location...";
//         } else {
//           destinationController.text =
//               "Getting your current location...";
//         }

//         _isPickupLoaded = false;
//       });
//     }

//     // ---------------------------------------------------------
//     // 4. ALWAYS get fresh location
//     // ---------------------------------------------------------
//     // final position = await Geolocator.getCurrentPosition(
//     //   locationSettings: const LocationSettings(
//     //     accuracy: LocationAccuracy.high,
//     //   ),
//     // );

//     final position = await Geolocator.getCurrentPosition(
//   desiredAccuracy: LocationAccuracy.high,
// );

//     debugPrint(
//       "FRESH GPS LOCATION: ${position.latitude}, ${position.longitude}",
//     );

//     debugPrint(
//       "GPS ACCURACY: ${position.accuracy} metres",
//     );

//     // ---------------------------------------------------------
//     // 5. Reject extremely inaccurate location
//     // ---------------------------------------------------------
//     if (position.accuracy > 100) {
//       debugPrint(
//         "Location accuracy too poor: ${position.accuracy}m",
//       );

//       if (!mounted) return;

//       setState(() {
//         if (_usesCurrentLocationAsPickup) {
//           pickupController.text =
//               "Getting a more accurate location...";
//         } else {
//           destinationController.text =
//               "Getting a more accurate location...";
//         }
//       });

//       // Try once more with high accuracy
//       final accuratePosition = await Geolocator.getCurrentPosition(
//   desiredAccuracy: LocationAccuracy.best,
// );

// CurrentLocation = LatLng(
//   accuratePosition.latitude,
//   accuratePosition.longitude,
// );
//     } else {
//       CurrentLocation = LatLng(
//         position.latitude,
//         position.longitude,
//       );
//     }

//     // ---------------------------------------------------------
//     // 6. Mark location as loaded
//     // ---------------------------------------------------------
//     _isPickupLoaded = true;

//     if (!mounted) return;

//     setState(() {
//       if (_usesCurrentLocationAsPickup) {
//         pickupController.text = "Finding address...";
//       } else {
//         destinationController.text = "Finding address...";
//       }
//     });

//     // ---------------------------------------------------------
//     // 7. Resolve address from FRESH coordinates
//     // ---------------------------------------------------------
//     await _setCurrentLocationAddress(CurrentLocation!);

//   } catch (e) {
//     debugPrint("Error fetching current location: $e");

//     if (!mounted) return;

//     setState(() {
//       if (_usesCurrentLocationAsPickup) {
//         pickupController.text = "Unable to fetch current location";
//       } else {
//         destinationController.text =
//             "Unable to fetch current location";
//       }

//       _isPickupLoaded = false;
//     });
//   }
// }



Future<void> _fetchCurrentLocation() async {
  try {
    // 1. Check location services
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!mounted) return;

    if (!serviceEnabled) {
      setState(() {
        if (_usesCurrentLocationAsPickup) {
          pickupController.text = "Location services disabled";
        } else {
          destinationController.text = "Location services disabled";
        }
        _isPickupLoaded = false;
      });
      return;
    }

    // 2. Check permissions
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        final message =
            permission == LocationPermission.deniedForever
                ? "Permission permanently denied"
                : "Permission denied";

        if (_usesCurrentLocationAsPickup) {
          pickupController.text = message;
        } else {
          destinationController.text = message;
        }

        _isPickupLoaded = false;
      });
      return;
    }

    // 3. Show loading
    setState(() {
      if (_usesCurrentLocationAsPickup) {
        pickupController.text = "Getting your current location...";
      } else {
        destinationController.text = "Getting your current location...";
      }

      _isPickupLoaded = false;
    });

    // 4. Get fresh GPS coordinates
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 25),
    );

    debugPrint(
      "FRESH GPS: ${position.latitude}, ${position.longitude}",
    );

    debugPrint("GPS ACCURACY: ${position.accuracy} metres");

    if (!mounted) return;

    // 5. Retry if accuracy is poor
    if (position.accuracy > 100) {
      setState(() {
        if (_usesCurrentLocationAsPickup) {
          pickupController.text = "Improving location accuracy...";
        } else {
          destinationController.text = "Improving location accuracy...";
        }
      });

      debugPrint("Retrying GPS with best accuracy...");

      // IMPORTANT: Reassign the existing variable.
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 25),
      );

      debugPrint(
        "RETRY GPS: ${position.latitude}, ${position.longitude}",
      );

      debugPrint(
        "RETRY ACCURACY: ${position.accuracy} metres",
      );
    }

    if (!mounted) return;

    // 6. Validate coordinates
    if (position.latitude == 0 && position.longitude == 0) {
      throw Exception("Invalid GPS coordinates");
    }

    if (position.accuracy > 100) {
      debugPrint(
        "WARNING: GPS accuracy remains poor: "
        "${position.accuracy} metres",
      );
    }

    final resolvedLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    // 7. Update the correct location state
    if (_usesCurrentLocationAsPickup) {
      CurrentLocation = resolvedLocation;
    } else {
      ref.read(destinationLocationProvider.notifier).state =
          resolvedLocation;
    }

    _isPickupLoaded = true;

    setState(() {
      if (_usesCurrentLocationAsPickup) {
        pickupController.text = "Finding address...";
      } else {
        destinationController.text = "Finding address...";
      }
    });

    // 8. Resolve address using fresh coordinates
    await _setCurrentLocationAddress(resolvedLocation);

    if (!mounted) return;

    debugPrint(
      "CURRENT LOCATION RESOLVED: "
      "${resolvedLocation.latitude}, "
      "${resolvedLocation.longitude}",
    );

  } catch (e, stackTrace) {
    debugPrint("Error fetching current location: $e");
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    setState(() {
      if (_usesCurrentLocationAsPickup) {
        pickupController.text = "Unable to fetch current location";
      } else {
        destinationController.text = "Unable to fetch current location";
      }

      _isPickupLoaded = false;
    });
  }
}


// Future<void> _setCurrentLocationAddress(LatLng location) async {
//   try {
//     await _getPlaceNameFromLatLng(location);
//   } catch (e) {
//     debugPrint("Error resolving current location address: $e");
//   }
// }

// Future<void> _setCurrentLocationAddress(LatLng location) async {
//   try {
//     final url =
//         "https://maps.googleapis.com/maps/api/geocode/json"
//         "?latlng=${location.latitude},${location.longitude}"
//         "&key=$mapKey";

//     debugPrint(
//       "Reverse geocoding: "
//       "${location.latitude}, ${location.longitude}",
//     );

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode != 200) {
//       debugPrint(
//         "Geocoding HTTP error: ${response.statusCode}",
//       );
//       return;
//     }

//     final data = jsonDecode(response.body);

//     debugPrint("Geocoding status: ${data['status']}");

//     if (data["status"] != "OK") {
//       debugPrint(
//         "Geocoding error: ${data["error_message"] ?? data["status"]}",
//       );
//       return;
//     }

//     final results = data["results"] as List?;

//     if (results == null || results.isEmpty) {
//       debugPrint("No address found for current location");
//       return;
//     }

//     final String address =
//         results[0]["formatted_address"]?.toString() ??
//         "Current Location";

//     debugPrint("Current address: $address");

//     if (!mounted) return;

//     setState(() {
//       // Passenger + Exhauster
//       // Current location → Pickup / Collection
//       if (_usesCurrentLocationAsPickup) {
//         pickupController.text = address;
//       }

//       // Water Bowser + Machinery
//       // Current location → Destination / Delivery / Site
//       else if (_usesCurrentLocationAsDestination) {
//         destinationController.text = address;
//      }
//     });
//   } catch (e) {
//     debugPrint(
//       "Error resolving current location address: $e",
//     );
//   }
// }



// Future<void> _setCurrentLocationAddress(LatLng location) async {
//   try {
//     debugPrint(
//       'Resolving location: '
//       '${location.latitude}, ${location.longitude}',
//     );

//     String address = 'Current Location';

//     // 1. Find the nearest named place.
//     final nearbyPlace = await _findNearestPlace(location);

//     if (!mounted) return;

//     if (nearbyPlace != null) {
//       final name =
//           nearbyPlace['displayName']?['text']?.toString() ?? '';

//       final formattedAddress =
//           nearbyPlace['formattedAddress']?.toString() ?? '';

//       if (name.isNotEmpty) {
//         if (formattedAddress.isNotEmpty &&
//             !formattedAddress.toLowerCase().contains(
//               name.toLowerCase(),
//             )) {
//           address = '$name, $formattedAddress';
//         } else {
//           address = name;
//         }

//         debugPrint(
//           'Nearest place: $name '
//           '(${nearbyPlace['_distance']} metres)',
//         );
//       }
//     } else {
//       // 2. Fall back to reverse geocoding.
//       final readableAddress =
//           await _getReadableAddress(location);

//       if (!mounted) return;

//       if (readableAddress != null &&
//           readableAddress.isNotEmpty) {
//         address = readableAddress;
//       }
//     }

//     debugPrint('FINAL LOCATION ADDRESS: $address');

//     if (!mounted) return;

//     // 3. Update the correct field.
//     setState(() {
//       if (_usesCurrentLocationAsPickup) {
//         pickupController.text = address;
//       } else if (_usesCurrentLocationAsDestination) {
//         destinationController.text = address;
//       }
//     });

//   } catch (e, stackTrace) {
//     debugPrint('Error resolving current location: $e');
//     debugPrintStack(stackTrace: stackTrace);
//   }
// }

Future<void> _setCurrentLocationAddress(LatLng location) async {
  try {
    debugPrint(
      'Resolving location: '
      '${location.latitude}, ${location.longitude}',
    );

    // Use the shared AMINI LocationService.
    final String address =
        await _locationService.getPlaceName(location);

    if (!mounted) return;

    debugPrint('FINAL LOCATION ADDRESS: $address');

    setState(() {
      if (_usesCurrentLocationAsPickup) {
        pickupController.text = address;
      } else if (_usesCurrentLocationAsDestination) {
        destinationController.text = address;
      }
    });

  } catch (e, stackTrace) {
    debugPrint('Error resolving current location: $e');
    debugPrintStack(stackTrace: stackTrace);
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
//google
//   Future<void> _getPlaceNameFromLatLng(LatLng latLng) async {
//     try {
//       final url =
//           // "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
//           // "?location=${latLng.latitude},${latLng.longitude}"
//           // "&radius=100"
//           // "&type=point_of_interest"
//           // "&key=$mapKey";
//           "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latLng.latitude},${latLng.longitude}&rankby=distance&type=establishment&key=$mapKey";
//       final response = await http.get(Uri.parse(url));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         if (data["results"] != null && data["results"].length > 0) {
//           final place = data["results"][0];
// final String placeName =
//             place["name"]?.toString() ?? "Current Location";
//           // setState(() {
//           //   pickupController.text = place["name"];
//           // });
//           if(mounted){
//              setState(() {
//           // Passenger + Exhauster
//           // Current location goes into Pickup/Collection
//           if (_usesCurrentLocationAsPickup) {
//             pickupController.text = placeName;
//           }

//           // Water Bowser + Machinery
//           // Current location goes into Destination/Delivery/Site
//           else if (_usesCurrentLocationAsDestination) {
//             destinationController.text = placeName;
//           }
//         });
//           }
//           return;
//         }
//       }

//       // fallback
//       await _getAddressFromLatLng(latLng);
//     } catch (e) {
//       debugPrint("Place fetch failed: $e");
//     }
//   }
// Future<void> _getPlaceNameFromLatLng(LatLng latLng) async {
//   try {
//     final url =
//         "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
//         "?location=${latLng.latitude},${latLng.longitude}"
//         "&rankby=distance"
//         "&type=establishment"
//         "&key=$mapKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);

//       if (data["results"] != null &&
//           data["results"].isNotEmpty) {
//         final place = data["results"][0];

//         final String placeName =
//             place["name"]?.toString() ?? "Current Location";

//         if (!mounted) return;

//         setState(() {
//           // Passenger + Exhauster
//           // Current location goes into Pickup/Collection
//           if (_usesCurrentLocationAsPickup) {
//             pickupController.text = placeName;
//           }

//           // Water Bowser + Machinery
//           // Current location goes into Destination/Delivery/Site
//           else if (_usesCurrentLocationAsDestination) {
//             destinationController.text = placeName;
//           }
//         });

//         return;
//       }
//     }

//     // Fallback
//     await _getAddressFromLatLng(latLng);
//   } catch (e) {
//     debugPrint("Place fetch failed: $e");

//     // Try address fallback even when Places fails
//     try {
//       await _getAddressFromLatLng(latLng);
//     } catch (e) {
//       debugPrint("Address fallback failed: $e");
//     }
//   }
// }
//mbox
//   Future<void> _getPlaceNameFromLatLng(LatLng latLng) async {
//   try {
//     final url = Uri.parse(
//       "https://api.mapbox.com/search/searchbox/v1/category/poi"
//       "?proximity=${latLng.longitude},${latLng.latitude}"
//       "&limit=1"
//       "&access_token=$mapboxAccessToken",
//     );

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);

//       if (data["features"] != null &&
//           (data["features"] as List).isNotEmpty) {
//         final place = data["features"][0];

//         setState(() {
//           pickupController.text =
//               place["properties"]?["name"] ??
//               place["properties"]?["full_address"] ??
//               "Unknown Place";
//         });

//         return;
//       }
//     }

//     // Fallback to reverse geocoding
//     await _getAddressFromLatLng(latLng);
//   } catch (e) {
//     debugPrint("Mapbox place fetch failed: $e");

//     // Fallback
//     await _getAddressFromLatLng(latLng);
//   }
// }


Future<void> _onSuggestionTap(Map<String, dynamic> place) async {
  LatLng? latLng;
  String name = "Selected location";

  try {
    // STEP 1: Resolve coordinates
    // Nearby Search results already contain lat/lng.
    // Autocomplete results contain place_id.

    if (place['lat'] != null && place['lng'] != null) {
      latLng = LatLng(
        (place['lat'] as num).toDouble(),
        (place['lng'] as num).toDouble(),
      );

      name = place['name'] ??
          place['description'] ??
          "Selected location";
    } else if (place['geometry']?['location'] != null) {
      // Backward compatibility with legacy results.
      final location = place['geometry']['location'];

      latLng = LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );

      name = place['description'] ?? "Selected location";
    } else if (place['place_id'] != null) {
      // Places API (New) - Place Details
      final placeId = place['place_id'];

      final detailsUrl = Uri.parse(
        'https://places.googleapis.com/v1/places/$placeId',
      );

      final res = await http.get(
        detailsUrl,
        headers: {
          'X-Goog-Api-Key': mapKey,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location',
        },
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (res.statusCode != 200) {
        debugPrint('Place Details Error: ${res.body}');
        _showError("Failed to get location details");
        return;
      }

      final details = json.decode(res.body);

      final location = details['location'];

      if (location == null ||
          location['latitude'] == null ||
          location['longitude'] == null) {
        _showError("Location coordinates not available");
        return;
      }

      latLng = LatLng(
        (location['latitude'] as num).toDouble(),
        (location['longitude'] as num).toDouble(),
      );

      name =
          details['displayName']?['text'] ??
          details['formattedAddress'] ??
          place['description'] ??
          "Selected location";
    } else {
      _showError("Unable to identify selected location");
      return;
    }

    if (!mounted || latLng == null) return;

    // STEP 2: Handle intermediate stops
    if (_activeStopIndex != null) {
      final index = _activeStopIndex!;

      stopControllers[index].text = name;

      _addStop({
        "lat": latLng.latitude,
        "lng": latLng.longitude,
        "description": name,
      });

      setState(() {
        _activeStopIndex = null;
        _suggestions.clear();
      });

      return;
    }

    // STEP 3: Update common selected location
    setState(() {
      _selectedPlace = {
        'lat': latLng!.latitude,
        'lng': latLng.longitude,
        'name': name,
      };

      _suggestions.clear();
    });

    // STEP 4: Handle pickup selection
    if (_selectingPickup) {
      CurrentLocation = latLng;
      pickupController.text = name;

      return;
    }

    // STEP 5: Handle destination selection
    ref.read(destinationLocationProvider.notifier).state = latLng;
    destinationController.text = name;

    final pickup = CurrentLocation;

    // STEP 6: Handle location picker
    if (widget.isLocationPicker) {
      Navigator.pop(
        context,
        {
          "address": name,
          "latitude": latLng.latitude,
          "longitude": latLng.longitude,
        },
      );

      return;
    }

    // STEP 7: Handle scheduled rides
    if (widget.IsScheduled == true) {
      // if (pickup == null) {
      //   _showError("Please set pickup location first.");
      //   return;
      // }

      final screen = ScheduleRideScreen(
        category: widget.category,
        pickupLocation: pickup,
        dropLocation: latLng,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );

      return;
    }

    // STEP 8: Handle normal ride categories
    switch (widget.category) {
      case VehicleCategory.passenger:
        if (pickup == null) {
          _showError("Please set pickup location first.");
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              pickup: pickup,
              destination: latLng!,
              stops: ref.read(stopsProvider),
              category: widget.category,
              isScheduled: widget.IsScheduled,
            ),
          ),
        );
        break;

      case VehicleCategory.exhauster:
      if (destinationController.text.isEmpty) {
        _showError("Please set destination location first.");
        return;
      }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HoneySuckerScreen(
              destination: latLng!,
              destinationPlaceName:
                  place['main_text'] ??
                  place['name'] ??
                  place['description'] ??
                  name,
              destinationSecondaryText:
                  place['secondary_text'] ?? "",
              category: widget.category,
              isScheduled: widget.IsScheduled,
            ),
          ),
        );
        break;

      case VehicleCategory.waterBowser:
       if (destinationController.text.isEmpty) {
        _showError("Please set destination location first.");
        return;
      }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaterBowerScreen(
              destination: latLng!,
              destinationPlaceName:
                  place['main_text'] ??
                  place['name'] ??
                  place['description'] ??
                  name,
              destinationSecondaryText:
                  place['secondary_text'] ?? "",
              category: widget.category,
              isScheduled: widget.IsScheduled,
            ),
          ),
        );
        break;

      case VehicleCategory.machinery:
       if (destinationController.text.isEmpty) {
        _showError("Please set destination location first.");
        return;
      }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MachineryScreen(
              destination: latLng!,
              destinationPlaceName:
                  place['main_text'] ??
                  place['name'] ??
                  place['description'] ??
                  name,
              destinationSecondaryText:
                  place['secondary_text'] ?? "",
              category: widget.category,
              isScheduled: widget.IsScheduled,
            ),
          ),
        );
        break;

      case VehicleCategory.breakdown:
        Navigator.pop(context, latLng);
        break;

      case VehicleCategory.ambulance:
        Navigator.pop(
          context,
          {
            'destination': latLng,
            'pickup': pickup,
          },
        );
        break;

      default:
        debugPrint(
          'Destination selected: $name '
          '(${latLng.latitude}, ${latLng.longitude})',
        );
        break;
    }
  } catch (e, stackTrace) {
    debugPrint('Suggestion selection error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    _showError("Unable to select this location. Please try again.");
  }
}

//google old
  // Future<void> _onSuggestionTap(Map<String, dynamic> place) async {
  //   LatLng latLng;
  //   String name;

  //   // ✅ STEP 1: Resolve location FIRST
  //   if (place['place_id'] == null) {
  //     latLng = LatLng(
  //       place['geometry']['location']['lat'],
  //       place['geometry']['location']['lng'],
  //     );

  //     name = place['description'] ?? "Selected location";
  //   } else {
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
  //         details['result']['name'] ?? details['result']['formatted_address'];
  //   }


  //   // ✅ STEP 2: HANDLE STOP (NOW SAFE)
  //   if (_activeStopIndex != null) {
  //     setState(() {
  //       // Update the stop text
  //       stopControllers[_activeStopIndex!].text = name;

  //       // Add the stop to the state
  //       _addStop({
  //         "lat": latLng.latitude,
  //         "lng": latLng.longitude,
  //         "description": name,
  //       });

  //       // Reset active stop index
  //       _activeStopIndex = null;

  //       // Clear suggestions inside setState so UI updates
  //       _suggestions.clear();
  //     });
  //     return;
  //   }

  //   // ✅ STEP 3: COMMON STATE
  //   setState(() {
  //     _selectedPlace = {
  //       'lat': latLng.latitude,
  //       'lng': latLng.longitude,
  //       'name': name,
  //     };
  //     _suggestions.clear();
  //   });

  //   // ✅ STEP 4: PICKUP
  //   if (_selectingPickup) {
  //     CurrentLocation = latLng;
  //     pickupController.text = name;
  //     return;
  //   }

  //   // ✅ STEP 5: DESTINATION
  //   ref.read(destinationLocationProvider.notifier).state = latLng;
  //   destinationController.text = name;

  //   final pickup = CurrentLocation;

  //   // if (widget.category == VehicleCategory.waterBowser) {
  //   //   Navigator.pop(context, latLng);
  //   //   return;
  //   // }
  //   if (widget.isLocationPicker) {
  //   if (!mounted) return;

  //   Navigator.pop(
  //     context,
  //     {
  //       "address": name,
  //       "latitude": latLng.latitude,
  //       "longitude": latLng.longitude,
  //     },
  //   );

  //   return;
  // }


  //   if (pickup != null || pickup==null){
  //     Widget screen;

  //     if (widget.IsScheduled != true) {
  //       if (widget.category == VehicleCategory.passenger && pickup != null) {
  //         screen = HomeScreen(
  //           pickup: pickup,
  //           destination: latLng,
  //           stops: ref.read(stopsProvider),
  //           category: widget.category,
  //           isScheduled: widget.IsScheduled,
  //         );
  //         Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  //       } 
  //       // else if (widget.category == VehicleCategory.movers) {
  //       //   Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
  //       // } else if (widget.category == VehicleCategory.cargo) {
  //       //   Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
  //       // }
  //        else if (widget.category == VehicleCategory.exhauster)
  //         {
  //           screen = HoneySuckerScreen(
  //           destination: latLng,
  //           destinationPlaceName:
  //       place['main_text'] ??
  //       place['description'] ??
  //       "Selected location",

  //   destinationSecondaryText:
  //       place['secondary_text'] ?? "",
  //          // destination: latLng,
  //           category: widget.category,
  //           isScheduled: widget.IsScheduled,
  //         );

  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //        // Navigator.pop(context, latLng);

  //       } 
  //       else if (widget.category == VehicleCategory.waterBowser)
  //         {
  //            screen = WaterBowerScreen(
  //           destination: latLng,
  //           destinationPlaceName:
  //       place['main_text'] ??
  //       place['description'] ??
  //       "Selected location",

  //   destinationSecondaryText:
  //       place['secondary_text'] ?? "",
  //          // destination: latLng,
  //           category: widget.category,
  //           isScheduled: widget.IsScheduled,
  //         );
          

  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //        // Navigator.pop(context, latLng);

  //       }
  //        else if (widget.category == VehicleCategory.machinery)
  //         {
  //            screen = MachineryScreen(
  //           destination: latLng,
  //           destinationPlaceName:
  //       place['main_text'] ??
  //       place['description'] ??
  //       "Selected location",

  //   destinationSecondaryText:
  //       place['secondary_text'] ?? "",
  //          // destination: latLng,
  //           category: widget.category,
  //           isScheduled: widget.IsScheduled,
  //         );
          

  //           Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //        // Navigator.pop(context, latLng);

  //       }
        
  //       else if (widget.category == VehicleCategory.waterBowser) {
  //         Navigator.pop(context, latLng);
  //       } else if (widget.category == VehicleCategory.breakdown) {
  //         Navigator.pop(context, latLng);
  //       } else if (widget.category == VehicleCategory.ambulance) {
  //         Navigator.pop(context, {'destination': latLng, 'pickup': pickup});
  //       }
  //     } else {
  //       screen = ScheduleRideScreen(
  //         pickupLocation: pickup,
  //         dropLocation: latLng,
  //       );
  //       Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //     }
  //   } else {
  //     _showError("Please set pickup location first.");
  //   }
  // }




//google
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
            category: widget.category,
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
  

  // @override
  // Widget build(BuildContext context) {
  //   if (!_isPickupLoaded &&
  //       (widget.category == VehicleCategory.passenger
  //           )) {
  //     return Scaffold(
  //       body:
  //           isPlacesLoading
  //               ? const Center(
  //                 child: CircularProgressIndicator(color:  Color(0xFF015ACE),),
  //               )
  //               : const Center(child: Text("Loading pickup...")),
  //     );
  //   }

  //   final stops = ref.watch(stopsProvider);

  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF9FAFB),
  //     appBar: AppBar(
  //       backgroundColor: Colors.white,
  //       elevation: 2,
  //       title:  Text(
  //         _getScreenTitle(),
  //         style: GoogleFonts.spaceGrotesk(
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
  //           /// 🔷 SCROLLABLE INPUT CARD
  //           ConstrainedBox(
  //             constraints: BoxConstraints(
  //               maxHeight: 400, // adjust max height as needed
  //             ),
  //             child: SingleChildScrollView(
  //               child: AnimatedContainer(
  //                 duration: const Duration(milliseconds: 300),
  //                 curve: Curves.easeInOut,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(16),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withOpacity(0.15),
  //                       blurRadius: 8,
  //                       offset: const Offset(0, 4),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     /// 🔷 SPECIAL CASE (NO PICKUP)
  //                     if (widget.category == VehicleCategory.exhauster ||
  //                         widget.category == VehicleCategory.waterBowser) ...[
  //                       _buildLocationField(
  //                         controller: destinationController,
  //                         icon: Icons.location_on,
  //                         iconColor: Colors.red,
  //                         hint:
  //                             widget.category == VehicleCategory.exhauster
  //                                 ? "Collection Location"
  //                                 : "Enter Destination",
  //                         onTap: () {
  //                           setState(() {
  //                             _selectingPickup = false;
  //                             _suggestions.clear();
  //                           });
  //                         },
  //                       ),
  //                     ] else ...[
  //                       /// 🔷 PICKUP
  //                       _buildLocationField(
  //                         controller: pickupController,
  //                         icon: Icons.my_location,
  //                         iconColor: Colors.green,
  //                         hint: "Set Pickup Location",
  //                         onTap: () {
  //                           setState(() {
  //                             _selectingPickup = true;
  //                             _activeStopIndex = null;
  //                             _suggestions.clear();
  //                           });
  //                         },
  //                       ),
  //                       const Divider(height: 1, color: Colors.grey),

  //                       /// 🔷 STOPS
  //                       ...List.generate(stopControllers.length, (index) {
  //                         return Column(
  //                           children: [
  //                             Row(
  //                               crossAxisAlignment: CrossAxisAlignment.center,
  //                               children: [
  //                                 Expanded(
  //                                   child: _buildLocationField(
  //                                     controller: stopControllers[index],
  //                                     icon: Icons.trip_origin,
  //                                     iconColor: Colors.orange,
  //                                     hint: "Stop ${index + 1}",
  //                                     onTap: () {
  //                                       setState(() {
  //                                         _selectingPickup = false;
  //                                         _activeStopIndex = index;
  //                                         _suggestions.clear();
  //                                       });
  //                                     },
  //                                   ),
  //                                 ),
  //                                 IconButton(
  //                                   icon: const Icon(
  //                                     Icons.close,
  //                                     color: Colors.red,
  //                                   ),
  //                                   onPressed: () {
  //                                     setState(() {
  //                                       stopControllers[index].dispose();
  //                                       stopControllers.removeAt(index);

  //                                       if (stops.length > index) {
  //                                         final updatedStops = [...stops]
  //                                           ..removeAt(index);
  //                                         ref
  //                                             .read(stopsProvider.notifier)
  //                                             .state = updatedStops;
  //                                       }

  //                                       if (_activeStopIndex == index)
  //                                         _activeStopIndex = null;
  //                                       _suggestions.clear();
  //                                     });
  //                                   },
  //                                 ),
  //                               ],
  //                             ),
  //                             const Divider(height: 1, color: Colors.grey),
  //                           ],
  //                         );
  //                       }),

  //                       /// 🔷 DESTINATION + ADD BUTTON
  //                       Row(
  //                         children: [
  //                           Expanded(
  //                             child: _buildLocationField(
  //                               controller: destinationController,
  //                               icon: Icons.location_on,
  //                               iconColor: Colors.red,
  //                               hint: "Enter Destination",
  //                               onTap: () {
  //                                 setState(() {
  //                                   _selectingPickup = false;
  //                                   _activeStopIndex = null;
  //                                   _suggestions.clear();
  //                                 });
  //                               },
  //                             ),
  //                           ),
  //                           IconButton(
  //                             icon: const Icon(
  //                               Icons.add_circle,
  //                               color: Colors.black,
  //                               size: 28,
  //                             ),
  //                             onPressed: _addStopField,
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),

  //           const SizedBox(height: 10),

  //           /// 🔷 EXPANDED CONTENT BELOW (Nearby Places / Search / Stops)
  //           Expanded(child: _buildExpandedContent(stops)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
String _getScreenTitle() {
  if (widget.isLocationPicker) {
    return "Pick Your Place";
  }

  switch (widget.category) {
    case VehicleCategory.passenger:
      return "Where To";

    case VehicleCategory.exhauster:
      return "Collection Location";

    case VehicleCategory.waterBowser:
      return "Delivery Location";

    case VehicleCategory.machinery:
      return "Site Machinery";

    default:
      return "Where To";
  }
}
  @override
Widget build(BuildContext context) {
  final requiresCurrentLocation =
      widget.category == VehicleCategory.passenger ||
      widget.category == VehicleCategory.exhauster ||
      widget.category == VehicleCategory.waterBowser ||
      widget.category == VehicleCategory.machinery;

  if (!_isPickupLoaded && requiresCurrentLocation) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF015ACE),
        ),
      ),
    );
  }

  final stops = ref.watch(stopsProvider);

  final isPassenger =
      widget.category == VehicleCategory.passenger;

  final isExhauster =
      widget.category == VehicleCategory.exhauster;

  final isWaterBowser =
      widget.category == VehicleCategory.waterBowser;

  final isMachinery =
      widget.category == VehicleCategory.machinery;

  return Scaffold(
    backgroundColor: const Color(0xFFF9FAFB),

    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: Text(
         _getScreenTitle(),
        style: GoogleFonts.spaceGrotesk(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
    ),

    body: Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [

          /// =====================================================
          /// LOCATION INPUT CARD
          /// =====================================================

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 400,
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

                    /// =================================================
                    /// PASSENGER
                    /// Pickup -> Stops -> Destination
                    /// =================================================

                    if (isPassenger && !widget.isLocationPicker) ...[
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

                      const Divider(
                        height: 1,
                        color: Colors.grey,
                      ),

                      /// STOPS
                      ...List.generate(
                        stopControllers.length,
                        (index) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLocationField(
                                      controller:
                                          stopControllers[index],
                                      icon: Icons.trip_origin,
                                      iconColor: Colors.orange,
                                      hint: "Stop ${index + 1}",

                                      onTap: () {
                                        setState(() {
                                          _selectingPickup = true;
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
                                        stopControllers[index]
                                            .dispose();

                                        stopControllers
                                            .removeAt(index);

                                        if (stops.length > index) {
                                          final updatedStops = [
                                            ...stops
                                          ]..removeAt(index);

                                          ref
                                              .read(
                                                stopsProvider
                                                    .notifier,
                                              )
                                              .state = updatedStops;
                                        }

                                        if (_activeStopIndex ==
                                            index) {
                                          _activeStopIndex = null;
                                        }

                                        _suggestions.clear();
                                      });
                                    },
                                  ),
                                ],
                              ),

                              const Divider(
                                height: 1,
                                color: Colors.grey,
                              ),
                            ],
                          );
                        },
                      ),

                      /// DESTINATION
                      Row(
                        children: [
                          Expanded(
                            child: _buildLocationField(
                              controller:
                                  destinationController,
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
                    ]

else if (widget.isLocationPicker && isPassenger) ...[
  _buildLocationField(
    controller: destinationController,
    icon: Icons.location_on_rounded,
    iconColor: const Color(0xFF015ACE),
    hint: "Search for a place",

    onTap: () {
      setState(() {
        _selectingPickup = false;
        _activeStopIndex = null;
        _suggestions.clear();
      });
    },
  ),
]

                    else if (isExhauster) ...[
                      _buildLocationField(
                        controller: destinationController,
                        icon: Icons.cleaning_services_rounded,
                        iconColor: const Color(0xFFF0D000),
                        hint: "Collection Location",

                        onTap: () {
                          setState(() {
                            _selectingPickup = false;
                            _activeStopIndex = null;
                            _suggestions.clear();
                          });
                        },
                      ),
                    ]

                    /// =================================================
                    /// WATER BOWSER
                    /// Current Location -> Delivery Location
                    /// =================================================

                    else if (isWaterBowser) ...[
                      _buildLocationField(
                        controller: destinationController,
                        icon: Icons.water_drop_rounded,
                        iconColor: const Color(0xFF015ACE),
                        hint: "Delivery Location",

                        onTap: () {
                          setState(() {
                            _selectingPickup = false;
                            _activeStopIndex = null;
                            _suggestions.clear();
                          });
                        },
                      ),
                    ]

                    /// =================================================
                    /// MACHINERY
                    /// Current Location -> Site
                    /// =================================================

                    else if (isMachinery) ...[
                      _buildLocationField(
                        controller: destinationController,
                        icon: Icons.construction_rounded,
                        iconColor: const Color(0xFFF0D000),
                        hint: "Site Location",

                        onTap: () {
                          setState(() {
                            _selectingPickup = false;
                            _activeStopIndex = null;
                            _suggestions.clear();
                          });
                        },
                      ),
                    ]

                    /// =================================================
                    /// OTHER SERVICES
                    /// Normal Pickup -> Destination
                    /// =================================================

                    else ...[
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

                      const Divider(
                        height: 1,
                        color: Colors.grey,
                      ),

                      _buildLocationField(
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
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// =====================================================
          /// SEARCH / NEARBY PLACES
          /// =====================================================

          Expanded(
            child: _buildExpandedContent(stops),
          ),
        ],
      ),
    ),
  );
}

  /// 🔷 HELPER METHOD FOR EXPANDED CONTENT
  //google
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
              leading: Icon(place['icon'], color:  Color(0xFF015ACE),),

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
  place['main_text'] ?? '',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: GoogleFonts.nunitoSans(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF111827),
  ),
),

subtitle: Text(
  place['secondary_text'] ?? '',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: GoogleFonts.nunitoSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B7280),
  ),
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
    leading: CircleAvatar(
      child: Text(
        '${index + 1}',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    title: Text(
      address,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),

    subtitle: Text(
      '${latLng.latitude.toStringAsFixed(4)}, '
      '${latLng.longitude.toStringAsFixed(4)}',
      style: GoogleFonts.nunitoSans(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),

    trailing: IconButton(
      icon: const Icon(
        Icons.close,
        color: Colors.red,
      ),
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
              leading: Icon(place['icon'], color: const Color(0xFF015ACE),),
              title: Text(
                place['name'],
                style: GoogleFonts.spaceGrotesk(

                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),


              subtitle: Text(
  place['address'],
  style: GoogleFonts.spaceGrotesk(
    fontSize: 14,
    color: Colors.grey,
  ),
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
    leading: Icon(
      icon,
      color: iconColor,
      size: 28,
    ),

    title: TextField(
      controller: controller,

      style: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),

      decoration: InputDecoration(
        border: InputBorder.none,

        hintText: hint,

        hintStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
        ),
      ),

      onTap: onTap,
    ),
  );
}}

class LocationResult {
  final LatLng pickup;
  final LatLng destination;

  LocationResult({required this.pickup, required this.destination});
}


 