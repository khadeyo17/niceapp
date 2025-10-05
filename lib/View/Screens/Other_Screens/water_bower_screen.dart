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
import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';

class WaterBowerScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? destination;

  const WaterBowerScreen({super.key, required this.category, this.destination});

  @override
  State<WaterBowerScreen> createState() => _HoneySuckerScreenState();
}

class _HoneySuckerScreenState extends State<WaterBowerScreen> {
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  String? displayAddress;
  BuildContext? _dialogContext;
  int? rideId2;
  //Map<String, double> priceMap = {};
  double? selectedPrice;
  final StreamController<bool> _driverLinkedController =
      StreamController<bool>.broadcast();

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

    if (widget.destination != null) {
      selectedLatLng = widget.destination;
      _getAddressFromLatLng(widget.destination!);
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
          // // Optional: select the first one by default
          // if (subcategories.isNotEmpty) {
          //  // selectedSubcategory = subcategories[0];
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

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _closeFindingDriverDialog();
      print("User is not authenticated");
      return;
    }

    final idToken = await user.getIdToken();
    // final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    // if (token == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Authentication error'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }
    final scheduledTime = null;
    final requestBody = {
      "firebaseIdToken": user.uid,
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
        Uri.parse('$baseUrl/rides/exhauster/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      setState(() => _isLoading = false);

      // if (response.statusCode == 200) {
      //   final responseData = jsonDecode(response.body);
      //   final rideId = responseData['rideId'];
      //   //rideId2 = responseData['rideId'];

      //   //await pollForDriverAssignment(rideId);

      //   if (scheduledTime == null) {
      //     await pollForDriverAssignment(rideId);
      //   } else {
      //     _closeFindingDriverDialog();
      //     Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(builder: (_) => RideHistoryScreen()),
      //     );
      //   }
      // }
      // else {
      //   _closeFindingDriverDialog();
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to book ride: ${response.statusCode}'),
      //     ),
      //   );
      //   print('Failed to book ride: ${response.statusCode}');
      //   print(response.body);
      // }
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final rideId = responseData['rideId'];
        rideId2 = responseData['rideId'];

        if (scheduledTime == null) {
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
        print('Failed to book ride: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      _closeFindingDriverDialog();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
      print('Error booking ride: $e');
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
            final url = '$baseUrl/rides/myrides/$realRideId';
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
                          //pickup: widget.pickup,
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

  void _openDestinationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhereToScreen(category: VehicleCategory.exhauster),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        selectedLatLng = result;
      });

      _getAddressFromLatLng(result);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          displayAddress =
              "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
        });
      } else {
        setState(() {
          displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
        });
      }
    } catch (e) {
      setState(() {
        displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
      });
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Bowser Service'),
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
                    'Request Water Bowser',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Subcategory>(
                    value: selectedSubcategory,
                    isExpanded: true,
                    hint: const Text('Select Quantity'),
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
                      labelText: "Quantity",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.plumbing),
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
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _openDestinationPicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayAddress ??
                                  'Tap to select destination on map',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    displayAddress == null
                                        ? Colors.grey[700]
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // if (selectedSubcategory == null ||
                      //     selectedLatLng == null) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(
                      //       content: Text(
                      //         'Please complete all required fields',
                      //       ),
                      //       backgroundColor: Colors.red,
                      //     ),
                      //   );
                      //   return;
                      // }

                      // final token =
                      //     await FirebaseAuth.instance.currentUser?.getIdToken();
                      // if (token == null) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(
                      //       content: Text('Authentication error'),
                      //       backgroundColor: Colors.red,
                      //     ),
                      //   );
                      //   return;
                      // }

                      // final requestBody = {
                      //   "firebaseIdToken": token,
                      //   "destLat": selectedLatLng!.latitude,
                      //   "destLng": selectedLatLng!.longitude,
                      //   "destination": displayAddress ?? '',
                      //   "notes": detailsController.text,
                      //   "subCategoryId": selectedSubcategory?.id,
                      //   "scheduledTime": null,
                      // };

                      // try {
                      //   setState(() => _isLoading = true);

                      //   final response = await http.post(
                      //     Uri.parse('$baseUrl/rides/exhauster/book'),
                      //     headers: {'Content-Type': 'application/json'},
                      //     body: jsonEncode(requestBody),
                      //   );

                      //   setState(() => _isLoading = false);

                      //   if (response.statusCode == 200) {
                      //     final data = jsonDecode(response.body);
                      //     final rideId = data['rideId'];

                      //     if (rideId != null && mounted) {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder:
                      //               (_) => DriverAssignmentsScreen(
                      //                 destination: selectedLatLng!,
                      //                 rideId: rideId,
                      //                 category: selectedSubcategory!,
                      //                 fare: selectedPrice ?? 0,
                      //               ),
                      //         ),
                      //       );
                      //     }
                      //   } else {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(
                      //         content: Text('Booking failed: ${response.body}'),
                      //         backgroundColor: Colors.red,
                      //       ),
                      //     );
                      //   }
                      // } catch (e) {
                      //   setState(() => _isLoading = false);
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(
                      //       content: Text(
                      //         'Unexpected error. Please try again.',
                      //       ),
                      //       backgroundColor: Colors.red,
                      //     ),
                      //   );
                      // }
                      if (mounted) {
                        // Instead of dialog, push full screen
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder:
                        //         (_) => FindingDriverScreen(
                        //           onCancel: () async {
                        //             // TODO: cancel ride request via API
                        //             print("Ride canceled by passenger");
                        //           },
                        //         ),
                        //   ),
                        // );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder:
                                (_) => FindingDriverScreen(
                                  onCancel: () async {
                                    // Call cancel API
                                    print("Ride canceled by passenger");
                                  },
                                  driverLinkedStream:
                                      _driverLinkedController.stream,
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
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// class WaterBowerScreen extends StatefulWidget {
//   final VehicleCategory category;
//   final LatLng? destination;
//   const WaterBowerScreen({super.key, required this.category, this.destination});

//   @override
//   State<WaterBowerScreen> createState() => _WaterBowserScreenState();
// }

// class _WaterBowserScreenState extends State<WaterBowerScreen> {
//   final TextEditingController detailsController = TextEditingController();
//   List<String> waterSubcategories = [];
//   String? selectedSubcategory;

//   LatLng? selectedLatLng;
//   String? displayAddress;
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchSubcategories();

//     if (widget.destination != null) {
//       selectedLatLng = widget.destination;
//       _getAddressFromLatLng(widget.destination!);
//     }
//   }

//   Future<void> fetchSubcategories() async {
//     setState(() => isLoading = true);
//     try {
//       final response = await http.get(
//         Uri.parse(
//           'https://yourapi.com/api/water-subcategories',
//         ), // Replace with your endpoint
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           waterSubcategories = List<String>.from(data);
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching subcategories: $e');
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _getAddressFromLatLng(LatLng latLng) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         latLng.latitude,
//         latLng.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         setState(() {
//           displayAddress =
//               "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
//         });
//       } else {
//         setState(() {
//           displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
//       });
//       debugPrint("Reverse geocoding failed: $e");
//     }
//   }

//   // Future<void> selectDestination() async {
//   //   final result = await Navigator.push(
//   //     context,
//   //     MaterialPageRoute(
//   //       builder:
//   //           (context) =>
//   //               const WhereToScreen(category: VehicleCategory.waterBowser),
//   //     ),
//   //   );

//   //   if (result != null && result is Map<String, dynamic>) {
//   //     final latLng = result['latlng'] as LatLng?;
//   //     final name = result['name'] as String?;

//   //     setState(() {
//   //       selectedLatLng = latLng;
//   //       displayAddress =
//   //           name ??
//   //           (latLng != null
//   //               ? 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}'
//   //               : null);
//   //     });
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Water Bowser Service'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black87,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Request Water Bowser',
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               DropdownButtonFormField<String>(
//                 value: selectedSubcategory,
//                 isExpanded: true,
//                 hint: const Text('Select Water Quantity'),
//                 items:
//                     waterSubcategories.map((subcategory) {
//                       return DropdownMenuItem<String>(
//                         value: subcategory,
//                         child: Text(subcategory),
//                       );
//                     }).toList(),
//                 onChanged:
//                     (value) => setState(() => selectedSubcategory = value),
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.water_drop),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: detailsController,
//                 decoration: const InputDecoration(
//                   labelText: 'Additional Details (Optional)',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.description),
//                 ),
//                 maxLines: 3,
//               ),
//               const SizedBox(height: 16),
//               InkWell(
//                 onTap: () async {
//                   final result = await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (context) => WhereToScreen(
//                             category: VehicleCategory.waterBowser,
//                           ),
//                     ),
//                   );

//                   if (result != null && result is LatLng) {
//                     setState(() {
//                       selectedLatLng = result;
//                     });
//                     _getAddressFromLatLng(result);
//                   }
//                 },

//                 //onTap: selectDestination,
//                 child: Container(
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade400),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.location_on_outlined,
//                         color: Colors.blue,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           displayAddress ?? 'Tap to select destination on map',
//                           style: TextStyle(
//                             color:
//                                 displayAddress == null
//                                     ? Colors.grey
//                                     : Colors.black87,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:latlong2/latlong.dart';
// // import 'package:geocoding/geocoding.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// // class WaterBowerScreen extends StatefulWidget {
// //   const WaterBowerScreen({super.key});

// //   @override
// //   _WaterBowserScreenState createState() => _WaterBowserScreenState();
// // }

// // class _WaterBowserScreenState extends State<WaterBowerScreen> {
// //   final TextEditingController detailsController = TextEditingController();
// //   List<String> waterSubcategories = [];
// //   String? selectedSubcategory;
// //   LatLng? selectedLatLng;
// //   String? displayAddress;
// //   bool isLoading = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchSubcategories();
// //   }

// //   Future<void> fetchSubcategories() async {
// //     setState(() => isLoading = true);
// //     try {
// //       final response = await http.get(
// //         Uri.parse(
// //           'https://yourapi.com/api/water-subcategories',
// //         ), // Replace with your actual endpoint
// //       );

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);
// //         setState(() {
// //           waterSubcategories = List<String>.from(data);
// //         });
// //       }
// //     } catch (e) {
// //       debugPrint('Error fetching subcategories: $e');
// //     } finally {
// //       setState(() => isLoading = false);
// //     }
// //   }

// //   Future<void> pickDestination() async {
// //     LatLng tempLatLng = LatLng(-1.286389, 36.817223); // Nairobi default

// //     await showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       builder:
// //           (context) => SizedBox(
// //             height: MediaQuery.of(context).size.height * 0.7,
// //             child: FlutterMap(
// //               options: MapOptions(
// //                 center: tempLatLng,
// //                 zoom: 12.0,
// //                 onTap: (tapPosition, point) {
// //                   Navigator.pop(context, point);
// //                 },
// //               ),
// //               children: [
// //                 TileLayer(
// //                   urlTemplate:
// //                       "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
// //                   subdomains: ['a', 'b', 'c'],
// //                 ),
// //               ],
// //             ),
// //           ),
// //     ).then((pickedPoint) async {
// //       if (pickedPoint != null && pickedPoint is LatLng) {
// //         setState(() {
// //           selectedLatLng = pickedPoint;
// //         });
// //         await _getDisplayAddress(pickedPoint);
// //       }
// //     });
// //   }

// //   Future<void> _getDisplayAddress(LatLng latLng) async {
// //     try {
// //       List<Placemark> placemarks = await placemarkFromCoordinates(
// //         latLng.latitude,
// //         latLng.longitude,
// //       );
// //       if (placemarks.isNotEmpty) {
// //         final placemark = placemarks.first;
// //         setState(() {
// //           displayAddress =
// //               '${placemark.name}, ${placemark.locality}, ${placemark.country}';
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Water Bowser Service'),
// //         centerTitle: true,
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         foregroundColor: Colors.black87,
// //       ),
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               const Text(
// //                 'Request Water Bowser',
// //                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 20),
// //               DropdownButtonFormField<String>(
// //                 value: selectedSubcategory,
// //                 isExpanded: true,
// //                 hint: const Text('Select Water Quantity'),
// //                 items:
// //                     waterSubcategories.map((subcategory) {
// //                       return DropdownMenuItem<String>(
// //                         value: subcategory,
// //                         child: Text(subcategory),
// //                       );
// //                     }).toList(),
// //                 onChanged:
// //                     (value) => setState(() => selectedSubcategory = value),
// //                 decoration: const InputDecoration(
// //                   border: OutlineInputBorder(),
// //                   prefixIcon: Icon(Icons.water_drop),
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //               TextFormField(
// //                 controller: detailsController,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Additional Details (Optional)',
// //                   border: OutlineInputBorder(),
// //                   prefixIcon: Icon(Icons.description),
// //                 ),
// //                 maxLines: 3,
// //               ),
// //               const SizedBox(height: 16),
// //               InkWell(
// //                 onTap:
                
// //                  pickDestination,
// //                 child: Container(
// //                   padding: const EdgeInsets.all(14),
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: Colors.grey.shade400),
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       const Icon(
// //                         Icons.location_on_outlined,
// //                         color: Colors.blue,
// //                       ),
// //                       const SizedBox(width: 12),
// //                       Expanded(
// //                         child: Text(
// //                           displayAddress ?? 'Tap to select destination on map',
// //                           style: TextStyle(
// //                             color:
// //                                 displayAddress == null
// //                                     ? Colors.grey
// //                                     : Colors.black87,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //               const Spacer(),
// //               SizedBox(
// //                 width: double.infinity,
// //                 height: 48,
// //                 child: ElevatedButton.icon(
// //                   onPressed: () {
// //                     if (selectedSubcategory == null || selectedLatLng == null) {
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(
// //                           content: Text(
// //                             'Please select both water quantity and destination.',
// //                           ),
// //                         ),
// //                       );
// //                       return;
// //                     }

// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder:
// //                             (context) => const WhereToScreen(
// //                               category: VehicleCategory.waterBowser,
// //                             ),
// //                       ),
// //                     );
// //                   },
// //                   icon: const Icon(Icons.arrow_forward),
// //                   label: const Text('Proceed to Destination'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.blue.shade700,
// //                     foregroundColor: Colors.white,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// // // class WaterBowerScreen extends StatefulWidget {
// // //   const WaterBowerScreen({super.key});

// // //   @override
// // //   _WaterBowserScreenState createState() => _WaterBowserScreenState();
// // // }

// // // class _WaterBowserScreenState extends State<WaterBowerScreen> {
// // //   final TextEditingController detailsController = TextEditingController();

// // //   List<String> waterSubcategories = [];
// // //   String? selectedSubcategory;
// // //   bool isLoading = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchSubcategories();
// // //   }

// // //   Future<void> fetchSubcategories() async {
// // //     setState(() => isLoading = true);
// // //     try {
// // //       final response = await http.get(
// // //         Uri.parse(
// // //           'https://yourapi.com/api/water-subcategories',
// // //         ), // 🔁 Replace with real endpoint
// // //       );

// // //       if (response.statusCode == 200) {
// // //         final data = jsonDecode(response.body);
// // //         setState(() {
// // //           waterSubcategories = List<String>.from(data);
// // //         });
// // //       } else {
// // //         debugPrint('Failed to load subcategories');
// // //       }
// // //     } catch (e) {
// // //       debugPrint('Error fetching subcategories: $e');
// // //     } finally {
// // //       setState(() => isLoading = false);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Water Bowser Service'),
// // //         centerTitle: true,
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         foregroundColor: Colors.black87,
// // //       ),
// // //       body: SafeArea(
// // //         child: Padding(
// // //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               const Text(
// // //                 'Request Water Bowser',
// // //                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               DropdownButtonFormField<String>(
// // //                 value: selectedSubcategory,
// // //                 isExpanded: true,
// // //                 hint: const Text('Select Water Quantity'),
// // //                 items:
// // //                     waterSubcategories.map((subcategory) {
// // //                       return DropdownMenuItem<String>(
// // //                         value: subcategory,
// // //                         child: Text(subcategory),
// // //                       );
// // //                     }).toList(),
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     selectedSubcategory = value;
// // //                   });
// // //                 },
// // //                 decoration: const InputDecoration(
// // //                   border: OutlineInputBorder(),
// // //                   prefixIcon: Icon(Icons.water_drop_outlined),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 16),
// // //               TextFormField(
// // //                 controller: detailsController,
// // //                 decoration: const InputDecoration(
// // //                   labelText: 'Additional Details (Optional)',
// // //                   border: OutlineInputBorder(),
// // //                   prefixIcon: Icon(Icons.description),
// // //                 ),
// // //                 maxLines: 3,
// // //               ),
// // //               const Spacer(),
// // //               SizedBox(
// // //                 width: double.infinity,
// // //                 height: 48,
// // //                 child: ElevatedButton.icon(
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder:
// // //                             (context) => const WhereToScreen(
// // //                               category: VehicleCategory.waterBowser,
// // //                             ),
// // //                       ),
// // //                     );
// // //                   },
// // //                   icon: const Icon(Icons.arrow_forward),
// // //                   label: const Text('Proceed to Destination'),
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: Colors.blue.shade700,
// // //                     foregroundColor: Colors.white,
// // //                     shape: RoundedRectangleBorder(
// // //                       borderRadius: BorderRadius.circular(12),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // import 'dart:convert';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_map/flutter_map.dart';
// // // // import 'package:latlong2/latlong.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// // // // class WaterBowerScreen extends StatefulWidget {
// // // //   const WaterBowerScreen({super.key});

// // // //   @override
// // // //   _WaterBowserScreenState createState() => _WaterBowserScreenState();
// // // // }

// // // // class _WaterBowserScreenState extends State<WaterBowerScreen> {
// // // //   final TextEditingController requesterNameController = TextEditingController();
// // // //   final TextEditingController detailsController = TextEditingController();
// // // //   LatLng? selectedLocation;

// // // //   List<String> waterSubcategories = [];
// // // //   String? selectedSubcategory;
// // // //   bool isLoading = false;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchSubcategories();
// // // //   }

// // // //   Future<void> fetchSubcategories() async {
// // // //     setState(() => isLoading = true);
// // // //     try {
// // // //       final response = await http.get(
// // // //         Uri.parse(
// // // //           'https://yourapi.com/api/water-subcategories',
// // // //         ), // Replace with real endpoint
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         final data = jsonDecode(response.body);
// // // //         setState(() {
// // // //           waterSubcategories = List<String>.from(data);
// // // //         });
// // // //       } else {
// // // //         // Handle server error
// // // //         debugPrint('Failed to load subcategories');
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('Error fetching subcategories: $e');
// // // //     } finally {
// // // //       setState(() => isLoading = false);
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text('Water Bowser Service'),
// // // //         centerTitle: true,
// // // //         backgroundColor: Colors.white,
// // // //         elevation: 0,
// // // //         foregroundColor: Colors.black87,
// // // //       ),
// // // //       body: SafeArea(
// // // //         child: Padding(
// // // //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               const Text(
// // // //                 'Request Water Bowser',
// // // //                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// // // //               ),
// // // //               const SizedBox(height: 20),
// // // //               TextFormField(
// // // //                 controller: requesterNameController,
// // // //                 decoration: const InputDecoration(
// // // //                   labelText: 'Requester Name',
// // // //                   border: OutlineInputBorder(),
// // // //                   prefixIcon: Icon(Icons.person),
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 16),
// // // //               DropdownButtonFormField<String>(
// // // //                 value: selectedSubcategory,
// // // //                 isExpanded: true,
// // // //                 hint: const Text('Select Water Quantity'),
// // // //                 items:
// // // //                     waterSubcategories.map((subcategory) {
// // // //                       return DropdownMenuItem<String>(
// // // //                         value: subcategory,
// // // //                         child: Text(subcategory),
// // // //                       );
// // // //                     }).toList(),
// // // //                 onChanged: (value) {
// // // //                   setState(() {
// // // //                     selectedSubcategory = value;
// // // //                   });
// // // //                 },
// // // //                 decoration: const InputDecoration(
// // // //                   border: OutlineInputBorder(),
// // // //                   prefixIcon: Icon(Icons.water_drop_outlined),
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 16),
// // // //               TextFormField(
// // // //                 controller: detailsController,
// // // //                 decoration: const InputDecoration(
// // // //                   labelText: 'Additional Details (Optional)',
// // // //                   border: OutlineInputBorder(),
// // // //                   prefixIcon: Icon(Icons.description),
// // // //                 ),
// // // //                 maxLines: 2,
// // // //               ),
// // // //               const SizedBox(height: 16),
// // // //               Expanded(
// // // //                 child: FlutterMap(
// // // //                   options: MapOptions(
// // // //                     center: LatLng(-1.286389, 36.817223), // Nairobi default
// // // //                     zoom: 12.0,
// // // //                     onTap: (tapPosition, point) {
// // // //                       setState(() {
// // // //                         selectedLocation = point;
// // // //                       });
// // // //                     },
// // // //                   ),
// // // //                   children: [
// // // //                     TileLayer(
// // // //                       urlTemplate:
// // // //                           "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
// // // //                       subdomains: ['a', 'b', 'c'],
// // // //                     ),
// // // //                     if (selectedLocation != null)
// // // //                       MarkerLayer(
// // // //                         markers: [
// // // //                           Marker(
// // // //                             point: selectedLocation!,
// // // //                             builder:
// // // //                                 (ctx) => const Icon(
// // // //                                   Icons.location_pin,
// // // //                                   color: Colors.blue,
// // // //                                   size: 36,
// // // //                                 ),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               const SizedBox(height: 12),
// // // //               SizedBox(
// // // //                 width: double.infinity,
// // // //                 height: 48,
// // // //                 child: ElevatedButton.icon(
// // // //                   onPressed: () {
// // // //                     Navigator.push(
// // // //                       context,
// // // //                       MaterialPageRoute(
// // // //                         builder:
// // // //                             (context) => const WhereToScreen(
// // // //                               category: VehicleCategory.waterBowser,
// // // //                             ),
// // // //                       ),
// // // //                     );
// // // //                   },
// // // //                   icon: const Icon(Icons.arrow_forward),
// // // //                   label: const Text('Proceed to Destination'),
// // // //                   style: ElevatedButton.styleFrom(
// // // //                     backgroundColor: Colors.blue.shade700,
// // // //                     foregroundColor: Colors.white,
// // // //                     shape: RoundedRectangleBorder(
// // // //                       borderRadius: BorderRadius.circular(12),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
