import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';

class MoversScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? pickup;
  final LatLng? destination;

  const MoversScreen({
    super.key,
    required this.category,
    this.pickup,
    this.destination,
  });

  @override
  State<MoversScreen> createState() => _MoversScreenScreenState();
}

class _MoversScreenScreenState extends State<MoversScreen> {
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  DateTime? movingDate;
  final TextEditingController movingDateController = TextEditingController();
  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  String? displayAddress;
  LatLng? pickupLatLng;
  String? pickupAddress;
  //Map<String, double> priceMap = {};
  double? selectedPrice;
  @override
  void dispose() {
    detailsController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchSubcategories();
    if (pickupLatLng == null && widget.pickup == null) {
      _getPickupLocationFromFirebase();
    } else {
      pickupLatLng = widget.pickup ?? pickupLatLng;
      _getAddressFromLatLng(pickupLatLng!, isPickup: true);
    }

    if (widget.destination != null && selectedLatLng == null) {
      selectedLatLng = widget.destination;
      _getAddressFromLatLng(widget.destination!, isPickup: false);
    }
  }

  Future<void> fetchSubcategories() async {
    final category = widget.category;

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/vehicles/categoryexhausterwater?categoryId=${category.index}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedSubcategories = List<Subcategory>.from(
          data.map((item) => Subcategory.fromJson(item)),
        );

        setState(() {
          subcategories = fetchedSubcategories;
          // Optional: select the first one by default
          // if (subcategories.isNotEmpty) {
          //   selectedSubcategory = subcategories[0];
          // }
        });
      } else {
        debugPrint('Failed to load subcategories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
    }
  }

  Future<void> _pollDriverAssignment(
    BuildContext context,
    String firebaseId,
  ) async {
    const pollingInterval = Duration(seconds: 5);
    const maxAttempts = 12; // 1 minute (12 x 5s)
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(pollingInterval);

      final response = await http.get(
        Uri.parse('$baseUrl/rides/passenger/current/$firebaseId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if driver has been assigned
        if (data['driver'] != null &&
            data['driver']['driverName'] != null &&
            data['driver']['driverName'] != 'N/A') {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // ✅ Dismiss "Searching..." dialog
          }

          // Push to driver assignment screen with info
          Navigator.pushReplacementNamed(
            context,
            '/driverAssignment',
            arguments: {
              'driverName': data['driver']['driverName'],
              'driverContact': data['driver']['driverPhone'],
              'vehicle': {
                'make': data['driver']['vehicleMake'],
                'model': data['driver']['vehicleModel'],
                'color': data['driver']['vehicleColour'],
                'registration': data['driver']['registrationNumber'],
              },
              'eta':
                  data['eta'] ??
                  5, // You can replace this with backend ETA when ready
            },
          );
          return;
        }
      }

      attempts++;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Dismiss "Searching..." if polling ends
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No driver found yet. Please try again later.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _openDestinationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhereToScreen(category: VehicleCategory.movers),
      ),
    );

    // if (result != null && result is LatLng) {
    //   setState(() {
    //     selectedLatLng = result;
    //   });

    if (result != null && result is Map<String, LatLng>) {
      setState(() {
        pickupLatLng = result['pickup'];
        selectedLatLng = result['destination'];
      });

      // Update both pickup and destination addresses
      if (pickupLatLng != null) {
        _getAddressFromLatLng(pickupLatLng!, isPickup: true);
      }
      if (selectedLatLng != null) {
        _getAddressFromLatLng(selectedLatLng!, isPickup: false);
      }
    }
  }

  Future<void> _getPickupLocationFromFirebase() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final ref = FirebaseDatabase.instance.ref("passengers/$uid/location");

      ref.onValue.listen((event) {
        final data = event.snapshot.value as Map?;
        if (data != null &&
            data['latitude'] != null &&
            data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();

          setState(() {
            pickupLatLng = LatLng(lat, lng);
          });

          _getAddressFromLatLng(LatLng(lat, lng), isPickup: true);
        }
      });
    } catch (e) {
      debugPrint("Error fetching pickup location: $e");
    }
  }

  // Future<void> _getAddressFromLatLng(LatLng latLng) async {
  //   try {
  //     final placemarks = await placemarkFromCoordinates(
  //       latLng.latitude,
  //       latLng.longitude,
  //     );
  //     if (placemarks.isNotEmpty) {
  //       final place = placemarks.first;
  //       setState(() {
  //         displayAddress =
  //             "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
  //       });
  //     } else {
  //       setState(() {
  //         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
  //     });
  //     debugPrint("Reverse geocoding failed: $e");
  //   }
  // }
  Future<void> _getAddressFromLatLng(
    LatLng latLng, {
    bool isPickup = false,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      String address;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address =
            "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
      } else {
        address = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
      }

      setState(() {
        if (isPickup) {
          pickupAddress = address;
        } else {
          displayAddress = address;
        }
      });
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movers Service'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request Movers',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: pickupAddress ?? 'Fetching pickup location...',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Destination Field (Clickable)
                  GestureDetector(
                    onTap: _openDestinationPicker,
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: displayAddress ?? 'Tap to select destination',
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Destination Location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () async {
                      DateTime now = DateTime.now();

                      // Step 1: Pick Date
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 1),
                      );

                      if (pickedDate != null) {
                        // Step 2: Pick Time
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (pickedTime != null) {
                          // Step 3: Combine date + time into one DateTime
                          final combinedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );

                          setState(() {
                            movingDate = combinedDateTime;
                            movingDateController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
                                "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                          });
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: movingDateController,
                        decoration: const InputDecoration(
                          labelText: 'Moving Date & Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.orange,
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Subcategory>(
                    value: selectedSubcategory,
                    isExpanded: true,
                    hint: const Text('Select No Of Rooms'),
                    items:
                        subcategories.map((subcategory) {
                          return DropdownMenuItem<Subcategory>(
                            value: subcategory,
                            child: Text(subcategory.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubcategory = value;
                        selectedPrice = value?.baseFare;
                        priceController.text =
                            selectedPrice != null
                                ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
                                : '';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Rooms",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.house),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextFormField(
                    controller: priceController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Price',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextFormField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Details (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 40),

                  // InkWell(
                  //onTap: _openDestinationPicker,
                  //   child: Container(
                  //     padding: const EdgeInsets.all(16),
                  //     decoration: BoxDecoration(
                  //       border: Border.all(color: Colors.grey.shade400),
                  //       borderRadius: BorderRadius.circular(12),
                  //       color: Colors.grey.shade100,
                  //     ),
                  //     child: Row(
                  //       children: [
                  //         const Icon(
                  //           Icons.location_on_outlined,
                  //           color: Colors.black,
                  //         ),
                  //         const SizedBox(width: 12),
                  //         Expanded(
                  //           child: Text(
                  //             displayAddress ??
                  //                 'Tap to select destination on map',
                  //             style: TextStyle(
                  //               fontSize: 16,
                  //               color:
                  //                   displayAddress == null
                  //                       ? Colors.grey[700]
                  //                       : Colors.black87,
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedSubcategory == null ||
                          selectedLatLng == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please complete all required fields',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final token =
                          await FirebaseAuth.instance.currentUser?.getIdToken();
                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authentication error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final requestBody = {
                        "firebaseIdToken": token,
                        "destLat": selectedLatLng!.latitude,
                        "destLng": selectedLatLng!.longitude,
                        "destination": displayAddress ?? '',
                        "notes": detailsController.text,
                        "subCategoryId": selectedSubcategory?.id,
                        "scheduledTime": null,
                      };

                      try {
                        setState(() => _isLoading = true);

                        final response = await http.post(
                          Uri.parse('$baseUrl/rides/exhauster/book'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(requestBody),
                        );

                        setState(() => _isLoading = false);

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          final rideId = data['rideId'];

                          if (rideId != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DriverAssignmentsScreen(
                                      destination: selectedLatLng!,
                                      pickup: pickupLatLng,
                                      rideId: rideId,
                                      category: selectedSubcategory!,
                                      fare: selectedPrice ?? 0,
                                    ),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking failed: ${response.body}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Unexpected error. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("Confirm and Submit Request"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ✅ Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// class Subcategory {
//   final int id;
//   final String name;
//   final double baseFare;

//   Subcategory({required this.id, required this.name, required this.baseFare});

//   factory Subcategory.fromJson(Map<String, dynamic> json) {
//     return Subcategory(
//       id: json['id'],
//       name: json['name'],
//       baseFare: (json['baseFare'] as num).toDouble(),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

// class MoversScreen extends ConsumerStatefulWidget {
//   final LatLng? pickupLocation;
//   final LatLng? dropLocation;

//   // const MoversScreen(
//   //   {
//   //   super.key, this.required.pickupLocation,
//   //   this.dropLocation,
//   // });

//   const MoversScreen({
//     super.key,
//     this.pickupLocation,
//     this.dropLocation,
//     required VehicleCategory category,
//   });

//   @override
//   ConsumerState<MoversScreen> createState() => _MoversScreenState();
// }

// class _MoversScreenState extends ConsumerState<MoversScreen> {
//   final TextEditingController itemDetailsController = TextEditingController();
//   final TextEditingController boxesController = TextEditingController();
//   LatLng? pickupLocation;
//   LatLng? dropLocation;
//   bool packingRequired = false;
//   bool unpackingRequired = false;
//   int? selectedSubCategoryId;
//   bool showAvailableMovers = false;
//   List<dynamic> availableMovers = [];
//   DateTime? travelDate;
//   double distanceRadius = 30;
//   bool pickupHasElevator = false;
//   bool pickupHasParking = false;
//   bool hasFragileItems = false;
//   bool hasHeavyItems = false;
//   bool needsDisassembly = false;
//   bool wantsInsurance = false;

//   @override
//   void initState() {
//     super.initState();
//     pickupLocation = widget.pickupLocation;
//     dropLocation = widget.dropLocation;
//   }

//   void openLocationSelector() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => WhereToScreen(category: VehicleCategory.movers),
//       ),
//     );

//     // Update after navigation
//     setState(() {
//       pickupLocation = ref.read(pickupLocationProvider);
//       dropLocation = ref.read(destinationLocationProvider);

//       //pickupLocation = ref.read(pickupLocationProvider);
//       //dropLocation = ref.read(destinationLocationProvider);
//     });
//   }

//   Future<void> searchAvailableMovers() async {
//     if (pickupLocation == null ||
//         dropLocation == null ||
//         selectedSubCategoryId == null) {
//       _showError("Please select pickup, drop, and item details.");
//       return;
//     }

//     try {
//       // final response = await http.get(
//       //   Uri.parse(
//       //     "$baseUrl/rides/movers/available?pickupLat=${pickupLocation!.latitude}&pickupLng=${pickupLocation!.longitude}&dropLat=${dropLocation!.latitude}&dropLng=${dropLocation!.longitude}&subCategoryId=$selectedSubCategoryId",
//       //   ),
//       //   headers: {'Content-Type': 'application/json'},
//       // );

//       // if (response.statusCode == 200) {
//       //   final data = json.decode(response.body);
//       //   setState(() {
//       //     availableMovers = data; // Should be a list of movers
//       //     showAvailableMovers = true;
//       //   });
//       // } else {
//       //   _showError("Failed to fetch available movers.");
//       // }
//       final queryParams = {
//         'pickupLat': pickupLocation!.latitude.toString(),
//         'pickupLng': pickupLocation!.longitude.toString(),
//         'dropLat': dropLocation!.latitude.toString(),
//         'dropLng': dropLocation!.longitude.toString(),
//         'subCategoryId': selectedSubCategoryId.toString(),
//         'radiusKm': distanceRadius.toInt().toString(),
//         'travelDate':
//             travelDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
//       };

//       final uri = Uri.parse(
//         "$baseUrl/rides/movers/available",
//       ).replace(queryParameters: queryParams);
//     } catch (e) {
//       _showError("Error: $e");
//     }
//   }

//   Future<void> fetchSubCategories() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/rides/subcategories?categoryType=movers'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data is List && data.isNotEmpty) {
//           setState(() {
//             selectedSubCategoryId = data[0]['id']; // Auto-select the first one
//           });
//         } else {
//           _showError("No subcategories found for Movers.");
//         }
//       } else {
//         _showError("Failed to fetch subcategories.");
//       }
//     } catch (e) {
//       _showError("Error fetching subcategories: $e");
//     }
//   }

//   Future<void> submitRequest() async {
//     final user = FirebaseAuth.instance.currentUser;
//     final idToken = await user?.getIdToken();

//     if (pickupLocation == null ||
//         dropLocation == null ||
//         idToken == null ||
//         selectedSubCategoryId == null) {
//       _showError("Missing required fields.");
//       return;
//     }

//     final payload = {
//       "pickupCoordinates": {
//         "latitude": pickupLocation!.latitude,
//         "longitude": pickupLocation!.longitude,
//       },
//       "destinationCoordinates": {
//         "latitude": dropLocation!.latitude,
//         "longitude": dropLocation!.longitude,
//       },
//       "itemDetails": itemDetailsController.text,
//       "subCategoryId": selectedSubCategoryId,
//       "firebaseIdToken": idToken,
//       "cargoWeight": 250, // optional
//       "estimatedFare": 1000, // optional
//     };

//     try {
//       final response = await http.post(
//         Uri.parse("$baseUrl/rides/movers/book"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(payload),
//       );

//       print("Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         _showMessage("Movers request submitted successfully.");
//       } else {
//         _showError("Failed to submit. (${response.statusCode})");
//       }
//     } catch (e) {
//       _showError("Error: ${e.toString()}");
//     }
//   }

//   Widget _sectionTitle(String text) {
//     return Text(
//       text,
//       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//     );
//   }
//   // Future<void> submitRequest() async {
//   //   final payload = {
//   //     "pickupCoordinates": {
//   //       "latitude": pickupLocation!.latitude,
//   //       "longitude": pickupLocation!.longitude,
//   //     },
//   //     "destinationCoordinates": {
//   //       "latitude": dropLocation!.latitude,
//   //       "longitude": dropLocation!.longitude,
//   //     },
//   //     "itemDetails": itemDetailsController.text,
//   //     "packingRequired": packingRequired,
//   //     "unpackingRequired": unpackingRequired,
//   //   };

//   //   try {
//   //     final response = await http.post(
//   //       Uri.parse("$baseUrl/rides/movers/book"),
//   //       headers: {"Content-Type": "application/json"},
//   //       body: jsonEncode(payload),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       _showMessage("Movers request submitted successfully.");
//   //     } else {
//   //       _showError("Failed to submit. (${response.statusCode})");
//   //     }
//   //   } catch (e) {
//   //     _showError("Error: ${e.toString()}");
//   //   }
//   // }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }

//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Movers Services'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: Stack(
//         children: [
//           ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               ItemDetailsSection(itemDetailsController: itemDetailsController),
//               const SizedBox(height: 20),
//               AccessibilitySection(
//                 pickupHasElevator: pickupHasElevator,
//                 pickupHasParking: pickupHasParking,
//                 onElevatorChanged:
//                     (val) => setState(() => pickupHasElevator = val),
//                 onParkingChanged:
//                     (val) => setState(() => pickupHasParking = val),
//               ),
//               const SizedBox(height: 20),
//               InventorySection(
//                 boxesController: boxesController,
//                 hasFragileItems: hasFragileItems,
//                 hasHeavyItems: hasHeavyItems,
//                 needsDisassembly: needsDisassembly,
//                 onFragileChanged:
//                     (val) => setState(() => hasFragileItems = val),
//                 onHeavyChanged: (val) => setState(() => hasHeavyItems = val),
//                 onDisassemblyChanged:
//                     (val) => setState(() => needsDisassembly = val),
//               ),
//               const SizedBox(height: 20),
//               PreferencesSection(
//                 packingRequired: packingRequired,
//                 wantsInsurance: wantsInsurance,
//                 onPackingChanged:
//                     (val) => setState(() => packingRequired = val),
//                 onInsuranceChanged:
//                     (val) => setState(() => wantsInsurance = val),
//               ),
//               const SizedBox(height: 20),
//               TripDetailsSection(
//                 travelDate: travelDate,
//                 pickupLocation: pickupLocation,
//                 dropLocation: dropLocation,
//                 onDatePicked: (picked) => setState(() => travelDate = picked),
//                 onSelectLocation: openLocationSelector,
//               ),
//               const SizedBox(height: 20),
//               SearchRadiusSection(
//                 radius: distanceRadius,
//                 onChanged: (val) => setState(() => distanceRadius = val),
//                 onFindMovers: searchAvailableMovers,
//               ),
//             ],
//           ),
//           if (showAvailableMovers)
//             DraggableScrollableSheet(
//               initialChildSize: 0.45,
//               minChildSize: 0.3,
//               maxChildSize: 0.85,
//               builder: (context, scrollController) {
//                 return Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(24),
//                     ),
//                     boxShadow: [
//                       BoxShadow(color: Colors.black26, blurRadius: 10),
//                     ],
//                   ),
//                   child: ListView.builder(
//                     controller: scrollController,
//                     itemCount: availableMovers.length,
//                     itemBuilder: (context, index) {
//                       final mover = availableMovers[index];

//                       return Card(
//                         elevation: 3,
//                         margin: const EdgeInsets.symmetric(vertical: 10),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.all(12),
//                           leading: CircleAvatar(
//                             radius: 28,
//                             backgroundImage: NetworkImage(
//                               mover['profileImageUrl'] ?? '',
//                             ),
//                             backgroundColor: Colors.grey[200],
//                           ),
//                           title: Text(
//                             mover['name'] ?? 'Mover #${index + 1}',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "🚚 Vehicle: ${mover['vehicleType'] ?? 'Unknown'}",
//                               ),
//                               Text(
//                                 "⭐ Rating: ${mover['rating']?.toStringAsFixed(1) ?? 'N/A'}",
//                               ),
//                               Text(
//                                 "💰 Fare: KES ${mover['estimatedFare'] ?? '---'}",
//                               ),
//                             ],
//                           ),
//                           trailing: ElevatedButton(
//                             child: const Text("Select"),
//                             onPressed: () {
//                               _showMessage("You selected ${mover['name']}");
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }
// }

// //       body: ListView(
// //   padding: const EdgeInsets.all(16),
// //   children: [
// //     ItemDetailsSection(itemDetailsController: itemDetailsController),
// //     const SizedBox(height: 20),
// //     AccessibilitySection(
// //       pickupHasElevator: pickupHasElevator,
// //       pickupHasParking: pickupHasParking,
// //       onElevatorChanged: (val) => setState(() => pickupHasElevator = val),
// //       onParkingChanged: (val) => setState(() => pickupHasParking = val),
// //     ),
// //     const SizedBox(height: 20),
// //     InventorySection(
// //       boxesController: boxesController,
// //       hasFragileItems: hasFragileItems,
// //       hasHeavyItems: hasHeavyItems,
// //       needsDisassembly: needsDisassembly,
// //       onFragileChanged: (val) => setState(() => hasFragileItems = val),
// //       onHeavyChanged: (val) => setState(() => hasHeavyItems = val),
// //       onDisassemblyChanged: (val) => setState(() => needsDisassembly = val),
// //     ),
// //     const SizedBox(height: 20),
// //     PreferencesSection(
// //       packingRequired: packingRequired,
// //       wantsInsurance: wantsInsurance,
// //       onPackingChanged: (val) => setState(() => packingRequired = val),
// //       onInsuranceChanged: (val) => setState(() => wantsInsurance = val),
// //     ),
// //     const SizedBox(height: 20),
// //     TripDetailsSection(
// //       travelDate: travelDate,
// //       pickupLocation: pickupLocation,
// //       dropLocation: dropLocation,
// //       onDatePicked: (picked) => setState(() => travelDate = picked),
// //       onSelectLocation: openLocationSelector,
// //     ),
// //     const SizedBox(height: 20),
// //     SearchRadiusSection(
// //       radius: distanceRadius,
// //       onChanged: (val) => setState(() => distanceRadius = val),
// //       onFindMovers: searchAvailableMovers,
// //     ),
// //   ],
// // ),

// // Draggable Sheet
// //           if (showAvailableMovers)
// //             DraggableScrollableSheet(
// //               initialChildSize: 0.45,
// //               minChildSize: 0.3,
// //               maxChildSize: 0.85,
// //               builder: (context, scrollController) {
// //                 return Container(
// //                   padding: const EdgeInsets.all(16),
// //                   decoration: const BoxDecoration(
// //                     color: Colors.white,
// //                     borderRadius: BorderRadius.vertical(
// //                       top: Radius.circular(24),
// //                     ),
// //                     boxShadow: [
// //                       BoxShadow(color: Colors.black26, blurRadius: 10),
// //                     ],
// //                   ),
// //                   child: ListView.builder(
// //                     controller: scrollController,
// //                     itemCount: availableMovers.length,
// //                     itemBuilder: (context, index) {
// //                       final mover = availableMovers[index];

// //                       return Card(
// //                         elevation: 3,
// //                         margin: const EdgeInsets.symmetric(vertical: 10),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(16),
// //                         ),
// //                         child: ListTile(
// //                           contentPadding: const EdgeInsets.all(12),
// //                           leading: CircleAvatar(
// //                             radius: 28,
// //                             backgroundImage: NetworkImage(
// //                               mover['profileImageUrl'] ?? '',
// //                             ),
// //                             backgroundColor: Colors.grey[200],
// //                           ),
// //                           title: Text(
// //                             mover['name'] ?? 'Mover #${index + 1}',
// //                             style: const TextStyle(fontWeight: FontWeight.bold),
// //                           ),
// //                           subtitle: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 "🚚 Vehicle: ${mover['vehicleType'] ?? 'Unknown'}",
// //                               ),
// //                               Text(
// //                                 "⭐ Rating: ${mover['rating']?.toStringAsFixed(1) ?? 'N/A'}",
// //                               ),
// //                               Text(
// //                                 "💰 Fare: KES ${mover['estimatedFare'] ?? '---'}",
// //                               ),
// //                             ],
// //                           ),
// //                           trailing: ElevatedButton(
// //                             child: const Text("Select"),
// //                             onPressed: () {
// //                               _showMessage("You selected ${mover['name']}");
// //                             },
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 );
// //               },
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // This is a cleaned-up modular version of your MoversScreen form.
// // Each section is extracted to a reusable widget for maintainability.

// class ItemDetailsSection extends StatelessWidget {
//   final TextEditingController itemDetailsController;

//   const ItemDetailsSection({super.key, required this.itemDetailsController});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Request Moving Service',
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         TextFormField(
//           controller: itemDetailsController,
//           decoration: InputDecoration(
//             labelText: 'Describe Items to be Moved',
//             prefixIcon: const Icon(Icons.inventory),
//             filled: true,
//             fillColor: Colors.grey[100],
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//           maxLines: 3,
//         ),
//       ],
//     );
//   }
// }

// class AccessibilitySection extends StatelessWidget {
//   final bool pickupHasElevator;
//   final bool pickupHasParking;
//   final Function(bool) onElevatorChanged;
//   final Function(bool) onParkingChanged;

//   const AccessibilitySection({
//     super.key,
//     required this.pickupHasElevator,
//     required this.pickupHasParking,
//     required this.onElevatorChanged,
//     required this.onParkingChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Location Accessibility',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           decoration: const InputDecoration(
//             labelText: "Pickup Floor (e.g., Ground, 1st, 4th)",
//             prefixIcon: Icon(Icons.stairs),
//           ),
//         ),
//         SwitchListTile(
//           title: const Text("Elevator Available at Pickup"),
//           value: pickupHasElevator,
//           onChanged: onElevatorChanged,
//         ),
//         SwitchListTile(
//           title: const Text("Parking Available at Pickup"),
//           value: pickupHasParking,
//           onChanged: onParkingChanged,
//         ),
//       ],
//     );
//   }
// }

// class InventorySection extends StatelessWidget {
//   final TextEditingController boxesController;
//   final bool hasFragileItems;
//   final bool hasHeavyItems;
//   final bool needsDisassembly;
//   final Function(bool) onFragileChanged;
//   final Function(bool) onHeavyChanged;
//   final Function(bool) onDisassemblyChanged;

//   const InventorySection({
//     super.key,
//     required this.boxesController,
//     required this.hasFragileItems,
//     required this.hasHeavyItems,
//     required this.needsDisassembly,
//     required this.onFragileChanged,
//     required this.onHeavyChanged,
//     required this.onDisassemblyChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Inventory & Special Items',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: boxesController,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(
//             labelText: "Number of Boxes",
//             prefixIcon: Icon(Icons.inventory_2_outlined),
//           ),
//         ),
//         CheckboxListTile(
//           title: const Text("Includes Fragile Items"),
//           value: hasFragileItems,
//           onChanged: (val) => onFragileChanged(val!),
//         ),
//         CheckboxListTile(
//           title: const Text("Includes Heavy Items (e.g., Piano, Safe)"),
//           value: hasHeavyItems,
//           onChanged: (val) => onHeavyChanged(val!),
//         ),
//         SwitchListTile(
//           title: const Text("Disassembly/Reassembly Required"),
//           value: needsDisassembly,
//           onChanged: onDisassemblyChanged,
//         ),
//       ],
//     );
//   }
// }

// class PreferencesSection extends StatelessWidget {
//   final bool packingRequired;
//   final bool wantsInsurance;
//   final Function(bool) onPackingChanged;
//   final Function(bool) onInsuranceChanged;

//   const PreferencesSection({
//     super.key,
//     required this.packingRequired,
//     required this.wantsInsurance,
//     required this.onPackingChanged,
//     required this.onInsuranceChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Other Preferences',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         SwitchListTile(
//           title: const Text("Transit Insurance Required"),
//           value: wantsInsurance,
//           onChanged: onInsuranceChanged,
//         ),
//         SwitchListTile(
//           title: const Text("Packing Required"),
//           value: packingRequired,
//           onChanged: onPackingChanged,
//           secondary: const Icon(Icons.all_inbox),
//         ),
//       ],
//     );
//   }
// }

// class TripDetailsSection extends StatelessWidget {
//   final DateTime? travelDate;
//   final LatLng? pickupLocation;
//   final LatLng? dropLocation;
//   final Function(DateTime) onDatePicked;
//   final VoidCallback onSelectLocation;

//   const TripDetailsSection({
//     super.key,
//     required this.travelDate,
//     required this.pickupLocation,
//     required this.dropLocation,
//     required this.onDatePicked,
//     required this.onSelectLocation,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ListTile(
//           leading: const Icon(Icons.calendar_today),
//           title: Text(
//             travelDate != null
//                 ? "Travel Date: ${travelDate!.toLocal().toString().split(' ')[0]}"
//                 : "Select Travel Date",
//           ),
//           trailing: const Icon(Icons.edit_calendar),
//           onTap: () async {
//             final picked = await showDatePicker(
//               context: context,
//               initialDate: DateTime.now(),
//               firstDate: DateTime.now(),
//               lastDate: DateTime.now().add(const Duration(days: 365)),
//             );
//             if (picked != null) {
//               onDatePicked(picked);
//             }
//           },
//         ),
//         ElevatedButton.icon(
//           icon: const Icon(Icons.location_on),
//           label: const Text("Select Pickup & Destination"),
//           onPressed: onSelectLocation,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blueAccent,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             minimumSize: const Size(double.infinity, 50),
//           ),
//         ),
//         const SizedBox(height: 10),
//         if (pickupLocation != null)
//           Text(
//             "📍 Pickup: ${pickupLocation!.latitude}, ${pickupLocation!.longitude}",
//           ),
//         if (dropLocation != null)
//           Text(
//             "📍 Drop: ${dropLocation!.latitude}, ${dropLocation!.longitude}",
//           ),
//       ],
//     );
//   }
// }

// class SearchRadiusSection extends StatelessWidget {
//   final double radius;
//   final ValueChanged<double> onChanged;
//   final VoidCallback onFindMovers;

//   const SearchRadiusSection({
//     super.key,
//     required this.radius,
//     required this.onChanged,
//     required this.onFindMovers,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Search Radius from Your Location (KM)",
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         Slider(
//           value: radius,
//           min: 10,
//           max: 100,
//           divisions: 18,
//           label: "${radius.toInt()} km",
//           onChanged: onChanged,
//         ),
//         Text(
//           "Searching within ${radius.toInt()} km",
//           style: TextStyle(color: Colors.grey[600]),
//         ),
//         const SizedBox(height: 20),
//         ElevatedButton.icon(
//           onPressed: onFindMovers,
//           icon: const Icon(Icons.search),
//           label: const Text("Find Movers"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.grey[700],
//             foregroundColor: Colors.white,
//             minimumSize: const Size(double.infinity, 50),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
