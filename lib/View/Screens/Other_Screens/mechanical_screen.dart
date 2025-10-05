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

class Garage {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final double distanceKm;

  Garage({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      id: json['id'],
      name: json['name'],
      lat: json['latitude'],
      lng: json['longitude'],
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
    );
  }
}

class MechanicalScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? destination;

  const MechanicalScreen({super.key, required this.category, this.destination});

  @override
  State<MechanicalScreen> createState() => _MechanicalScreenState();
}

class _MechanicalScreenState extends State<MechanicalScreen> {
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
  // Inside _MechanicalScreenState

  List<Garage> nearbyGarages = [];
  Garage? selectedGarage;

  // Fetch nearest garages
  Future<void> _searchNearestGarages() async {
    if (selectedSubcategory == null || selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select service and location first")),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/mechanics/nearest?lat=${selectedLatLng!.latitude}&lng=${selectedLatLng!.longitude}&serviceId=${selectedSubcategory!.id}&limit=10',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          nearbyGarages = data.map((e) => Garage.fromJson(e)).toList();
        });

        _showGarageSelectionSheet();
      } else {
        debugPrint("Garage search failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error searching garages: $e");
    }
  }

  // Show bottom sheet with garages
  void _showGarageSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView.builder(
          itemCount: nearbyGarages.length,
          itemBuilder: (context, index) {
            final garage = nearbyGarages[index];
            return ListTile(
              leading: const Icon(Icons.home_repair_service, color: Colors.red),
              title: Text(garage.name),
              subtitle: Text("${garage.distanceKm.toStringAsFixed(1)} km away"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showGarageOnMap(garage);
              },
            );
          },
        );
      },
    );
  }

  // Show garage on map with confirm/reject
  void _showGarageOnMap(Garage garage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(garage.lat, garage.lng),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(garage.id.toString()),
                      position: LatLng(garage.lat, garage.lng),
                      infoWindow: InfoWindow(title: garage.name),
                    ),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => selectedGarage = garage);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Confirmed ${garage.name}")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Confirm"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _searchNearestGarages,
                      icon: const Icon(Icons.search),
                      label: const Text("Search Nearest Garages"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
        title: const Text('Mechanical Service'),
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
                    'Request Mechanical Service',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Subcategory>(
                    value: selectedSubcategory,
                    isExpanded: true,
                    hint: const Text('Select Service'),
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
                      labelText: "Service",
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
                      prefixIcon: Icon(Icons.car_crash_outlined),
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

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedSubcategory == null ||
                          selectedLatLng == null) {
                        _showGarageSelectionSheet();
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text(
                        //       'Please complete all required fields',
                        //     ),
                        //     backgroundColor: Colors.red,
                        //   ),
                        // );
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
                      // }
                      // catch (e) {
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
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("Seach Mechanical Services"),
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

//Mechanical Service

// import 'package:flutter/material.dart';

// class MechanicalScreen extends StatelessWidget {
//   const MechanicalScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Mechanical Services",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.red, // Vicsacs theme color
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             _buildServiceCard(
//               context,
//               title: "Emergency Breakdown",
//               subtitle: "24/7 roadside assistance & towing",
//               icon: Icons.build,
//             ),
//             _buildServiceCard(
//               context,
//               title: "Vehicle Diagnostics",
//               subtitle: "Full car check-up & fault analysis",
//               icon: Icons.car_repair,
//             ),
//             _buildServiceCard(
//               context,
//               title: "Tyre & Battery Services",
//               subtitle: "Onsite tyre change & battery replacement",
//               icon: Icons.battery_charging_full,
//             ),
//             _buildServiceCard(
//               context,
//               title: "Scheduled Maintenance",
//               subtitle: "Book regular car servicing",
//               icon: Icons.miscellaneous_services,
//             ),
//             _buildServiceCard(
//               context,
//               title: "Spare Parts",
//               subtitle: "Genuine spare parts ordering",
//               icon: Icons.shopping_cart,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(
//     BuildContext context, {
//     required String title,
//     required String subtitle,
//     required IconData icon,
//   }) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Icon(icon, size: 36, color: Colors.redAccent),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(subtitle),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//         onTap: () {
//           // Navigate to detail/booking page
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text("Selected: $title")));
//         },
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';

// // class MechanicalScreen extends StatelessWidget {
// //   const MechanicalScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         title: const Text('Mechanical Services'),
// //         centerTitle: true,
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         foregroundColor: Colors.black,
// //       ),
// //       body: const Center(
// //         child: Text(
// //           'Welcome to Mechanical Services',
// //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
// //         ),
// //       ),
// //     );
// //   }
// // }
