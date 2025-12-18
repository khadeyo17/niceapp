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

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _selectingPickup = false;
  Map<String, dynamic>? _selectedPlace;

  LatLng? CurrentLocation;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchCurrentLocation();
      // final existingPickup = ref.read(pickupLocationProvider);
      //   if (existingPickup == null) {
      //   // Try to load from Firebase Realtime Database
      //   final LatLng? firebasePickup = await _fetchPickupFromFirebase();
      //   if (firebasePickup != null) {
      //     ref.read(pickupLocationProvider.notifier).state = firebasePickup;

      //     final address = await ReverseGeocodingService.getAddressFromLatLng(
      //       firebasePickup,
      //     );
      //     if (mounted) {
      //       setState(() {
      //         pickupController.text = address ?? "Current Location";
      //       });
      //     }
      //   }
      //   if (widget.initialPickupLocation != null) {
      //     // fallback to initialPickupLocation if firebase null
      //     ref.read(pickupLocationProvider.notifier).state =
      //         widget.initialPickupLocation!;
      //     final address = await ReverseGeocodingService.getAddressFromLatLng(
      //       widget.initialPickupLocation!,
      //     );
      //     if (mounted) {
      //       setState(() {
      //         pickupController.text = address ?? "Current Location";
      //       });
      //     }
      //   }
      // }
      // else {
      //   // If state already has pickup, just update the text
      //   final address = await ReverseGeocodingService.getAddressFromLatLng(
      //     existingPickup,
      //   );
      //   if (mounted) {
      //     setState(() {
      //       pickupController.text = address ?? "Current Location";
      //     });
      //   }
      // }
    });

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
          setState(() {
            _suggestions = List<Map<String, dynamic>>.from(data['predictions']);
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

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => pickupController.text = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => pickupController.text = "Permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => pickupController.text = "Permission permanently denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      CurrentLocation = LatLng(position.latitude, position.longitude);
      _getAddressFromLatLng(CurrentLocation!);
    } catch (e) {
      debugPrint("Error fetching location: $e");
      setState(() => pickupController.text = "Unable to fetch location");
    }
  }

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
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      String address;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Uber-style dynamic formatting
        final parts = [
          if (p.name != null && p.name!.isNotEmpty) p.name,
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea,
        ];

        address = parts.join(", ");
      } else {
        address = "Lat: ${latLng.latitude}, Lng: ${latLng.longitude}";
      }

      setState(() {
        pickupController.text = address;
      });
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  Future<void> _onSuggestionTap(Map<String, dynamic> place) async {
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
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final latLng = LatLng(lat, lon);
    final address = place['display_name'];

    final currentStops = ref.read(stopsProvider);

    final isDuplicate = currentStops.any(
      (stop) =>
          stop['latLng'].latitude == lat && stop['latLng'].longitude == lon,
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
      backgroundColor: const Color(0xFFF9FAFB), // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Where to?",
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (widget.category == VehicleCategory.exhauster ||
                      widget.category == VehicleCategory.waterBowser) ...[
                    _buildLocationField(
                      controller: destinationController,
                      icon: Icons.location_on,
                      iconColor: Colors.red,

                      // hint: "Enter Destination",
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
                    _buildLocationField(
                      controller: pickupController,
                      icon: Icons.my_location,
                      iconColor: Colors.green,
                      hint: "Set Pickup Location",
                      onTap: () {
                        setState(() {
                          _selectingPickup = true;
                          _suggestions.clear();
                        });
                      },
                    ),
                    const Divider(height: 1, color: Colors.grey),

                    //const Divider(),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),
                    //   child: Column(
                    //     children: const [
                    //       Icon(
                    //         Icons.arrow_downward,
                    //         color: Colors.grey,
                    //         size: 20,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // _buildLocationField(
                    //   controller: destinationController,
                    //   icon: Icons.location_on,
                    //   iconColor: Colors.red,
                    //   hint: "Enter Destination",
                    //   onTap: () {
                    //     setState(() {
                    //       _selectingPickup = false;
                    //       _suggestions.clear();
                    //     });
                    //   },
                    // ),
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
                  ],
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 10),
            if (_suggestions.isNotEmpty)
              Expanded(
                child: AnimatedList(
                  initialItemCount: _suggestions.length,
                  itemBuilder: (context, index, animation) {
                    final place = _suggestions[index];
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut)),
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.place_outlined,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            place['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => _onSuggestionTap(place),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_suggestions.isEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: stops.length,
                  itemBuilder: (_, index) {
                    final stop = stops[index];
                    final latLng = stop['latLng'] as LatLng;
                    final address = stop['address'] as String;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            final updatedStops = [...stops]..removeAt(index);
                            ref.read(stopsProvider.notifier).state =
                                updatedStops;
                          },
                        ),
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