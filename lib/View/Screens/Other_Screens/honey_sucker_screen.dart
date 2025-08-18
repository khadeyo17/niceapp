import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';

class HoneySuckerScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? destination;

  const HoneySuckerScreen({
    super.key,
    required this.category,
    this.destination,
  });

  @override
  State<HoneySuckerScreen> createState() => _HoneySuckerScreenState();
}

class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  String? displayAddress;
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
        title: const Text('Exhauster Service'),
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
                    'Request Exhauster',
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

class Subcategory {
  final int id;
  final String name;
  final double baseFare;
  final double? pricePerKilometer;

  Subcategory({
    required this.id,
    required this.name,
    required this.baseFare,
    this.pricePerKilometer,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      baseFare: (json['baseFare'] as num).toDouble(),
      pricePerKilometer: (json['baseFare'] as num).toDouble(),
    );
  }
}

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// class HoneySuckerScreen extends StatefulWidget {
//   final VehicleCategory category;
//   final LatLng? destination;

//   const HoneySuckerScreen({
//     super.key,
//     required this.category,
//     this.destination,
//   });

//   @override
//   State<HoneySuckerScreen> createState() => _HoneySuckerScreenState();
// }

// class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
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
//         Uri.parse('https://yourapi.com/api/water-subcategories'),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Exhauster Service'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black87,
//       ),
//       body: SafeArea(
//         child:
//             isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 16,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Request Exhauster',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       /// Quantity Dropdown
//                       DropdownButtonFormField<String>(
//                         value: selectedSubcategory,
//                         isExpanded: true,
//                         hint: const Text('Select Quantity'),
//                         items:
//                             waterSubcategories.map((subcategory) {
//                               return DropdownMenuItem<String>(
//                                 value: subcategory,
//                                 child: Text(subcategory),
//                               );
//                             }).toList(),
//                         onChanged:
//                             (value) =>
//                                 setState(() => selectedSubcategory = value),
//                         decoration: const InputDecoration(
//                           labelText: "Quantity",
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.water_drop_outlined),
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       /// Additional Notes
//                       TextFormField(
//                         controller: detailsController,
//                         decoration: const InputDecoration(
//                           labelText: 'Additional Details (Optional)',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.description_outlined),
//                         ),
//                         maxLines: 3,
//                       ),

//                       const SizedBox(height: 20),

//                       /// Destination Picker
//                       InkWell(
//                         onTap: () async {
//                           final result = await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (context) => WhereToScreen(
//                                     category: VehicleCategory.exhauster,
//                                   ),
//                             ),
//                           );

//                           if (result != null && result is LatLng) {
//                             setState(() {
//                               selectedLatLng = result;
//                             });
//                             _getAddressFromLatLng(result);
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(12),
//                             color: Colors.grey.shade100,
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.location_on_outlined,
//                                 color: Colors.blueAccent,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   displayAddress ??
//                                       'Tap to select destination on map',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color:
//                                         displayAddress == null
//                                             ? Colors.grey
//                                             : Colors.black87,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       /// Submit Button (optional)
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           if (selectedSubcategory == null ||
//                               selectedLatLng == null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                   'Please complete all required fields',
//                                 ),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                             return;
//                           }

//                           // Submit request logic
//                           debugPrint("Submitting request...");
//                         },
//                         icon: const Icon(Icons.send),
//                         label: const Text("Submit Request"),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           backgroundColor: Colors.blueAccent,
//                           textStyle: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           minimumSize: const Size.fromHeight(48),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//       ),
//     );
//   }
// }

// // import 'dart:convert';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:latlong2/latlong.dart';
// // import 'package:geocoding/geocoding.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// // class HoneySuckerScreen extends StatefulWidget {
// //   final VehicleCategory category;
// //   final LatLng? destination;
// //   const HoneySuckerScreen({
// //     super.key,
// //     required this.category,
// //     this.destination,
// //   });

// //   @override
// //   State<HoneySuckerScreen> createState() => _HoneySuckerScreenState();
// // }

// // class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
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

// //     if (widget.destination != null) {
// //       selectedLatLng = widget.destination;
// //       _getAddressFromLatLng(widget.destination!);
// //     }
// //   }

// //   Future<void> fetchSubcategories() async {
// //     setState(() => isLoading = true);
// //     try {
// //       final response = await http.get(
// //         Uri.parse(
// //           'https://yourapi.com/api/water-subcategories',
// //         ), // Replace with your endpoint
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

// //   Future<void> _getAddressFromLatLng(LatLng latLng) async {
// //     try {
// //       final placemarks = await placemarkFromCoordinates(
// //         latLng.latitude,
// //         latLng.longitude,
// //       );
// //       if (placemarks.isNotEmpty) {
// //         final place = placemarks.first;
// //         setState(() {
// //           displayAddress =
// //               "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
// //         });
// //       } else {
// //         setState(() {
// //           displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// //       });
// //       debugPrint("Reverse geocoding failed: $e");
// //     }
// //   }

// //   // Future<void> selectDestination() async {
// //   //   final result = await Navigator.push(
// //   //     context,
// //   //     MaterialPageRoute(
// //   //       builder:
// //   //           (context) =>
// //   //               const WhereToScreen(category: VehicleCategory.waterBowser),
// //   //     ),
// //   //   );

// //   //   if (result != null && result is Map<String, dynamic>) {
// //   //     final latLng = result['latlng'] as LatLng?;
// //   //     final name = result['name'] as String?;

// //   //     setState(() {
// //   //       selectedLatLng = latLng;
// //   //       displayAddress =
// //   //           name ??
// //   //           (latLng != null
// //   //               ? 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}'
// //   //               : null);
// //   //     });
// //   //   }
// //   // }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Exhauster Service'),
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
// //                 'Request Exhauster',
// //                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 20),
// //               DropdownButtonFormField<String>(
// //                 value: selectedSubcategory,
// //                 isExpanded: true,
// //                 hint: const Text('Select Quantity'),
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
// //                 onTap: () async {
// //                   final result = await Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder:
// //                           (context) => WhereToScreen(
// //                             category: VehicleCategory.exhauster,
// //                           ),
// //                     ),
// //                   );

// //                   if (result != null && result is LatLng) {
// //                     setState(() {
// //                       selectedLatLng = result;
// //                     });
// //                     _getAddressFromLatLng(result);
// //                   }
// //                 },

// //                 //onTap: selectDestination,
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
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ignore: file_names
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:latlong2/latlong.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// // //import 'where_to_screen.dart';

// // class HoneySuckerScreen extends StatefulWidget {
// //   const HoneySuckerScreen({super.key, required VehicleCategory category});

// //   @override
// //   _HoneySuckerScreenState createState() => _HoneySuckerScreenState();
// // }

// // class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
// //   final TextEditingController detailsController = TextEditingController();
// //   LatLng? selectedLocation;
// //   LatLng? destinationLocation;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         title: const Text('Honey Sucker Services'),
// //         centerTitle: true,
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         foregroundColor: Colors.black,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               'Request Honey Sucker Service',
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 10),
// //             TextFormField(
// //               controller: detailsController,
// //               decoration: const InputDecoration(labelText: 'Service Details'),
// //               maxLines: 3,
// //             ),
// //             const SizedBox(height: 10),
// //             Expanded(
// //               child: FlutterMap(
// //                 options: MapOptions(
// //                   center: LatLng(-1.286389, 36.817223), // Default to Nairobi
// //                   zoom: 12.0,
// //                   onTap: (tapPosition, point) {
// //                     setState(() {
// //                       if (selectedLocation == null) {
// //                         selectedLocation = point;
// //                       } else {
// //                         destinationLocation = point;
// //                       }
// //                     });
// //                   },
// //                 ),
// //                 children: [
// //                   TileLayer(
// //                     urlTemplate:
// //                         "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
// //                     subdomains: ['a', 'b', 'c'],
// //                   ),
// //                   if (selectedLocation != null)
// //                     MarkerLayer(
// //                       markers: [
// //                         Marker(
// //                           point: selectedLocation!,
// //                           builder:
// //                               (ctx) => const Icon(
// //                                 Icons.location_pin,
// //                                 color: Colors.blue,
// //                                 size: 40,
// //                               ),
// //                         ),
// //                       ],
// //                     ),
// //                   if (destinationLocation != null)
// //                     MarkerLayer(
// //                       markers: [
// //                         Marker(
// //                           point: destinationLocation!,
// //                           builder:
// //                               (ctx) => const Icon(
// //                                 Icons.flag,
// //                                 color: Colors.green,
// //                                 size: 40,
// //                               ),
// //                         ),
// //                       ],
// //                     ),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(height: 10),
// //             ElevatedButton(
// //               onPressed: () {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder:
// //                         (context) => const WhereToScreen(
// //                           category: VehicleCategory.exhauster,
// //                         ),
// //                   ),
// //                 );
// //               },
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.lightBlueAccent,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text('Request Service'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
