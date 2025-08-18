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

class CarHireScreen extends StatefulWidget {
  final VehicleCategory category;

  const CarHireScreen({super.key, required this.category});

  @override
  State<CarHireScreen> createState() => _CarHireScreenScreenState();
}

class _CarHireScreenScreenState extends State<CarHireScreen> {
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  // DateTime? movingDate;
  // final TextEditingController movingDateController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  String? displayAddress;
  LatLng? pickupLatLng;
  String? pickupAddress;
  double? kilometersCovered;
  //Map<String, double> priceMap = {};
  double? selectedPrice;
  @override
  void dispose() {
    detailsController.dispose();
    priceController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchSubcategories();
    // if (pickupLatLng == null && widget.pickup == null) {
    //   _getPickupLocationFromFirebase();
    // } else {
    //   pickupLatLng = widget.pickup ?? pickupLatLng;
    //   _getAddressFromLatLng(pickupLatLng!, isPickup: true);
    // }

    // if (widget.destination != null && selectedLatLng == null) {
    //   selectedLatLng = widget.destination;
    //   _getAddressFromLatLng(widget.destination!, isPickup: false);
    // }
  }

  // Future<void> _pickDate(
  //   TextEditingController controller,
  //   bool isFromDate,
  // ) async {
  //   DateTime now = DateTime.now();
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: now,
  //     firstDate: now,
  //     lastDate: DateTime(now.year + 1),
  //   );

  //   if (picked != null) {
  //     setState(() {
  //       controller.text =
  //           "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
  //       if (isFromDate) {
  //         fromDate = picked;
  //       } else {
  //         toDate = picked;
  //       }
  //     });
  //   }
  // }

  Future<void> _pickFromDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
        fromDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

        // Auto set ToDate = FromDate + 2 days
        toDate = picked.add(const Duration(days: 2));
        toDateController.text =
            "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";

        _updatePrice();
      });
    }
  }

  Future<void> _pickToDate() async {
    if (fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select From Date first")),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate!.add(const Duration(days: 2)),
      firstDate: fromDate!.add(
        const Duration(days: 2),
      ), // ✅ At least 2 days later
      lastDate: DateTime(fromDate!.year + 1),
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
        toDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _updatePrice();
      });
    }
  }

  void _updatePrice() {
    if (selectedSubcategory != null && fromDate != null && toDate != null) {
      final days = toDate!.difference(fromDate!).inDays;

      // if (selectedSubcategory!.pricePerKilometer == 0) {
      //   // Multiply base fare by number of days
      //   selectedPrice = (selectedSubcategory!.baseFare ?? 0) * days;
      // } else {
      //   // Multiply price per kilometer by kilometers covered
      //   selectedPrice =
      //       (selectedSubcategory!.pricePerKilometer ?? 0) *
      //       (kilometersCovered ?? 0);
      // }
      selectedPrice = (selectedSubcategory!.baseFare ?? 0) * days;
      priceController.text = 'KES ${selectedPrice!.toStringAsFixed(2)}';
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
        content: Text('No Car Hire found yet. Please try again later.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // void _openDestinationPicker() async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => WhereToScreen(category: VehicleCategory.movers),
  //     ),
  //   );

  //   // if (result != null && result is LatLng) {
  //   //   setState(() {
  //   //     selectedLatLng = result;
  //   //   });

  //   if (result != null && result is Map<String, LatLng>) {
  //     setState(() {
  //       pickupLatLng = result['pickup'];
  //       selectedLatLng = result['destination'];
  //     });

  //     // Update both pickup and destination addresses
  //     if (pickupLatLng != null) {
  //       _getAddressFromLatLng(pickupLatLng!, isPickup: true);
  //     }
  //     if (selectedLatLng != null) {
  //       _getAddressFromLatLng(selectedLatLng!, isPickup: false);
  //     }
  //   }
  // }

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
        title: const Text('Car Hire Service'),
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
                    'Request Car Hire',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<Subcategory>(
                    value: selectedSubcategory,
                    isExpanded: true,
                    hint: const Text('Select Car Categories'),

                    // Cards for dropdown menu
                    items:
                        subcategories.map((subcategory) {
                          return DropdownMenuItem<Subcategory>(
                            value: subcategory,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  subcategory.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                    // Plain text for selected value
                    selectedItemBuilder: (context) {
                      return subcategories.map((subcategory) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            subcategory.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList();
                    },

                    onChanged: (value) {
                      setState(() {
                        selectedSubcategory = value;
                        // selectedPrice = value?.baseFare;
                        priceController.text =
                            selectedPrice != null
                                ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
                                : '';
                      });
                    },

                    decoration: InputDecoration(
                      labelText: "Car categories",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.house),
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
                  // From Date
                  GestureDetector(
                    onTap: () => _pickFromDate(),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: fromDateController,
                        decoration: const InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.green,
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // To Date
                  GestureDetector(
                    onTap: () => _pickToDate(),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: toDateController,
                        decoration: const InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.red,
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // const SizedBox(height: 20),
                  // TextFormField(
                  //   readOnly: true,
                  //   controller: TextEditingController(
                  //     text: pickupAddress ?? 'Fetching pickup location...',
                  //   ),
                  //   decoration: const InputDecoration(
                  //     labelText: 'Pickup Location',
                  //     border: OutlineInputBorder(),
                  //     prefixIcon: Icon(Icons.my_location, color: Colors.blue),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),

                  // // Destination Field (Clickable)
                  // GestureDetector(
                  //   onTap: _openDestinationPicker,
                  //   child: AbsorbPointer(
                  //     child: TextFormField(
                  //       readOnly: true,
                  //       controller: TextEditingController(
                  //         text: displayAddress ?? 'Tap to select destination',
                  //       ),
                  //       decoration: const InputDecoration(
                  //         labelText: 'Destination Location',
                  //         border: OutlineInputBorder(),
                  //         prefixIcon: Icon(
                  //           Icons.location_on,
                  //           color: Colors.red,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  //const SizedBox(height: 20),

                  // GestureDetector(
                  //   onTap: () async {
                  //     DateTime now = DateTime.now();

                  //     // Step 1: Pick Date
                  //     final pickedDate = await showDatePicker(
                  //       context: context,
                  //       initialDate: now,
                  //       firstDate: now,
                  //       lastDate: DateTime(now.year + 1),
                  //     );

                  //     if (pickedDate != null) {
                  //       // Step 2: Pick Time
                  //       final pickedTime = await showTimePicker(
                  //         context: context,
                  //         initialTime: TimeOfDay.now(),
                  //       );

                  //       if (pickedTime != null) {
                  //         // Step 3: Combine date + time into one DateTime
                  //         final combinedDateTime = DateTime(
                  //           pickedDate.year,
                  //           pickedDate.month,
                  //           pickedDate.day,
                  //           pickedTime.hour,
                  //           pickedTime.minute,
                  //         );

                  //         setState(() {
                  //           movingDate = combinedDateTime;
                  //           movingDateController.text =
                  //               "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
                  //               "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                  //         });
                  //       }
                  //     }
                  //   },
                  //   child: AbsorbPointer(
                  //     child: TextFormField(
                  //       controller: movingDateController,
                  //       decoration: const InputDecoration(
                  //         labelText: 'Moving Date & Time',
                  //         border: OutlineInputBorder(),
                  //         prefixIcon: Icon(
                  //           Icons.calendar_today,
                  //           color: Colors.orange,
                  //         ),
                  //       ),
                  //       readOnly: true,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),
                  // DropdownButtonFormField<Subcategory>(
                  //   value: selectedSubcategory,
                  //   isExpanded: true,
                  //   hint: const Text('Select No Of Rooms'),
                  //   items:
                  //       subcategories.map((subcategory) {
                  //         return DropdownMenuItem<Subcategory>(
                  //           value: subcategory,
                  //           child: Text(subcategory.name),
                  //         );
                  //       }).toList(),
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedSubcategory = value;
                  //       selectedPrice = value?.baseFare;
                  //       priceController.text =
                  //           selectedPrice != null
                  //               ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
                  //               : '';
                  //     });
                  //   },
                  //   decoration: const InputDecoration(
                  //     labelText: "Rooms",
                  //     border: OutlineInputBorder(),
                  //     prefixIcon: Icon(Icons.house),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),
                  // DropdownButtonFormField<Subcategory>(
                  //   value: selectedSubcategory,
                  //   isExpanded: true,
                  //   hint: const Text('Select No Of Rooms'),
                  //   items:
                  //       subcategories.map((subcategory) {
                  //         return DropdownMenuItem<Subcategory>(
                  //           value: subcategory,
                  //           child: Text(subcategory.name),
                  //         );
                  //       }).toList(),
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedSubcategory = value;
                  //       selectedPrice = value?.baseFare;
                  //       priceController.text =
                  //           selectedPrice != null
                  //               ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
                  //               : '';
                  //     });
                  //   },
                  //   decoration: InputDecoration(
                  //     labelText: "Rooms",
                  //     border: OutlineInputBorder(
                  //       // ✅ Outer border for the field
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     enabledBorder: OutlineInputBorder(
                  //       // ✅ Default border
                  //       borderRadius: BorderRadius.circular(8),
                  //       borderSide: BorderSide(
                  //         color: Colors.grey.shade400,
                  //         width: 1.5,
                  //       ),
                  //     ),
                  //     focusedBorder: OutlineInputBorder(
                  //       // ✅ Border when focused
                  //       borderRadius: BorderRadius.circular(8),
                  //       borderSide: BorderSide(color: Colors.blue, width: 2),
                  //     ),
                  //     prefixIcon: const Icon(Icons.house),
                  //     contentPadding: const EdgeInsets.symmetric(
                  //       horizontal: 12,
                  //       vertical: 14,
                  //     ),
                  //   ),
                  // ),
                  // DropdownButtonFormField<Subcategory>(
                  //   value: selectedSubcategory,
                  //   isExpanded: true,
                  //   hint: const Text('Select Car Categories'),
                  //   items:
                  //       subcategories.map((subcategory) {
                  //         return DropdownMenuItem<Subcategory>(
                  //           value: subcategory,

                  //           child: Card(
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(8),
                  //               side: BorderSide(color: Colors.grey.shade300),
                  //             ),
                  //             elevation: 2,
                  //             margin: const EdgeInsets.symmetric(vertical: 4),
                  //             child: Padding(
                  //               padding: const EdgeInsets.all(8.0),
                  //               child: Text(
                  //                 subcategory.name,
                  //                 style: const TextStyle(fontSize: 16),
                  //               ),
                  //             ),
                  //           ),
                  //         );
                  //       }).toList(),

                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedSubcategory = value;
                  //       selectedPrice = value?.baseFare;
                  //       priceController.text =
                  //           selectedPrice != null
                  //               ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
                  //               : '';
                  //     });
                  //   },
                  //   decoration: InputDecoration(
                  //     labelText: "Car categories",
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     prefixIcon: const Icon(Icons.house),
                  //   ),
                  // ),
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

                  ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedSubcategory == null ||
                          fromDate == null ||
                          toDate == null) {
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

// // ignore: file_names
// import 'package:flutter/material.dart';

// class CarHireScreen extends StatefulWidget {
//   const CarHireScreen({super.key});

//   @override
//   _CarHireScreenState createState() => _CarHireScreenState();
// }

// class _CarHireScreenState extends State<CarHireScreen> {
//   final TextEditingController carTypeController = TextEditingController();
//   final TextEditingController rentalDurationController =
//       TextEditingController();
//   final TextEditingController pickupLocationController =
//       TextEditingController();
//   final TextEditingController dropoffLocationController =
//       TextEditingController();
//   final TextEditingController additionalNotesController =
//       TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Car Hire Services'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Request Car Hire Service',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             TextFormField(
//               controller: carTypeController,
//               decoration: const InputDecoration(
//                 labelText: 'Preferred Car Type',
//               ),
//             ),
//             TextFormField(
//               controller: rentalDurationController,
//               decoration: const InputDecoration(
//                 labelText: 'Rental Duration (e.g., 2 days, 1 week)',
//               ),
//             ),
//             TextFormField(
//               controller: pickupLocationController,
//               decoration: const InputDecoration(labelText: 'Pickup Location'),
//             ),
//             TextFormField(
//               controller: dropoffLocationController,
//               decoration: const InputDecoration(labelText: 'Dropoff Location'),
//             ),
//             TextFormField(
//               controller: additionalNotesController,
//               decoration: const InputDecoration(
//                 labelText: 'Additional Notes (Optional)',
//               ),
//               maxLines: 3,
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Implement request logic
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.lightBlueAccent,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Request Car Hire'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
