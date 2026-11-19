import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/finding_driver_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

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

class _MoversScreenScreenState extends State<MoversScreen>
    with AutomaticKeepAliveClientMixin {
  // ✅ Add PageStorageBucket for persistence
  final PageStorageBucket _bucket = PageStorageBucket();

  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController movingDateController = TextEditingController();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  DateTime? movingDate;
  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  LatLng? pickupLatLng;
  String? pickupAddress;
  String? displayAddress;
  int? rideId2;
  BuildContext? _dialogContext;
  double? selectedPrice;

  final StreamController<bool> _driverLinkedController =
      StreamController<bool>.broadcast();

  @override
  void dispose() {
    detailsController.dispose();
    priceController.dispose();
    movingDateController.dispose();
    pickupController.dispose();
    destinationController.dispose();
    _driverLinkedController.close();
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
      if (pickupLatLng != null) {
        _getAddressFromLatLng(pickupLatLng!, isPickup: true);
      }
    }

    if (widget.destination != null && selectedLatLng == null) {
      selectedLatLng = widget.destination;
      _getAddressFromLatLng(widget.destination!, isPickup: false);
    }
  }

  @override
  bool get wantKeepAlive => true; // ✅ Keeps state alive

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
        });
      } else {
        debugPrint('Failed to load subcategories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
    }
  }

  void _openDestinationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => WhereToScreen(
              category: VehicleCategory.movers,
              initialPickupLocation: pickupLatLng,
            ),
      ),
    );

    // ✅ Ensure state survives when coming back
    if (!mounted) return;
    if (result != null && result is Map<String, LatLng>) {
      setState(() {
        pickupLatLng = result['pickup'] ?? pickupLatLng;
        selectedLatLng = result['destination'] ?? selectedLatLng;
      });

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
          pickupController.text = address;
        } else {
          displayAddress = address;
          destinationController.text = address;
        }
      });
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _closeFindingDriverDialog();
      print("User is not authenticated");
      return;
    }

    if (pickupLatLng == null ||
        selectedLatLng == null ||
        selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final url = '$baseUrl/passengerrides/movers/request';

      final body = {
        "firebaseIdToken": idToken, // ✅ use real token
        "pickupLocation": pickupAddress,
        "destination": displayAddress,
        "pickupLat": pickupLatLng!.latitude,
        "pickupLng": pickupLatLng!.longitude,
        "destLat": selectedLatLng!.latitude,
        "destLng": selectedLatLng!.longitude,
        "subCategoryId": selectedSubcategory?.id,
        "scheduledTime": movingDate?.toIso8601String(),
        "notes": detailsController.text,
        "fare": selectedPrice, //.toStringAsFixed(2),
      };

      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final rideId = responseData['rideId'];
        rideId2 = responseData['rideId'];

        if (movingDate == null) {
          await pollForDriverAssignment(rideId);
        } else {
          _closeFindingDriverDialog();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RideHistoryScreen()),
          );
        }
      } else {
        _closeFindingDriverDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book ride: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _closeFindingDriverDialog();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
    }
  }

  void _closeFindingDriverDialog() {
    if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
      Navigator.pop(_dialogContext!);
    }
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

          // ✅ Real rideId should now exist when driver accepts
          if (requestData['rideId'] != null) {
            final realRideId = requestData['rideId'];

            // 2. Now check backend ride
            final url = '$baseUrl/passengerrides/myrides/$realRideId';
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ required for AutomaticKeepAliveClientMixin

    return PageStorage(
      bucket: _bucket,
      child: Scaffold(
        key: const PageStorageKey("MoversScreen"), // ✅ persist screen state
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Movers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      readOnly: true,
                      controller: pickupController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.my_location, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _openDestinationPicker,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          controller: destinationController,
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
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 1),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
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

                    ElevatedButton.icon(
                      onPressed: () async {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder:
                                  (_) => FindingDriverScreen(
                                    onCancel: () async {
                                      // TODO: cancel API here
                                      print("Ride canceled by passenger");
                                    },
                                    driverLinkedStream:
                                        _driverLinkedController.stream,
                                        category: widget.category,
                                  ),
                            ),
                          );
                          await bookRide();
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

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
//                     // ... rest of your UI remains same
//                   ],
//                 ),
//               ),
//             ),
//             if (_isLoading)
//               Container(
//                 color: Colors.black.withOpacity(0.5),
//                 child: const Center(
//                   child: CircularProgressIndicator(color: Colors.white),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// // import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:geocoding/geocoding.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/finding_driver_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
// import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';
// import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';

// class MoversScreen extends StatefulWidget {
//   final VehicleCategory category;
//   final LatLng? pickup;
//   final LatLng? destination;

//   const MoversScreen({
//     super.key,
//     required this.category,
//     this.pickup,
//     this.destination,
//   });

//   @override
//   State<MoversScreen> createState() => _MoversScreenScreenState();
// }

// class _MoversScreenScreenState extends State<MoversScreen>
//     with AutomaticKeepAliveClientMixin {
//   final TextEditingController detailsController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController movingDateController = TextEditingController();
//   final TextEditingController pickupController = TextEditingController();
//   final TextEditingController destinationController = TextEditingController();

//   DateTime? movingDate;
//   List<Subcategory> subcategories = [];
//   Subcategory? selectedSubcategory;
//   bool _isLoading = false;
//   LatLng? selectedLatLng;
//   LatLng? pickupLatLng;
//   String? pickupAddress;
//   String? displayAddress;
//   int? rideId2;
//   BuildContext? _dialogContext;
//   double? selectedPrice;

//   final StreamController<bool> _driverLinkedController =
//       StreamController<bool>.broadcast();

//   @override
//   void dispose() {
//     detailsController.dispose();
//     priceController.dispose();
//     movingDateController.dispose();
//     pickupController.dispose();
//     destinationController.dispose();
//     _driverLinkedController.close();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchSubcategories();

//     if (pickupLatLng == null && widget.pickup == null) {
//       _getPickupLocationFromFirebase();
//     } else {
//       pickupLatLng = widget.pickup ?? pickupLatLng;
//       if (pickupLatLng != null) {
//         _getAddressFromLatLng(pickupLatLng!, isPickup: true);
//       }
//     }

//     if (widget.destination != null && selectedLatLng == null) {
//       selectedLatLng = widget.destination;
//       _getAddressFromLatLng(widget.destination!, isPickup: false);
//     }
//   }

//   @override
//   bool get wantKeepAlive => true; // ✅ Keeps state alive

//   Future<void> fetchSubcategories() async {
//     final category = widget.category;

//     try {
//       final response = await http.get(
//         Uri.parse(
//           '$baseUrl/vehicles/categoryexhausterwater?categoryId=${category.index}',
//         ),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final fetchedSubcategories = List<Subcategory>.from(
//           data.map((item) => Subcategory.fromJson(item)),
//         );

//         setState(() {
//           subcategories = fetchedSubcategories;
//         });
//       } else {
//         debugPrint('Failed to load subcategories: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching subcategories: $e');
//     }
//   }

//   void _openDestinationPicker() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => WhereToScreen(category: VehicleCategory.movers),
//       ),
//     );

//     // ✅ Only update if user selected something
//     if (result != null && result is Map<String, LatLng>) {
//       setState(() {
//         pickupLatLng = result['pickup'] ?? pickupLatLng;
//         selectedLatLng = result['destination'] ?? selectedLatLng;
//       });

//       if (pickupLatLng != null) {
//         _getAddressFromLatLng(pickupLatLng!, isPickup: true);
//       }
//       if (selectedLatLng != null) {
//         _getAddressFromLatLng(selectedLatLng!, isPickup: false);
//       }
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

//           setState(() {
//             pickupLatLng = LatLng(lat, lng);
//           });

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
//       String address;
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         address =
//             "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
//       } else {
//         address = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
//       }

//       setState(() {
//         if (isPickup) {
//           pickupAddress = address;
//           pickupController.text = address;
//         } else {
//           displayAddress = address;
//           destinationController.text = address;
//         }
//       });
//     } catch (e) {
//       debugPrint("Reverse geocoding failed: $e");
//     }
//   }

//   Future<void> bookRide() async {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       _closeFindingDriverDialog();
//       print("User is not authenticated");
//       return;
//     }

//     if (pickupLatLng == null ||
//         selectedLatLng == null ||
//         selectedSubcategory == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all required fields.")),
//       );
//       return;
//     }

//     try {
//       final idToken = await user.getIdToken();
//       final url = '$baseUrl/passengerrides/movers/request';

//       final body = {
//         "firebaseIdToken": idToken, // ✅ use real token
//         "pickupLocation": pickupAddress,
//         "destination": displayAddress,
//         "pickupLat": pickupLatLng!.latitude,
//         "pickupLng": pickupLatLng!.longitude,
//         "destLat": selectedLatLng!.latitude,
//         "destLng": selectedLatLng!.longitude,
//         "subCategoryId": selectedSubcategory?.id,
//         "scheduledTime": movingDate?.toIso8601String(),
//         "notes": detailsController.text,
//         "fare": selectedPrice, //.toStringAsFixed(2),
//       };

//       setState(() => _isLoading = true);

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(body),
//       );

//       setState(() => _isLoading = false);

//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         final rideId = responseData['rideId'];
//         rideId2 = responseData['rideId'];

//         if (movingDate == null) {
//           await pollForDriverAssignment(rideId);
//         } else {
//           _closeFindingDriverDialog();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => RideHistoryScreen()),
//           );
//         }
//       } else {
//         _closeFindingDriverDialog();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to book ride: ${response.statusCode}'),
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _closeFindingDriverDialog();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
//     }
//   }

//   void _closeFindingDriverDialog() {
//     if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
//       Navigator.pop(_dialogContext!);
//     }
//   }

//   Future<void> pollForDriverAssignment(int requestId) async {
//     const maxAttempts = 20;
//     const interval = Duration(seconds: 5);

//     for (int i = 0; i < maxAttempts; i++) {
//       if (!mounted) return;

//       try {
//         // 1. Check Firebase first
//         //final dbRef = FirebaseDatabase.instance.ref("rideRequests/$requestId");
//         final dbRef = FirebaseDatabase.instance.ref(
//           "rideRequests/${requestId.toString()}",
//         );

//         final dbSnapshot = await dbRef.get();

//         if (dbSnapshot.exists) {
//           final requestData = dbSnapshot.value as Map;

//           // ✅ Real rideId should now exist when driver accepts
//           if (requestData['rideId'] != null) {
//             final realRideId = requestData['rideId'];

//             // 2. Now check backend ride
//             final url = '$baseUrl/passengerrides/myrides/$realRideId';
//             final response = await http.get(Uri.parse(url));

//             if (response.statusCode == 200) {
//               final rideData = jsonDecode(response.body);

//               if (rideData['driver'] != null) {
//                 final driverData = rideData['driver'];

//                 _driverLinkedController.add(true);

//                 await Future.delayed(const Duration(milliseconds: 200));

//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (_) => DriverConfirmationScreen(
//                           rideId: realRideId,
//                           pickup: widget.pickup,
//                           driverId: driverData['firebaseId'],
//                           Phone: driverData['phoneNumber'],
//                           regnumber: driverData['registrationNumber'],
//                           vehicleMake: driverData['vehicleMake'],
//                           vehicleModel: driverData['vehicleModel'],
//                           colour: driverData['vehicleColour'],
//                           drivername: driverData['firstName'],
//                         ),
//                   ),
//                 );
//                 return;
//               }
//             }
//           }
//         }
//       } catch (e) {
//         debugPrint("Error checking driver assignment: $e");
//       }

//       await Future.delayed(interval);
//     }

//     _driverLinkedController.add(false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("No driver accepted your ride. Try again later."),
//       ),
//     );
//   }

//   //BuildContext? _dialogContext;

//   void showFindingDriverDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext dialogContext) {
//         _dialogContext = dialogContext;
//         return AlertDialog(
//           title: const Text("Finding you a driver..."),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: const [
//               CircularProgressIndicator(),
//               SizedBox(height: 10),
//               Text("Please wait while we assign a driver."),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   // Future<void> pollForDriverAssignment(int requestId) async {
//   //   const maxAttempts = 20;
//   //   const interval = Duration(seconds: 5);

//   //   for (int i = 0; i < maxAttempts; i++) {
//   //     if (!mounted) return;

//   //     try {
//   //       final dbRef = FirebaseDatabase.instance.ref(
//   //         "rideRequests/${requestId.toString()}",
//   //       );
//   //       final dbSnapshot = await dbRef.get();

//   //       if (dbSnapshot.exists) {
//   //         final requestData = dbSnapshot.value as Map;

//   //         if (requestData['rideId'] != null) {
//   //           final realRideId = requestData['rideId'];

//   //           final url = '$baseUrl/passengerrides/myrides/$realRideId';
//   //           final response = await http.get(Uri.parse(url));

//   //           if (response.statusCode == 200) {
//   //             final rideData = jsonDecode(response.body);

//   //             if (rideData['driver'] != null) {
//   //               final driverData = rideData['driver'];

//   //               _driverLinkedController.add(true);

//   //               await Future.delayed(const Duration(milliseconds: 200));

//   //               if (!mounted) return;
//   //               Navigator.push(
//   //                 context,
//   //                 MaterialPageRoute(
//   //                   builder:
//   //                       (_) => DriverConfirmationScreen(
//   //                         rideId: realRideId,
//   //                         pickup: widget.pickup,
//   //                         driverId: driverData['firebaseId'],
//   //                         Phone: driverData['phoneNumber'],
//   //                         regnumber: driverData['registrationNumber'],
//   //                         vehicleMake: driverData['vehicleMake'],
//   //                         vehicleModel: driverData['vehicleModel'],
//   //                         colour: driverData['vehicleColour'],
//   //                         drivername: driverData['firstName'],
//   //                       ),
//   //                 ),
//   //               );
//   //               return;
//   //             }
//   //           }
//   //         }
//   //       }
//   //     } catch (e) {
//   //       debugPrint("Error checking driver assignment: $e");
//   //     }

//   //     await Future.delayed(interval);
//   //   }

//   //   _driverLinkedController.add(false);
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     const SnackBar(
//   //       content: Text("No driver accepted your ride. Try again later."),
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // ✅ required for AutomaticKeepAliveClientMixin

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Movers Service'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black87,
//       ),
//       body: Stack(
//         children: [
//           SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Request Movers',
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),

//                   TextFormField(
//                     readOnly: true,
//                     controller: pickupController,
//                     decoration: const InputDecoration(
//                       labelText: 'Pickup Location',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.my_location, color: Colors.blue),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   GestureDetector(
//                     onTap: _openDestinationPicker,
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         readOnly: true,
//                         controller: destinationController,
//                         decoration: const InputDecoration(
//                           labelText: 'Destination Location',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(
//                             Icons.location_on,
//                             color: Colors.red,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   GestureDetector(
//                     onTap: () async {
//                       DateTime now = DateTime.now();
//                       final pickedDate = await showDatePicker(
//                         context: context,
//                         initialDate: now,
//                         firstDate: now,
//                         lastDate: DateTime(now.year + 1),
//                       );
//                       if (pickedDate != null) {
//                         final pickedTime = await showTimePicker(
//                           context: context,
//                           initialTime: TimeOfDay.now(),
//                         );
//                         if (pickedTime != null) {
//                           final combinedDateTime = DateTime(
//                             pickedDate.year,
//                             pickedDate.month,
//                             pickedDate.day,
//                             pickedTime.hour,
//                             pickedTime.minute,
//                           );
//                           setState(() {
//                             movingDate = combinedDateTime;
//                             movingDateController.text =
//                                 "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
//                                 "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
//                           });
//                         }
//                       }
//                     },
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         controller: movingDateController,
//                         decoration: const InputDecoration(
//                           labelText: 'Moving Date & Time',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(
//                             Icons.calendar_today,
//                             color: Colors.orange,
//                           ),
//                         ),
//                         readOnly: true,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   DropdownButtonFormField<Subcategory>(
//                     value: selectedSubcategory,
//                     isExpanded: true,
//                     hint: const Text('Select No Of Rooms'),
//                     items:
//                         subcategories.map((subcategory) {
//                           return DropdownMenuItem<Subcategory>(
//                             value: subcategory,
//                             child: Text(subcategory.name),
//                           );
//                         }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedSubcategory = value;
//                         selectedPrice = value?.baseFare;
//                         priceController.text =
//                             selectedPrice != null
//                                 ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
//                                 : '';
//                       });
//                     },
//                     decoration: const InputDecoration(
//                       labelText: "Rooms",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.house),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   TextFormField(
//                     controller: priceController,
//                     readOnly: true,
//                     decoration: const InputDecoration(
//                       labelText: 'Estimated Price',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.attach_money),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   TextFormField(
//                     controller: detailsController,
//                     decoration: const InputDecoration(
//                       labelText: 'Additional Details (Optional)',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.description_outlined),
//                     ),
//                     maxLines: 3,
//                   ),
//                   const SizedBox(height: 40),

//                   ElevatedButton.icon(
//                     onPressed: () async {
//                       if (mounted) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             fullscreenDialog: true,
//                             builder:
//                                 (_) => FindingDriverScreen(
//                                   onCancel: () async {
//                                     // TODO: cancel API here
//                                     print("Ride canceled by passenger");
//                                   },
//                                   driverLinkedStream:
//                                       _driverLinkedController.stream,
//                                 ),
//                           ),
//                         );
//                         await bookRide();
//                       }
//                     },
//                     icon: const Icon(Icons.send),
//                     label: const Text("Confirm and Submit Request"),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: Colors.grey[700],
//                       foregroundColor: Colors.white,
//                       textStyle: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       minimumSize: const Size.fromHeight(48),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:geocoding/geocoding.dart';
// // import 'package:niceapp/Container/utils/keys.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/finding_driver_screen.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';

// // class MoversScreen extends StatefulWidget {
// //   final VehicleCategory category;
// //   final LatLng? pickup;
// //   final LatLng? destination;

// //   const MoversScreen({
// //     super.key,
// //     required this.category,
// //     this.pickup,
// //     this.destination,
// //   });

// //   @override
// //   State<MoversScreen> createState() => _MoversScreenScreenState();
// // }

// // class _MoversScreenScreenState extends State<MoversScreen> {
// //   final TextEditingController detailsController = TextEditingController();
// //   final TextEditingController priceController = TextEditingController();
// //   DateTime? movingDate;
// //   final TextEditingController movingDateController = TextEditingController();
// //   List<Subcategory> subcategories = [];
// //   Subcategory? selectedSubcategory;
// //   bool _isLoading = false;
// //   LatLng? selectedLatLng;
// //   String? displayAddress;
// //   LatLng? pickupLatLng;
// //   String? pickupAddress;
// //   int? rideId2;
// //   BuildContext? _dialogContext;

// //   //Map<String, double> priceMap = {};
// //   final StreamController<bool> _driverLinkedController =
// //       StreamController<bool>.broadcast();
// //   double? selectedPrice;
// //   @override
// //   void dispose() {
// //     detailsController.dispose();
// //     priceController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchSubcategories();
// //     if (pickupLatLng == null && widget.pickup == null) {
// //       _getPickupLocationFromFirebase();
// //     } else {
// //       pickupLatLng = widget.pickup ?? pickupLatLng;
// //       _getAddressFromLatLng(pickupLatLng!, isPickup: true);
// //     }

// //     if (widget.destination != null && selectedLatLng == null) {
// //       selectedLatLng = widget.destination;
// //       _getAddressFromLatLng(widget.destination!, isPickup: false);
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

// //   void _openDestinationPicker() async {
// //     final result = await Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) => WhereToScreen(category: VehicleCategory.movers),
// //       ),
// //     );

// //     // if (result != null && result is LatLng) {
// //     //   setState(() {
// //     //     selectedLatLng = result;
// //     //   });

// //     if (result != null && result is Map<String, LatLng>) {
// //       setState(() {
// //         pickupLatLng = result['pickup'];
// //         selectedLatLng = result['destination'];
// //       });

// //       // Update both pickup and destination addresses
// //       if (pickupLatLng != null) {
// //         _getAddressFromLatLng(pickupLatLng!, isPickup: true);
// //       }
// //       if (selectedLatLng != null) {
// //         _getAddressFromLatLng(selectedLatLng!, isPickup: false);
// //       }
// //     }
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

// //   // Future<void> _getAddressFromLatLng(LatLng latLng) async {
// //   //   try {
// //   //     final placemarks = await placemarkFromCoordinates(
// //   //       latLng.latitude,
// //   //       latLng.longitude,
// //   //     );
// //   //     if (placemarks.isNotEmpty) {
// //   //       final place = placemarks.first;
// //   //       setState(() {
// //   //         displayAddress =
// //   //             "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
// //   //       });
// //   //     } else {
// //   //       setState(() {
// //   //         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// //   //       });
// //   //     }
// //   //   } catch (e) {
// //   //     setState(() {
// //   //       displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// //   //     });
// //   //     debugPrint("Reverse geocoding failed: $e");
// //   //   }
// //   // }
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

// //   Future<void> bookRide() async {
// //     final user = FirebaseAuth.instance.currentUser;

// //     if (user == null) {
// //       _closeFindingDriverDialog();
// //       print("User is not authenticated");
// //       return;
// //     }

// //     try {
// //       final idToken = await user.getIdToken();
// //       final url = '$baseUrl/passengerrides/movers/request';

// //       final pickupLat = pickupLatLng!.latitude;
// //       final pickupLng = pickupLatLng!.longitude;
// //       final destLat = selectedLatLng!.latitude;
// //       final destLng = selectedLatLng!.longitude;
// //       final subCategoryId = selectedSubcategory?.id;
// //       final scheduledTime = movingDate;
// //       final notes = detailsController.text;
// //       // final pickupAddress = await ReverseGeocodingService.getAddressFromLatLng(
// //       //   LatLng(pickupLat, pickupLng),
// //       // );
// //       // final destinationAddress =
// //       //     await ReverseGeocodingService.getAddressFromLatLng(
// //       //       LatLng(destLat, destLng),
// //       //     );

// //       final body = {
// //         "firebaseIdToken": user.uid,
// //         "pickupLocation": pickupAddress,
// //         "destination": displayAddress,
// //         "pickupLat": pickupLat,
// //         "pickupLng": pickupLng,
// //         "destLat": destLat,
// //         "destLng": destLng,
// //         "subCategoryId": subCategoryId,
// //         "scheduledTime": scheduledTime?.toIso8601String(),
// //         "notes": notes,
// //       };

// //       if (!mounted) return;

// //       final response = await http.post(
// //         Uri.parse(url),
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode(body),
// //       );

// //       if (response.statusCode == 200) {
// //         final responseData = jsonDecode(response.body);
// //         final rideId = responseData['rideId'];
// //         rideId2 = responseData['rideId'];

// //         if (scheduledTime == null) {
// //           await pollForDriverAssignment(rideId);
// //         } else {
// //           _closeFindingDriverDialog();
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(builder: (_) => RideHistoryScreen()),
// //           );
// //         }
// //       } else {
// //         _closeFindingDriverDialog();
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Failed to book ride: ${response.statusCode}'),
// //           ),
// //         );
// //         print('Failed to book ride: ${response.statusCode}');
// //         print(response.body);
// //       }
// //     } catch (e) {
// //       _closeFindingDriverDialog();
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
// //       print('Error booking ride: $e');
// //     }
// //   }

// //   void _closeFindingDriverDialog() {
// //     if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
// //       Navigator.pop(_dialogContext!);
// //     }
// //   }

// //   Future<void> pollForDriverAssignment(int requestId) async {
// //     const maxAttempts = 20;
// //     const interval = Duration(seconds: 5);

// //     for (int i = 0; i < maxAttempts; i++) {
// //       if (!mounted) return;

// //       try {
// //         // 1. Check Firebase first
// //         //final dbRef = FirebaseDatabase.instance.ref("rideRequests/$requestId");
// //         final dbRef = FirebaseDatabase.instance.ref(
// //           "rideRequests/${requestId.toString()}",
// //         );

// //         final dbSnapshot = await dbRef.get();

// //         if (dbSnapshot.exists) {
// //           final requestData = dbSnapshot.value as Map;

// //           // ✅ Real rideId should now exist when driver accepts
// //           if (requestData['rideId'] != null) {
// //             final realRideId = requestData['rideId'];

// //             // 2. Now check backend ride
// //             final url = '$baseUrl/passengerrides/myrides/$realRideId';
// //             final response = await http.get(Uri.parse(url));

// //             if (response.statusCode == 200) {
// //               final rideData = jsonDecode(response.body);

// //               if (rideData['driver'] != null) {
// //                 final driverData = rideData['driver'];

// //                 _driverLinkedController.add(true);

// //                 await Future.delayed(const Duration(milliseconds: 200));

// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder:
// //                         (_) => DriverConfirmationScreen(
// //                           rideId: realRideId,
// //                           pickup: widget.pickup,
// //                           driverId: driverData['firebaseId'],
// //                           Phone: driverData['phoneNumber'],
// //                           regnumber: driverData['registrationNumber'],
// //                           vehicleMake: driverData['vehicleMake'],
// //                           vehicleModel: driverData['vehicleModel'],
// //                           colour: driverData['vehicleColour'],
// //                           drivername: driverData['firstName'],
// //                         ),
// //                   ),
// //                 );
// //                 return;
// //               }
// //             }
// //           }
// //         }
// //       } catch (e) {
// //         debugPrint("Error checking driver assignment: $e");
// //       }

// //       await Future.delayed(interval);
// //     }

// //     _driverLinkedController.add(false);
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text("No driver accepted your ride. Try again later."),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Movers Service'),
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
// //                     'Request Movers',
// //                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// //                   ),

// //                   const SizedBox(height: 20),
// //                   TextFormField(
// //                     readOnly: true,
// //                     controller: TextEditingController(
// //                       text: pickupAddress ?? 'Fetching pickup location...',
// //                     ),
// //                     decoration: const InputDecoration(
// //                       labelText: 'Pickup Location',
// //                       border: OutlineInputBorder(),
// //                       prefixIcon: Icon(Icons.my_location, color: Colors.blue),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),

// //                   // Destination Field (Clickable)
// //                   GestureDetector(
// //                     onTap: _openDestinationPicker,
// //                     child: AbsorbPointer(
// //                       child: TextFormField(
// //                         readOnly: true,
// //                         controller: TextEditingController(
// //                           text: displayAddress ?? 'Tap to select destination',
// //                         ),
// //                         decoration: const InputDecoration(
// //                           labelText: 'Destination Location',
// //                           border: OutlineInputBorder(),
// //                           prefixIcon: Icon(
// //                             Icons.location_on,
// //                             color: Colors.red,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),

// //                   GestureDetector(
// //                     onTap: () async {
// //                       DateTime now = DateTime.now();

// //                       // Step 1: Pick Date
// //                       final pickedDate = await showDatePicker(
// //                         context: context,
// //                         initialDate: now,
// //                         firstDate: now,
// //                         lastDate: DateTime(now.year + 1),
// //                       );

// //                       if (pickedDate != null) {
// //                         // Step 2: Pick Time
// //                         final pickedTime = await showTimePicker(
// //                           context: context,
// //                           initialTime: TimeOfDay.now(),
// //                         );

// //                         if (pickedTime != null) {
// //                           // Step 3: Combine date + time into one DateTime
// //                           final combinedDateTime = DateTime(
// //                             pickedDate.year,
// //                             pickedDate.month,
// //                             pickedDate.day,
// //                             pickedTime.hour,
// //                             pickedTime.minute,
// //                           );

// //                           setState(() {
// //                             movingDate = combinedDateTime;
// //                             movingDateController.text =
// //                                 "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
// //                                 "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
// //                           });
// //                         }
// //                       }
// //                     },
// //                     child: AbsorbPointer(
// //                       child: TextFormField(
// //                         controller: movingDateController,
// //                         decoration: const InputDecoration(
// //                           labelText: 'Moving Date & Time',
// //                           border: OutlineInputBorder(),
// //                           prefixIcon: Icon(
// //                             Icons.calendar_today,
// //                             color: Colors.orange,
// //                           ),
// //                         ),
// //                         readOnly: true,
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 20),
// //                   DropdownButtonFormField<Subcategory>(
// //                     value: selectedSubcategory,
// //                     isExpanded: true,
// //                     hint: const Text('Select No Of Rooms'),
// //                     items:
// //                         subcategories.map((subcategory) {
// //                           return DropdownMenuItem<Subcategory>(
// //                             value: subcategory,
// //                             child: Text(subcategory.name),
// //                           );
// //                         }).toList(),
// //                     onChanged: (value) {
// //                       setState(() {
// //                         selectedSubcategory = value;
// //                         selectedPrice = value?.baseFare;
// //                         priceController.text =
// //                             selectedPrice != null
// //                                 ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
// //                                 : '';
// //                       });
// //                     },
// //                     decoration: const InputDecoration(
// //                       labelText: "Rooms",
// //                       border: OutlineInputBorder(),
// //                       prefixIcon: Icon(Icons.house),
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
// //                       if (mounted) {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             fullscreenDialog: true,
// //                             builder:
// //                                 (_) => FindingDriverScreen(
// //                                   onCancel: () async {
// //                                     // Call cancel API
// //                                     print("Ride canceled by passenger");
// //                                   },
// //                                   driverLinkedStream:
// //                                       _driverLinkedController.stream,
// //                                 ),
// //                           ),
// //                         );

// //                         await bookRide();
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

// // // class Subcategory {
// // //   final int id;
// // //   final String name;
// // //   final double baseFare;

// // //   Subcategory({required this.id, required this.name, required this.baseFare});

// // //   factory Subcategory.fromJson(Map<String, dynamic> json) {
// // //     return Subcategory(
// // //       id: json['id'],
// // //       name: json['name'],
// // //       baseFare: (json['baseFare'] as num).toDouble(),
// // //     );
// // //   }
// // // }

// // // import 'dart:convert';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:niceapp/Container/utils/keys.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

// // // class MoversScreen extends ConsumerStatefulWidget {
// // //   final LatLng? pickupLocation;
// // //   final LatLng? dropLocation;

// // //   // const MoversScreen(
// // //   //   {
// // //   //   super.key, this.required.pickupLocation,
// // //   //   this.dropLocation,
// // //   // });

// // //   const MoversScreen({
// // //     super.key,
// // //     this.pickupLocation,
// // //     this.dropLocation,
// // //     required VehicleCategory category,
// // //   });

// // //   @override
// // //   ConsumerState<MoversScreen> createState() => _MoversScreenState();
// // // }

// // // class _MoversScreenState extends ConsumerState<MoversScreen> {
// // //   final TextEditingController itemDetailsController = TextEditingController();
// // //   final TextEditingController boxesController = TextEditingController();
// // //   LatLng? pickupLocation;
// // //   LatLng? dropLocation;
// // //   bool packingRequired = false;
// // //   bool unpackingRequired = false;
// // //   int? selectedSubCategoryId;
// // //   bool showAvailableMovers = false;
// // //   List<dynamic> availableMovers = [];
// // //   DateTime? travelDate;
// // //   double distanceRadius = 30;
// // //   bool pickupHasElevator = false;
// // //   bool pickupHasParking = false;
// // //   bool hasFragileItems = false;
// // //   bool hasHeavyItems = false;
// // //   bool needsDisassembly = false;
// // //   bool wantsInsurance = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     pickupLocation = widget.pickupLocation;
// // //     dropLocation = widget.dropLocation;
// // //   }

// // //   void openLocationSelector() async {
// // //     await Navigator.push(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (_) => WhereToScreen(category: VehicleCategory.movers),
// // //       ),
// // //     );

// // //     // Update after navigation
// // //     setState(() {
// // //       pickupLocation = ref.read(pickupLocationProvider);
// // //       dropLocation = ref.read(destinationLocationProvider);

// // //       //pickupLocation = ref.read(pickupLocationProvider);
// // //       //dropLocation = ref.read(destinationLocationProvider);
// // //     });
// // //   }

// // //   Future<void> searchAvailableMovers() async {
// // //     if (pickupLocation == null ||
// // //         dropLocation == null ||
// // //         selectedSubCategoryId == null) {
// // //       _showError("Please select pickup, drop, and item details.");
// // //       return;
// // //     }

// // //     try {
// // //       // final response = await http.get(
// // //       //   Uri.parse(
// // //       //     "$baseUrl/passengerrides/movers/available?pickupLat=${pickupLocation!.latitude}&pickupLng=${pickupLocation!.longitude}&dropLat=${dropLocation!.latitude}&dropLng=${dropLocation!.longitude}&subCategoryId=$selectedSubCategoryId",
// // //       //   ),
// // //       //   headers: {'Content-Type': 'application/json'},
// // //       // );

// // //       // if (response.statusCode == 200) {
// // //       //   final data = json.decode(response.body);
// // //       //   setState(() {
// // //       //     availableMovers = data; // Should be a list of movers
// // //       //     showAvailableMovers = true;
// // //       //   });
// // //       // } else {
// // //       //   _showError("Failed to fetch available movers.");
// // //       // }
// // //       final queryParams = {
// // //         'pickupLat': pickupLocation!.latitude.toString(),
// // //         'pickupLng': pickupLocation!.longitude.toString(),
// // //         'dropLat': dropLocation!.latitude.toString(),
// // //         'dropLng': dropLocation!.longitude.toString(),
// // //         'subCategoryId': selectedSubCategoryId.toString(),
// // //         'radiusKm': distanceRadius.toInt().toString(),
// // //         'travelDate':
// // //             travelDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
// // //       };

// // //       final uri = Uri.parse(
// // //         "$baseUrl/passengerrides/movers/available",
// // //       ).replace(queryParameters: queryParams);
// // //     } catch (e) {
// // //       _showError("Error: $e");
// // //     }
// // //   }

// // //   Future<void> fetchSubCategories() async {
// // //     try {
// // //       final response = await http.get(
// // //         Uri.parse('$baseUrl/passengerrides/subcategories?categoryType=movers'),
// // //         headers: {'Content-Type': 'application/json'},
// // //       );

// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         if (data is List && data.isNotEmpty) {
// // //           setState(() {
// // //             selectedSubCategoryId = data[0]['id']; // Auto-select the first one
// // //           });
// // //         } else {
// // //           _showError("No subcategories found for Movers.");
// // //         }
// // //       } else {
// // //         _showError("Failed to fetch subcategories.");
// // //       }
// // //     } catch (e) {
// // //       _showError("Error fetching subcategories: $e");
// // //     }
// // //   }

// // //   Future<void> submitRequest() async {
// // //     final user = FirebaseAuth.instance.currentUser;
// // //     final idToken = await user?.getIdToken();

// // //     if (pickupLocation == null ||
// // //         dropLocation == null ||
// // //         idToken == null ||
// // //         selectedSubCategoryId == null) {
// // //       _showError("Missing required fields.");
// // //       return;
// // //     }

// // //     final payload = {
// // //       "pickupCoordinates": {
// // //         "latitude": pickupLocation!.latitude,
// // //         "longitude": pickupLocation!.longitude,
// // //       },
// // //       "destinationCoordinates": {
// // //         "latitude": dropLocation!.latitude,
// // //         "longitude": dropLocation!.longitude,
// // //       },
// // //       "itemDetails": itemDetailsController.text,
// // //       "subCategoryId": selectedSubCategoryId,
// // //       "firebaseIdToken": idToken,
// // //       "cargoWeight": 250, // optional
// // //       "estimatedFare": 1000, // optional
// // //     };

// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse("$baseUrl/passengerrides/movers/book"),
// // //         headers: {"Content-Type": "application/json"},
// // //         body: jsonEncode(payload),
// // //       );

// // //       print("Response body: ${response.body}");

// // //       if (response.statusCode == 200) {
// // //         _showMessage("Movers request submitted successfully.");
// // //       } else {
// // //         _showError("Failed to submit. (${response.statusCode})");
// // //       }
// // //     } catch (e) {
// // //       _showError("Error: ${e.toString()}");
// // //     }
// // //   }

// // //   Widget _sectionTitle(String text) {
// // //     return Text(
// // //       text,
// // //       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
// // //     );
// // //   }
// // //   // Future<void> submitRequest() async {
// // //   //   final payload = {
// // //   //     "pickupCoordinates": {
// // //   //       "latitude": pickupLocation!.latitude,
// // //   //       "longitude": pickupLocation!.longitude,
// // //   //     },
// // //   //     "destinationCoordinates": {
// // //   //       "latitude": dropLocation!.latitude,
// // //   //       "longitude": dropLocation!.longitude,
// // //   //     },
// // //   //     "itemDetails": itemDetailsController.text,
// // //   //     "packingRequired": packingRequired,
// // //   //     "unpackingRequired": unpackingRequired,
// // //   //   };

// // //   //   try {
// // //   //     final response = await http.post(
// // //   //       Uri.parse("$baseUrl/passengerrides/movers/book"),
// // //   //       headers: {"Content-Type": "application/json"},
// // //   //       body: jsonEncode(payload),
// // //   //     );

// // //   //     if (response.statusCode == 200) {
// // //   //       _showMessage("Movers request submitted successfully.");
// // //   //     } else {
// // //   //       _showError("Failed to submit. (${response.statusCode})");
// // //   //     }
// // //   //   } catch (e) {
// // //   //     _showError("Error: ${e.toString()}");
// // //   //   }
// // //   // }

// // //   void _showError(String msg) {
// // //     ScaffoldMessenger.of(
// // //       context,
// // //     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
// // //   }

// // //   void _showMessage(String msg) {
// // //     ScaffoldMessenger.of(
// // //       context,
// // //     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       appBar: AppBar(
// // //         title: const Text('Movers Services'),
// // //         centerTitle: true,
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         foregroundColor: Colors.black,
// // //       ),
// // //       body: Stack(
// // //         children: [
// // //           ListView(
// // //             padding: const EdgeInsets.all(16),
// // //             children: [
// // //               ItemDetailsSection(itemDetailsController: itemDetailsController),
// // //               const SizedBox(height: 20),
// // //               AccessibilitySection(
// // //                 pickupHasElevator: pickupHasElevator,
// // //                 pickupHasParking: pickupHasParking,
// // //                 onElevatorChanged:
// // //                     (val) => setState(() => pickupHasElevator = val),
// // //                 onParkingChanged:
// // //                     (val) => setState(() => pickupHasParking = val),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               InventorySection(
// // //                 boxesController: boxesController,
// // //                 hasFragileItems: hasFragileItems,
// // //                 hasHeavyItems: hasHeavyItems,
// // //                 needsDisassembly: needsDisassembly,
// // //                 onFragileChanged:
// // //                     (val) => setState(() => hasFragileItems = val),
// // //                 onHeavyChanged: (val) => setState(() => hasHeavyItems = val),
// // //                 onDisassemblyChanged:
// // //                     (val) => setState(() => needsDisassembly = val),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               PreferencesSection(
// // //                 packingRequired: packingRequired,
// // //                 wantsInsurance: wantsInsurance,
// // //                 onPackingChanged:
// // //                     (val) => setState(() => packingRequired = val),
// // //                 onInsuranceChanged:
// // //                     (val) => setState(() => wantsInsurance = val),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               TripDetailsSection(
// // //                 travelDate: travelDate,
// // //                 pickupLocation: pickupLocation,
// // //                 dropLocation: dropLocation,
// // //                 onDatePicked: (picked) => setState(() => travelDate = picked),
// // //                 onSelectLocation: openLocationSelector,
// // //               ),
// // //               const SizedBox(height: 20),
// // //               SearchRadiusSection(
// // //                 radius: distanceRadius,
// // //                 onChanged: (val) => setState(() => distanceRadius = val),
// // //                 onFindMovers: searchAvailableMovers,
// // //               ),
// // //             ],
// // //           ),
// // //           if (showAvailableMovers)
// // //             DraggableScrollableSheet(
// // //               initialChildSize: 0.45,
// // //               minChildSize: 0.3,
// // //               maxChildSize: 0.85,
// // //               builder: (context, scrollController) {
// // //                 return Container(
// // //                   padding: const EdgeInsets.all(16),
// // //                   decoration: const BoxDecoration(
// // //                     color: Colors.white,
// // //                     borderRadius: BorderRadius.vertical(
// // //                       top: Radius.circular(24),
// // //                     ),
// // //                     boxShadow: [
// // //                       BoxShadow(color: Colors.black26, blurRadius: 10),
// // //                     ],
// // //                   ),
// // //                   child: ListView.builder(
// // //                     controller: scrollController,
// // //                     itemCount: availableMovers.length,
// // //                     itemBuilder: (context, index) {
// // //                       final mover = availableMovers[index];

// // //                       return Card(
// // //                         elevation: 3,
// // //                         margin: const EdgeInsets.symmetric(vertical: 10),
// // //                         shape: RoundedRectangleBorder(
// // //                           borderRadius: BorderRadius.circular(16),
// // //                         ),
// // //                         child: ListTile(
// // //                           contentPadding: const EdgeInsets.all(12),
// // //                           leading: CircleAvatar(
// // //                             radius: 28,
// // //                             backgroundImage: NetworkImage(
// // //                               mover['profileImageUrl'] ?? '',
// // //                             ),
// // //                             backgroundColor: Colors.grey[200],
// // //                           ),
// // //                           title: Text(
// // //                             mover['name'] ?? 'Mover #${index + 1}',
// // //                             style: const TextStyle(fontWeight: FontWeight.bold),
// // //                           ),
// // //                           subtitle: Column(
// // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // //                             children: [
// // //                               Text(
// // //                                 "🚚 Vehicle: ${mover['vehicleType'] ?? 'Unknown'}",
// // //                               ),
// // //                               Text(
// // //                                 "⭐ Rating: ${mover['rating']?.toStringAsFixed(1) ?? 'N/A'}",
// // //                               ),
// // //                               Text(
// // //                                 "💰 Fare: KES ${mover['estimatedFare'] ?? '---'}",
// // //                               ),
// // //                             ],
// // //                           ),
// // //                           trailing: ElevatedButton(
// // //                             child: const Text("Select"),
// // //                             onPressed: () {
// // //                               _showMessage("You selected ${mover['name']}");
// // //                             },
// // //                           ),
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // //       body: ListView(
// // // //   padding: const EdgeInsets.all(16),
// // // //   children: [
// // // //     ItemDetailsSection(itemDetailsController: itemDetailsController),
// // // //     const SizedBox(height: 20),
// // // //     AccessibilitySection(
// // // //       pickupHasElevator: pickupHasElevator,
// // // //       pickupHasParking: pickupHasParking,
// // // //       onElevatorChanged: (val) => setState(() => pickupHasElevator = val),
// // // //       onParkingChanged: (val) => setState(() => pickupHasParking = val),
// // // //     ),
// // // //     const SizedBox(height: 20),
// // // //     InventorySection(
// // // //       boxesController: boxesController,
// // // //       hasFragileItems: hasFragileItems,
// // // //       hasHeavyItems: hasHeavyItems,
// // // //       needsDisassembly: needsDisassembly,
// // // //       onFragileChanged: (val) => setState(() => hasFragileItems = val),
// // // //       onHeavyChanged: (val) => setState(() => hasHeavyItems = val),
// // // //       onDisassemblyChanged: (val) => setState(() => needsDisassembly = val),
// // // //     ),
// // // //     const SizedBox(height: 20),
// // // //     PreferencesSection(
// // // //       packingRequired: packingRequired,
// // // //       wantsInsurance: wantsInsurance,
// // // //       onPackingChanged: (val) => setState(() => packingRequired = val),
// // // //       onInsuranceChanged: (val) => setState(() => wantsInsurance = val),
// // // //     ),
// // // //     const SizedBox(height: 20),
// // // //     TripDetailsSection(
// // // //       travelDate: travelDate,
// // // //       pickupLocation: pickupLocation,
// // // //       dropLocation: dropLocation,
// // // //       onDatePicked: (picked) => setState(() => travelDate = picked),
// // // //       onSelectLocation: openLocationSelector,
// // // //     ),
// // // //     const SizedBox(height: 20),
// // // //     SearchRadiusSection(
// // // //       radius: distanceRadius,
// // // //       onChanged: (val) => setState(() => distanceRadius = val),
// // // //       onFindMovers: searchAvailableMovers,
// // // //     ),
// // // //   ],
// // // // ),

// // // // Draggable Sheet
// // // //           if (showAvailableMovers)
// // // //             DraggableScrollableSheet(
// // // //               initialChildSize: 0.45,
// // // //               minChildSize: 0.3,
// // // //               maxChildSize: 0.85,
// // // //               builder: (context, scrollController) {
// // // //                 return Container(
// // // //                   padding: const EdgeInsets.all(16),
// // // //                   decoration: const BoxDecoration(
// // // //                     color: Colors.white,
// // // //                     borderRadius: BorderRadius.vertical(
// // // //                       top: Radius.circular(24),
// // // //                     ),
// // // //                     boxShadow: [
// // // //                       BoxShadow(color: Colors.black26, blurRadius: 10),
// // // //                     ],
// // // //                   ),
// // // //                   child: ListView.builder(
// // // //                     controller: scrollController,
// // // //                     itemCount: availableMovers.length,
// // // //                     itemBuilder: (context, index) {
// // // //                       final mover = availableMovers[index];

// // // //                       return Card(
// // // //                         elevation: 3,
// // // //                         margin: const EdgeInsets.symmetric(vertical: 10),
// // // //                         shape: RoundedRectangleBorder(
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                         ),
// // // //                         child: ListTile(
// // // //                           contentPadding: const EdgeInsets.all(12),
// // // //                           leading: CircleAvatar(
// // // //                             radius: 28,
// // // //                             backgroundImage: NetworkImage(
// // // //                               mover['profileImageUrl'] ?? '',
// // // //                             ),
// // // //                             backgroundColor: Colors.grey[200],
// // // //                           ),
// // // //                           title: Text(
// // // //                             mover['name'] ?? 'Mover #${index + 1}',
// // // //                             style: const TextStyle(fontWeight: FontWeight.bold),
// // // //                           ),
// // // //                           subtitle: Column(
// // // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // // //                             children: [
// // // //                               Text(
// // // //                                 "🚚 Vehicle: ${mover['vehicleType'] ?? 'Unknown'}",
// // // //                               ),
// // // //                               Text(
// // // //                                 "⭐ Rating: ${mover['rating']?.toStringAsFixed(1) ?? 'N/A'}",
// // // //                               ),
// // // //                               Text(
// // // //                                 "💰 Fare: KES ${mover['estimatedFare'] ?? '---'}",
// // // //                               ),
// // // //                             ],
// // // //                           ),
// // // //                           trailing: ElevatedButton(
// // // //                             child: const Text("Select"),
// // // //                             onPressed: () {
// // // //                               _showMessage("You selected ${mover['name']}");
// // // //                             },
// // // //                           ),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                   ),
// // // //                 );
// // // //               },
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // This is a cleaned-up modular version of your MoversScreen form.
// // // // Each section is extracted to a reusable widget for maintainability.

// // // class ItemDetailsSection extends StatelessWidget {
// // //   final TextEditingController itemDetailsController;

// // //   const ItemDetailsSection({super.key, required this.itemDetailsController});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         const Text(
// // //           'Request Moving Service',
// // //           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// // //         ),
// // //         const SizedBox(height: 16),
// // //         TextFormField(
// // //           controller: itemDetailsController,
// // //           decoration: InputDecoration(
// // //             labelText: 'Describe Items to be Moved',
// // //             prefixIcon: const Icon(Icons.inventory),
// // //             filled: true,
// // //             fillColor: Colors.grey[100],
// // //             border: OutlineInputBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //               borderSide: BorderSide.none,
// // //             ),
// // //           ),
// // //           maxLines: 3,
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class AccessibilitySection extends StatelessWidget {
// // //   final bool pickupHasElevator;
// // //   final bool pickupHasParking;
// // //   final Function(bool) onElevatorChanged;
// // //   final Function(bool) onParkingChanged;

// // //   const AccessibilitySection({
// // //     super.key,
// // //     required this.pickupHasElevator,
// // //     required this.pickupHasParking,
// // //     required this.onElevatorChanged,
// // //     required this.onParkingChanged,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         const Text(
// // //           'Location Accessibility',
// // //           style: TextStyle(fontWeight: FontWeight.bold),
// // //         ),
// // //         const SizedBox(height: 8),
// // //         TextFormField(
// // //           decoration: const InputDecoration(
// // //             labelText: "Pickup Floor (e.g., Ground, 1st, 4th)",
// // //             prefixIcon: Icon(Icons.stairs),
// // //           ),
// // //         ),
// // //         SwitchListTile(
// // //           title: const Text("Elevator Available at Pickup"),
// // //           value: pickupHasElevator,
// // //           onChanged: onElevatorChanged,
// // //         ),
// // //         SwitchListTile(
// // //           title: const Text("Parking Available at Pickup"),
// // //           value: pickupHasParking,
// // //           onChanged: onParkingChanged,
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class InventorySection extends StatelessWidget {
// // //   final TextEditingController boxesController;
// // //   final bool hasFragileItems;
// // //   final bool hasHeavyItems;
// // //   final bool needsDisassembly;
// // //   final Function(bool) onFragileChanged;
// // //   final Function(bool) onHeavyChanged;
// // //   final Function(bool) onDisassemblyChanged;

// // //   const InventorySection({
// // //     super.key,
// // //     required this.boxesController,
// // //     required this.hasFragileItems,
// // //     required this.hasHeavyItems,
// // //     required this.needsDisassembly,
// // //     required this.onFragileChanged,
// // //     required this.onHeavyChanged,
// // //     required this.onDisassemblyChanged,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         const Text(
// // //           'Inventory & Special Items',
// // //           style: TextStyle(fontWeight: FontWeight.bold),
// // //         ),
// // //         const SizedBox(height: 8),
// // //         TextFormField(
// // //           controller: boxesController,
// // //           keyboardType: TextInputType.number,
// // //           decoration: const InputDecoration(
// // //             labelText: "Number of Boxes",
// // //             prefixIcon: Icon(Icons.inventory_2_outlined),
// // //           ),
// // //         ),
// // //         CheckboxListTile(
// // //           title: const Text("Includes Fragile Items"),
// // //           value: hasFragileItems,
// // //           onChanged: (val) => onFragileChanged(val!),
// // //         ),
// // //         CheckboxListTile(
// // //           title: const Text("Includes Heavy Items (e.g., Piano, Safe)"),
// // //           value: hasHeavyItems,
// // //           onChanged: (val) => onHeavyChanged(val!),
// // //         ),
// // //         SwitchListTile(
// // //           title: const Text("Disassembly/Reassembly Required"),
// // //           value: needsDisassembly,
// // //           onChanged: onDisassemblyChanged,
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class PreferencesSection extends StatelessWidget {
// // //   final bool packingRequired;
// // //   final bool wantsInsurance;
// // //   final Function(bool) onPackingChanged;
// // //   final Function(bool) onInsuranceChanged;

// // //   const PreferencesSection({
// // //     super.key,
// // //     required this.packingRequired,
// // //     required this.wantsInsurance,
// // //     required this.onPackingChanged,
// // //     required this.onInsuranceChanged,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         const Text(
// // //           'Other Preferences',
// // //           style: TextStyle(fontWeight: FontWeight.bold),
// // //         ),
// // //         const SizedBox(height: 8),
// // //         SwitchListTile(
// // //           title: const Text("Transit Insurance Required"),
// // //           value: wantsInsurance,
// // //           onChanged: onInsuranceChanged,
// // //         ),
// // //         SwitchListTile(
// // //           title: const Text("Packing Required"),
// // //           value: packingRequired,
// // //           onChanged: onPackingChanged,
// // //           secondary: const Icon(Icons.all_inbox),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class TripDetailsSection extends StatelessWidget {
// // //   final DateTime? travelDate;
// // //   final LatLng? pickupLocation;
// // //   final LatLng? dropLocation;
// // //   final Function(DateTime) onDatePicked;
// // //   final VoidCallback onSelectLocation;

// // //   const TripDetailsSection({
// // //     super.key,
// // //     required this.travelDate,
// // //     required this.pickupLocation,
// // //     required this.dropLocation,
// // //     required this.onDatePicked,
// // //     required this.onSelectLocation,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         ListTile(
// // //           leading: const Icon(Icons.calendar_today),
// // //           title: Text(
// // //             travelDate != null
// // //                 ? "Travel Date: ${travelDate!.toLocal().toString().split(' ')[0]}"
// // //                 : "Select Travel Date",
// // //           ),
// // //           trailing: const Icon(Icons.edit_calendar),
// // //           onTap: () async {
// // //             final picked = await showDatePicker(
// // //               context: context,
// // //               initialDate: DateTime.now(),
// // //               firstDate: DateTime.now(),
// // //               lastDate: DateTime.now().add(const Duration(days: 365)),
// // //             );
// // //             if (picked != null) {
// // //               onDatePicked(picked);
// // //             }
// // //           },
// // //         ),
// // //         ElevatedButton.icon(
// // //           icon: const Icon(Icons.location_on),
// // //           label: const Text("Select Pickup & Destination"),
// // //           onPressed: onSelectLocation,
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: Colors.blueAccent,
// // //             foregroundColor: Colors.white,
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(10),
// // //             ),
// // //             minimumSize: const Size(double.infinity, 50),
// // //           ),
// // //         ),
// // //         const SizedBox(height: 10),
// // //         if (pickupLocation != null)
// // //           Text(
// // //             "📍 Pickup: ${pickupLocation!.latitude}, ${pickupLocation!.longitude}",
// // //           ),
// // //         if (dropLocation != null)
// // //           Text(
// // //             "📍 Drop: ${dropLocation!.latitude}, ${dropLocation!.longitude}",
// // //           ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class SearchRadiusSection extends StatelessWidget {
// // //   final double radius;
// // //   final ValueChanged<double> onChanged;
// // //   final VoidCallback onFindMovers;

// // //   const SearchRadiusSection({
// // //     super.key,
// // //     required this.radius,
// // //     required this.onChanged,
// // //     required this.onFindMovers,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         const Text(
// // //           "Search Radius from Your Location (KM)",
// // //           style: TextStyle(fontWeight: FontWeight.w600),
// // //         ),
// // //         Slider(
// // //           value: radius,
// // //           min: 10,
// // //           max: 100,
// // //           divisions: 18,
// // //           label: "${radius.toInt()} km",
// // //           onChanged: onChanged,
// // //         ),
// // //         Text(
// // //           "Searching within ${radius.toInt()} km",
// // //           style: TextStyle(color: Colors.grey[600]),
// // //         ),
// // //         const SizedBox(height: 20),
// // //         ElevatedButton.icon(
// // //           onPressed: onFindMovers,
// // //           icon: const Icon(Icons.search),
// // //           label: const Text("Find Movers"),
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: Colors.grey[700],
// // //             foregroundColor: Colors.white,
// // //             minimumSize: const Size(double.infinity, 50),
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }
