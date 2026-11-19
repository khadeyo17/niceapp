import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

class CarHireScreen extends StatefulWidget {
  final VehicleCategory category;
  const CarHireScreen({super.key, required this.category});

  @override
  State<CarHireScreen> createState() => _CarHireScreenState();
}

class _CarHireScreenState extends State<CarHireScreen> {
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;
  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  String? displayAddress;
  LatLng? pickupLatLng;
  String? pickupAddress;
  double? selectedPrice;

  @override
  void initState() {
    super.initState();
    fetchSubcategories();
    _getPickupLocationFromFirebase();
  }

  @override
  void dispose() {
    detailsController.dispose();
    priceController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

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
      firstDate: fromDate!.add(const Duration(days: 2)),
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
      selectedPrice = (selectedSubcategory!.baseFare ?? 0) * days;
      priceController.text = 'KES ${selectedPrice!.toStringAsFixed(2)}';
    }
  }

  Future<void> fetchSubcategories() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/vehicles/categoryexhausterwater?categoryId=${widget.category.index}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedSubcategories = List<Subcategory>.from(
          data.map((item) => Subcategory.fromJson(item)),
        );
        setState(() => subcategories = fetchedSubcategories);
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
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
          setState(() => pickupLatLng = LatLng(lat, lng));
          _getAddressFromLatLng(LatLng(lat, lng), isPickup: true);
        }
      });
    } catch (e) {
      debugPrint("Error fetching pickup location: $e");
    }
  }

  Future<void> _getAddressFromLatLng(
    LatLng latLng, {
    bool isPickup = false,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final address =
          place != null
              ? "${place.name}, ${place.locality}, ${place.administrativeArea}"
              : 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
      setState(() {
        if (isPickup)
          pickupAddress = address;
        else
          displayAddress = address;
      });
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car hire Service'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),

      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              // Hero image – 1/4 screen
              // Container(
              //   height: screenHeight * 0.25,
              //   width: double.infinity,
              //   decoration: const BoxDecoration(
              //     image: DecorationImage(
              //       image: AssetImage('assets/imgs/carhirerent.webp'),
              //       fit: BoxFit.cover,
              //     ),
              //     borderRadius: BorderRadius.only(
              //       bottomLeft: Radius.circular(30),
              //       bottomRight: Radius.circular(30),
              //     ),
              //   ),
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.black.withOpacity(0.4),
              //       borderRadius: const BorderRadius.only(
              //         bottomLeft: Radius.circular(30),
              //         bottomRight: Radius.circular(30),
              //       ),
              //     ),
              //     child: const Center(
              //       child: Text(
              //         "Hire Your Ride Instantly",
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 24,
              //           fontWeight: FontWeight.w700,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              // Container(
              //   height: MediaQuery.of(context).size.height * 0.25,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(
              //       color: Colors.blueAccent.withOpacity(0.3),
              //       width: 1.5,
              //     ),
              //     image: const DecorationImage(
              //       image: AssetImage('assets/imgs/carhirerent.webp'),
              //       fit: BoxFit.cover,
              //     ),
              //   ),
              // ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                            width: 1.5,
                          ),
                          image: const DecorationImage(
                            image: AssetImage('assets/imgs/carhirerent.webp'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Car Hire Details",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card container for inputs
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          elevation: 2,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              subcategory.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
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

                              // DropdownButtonFormField<Subcategory>(
                              //   value: selectedSubcategory,
                              //   isExpanded: true,
                              //   hint: const Text('Select Car Type'),
                              //   items:
                              //       subcategories.map((subcategory) {
                              //         return DropdownMenuItem(
                              //           value: subcategory,
                              //           child: Text(subcategory.name),
                              //         );
                              //       }).toList(),
                              //   onChanged: (value) {
                              //     setState(() {
                              //       selectedSubcategory = value;
                              //       _updatePrice();
                              //     });
                              //   },
                              //   decoration: const InputDecoration(
                              //     prefixIcon: Icon(
                              //       Icons.directions_car_outlined,
                              //     ),
                              //     labelText: "Car Type",
                              //     border: OutlineInputBorder(),
                              //   ),
                              // ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: detailsController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.notes_outlined),
                                  labelText: 'Additional Details (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 16),

                              GestureDetector(
                                onTap: _pickFromDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: fromDateController,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.calendar_today,
                                        color: Colors.green,
                                      ),
                                      labelText: 'From Date',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              GestureDetector(
                                onTap: _pickToDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: toDateController,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.calendar_today,
                                        color: Colors.red,
                                      ),
                                      labelText: 'To Date',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: priceController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.attach_money),
                                  labelText: 'Estimated Price',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitRequest,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Confirm & Hire Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(55),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (selectedSubcategory == null || fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
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
      "destLat": selectedLatLng?.latitude ?? 0,
      "destLng": selectedLatLng?.longitude ?? 0,
      "destination": displayAddress ?? '',
      "notes": detailsController.text,
      "subCategoryId": selectedSubcategory?.id,
      "scheduledTime": null,
    };

    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse('$baseUrl/passengerrides/exhauster/book'),
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
          content: Text('Unexpected error. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
// // import 'dart:convert';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:geocoding/geocoding.dart';
// // import 'package:niceapp/Container/utils/keys.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';
// // import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

// // class CarHireScreen extends StatefulWidget {
// //   final VehicleCategory category;

// //   const CarHireScreen({super.key, required this.category});

// //   @override
// //   State<CarHireScreen> createState() => _CarHireScreenScreenState();
// // }

// // class _CarHireScreenScreenState extends State<CarHireScreen> {
// //   final TextEditingController detailsController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   // DateTime? movingDate;
// //   // final TextEditingController movingDateController = TextEditingController();

// //   DateTime? fromDate;
// //   DateTime? toDate;
// //   final TextEditingController fromDateController = TextEditingController();
// //   final TextEditingController toDateController = TextEditingController();

// //   List<Subcategory> subcategories = [];
// //   Subcategory? selectedSubcategory;
// //   bool _isLoading = false;
// //   LatLng? selectedLatLng;
// //   String? displayAddress;
// //   LatLng? pickupLatLng;
// //   String? pickupAddress;
// //   double? kilometersCovered;
// //   //Map<String, double> priceMap = {};
// //   double? selectedPrice;
// //   @override
// //   void dispose() {
// //     detailsController.dispose();
// //     priceController.dispose();
// //     fromDateController.dispose();
// //     toDateController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchSubcategories();
// //   }

// //   Future<void> _pickFromDate() async {
// //     DateTime now = DateTime.now();
// //     final picked = await showDatePicker(
// //       context: context,
// //       initialDate: now,
// //       firstDate: now,
// //       lastDate: DateTime(now.year + 1),
// //     );

// //     if (picked != null) {
// //       setState(() {
// //         fromDate = picked;
// //         fromDateController.text =
// //             "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

// //         // Auto set ToDate = FromDate + 2 days
// //         toDate = picked.add(const Duration(days: 2));
// //         toDateController.text =
// //             "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";

// //         _updatePrice();
// //       });
// //     }
// //   }

// //   Future<void> _pickToDate() async {
// //     if (fromDate == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Please select From Date first")),
// //       );
// //       return;
// //     }

// //     final picked = await showDatePicker(
// //       context: context,
// //       initialDate: fromDate!.add(const Duration(days: 2)),
// //       firstDate: fromDate!.add(
// //         const Duration(days: 2),
// //       ), // ✅ At least 2 days later
// //       lastDate: DateTime(fromDate!.year + 1),
// //     );

// //     if (picked != null) {
// //       setState(() {
// //         toDate = picked;
// //         toDateController.text =
// //             "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
// //         _updatePrice();
// //       });
// //     }
// //   }

// //   void _updatePrice() {
// //     if (selectedSubcategory != null && fromDate != null && toDate != null) {
// //       final days = toDate!.difference(fromDate!).inDays;

// //       selectedPrice = (selectedSubcategory!.baseFare ?? 0) * days;
// //       priceController.text = 'KES ${selectedPrice!.toStringAsFixed(2)}';
// //     }
// //   }

// //   Future<void> fetchSubcategories() async {
// //     final category = widget.category;

// //     try {
// //       final response = await http.get(
// //         Uri.parse(
// //           '$baseUrl/vehicles/categoryexhausterwater?categoryId=${category.index}',
// //         ),
// //       );

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);
// //         final fetchedSubcategories = List<Subcategory>.from(
// //           data.map((item) => Subcategory.fromJson(item)),
// //         );

// //         setState(() {
// //           subcategories = fetchedSubcategories;
// //           // Optional: select the first one by default
// //           // if (subcategories.isNotEmpty) {
// //           //   selectedSubcategory = subcategories[0];
// //           // }
// //         });
// //       } else {
// //         debugPrint('Failed to load subcategories: ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       debugPrint('Error fetching subcategories: $e');
// //     }
// //   }

// //   Future<void> _pollDriverAssignment(
// //     BuildContext context,
// //     String firebaseId,
// //   ) async {
// //     const pollingInterval = Duration(seconds: 5);
// //     const maxAttempts = 12; // 1 minute (12 x 5s)
// //     int attempts = 0;

// //     while (attempts < maxAttempts) {
// //       await Future.delayed(pollingInterval);

// //       final response = await http.get(
// //         Uri.parse('$baseUrl/passengerrides/passenger/current/$firebaseId'),
// //       );

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);

// //         // Check if driver has been assigned
// //         if (data['driver'] != null &&
// //             data['driver']['driverName'] != null &&
// //             data['driver']['driverName'] != 'N/A') {
// //           if (Navigator.canPop(context)) {
// //             Navigator.pop(context); // ✅ Dismiss "Searching..." dialog
// //           }

// //           // Push to driver assignment screen with info
// //           Navigator.pushReplacementNamed(
// //             context,
// //             '/driverAssignment',
// //             arguments: {
// //               'driverName': data['driver']['driverName'],
// //               'driverContact': data['driver']['driverPhone'],
// //               'vehicle': {
// //                 'make': data['driver']['vehicleMake'],
// //                 'model': data['driver']['vehicleModel'],
// //                 'color': data['driver']['vehicleColour'],
// //                 'registration': data['driver']['registrationNumber'],
// //               },
// //               'eta':
// //                   data['eta'] ??
// //                   5, // You can replace this with backend ETA when ready
// //             },
// //           );
// //           return;
// //         }
// //       }

// //       attempts++;
// //     }

// //     if (Navigator.canPop(context)) {
// //       Navigator.pop(context); // Dismiss "Searching..." if polling ends
// //     }

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text('No Car Hire found yet. Please try again later.'),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }

// //   Future<void> _getPickupLocationFromFirebase() async {
// //     try {
// //       final uid = FirebaseAuth.instance.currentUser?.uid;
// //       if (uid == null) return;

// //       final ref = FirebaseDatabase.instance.ref("passengers/$uid/location");

// //       ref.onValue.listen((event) {
// //         final data = event.snapshot.value as Map?;
// //         if (data != null &&
// //             data['latitude'] != null &&
// //             data['longitude'] != null) {
// //           final lat = (data['latitude'] as num).toDouble();
// //           final lng = (data['longitude'] as num).toDouble();

// //           setState(() {
// //             pickupLatLng = LatLng(lat, lng);
// //           });

// //           _getAddressFromLatLng(LatLng(lat, lng), isPickup: true);
// //         }
// //       });
// //     } catch (e) {
// //       debugPrint("Error fetching pickup location: $e");
// //     }
// //   }

// //   Future<void> _getAddressFromLatLng(
// //     LatLng latLng, {
// //     bool isPickup = false,
// //   }) async {
// //     try {
// //       final placemarks = await placemarkFromCoordinates(
// //         latLng.latitude,
// //         latLng.longitude,
// //       );
// //       String address;
// //       if (placemarks.isNotEmpty) {
// //         final place = placemarks.first;
// //         address =
// //             "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
// //       } else {
// //         address = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// //       }

// //       setState(() {
// //         if (isPickup) {
// //           pickupAddress = address;
// //         } else {
// //           displayAddress = address;
// //         }
// //       });
// //     } catch (e) {
// //       debugPrint("Reverse geocoding failed: $e");
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Car Hire Service'),
// //         centerTitle: true,
// //         backgroundColor: Colors.white,
// //         elevation: 1,
// //         foregroundColor: Colors.black87,
// //       ),
// //       body: Stack(
// //         children: [
// //           SafeArea(
// //             child: SingleChildScrollView(
// //               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Text(
// //                     'Request Car Hire',
// //                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// //                   ),

// //                   const SizedBox(height: 20),

// //                   DropdownButtonFormField<Subcategory>(
// //                     value: selectedSubcategory,
// //                     isExpanded: true,
// //                     hint: const Text('Select Car Categories'),

// //                     // Cards for dropdown menu
// //                     items:
// //                         subcategories.map((subcategory) {
// //                           return DropdownMenuItem<Subcategory>(
// //                             value: subcategory,
// //                             child: Card(
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(8),
// //                                 side: BorderSide(color: Colors.grey.shade300),
// //                               ),
// //                               elevation: 2,
// //                               margin: const EdgeInsets.symmetric(vertical: 4),
// //                               child: Padding(
// //                                 padding: const EdgeInsets.all(8.0),
// //                                 child: Text(
// //                                   subcategory.name,
// //                                   style: const TextStyle(fontSize: 16),
// //                                 ),
// //                               ),
// //                             ),
// //                           );
// //                         }).toList(),

// //                     // Plain text for selected value
// //                     selectedItemBuilder: (context) {
// //                       return subcategories.map((subcategory) {
// //                         return Align(
// //                           alignment: Alignment.centerLeft,
// //                           child: Text(
// //                             subcategory.name,
// //                             style: const TextStyle(fontSize: 16),
// //                           ),
// //                         );
// //                       }).toList();
// //                     },

// //                     onChanged: (value) {
// //                       setState(() {
// //                         selectedSubcategory = value;
// //                         // selectedPrice = value?.baseFare;
// //                         priceController.text =
// //                             selectedPrice != null
// //                                 ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
// //                                 : '';
// //                       });
// //                     },

// //                     decoration: InputDecoration(
// //                       labelText: "Car categories",
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       prefixIcon: const Icon(Icons.house),
// //                     ),
// //                   ),

// //                   const SizedBox(height: 20),
// //                   TextFormField(
// //                     controller: priceController,
// //                     readOnly: true,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Estimated Price',
// //                       border: OutlineInputBorder(),
// //                       prefixIcon: Icon(Icons.attach_money),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   // From Date
// //                   GestureDetector(
// //                     onTap: () => _pickFromDate(),
// //                     child: AbsorbPointer(
// //                       child: TextFormField(
// //                         controller: fromDateController,
// //                         decoration: const InputDecoration(
// //                           labelText: 'From Date',
// //                           border: OutlineInputBorder(),
// //                           prefixIcon: Icon(
// //                             Icons.calendar_today,
// //                             color: Colors.green,
// //                           ),
// //                         ),
// //                         readOnly: true,
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),

// //                   // To Date
// //                   GestureDetector(
// //                     onTap: () => _pickToDate(),
// //                     child: AbsorbPointer(
// //                       child: TextFormField(
// //                         controller: toDateController,
// //                         decoration: const InputDecoration(
// //                           labelText: 'To Date',
// //                           border: OutlineInputBorder(),
// //                           prefixIcon: Icon(
// //                             Icons.calendar_today,
// //                             color: Colors.red,
// //                           ),
// //                         ),
// //                         readOnly: true,
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),

// //                   const SizedBox(height: 20),
// //                   TextFormField(
// //                     controller: detailsController,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Additional Details (Optional)',
// //                       border: OutlineInputBorder(),
// //                       prefixIcon: Icon(Icons.description_outlined),
// //                     ),
// //                     maxLines: 3,
// //                   ),

// //                   const SizedBox(height: 40),

// //                   ElevatedButton.icon(
// //                     onPressed: () async {
// //                       if (selectedSubcategory == null ||
// //                           fromDate == null ||
// //                           toDate == null) {
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           const SnackBar(
// //                             content: Text(
// //                               'Please complete all required fields',
// //                             ),
// //                             backgroundColor: Colors.red,
// //                           ),
// //                         );
// //                         return;
// //                       }

// //                       final token =
// //                           await FirebaseAuth.instance.currentUser?.getIdToken();
// //                       if (token == null) {
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           const SnackBar(
// //                             content: Text('Authentication error'),
// //                             backgroundColor: Colors.red,
// //                           ),
// //                         );
// //                         return;
// //                       }

// //                       final requestBody = {
// //                         "firebaseIdToken": token,
// //                         "destLat": selectedLatLng!.latitude,
// //                         "destLng": selectedLatLng!.longitude,
// //                         "destination": displayAddress ?? '',
// //                         "notes": detailsController.text,
// //                         "subCategoryId": selectedSubcategory?.id,
// //                         "scheduledTime": null,
// //                       };

// //                       try {
// //                         setState(() => _isLoading = true);

// //                         final response = await http.post(
// //                           Uri.parse('$baseUrl/passengerrides/exhauster/book'),
// //                           headers: {'Content-Type': 'application/json'},
// //                           body: jsonEncode(requestBody),
// //                         );

// //                         setState(() => _isLoading = false);

// //                         if (response.statusCode == 200) {
// //                           final data = jsonDecode(response.body);
// //                           final rideId = data['rideId'];

// //                           if (rideId != null && mounted) {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder:
// //                                     (_) => DriverAssignmentsScreen(
// //                                       destination: selectedLatLng!,
// //                                       pickup: pickupLatLng,
// //                                       rideId: rideId,
// //                                       category: selectedSubcategory!,
// //                                       fare: selectedPrice ?? 0,
// //                                     ),
// //                               ),
// //                             );
// //                           }
// //                         } else {
// //                           ScaffoldMessenger.of(context).showSnackBar(
// //                             SnackBar(
// //                               content: Text('Booking failed: ${response.body}'),
// //                               backgroundColor: Colors.red,
// //                             ),
// //                           );
// //                         }
// //                       } catch (e) {
// //                         setState(() => _isLoading = false);
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           const SnackBar(
// //                             content: Text(
// //                               'Unexpected error. Please try again.',
// //                             ),
// //                             backgroundColor: Colors.red,
// //                           ),
// //                         );
// //                       }
// //                     },
// //                     icon: const Icon(Icons.send),
// //                     label: const Text("Confirm and Submit Request"),
// //                     style: ElevatedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                       backgroundColor: Colors.grey[700],
// //                       foregroundColor: Colors.white,
// //                       textStyle: const TextStyle(
// //                         fontSize: 16,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                       minimumSize: const Size.fromHeight(48),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),

// //           /// ✅ Loading overlay
// //           if (_isLoading)
// //             Container(
// //               color: Colors.black.withOpacity(0.5),
// //               child: const Center(
// //                 child: CircularProgressIndicator(color: Colors.white),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // // ignore: file_names
// // // import 'package:flutter/material.dart';

// // // class CarHireScreen extends StatefulWidget {
// // //   const CarHireScreen({super.key});

// // //   @override
// // //   _CarHireScreenState createState() => _CarHireScreenState();
// // // }

// // // class _CarHireScreenState extends State<CarHireScreen> {
// // //   final TextEditingController carTypeController = TextEditingController();
// // //   final TextEditingController rentalDurationController =
// // //       TextEditingController();
// // //   final TextEditingController pickupLocationController =
// // //       TextEditingController();
// // //   final TextEditingController dropoffLocationController =
// // //       TextEditingController();
// // //   final TextEditingController additionalNotesController =
// // //       TextEditingController();

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       appBar: AppBar(
// // //         title: const Text('Car Hire Services'),
// // //         centerTitle: true,
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         foregroundColor: Colors.black,
// // //       ),
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             const Text(
// // //               'Request Car Hire Service',
// // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             TextFormField(
// // //               controller: carTypeController,
// // //               decoration: const InputDecoration(
// // //                 labelText: 'Preferred Car Type',
// // //               ),
// // //             ),
// // //             TextFormField(
// // //               controller: rentalDurationController,
// // //               decoration: const InputDecoration(
// // //                 labelText: 'Rental Duration (e.g., 2 days, 1 week)',
// // //               ),
// // //             ),
// // //             TextFormField(
// // //               controller: pickupLocationController,
// // //               decoration: const InputDecoration(labelText: 'Pickup Location'),
// // //             ),
// // //             TextFormField(
// // //               controller: dropoffLocationController,
// // //               decoration: const InputDecoration(labelText: 'Dropoff Location'),
// // //             ),
// // //             TextFormField(
// // //               controller: additionalNotesController,
// // //               decoration: const InputDecoration(
// // //                 labelText: 'Additional Notes (Optional)',
// // //               ),
// // //               maxLines: 3,
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ElevatedButton(
// // //               onPressed: () {
// // //                 // TODO: Implement request logic
// // //               },
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: Colors.lightBlueAccent,
// // //                 foregroundColor: Colors.white,
// // //               ),
// // //               child: const Text('Request Car Hire'),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// ✨ Improved for visual appeal — larger fonts and better hierarchy ✨
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:geocoding/geocoding.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';
// import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

// class CarHireScreen extends StatefulWidget {
//   final VehicleCategory category;
//   const CarHireScreen({super.key, required this.category});

//   @override
//   State<CarHireScreen> createState() => _CarHireScreenState();
// }

// class _CarHireScreenState extends State<CarHireScreen> {
//   final TextEditingController detailsController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController fromDateController = TextEditingController();
//   final TextEditingController toDateController = TextEditingController();

//   DateTime? fromDate;
//   DateTime? toDate;
//   List<Subcategory> subcategories = [];
//   Subcategory? selectedSubcategory;
//   bool _isLoading = false;
//   LatLng? selectedLatLng;
//   String? displayAddress;
//   LatLng? pickupLatLng;
//   String? pickupAddress;
//   double? selectedPrice;

//   @override
//   void initState() {
//     super.initState();
//     fetchSubcategories();
//     _getPickupLocationFromFirebase();
//   }

//   @override
//   void dispose() {
//     detailsController.dispose();
//     priceController.dispose();
//     fromDateController.dispose();
//     toDateController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFromDate() async {
//     DateTime now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: now,
//       lastDate: DateTime(now.year + 1),
//     );

//     if (picked != null) {
//       setState(() {
//         fromDate = picked;
//         fromDateController.text =
//             "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
//         toDate = picked.add(const Duration(days: 2));
//         toDateController.text =
//             "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";
//         _updatePrice();
//       });
//     }
//   }

//   Future<void> _pickToDate() async {
//     if (fromDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select From Date first")),
//       );
//       return;
//     }

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: fromDate!.add(const Duration(days: 2)),
//       firstDate: fromDate!.add(const Duration(days: 2)),
//       lastDate: DateTime(fromDate!.year + 1),
//     );

//     if (picked != null) {
//       setState(() {
//         toDate = picked;
//         toDateController.text =
//             "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
//         _updatePrice();
//       });
//     }
//   }

//   void _updatePrice() {
//     if (selectedSubcategory != null && fromDate != null && toDate != null) {
//       final days = toDate!.difference(fromDate!).inDays;
//       selectedPrice = (selectedSubcategory!.baseFare ?? 0) * days;
//       priceController.text = 'KES ${selectedPrice!.toStringAsFixed(2)}';
//     }
//   }

//   Future<void> fetchSubcategories() async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//           '$baseUrl/vehicles/categoryexhausterwater?categoryId=${widget.category.index}',
//         ),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final fetchedSubcategories = List<Subcategory>.from(
//           data.map((item) => Subcategory.fromJson(item)),
//         );
//         setState(() => subcategories = fetchedSubcategories);
//       }
//     } catch (e) {
//       debugPrint('Error fetching subcategories: $e');
//     }
//   }

//   Future<void> _getPickupLocationFromFirebase() async {
//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) return;

//       final ref = FirebaseDatabase.instance.ref("passengers/$uid/location");
//       ref.onValue.listen((event) {
//         final data = event.snapshot.value as Map?;
//         if (data != null &&
//             data['latitude'] != null &&
//             data['longitude'] != null) {
//           final lat = (data['latitude'] as num).toDouble();
//           final lng = (data['longitude'] as num).toDouble();
//           setState(() => pickupLatLng = LatLng(lat, lng));
//           _getAddressFromLatLng(LatLng(lat, lng), isPickup: true);
//         }
//       });
//     } catch (e) {
//       debugPrint("Error fetching pickup location: $e");
//     }
//   }

//   Future<void> _getAddressFromLatLng(
//     LatLng latLng, {
//     bool isPickup = false,
//   }) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         latLng.latitude,
//         latLng.longitude,
//       );
//       final place = placemarks.isNotEmpty ? placemarks.first : null;
//       final address =
//           place != null
//               ? "${place.name}, ${place.locality}, ${place.administrativeArea}"
//               : 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
//       setState(() {
//         if (isPickup)
//           pickupAddress = address;
//         else
//           displayAddress = address;
//       });
//     } catch (e) {
//       debugPrint("Reverse geocoding failed: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Car Hire Service',
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black87,
//       ),
//       backgroundColor: Colors.grey[50],
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header image
//                 Container(
//                   height: MediaQuery.of(context).size.height * 0.16,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: Colors.blueAccent.withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                     image: const DecorationImage(
//                       image: AssetImage('assets/imgs/carhirerent.webp'),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Car Hire Details",
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 Card(
//                   elevation: 3,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(18),
//                     child: Column(
//                       children: [
//                         DropdownButtonFormField<Subcategory>(
//                           value: selectedSubcategory,
//                           isExpanded: true,
//                           hint: const Text(
//                             'Select Car Category',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                           items:
//                               subcategories.map((subcategory) {
//                                 return DropdownMenuItem<Subcategory>(
//                                   value: subcategory,
//                                   child: Text(
//                                     subcategory.name,
//                                     style: const TextStyle(fontSize: 18),
//                                   ),
//                                 );
//                               }).toList(),
//                           onChanged: (value) {
//                             setState(() {
//                               selectedSubcategory = value;
//                               _updatePrice();
//                             });
//                           },
//                           decoration: InputDecoration(
//                             labelText: "Car categories",
//                             labelStyle: const TextStyle(fontSize: 17),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.directions_car),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         TextFormField(
//                           controller: detailsController,
//                           maxLines: 3,
//                           style: const TextStyle(fontSize: 17),
//                           decoration: const InputDecoration(
//                             prefixIcon: Icon(Icons.notes_outlined),
//                             labelText: 'Additional Details (Optional)',
//                             labelStyle: TextStyle(fontSize: 17),
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         GestureDetector(
//                           onTap: _pickFromDate,
//                           child: AbsorbPointer(
//                             child: TextFormField(
//                               controller: fromDateController,
//                               style: const TextStyle(fontSize: 17),
//                               decoration: const InputDecoration(
//                                 prefixIcon: Icon(
//                                   Icons.calendar_today,
//                                   color: Colors.green,
//                                 ),
//                                 labelText: 'From Date',
//                                 labelStyle: TextStyle(fontSize: 17),
//                                 border: OutlineInputBorder(),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         GestureDetector(
//                           onTap: _pickToDate,
//                           child: AbsorbPointer(
//                             child: TextFormField(
//                               controller: toDateController,
//                               style: const TextStyle(fontSize: 17),
//                               decoration: const InputDecoration(
//                                 prefixIcon: Icon(
//                                   Icons.calendar_today,
//                                   color: Colors.red,
//                                 ),
//                                 labelText: 'To Date',
//                                 labelStyle: TextStyle(fontSize: 17),
//                                 border: OutlineInputBorder(),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         TextFormField(
//                           controller: priceController,
//                           readOnly: true,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           decoration: const InputDecoration(
//                             prefixIcon: Icon(Icons.attach_money),
//                             labelText: 'Estimated Price',
//                             labelStyle: TextStyle(fontSize: 17),
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton.icon(
//                   onPressed: _isLoading ? null : _submitRequest,
//                   icon: const Icon(Icons.check_circle_outline, size: 24),
//                   label: const Text(
//                     "Confirm & Hire Now",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size.fromHeight(55),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (_isLoading)
//             Container(
//               color: Colors.black54,
//               child: const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitRequest() async {
//     if (selectedSubcategory == null || fromDate == null || toDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill in all required fields'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final token = await FirebaseAuth.instance.currentUser?.getIdToken();
//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Authentication error'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final requestBody = {
//       "firebaseIdToken": token,
//       "destLat": selectedLatLng?.latitude ?? 0,
//       "destLng": selectedLatLng?.longitude ?? 0,
//       "destination": displayAddress ?? '',
//       "notes": detailsController.text,
//       "subCategoryId": selectedSubcategory?.id,
//       "scheduledTime": null,
//     };

//     try {
//       setState(() => _isLoading = true);
//       final response = await http.post(
//         Uri.parse('$baseUrl/passengerrides/exhauster/book'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );
//       setState(() => _isLoading = false);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final rideId = data['rideId'];
//         if (rideId != null && mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) => DriverAssignmentsScreen(
//                     destination: selectedLatLng!,
//                     pickup: pickupLatLng,
//                     rideId: rideId,
//                     category: selectedSubcategory!,
//                     fare: selectedPrice ?? 0,
//                   ),
//             ),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Booking failed: ${response.body}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Unexpected error. Try again.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }
