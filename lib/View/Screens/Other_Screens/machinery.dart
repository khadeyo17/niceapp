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
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/waterexhauster_driver_pending.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

Widget machineryHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
      ],
    ),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            "assets/imgs/crane.png", // <-- put crane image here
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Machinery Service",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "Book heavy machinery with ease",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    ),
  );
}

class MachineryScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? destination;

  const MachineryScreen({super.key, required this.category, this.destination});

  @override
  State<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<MachineryScreen> {
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  List<Subcategory> subcategories = [];
  Subcategory? selectedSubcategory;
  bool _isLoading = false;
  LatLng? selectedLatLng;
  String? displayAddress;
  //Map<String, double> priceMap = {};
  double? selectedPrice;
  final TextEditingController hoursController = TextEditingController();
  double? totalFare;

  @override
  void dispose() {
    detailsController.dispose();
    priceController.dispose();
    hoursController.dispose();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Machinery Service'),
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
                  /// TOP CRANE BANNER
                  machineryHeader(),
                  const SizedBox(height: 24),

                  /// Main Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField<Subcategory>(
                          value: selectedSubcategory,
                          isExpanded: true,
                          hint: const Text('Select Machinery'),
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
                          decoration: InputDecoration(
                            labelText: "Machinery Type",
                            prefixIcon: const Icon(
                              Icons.precision_manufacturing,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Number of Hours',
                            prefixIcon: const Icon(Icons.timer_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: (value) {
                            final hours = double.tryParse(value) ?? 0;
                            if (selectedPrice != null) {
                              setState(() {
                                totalFare = hours * selectedPrice!;
                                priceController.text =
                                    "KES ${totalFare!.toStringAsFixed(2)}";
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: priceController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Estimated Price',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: detailsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Additional Details (Optional)',
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// Modern Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              /// 👇 YOUR EXISTING LOGIC (unchanged)
                              if (selectedSubcategory == null) {
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
                                  await FirebaseAuth.instance.currentUser
                                      ?.getIdToken();

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
                                      content: Text(
                                        'Booking failed: ${response.body}',
                                      ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Confirm and Submit Request",
                              style: TextStyle(
                                fontSize: 16,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Machinery Service'),
  //       centerTitle: true,
  //       backgroundColor: Colors.white,
  //       elevation: 1,
  //       foregroundColor: Colors.black87,
  //     ),
  //     body: Stack(
  //       children: [
  //         SafeArea(
  //           child: SingleChildScrollView(
  //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                   'Request Machinery',
  //                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 DropdownButtonFormField<Subcategory>(
  //                   value: selectedSubcategory,
  //                   isExpanded: true,
  //                   hint: const Text('Select Machinery'),
  //                   items:
  //                       subcategories.map((subcategory) {
  //                         return DropdownMenuItem<Subcategory>(
  //                           value: subcategory,
  //                           child: Text(subcategory.name),
  //                         );
  //                       }).toList(),
  //                   onChanged: (value) {
  //                     setState(() {
  //                       selectedSubcategory = value;
  //                       selectedPrice = value?.baseFare;
  //                       priceController.text =
  //                           selectedPrice != null
  //                               ? 'KES ${selectedPrice!.toStringAsFixed(2)}'
  //                               : '';
  //                     });
  //                   },
  //                   decoration: const InputDecoration(
  //                     labelText: "Machinery Type",
  //                     border: OutlineInputBorder(),
  //                     prefixIcon: Icon(Icons.car_crash_outlined),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),

  //                 TextFormField(
  //                   controller: hoursController,
  //                   keyboardType: TextInputType.number,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Number of Hours',
  //                     border: OutlineInputBorder(),
  //                     prefixIcon: Icon(Icons.timer_outlined),
  //                   ),
  //                   onChanged: (value) {
  //                     final hours = double.tryParse(value) ?? 0;
  //                     if (selectedPrice != null) {
  //                       setState(() {
  //                         totalFare = hours * selectedPrice!;
  //                         priceController.text =
  //                             "KES ${totalFare!.toStringAsFixed(2)}";
  //                       });
  //                     }
  //                   },
  //                 ),

  //                 const SizedBox(height: 20),
  //                 TextFormField(
  //                   controller: priceController,
  //                   readOnly: true,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Estimated Price',
  //                     border: OutlineInputBorder(),
  //                     prefixIcon: Icon(Icons.attach_money),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 TextFormField(
  //                   controller: detailsController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Additional Details (Optional)',
  //                     border: OutlineInputBorder(),
  //                     prefixIcon: Icon(Icons.description_outlined),
  //                   ),
  //                   maxLines: 3,
  //                 ),
  //                 const SizedBox(height: 20),

  //                 ElevatedButton.icon(
  //                   onPressed: () async {
  //                     if (selectedSubcategory == null) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text(
  //                             'Please complete all required fields',
  //                           ),
  //                           backgroundColor: Colors.red,
  //                         ),
  //                       );
  //                       return;
  //                     }

  //                     final token =
  //                         await FirebaseAuth.instance.currentUser?.getIdToken();
  //                     if (token == null) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text('Authentication error'),
  //                           backgroundColor: Colors.red,
  //                         ),
  //                       );
  //                       return;
  //                     }

  //                     final requestBody = {
  //                       "firebaseIdToken": token,
  //                       "destLat": selectedLatLng!.latitude,
  //                       "destLng": selectedLatLng!.longitude,
  //                       "destination": displayAddress ?? '',
  //                       "notes": detailsController.text,
  //                       "subCategoryId": selectedSubcategory?.id,
  //                       "scheduledTime": null,
  //                     };

  //                     try {
  //                       setState(() => _isLoading = true);

  //                       final response = await http.post(
  //                         Uri.parse('$baseUrl/rides/exhauster/book'),
  //                         headers: {'Content-Type': 'application/json'},
  //                         body: jsonEncode(requestBody),
  //                       );

  //                       setState(() => _isLoading = false);

  //                       if (response.statusCode == 200) {
  //                         final data = jsonDecode(response.body);
  //                         final rideId = data['rideId'];

  //                         if (rideId != null && mounted) {
  //                           Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                               builder:
  //                                   (_) => DriverAssignmentsScreen(
  //                                     destination: selectedLatLng!,
  //                                     rideId: rideId,
  //                                     category: selectedSubcategory!,
  //                                     fare: selectedPrice ?? 0,
  //                                   ),
  //                             ),
  //                           );
  //                         }
  //                       } else {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(
  //                             content: Text('Booking failed: ${response.body}'),
  //                             backgroundColor: Colors.red,
  //                           ),
  //                         );
  //                       }
  //                     } catch (e) {
  //                       setState(() => _isLoading = false);
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text(
  //                             'Unexpected error. Please try again.',
  //                           ),
  //                           backgroundColor: Colors.red,
  //                         ),
  //                       );
  //                     }
  //                   },
  //                   icon: const Icon(Icons.send),
  //                   label: const Text("Confirm and Submit Request"),
  //                   style: ElevatedButton.styleFrom(
  //                     padding: const EdgeInsets.symmetric(vertical: 16),
  //                     backgroundColor: Colors.grey[700],
  //                     foregroundColor: Colors.white,
  //                     textStyle: const TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                     minimumSize: const Size.fromHeight(48),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),

  //         /// ✅ Loading overlay
  //         if (_isLoading)
  //           Container(
  //             color: Colors.black.withOpacity(0.5),
  //             child: const Center(
  //               child: CircularProgressIndicator(color: Colors.white),
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }
}
