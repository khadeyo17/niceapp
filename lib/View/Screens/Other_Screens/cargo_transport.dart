import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/order_details_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/pending_vehicle_assignment.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

/// Modernized CargoTransportScreen
class CargoTransportScreen extends ConsumerStatefulWidget {
  final VehicleCategory category;
  final LatLng? pickup;
  final LatLng? destination;

  const CargoTransportScreen({
    super.key,
    required this.category,
    this.pickup,
    this.destination,
  });

  @override
  ConsumerState<CargoTransportScreen> createState() =>
      _CargoTransportScreenState();
}

class _CargoTransportScreenState extends ConsumerState<CargoTransportScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController receiverMobileController =
      TextEditingController();
  final TextEditingController cargoTypeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController transportDateController = TextEditingController();

  DateTime? transportDate;

  List<VehicleSubCategory> vehicleCategories = [];
  List<FareEstimate?> fareEstimates = [];
  bool isLoadingCategories = true;
  bool showDragSheet = false;
  int selectedIndex = -1;
  double durationInMinutes = 0;
  String? fromLocation;
  String? toLocation;
  double distanceInKm = 0.0;
  List<LatLng> routePoints = [];
  LatLng? pickup;
  LatLng? destination;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  List<Map<String, dynamic>> nearbyTransporters = [];

  // Theme colors kept as requested (yellow + blue local accents)
  final Color primaryColor = Colors.yellow.shade700;
  final Color accentColor = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    transportDateController.text = '';
    // _initializeFromTo();
    // WidgetsBinding.instance.addPostFrameCallback(
    //   (_) => _loadCategoriesAndEstimates(),
    // );
  }

  @override
  void dispose() {
    receiverNameController.dispose();
    cargoTypeController.dispose();
    weightController.dispose();
    volumeController.dispose();
    detailsController.dispose();
    transportDateController.dispose();
    super.dispose();
  }

  // Future<void> bookRide() async {
  //   final user = FirebaseAuth.instance.currentUser;

  //   if (user == null) {
  //     _closeFindingDriverDialog();
  //     print("User not authenticated");
  //     return;
  //   }

  //   try {
  //     final url = '$baseUrl/rides/passenger/request';
  //     final pickupLat = pickup!.latitude;
  //     final pickupLng = pickup!.longitude;
  //     final destLat = destination!.latitude;
  //     final destLng = destination!.longitude;
  //     final subCategoryId = selectedIndex;
  //     final scheduledTime = transportDate;

  //     final body = {
  //       "firebaseIdToken": user.uid,
  //       "pickupLocation": fromLocation,
  //       "destination": toLocation,
  //       "pickupLat": pickupLat,
  //       "pickupLng": pickupLng,
  //       "destLat": destLat,
  //       "destLng": destLng,
  //       "subCategoryId": subCategoryId,
  //       "scheduledTime": scheduledTime?.toIso8601String(),
  //       "transportDate": scheduledTime?.toIso8601String(),
  //       "receiverName": receiverNameController.text,
  //       "receiverPhone": receiverMobileController.text,
  //       "cargoType": cargoTypeController.text,
  //       "weight": weightController.text,
  //       "volume": volumeController.text,
  //       "details": detailsController.text,
  //       "fare": fareEstimates['fare']
  //     };

  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);
  //       final rideId = responseData['rideId'];

  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (_) => OrderDetailsScreen(
  //                 serviceType: widget.category,
  //                 rideId: rideId,
  //                 destination: destination,
  //                 pickup: pickup,
  //               ),
  //         ),
  //       );

  //       // if (scheduledTime == null) {
  //       //   // 👇 Start realtime listener instead of polling
  //       //   listenForDriverAssignment(rideId);
  //       // } else {
  //       //   Navigator.pushReplacement(
  //       //     context,
  //       //     MaterialPageRoute(builder: (_) => RideHistoryScreen()),
  //       //   );
  //       // }
  //     }
  //      else {
  //      // _closeFindingDriverDialog();
  //       print('Failed to book ride: ${response.body}');
  //     }
  //   } catch (e) {
  //    // _closeFindingDriverDialog();
  //     print("Error booking ride: $e");
  //   }
  // }

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("❌ User not authenticated");
      return;
    }

    if (pickup == null || destination == null) {
      print("❌ Pickup or destination missing");
      return;
    }

    try {
      final url =
          '$baseUrl/rides/cargo/request'; // Adjust to your actual endpoint

      final body = {
        "firebaseId": user.uid,
        "pickupLat": pickup!.latitude,
        "pickupLng": pickup!.longitude,
        "destLat": destination!.latitude,
        "destLng": destination!.longitude,
        "pickupLocation": fromLocation ?? "",
        "destination": toLocation ?? "",
        "subCategoryId":
            selectedIndex != -1 ? vehicleCategories[selectedIndex].id : 0,
        "transportDate": transportDate?.toIso8601String(),
        // optional user fields (backend can ignore)
        "receiverName": receiverNameController.text.trim(),
        "receiverPhone": receiverMobileController.text.trim(),
        "cargoType": cargoTypeController.text.trim(),
        "weight": double.tryParse(weightController.text) ?? 0,
        "volume": double.tryParse(volumeController.text) ?? 0,
        "details": detailsController.text.trim(),
        "fare":
            selectedIndex != -1 && fareEstimates[selectedIndex] != null
                ? fareEstimates[selectedIndex]!.fare
                : 0,
      };

      print("📦 Booking body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final rideId = responseData['rideId'] ?? 0;

        print("✅ Ride booked successfully: ID $rideId");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => OrderDetailsScreen(
                  pickup: pickup!,
                  destination: destination!,
                  serviceType: widget.category,
                  // fare: fareEstimates[selectedIndex]?.fare,
                  // receiverName: receiverNameController.text,
                  // cargoType: cargoTypeController.text,
                  // details: detailsController.text,
                  // transportDate: transportDate ?? DateTime.now(),
                  // volume: double.tryParse(volumeController.text),
                  // weight: double.tryParse(weightController.text),
                  // distance: distanceInKm,
                  // phone: receiverMobileController.text,
                ),
          ),
        );
      } else {
        print("❌ Failed to book ride: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print("💥 Error booking ride: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
    }
  }

  Future<void> _initializeFromTo() async {
    if (pickup != null) {
      final fromName = await _getPlaceName(pickup!);
      setState(() => fromLocation = fromName);
    }

    if (destination != null) {
      final toName = await _getPlaceName(destination!);
      setState(() => toLocation = toName);
    }
  }

  Future<void> getRoadDistanceInKm(LatLng pickup, LatLng destination) async {
    const apiKey = mapKey; // 🔐 Replace with your key
    final url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?"
        "origins=${pickup.latitude},${pickup.longitude}"
        "&destinations=${destination.latitude},${destination.longitude}"
        "&mode=driving&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception("❌ HTTP error: ${response.statusCode}");
    }

    final data = json.decode(response.body);
    debugPrint("📦 Distance Matrix API response: $data");

    if (data['status'] == 'OK' &&
        data['rows'] != null &&
        data['rows'].isNotEmpty &&
        data['rows'][0]['elements'] != null &&
        data['rows'][0]['elements'].isNotEmpty &&
        data['rows'][0]['elements'][0]['status'] == 'OK') {
      final element = data['rows'][0]['elements'][0];
      final distanceMeters = element['distance']['value'];
      final durationSeconds = element['duration']['value'];

      setState(() {
        distanceInKm = distanceMeters / 1000;
        durationInMinutes = durationSeconds / 60;
      });

      debugPrint("✅ Distance: ${distanceInKm.toStringAsFixed(2)} km");
      debugPrint("✅ Duration: ${durationInMinutes.toStringAsFixed(1)} min");
    } else {
      throw Exception(
        "❌ Invalid Distance Matrix API response: ${data['status']}",
      );
    }
  }

  Future<List<VehicleSubCategory>> fetchVehicleSubCategories(int type) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rides/categories?type=$type'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final List<dynamic> allSubCategories =
          jsonList
              .expand((category) => category['subCategories'] ?? [])
              .toList();
      return allSubCategories
          .map((e) => VehicleSubCategory.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load vehicle categories');
    }
  }

  Future<String> _getPlaceName(LatLng coords) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );
      final p = placemarks.first;
      return "${p.name ?? ''}, ${p.locality ?? p.subAdministrativeArea ?? ''}, ${p.country ?? ''}"
          .replaceAll(RegExp(r',\s*$'), '');
    } catch (e) {
      return "Location not found";
    }
  }

  Future<void> _selectTransportDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() {
        transportDate = picked;
        transportDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _openWhereTo() async {
    if (receiverNameController.text.isEmpty ||
        cargoTypeController.text.isEmpty ||
        weightController.text.isEmpty ||
        volumeController.text.isEmpty ||
        volumeController.text.isEmpty ||
        transportDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill in all required fields before proceeding.",
          ),
        ),
      );
      return;
    }
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(receiverMobileController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid phone number (e.g. +254712345678).",
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => const WhereToScreen(category: VehicleCategory.cargo),
      ),
    );
    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      pickup = result['pickup'] as LatLng?;
      destination = result['destination'] as LatLng?;

      if (pickup != null && destination != null) {
        setState(() {
          fromLocation = result['from'] ?? fromLocation;
          toLocation = result['to'] ?? toLocation;
        });

        if (pickup != null) {
          final fromName = await _getPlaceName(pickup!);
          setState(() => fromLocation = fromName);
        }

        if (destination != null) {
          final toName = await _getPlaceName(destination!);
          setState(() => toLocation = toName);
        }
        // 👇 Show draggable sheet instantly (while loading)
        setState(() {
          showDragSheet = true;
          isLoadingCategories = true;
        });

        // 👇 Add a small delay so UI shows the sheet smoothly
        await Future.delayed(const Duration(milliseconds: 300));

        // pickup = pickup;
        //await _fetchRoute();
        await getRoadDistanceInKm(pickup!, destination!);

        await _loadCategoriesAndEstimates();
        // setState(() {
        //   showDragSheet = true;
        //   isLoadingCategories = true;
        // });
      }
    }
  }

  Future<void> _loadCategoriesAndEstimates() async {
    try {
      debugPrint(">>> Fetching vehicle subcategories...");
      final categories = await fetchVehicleSubCategories(widget.category.index);
      debugPrint(">>> Categories fetched: ${categories.length}");

      fareEstimates = List<FareEstimate?>.filled(categories.length, null);
      setState(() {
        vehicleCategories = categories;
        isLoadingCategories = false;
        if (categories.isNotEmpty) {
          selectedIndex = 0;
          ref.read(selectedCategoryProvider.notifier).state = categories[0];
        }
      });

      if (pickup != null && destination != null) {
        debugPrint(">>> Getting road distance...");

        debugPrint(">>> Road distance fetched: $distanceInKm km");

        if (categories.isEmpty) {
          debugPrint("⚠️ No categories found. Skipping fare fetch.");
          return;
        }

        for (int i = 0; i < categories.length; i++) {
          final category = categories[i];
          debugPrint(">>> Fetching fare estimate for: ${category.name}");
          try {
            final estimate = await FareService.getFareEstimate(
              categoryId: category.id,
              pickupLat: pickup!.latitude,
              pickupLng: pickup!.longitude,
              destLat: destination!.latitude,
              destLng: destination!.longitude,
              distanceKm: distanceInKm,
              countryCode: "KE",
            );
            setState(() => fareEstimates[i] = estimate);
            debugPrint("✅ Fare fetched for ${category.name}: ${estimate.fare}");
          } catch (e) {
            debugPrint('❌ Failed to fetch fare for ${category.name}: $e');
          }
        }
      } else {
        debugPrint("⚠️ Pickup or destination is null.");
      }
    } catch (e) {
      debugPrint('💥 Error loading categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  void _showNearbyTransportersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child:
              nearbyTransporters.isEmpty
                  ? const SizedBox(
                    height: 120,
                    child: Center(child: Text("No nearby transporters found.")),
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nearby Transporters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...nearbyTransporters.map((t) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(t['name'] ?? 'Transporter'),
                            subtitle: Text(
                              'Distance: ${t['distance_km'] ?? '-'} km',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context),
                          ),
                        );
                      }),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildCardInput({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onTap: onTap,
      validator:
          required
              ? (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              }
              : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedFare =
        (selectedIndex >= 0 && selectedIndex < fareEstimates.length)
            ? fareEstimates[selectedIndex]?.fare ?? 0.0
            : 0.0;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Transport'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Hero image (1/4 of screen)

            // Form area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.18,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
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
                                  image: AssetImage(
                                    'assets/imgs/CargoTruck.jpg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            Positioned(
                              left: 20,
                              bottom: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Book Cargo Transport',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fast, reliable cargo delivery',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ClipRRect(
                            //   borderRadius: const BorderRadius.vertical(
                            //     bottom: Radius.circular(20),
                            //   ),
                            //   child: Image.asset(
                            //     'assets/imgs/CargoTruck.jpg', // replace with your asset
                            //     fit: BoxFit.cover,
                            //   ),
                            // ),
                            // Container(
                            //   decoration: BoxDecoration(
                            //     borderRadius: const BorderRadius.vertical(
                            //       bottom: Radius.circular(20),
                            //     ),
                            //     gradient: LinearGradient(
                            //       colors: [
                            //         Colors.black.withOpacity(0.12),
                            //         Colors.transparent,
                            //       ],
                            //       begin: Alignment.topCenter,
                            //       end: Alignment.bottomCenter,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      _buildCardInput(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cargo Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              receiverNameController,
                              'Receiver Name',
                              required: true,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              receiverMobileController,
                              'Receiver Phone',
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              cargoTypeController,
                              'Type of Cargo',
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    weightController,
                                    'Weight (Kg)',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    required: true,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextField(
                                    volumeController,
                                    'Volume (m³)',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    required: true,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTransportDate(context),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  transportDateController,
                                  'Transportation Date',
                                  readOnly: true,
                                  required: true,
                                  onTap: () => _selectTransportDate(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              detailsController,
                              'Additional Details (Optional)',
                              maxLines: 3,
                              required: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      _buildCardInput(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup & Destination',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _openWhereTo,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fromLocation ??
                                                'Tap to select pickup',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            toLocation ??
                                                'Tap to select destination',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (distanceInKm > 0)
                              Text(
                                'Distance: $distanceInKm km',
                                style: const TextStyle(color: Colors.black54),
                              ),
                          ],
                        ),
                      ),

                      // Search Transport button
                      // ElevatedButton.icon(
                      //   onPressed: () async {
                      //     // validate pickup & destination
                      //     if (fromLocation == null || toLocation == null) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //           content: Text(
                      //             'Please select pickup & destination',
                      //           ),
                      //         ),
                      //       );
                      //       return;
                      //     }
                      //     setState(() {
                      //       showDragSheet = true;
                      //       isLoadingCategories = true;
                      //     });
                      //     await _loadCategoriesAndEstimates();
                      //   },
                      //   icon: const Icon(Icons.search),
                      //   label: const Text('Search Transporters'),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: accentColor,
                      //     foregroundColor: Colors.white,
                      //     padding: const EdgeInsets.symmetric(vertical: 14),
                      //     textStyle: const TextStyle(
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Draggable sheet for categories when available
      bottomSheet: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder:
            (child, animation) => SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
        child:
            showDragSheet
                ? DraggableScrollableSheet(
                  key: const ValueKey('sheet'),
                  initialChildSize: 0.42,
                  minChildSize: 0.28,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    // ... existing code inside sheet

                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Available Vehicle Options',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (distanceInKm > 0)
                                  Text(
                                    '$distanceInKm km',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child:
                                isLoadingCategories
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      itemCount: vehicleCategories.length,
                                      itemBuilder: (context, index) {
                                        final category =
                                            vehicleCategories[index];
                                        final estimate =
                                            (index < fareEstimates.length)
                                                ? fareEstimates[index]
                                                : null;
                                        final fareDisplay =
                                            estimate != null
                                                ? "${estimate.currency} ${estimate.fare.toStringAsFixed(2)}"
                                                : "Estimating...";
                                        final etaDisplay =
                                            estimate != null
                                                ? "${estimate.timeEstimate} mins"
                                                : "Est.";
                                        final isSelected =
                                            selectedIndex == index;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedIndex = index;
                                              ref
                                                  .read(
                                                    selectedCategoryProvider
                                                        .notifier,
                                                  )
                                                  .state = category;
                                            });
                                          },
                                          child: Card(
                                            elevation: isSelected ? 6 : 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  // icon or asset
                                                  category.iconUrl != null &&
                                                          category
                                                              .iconUrl!
                                                              .isNotEmpty
                                                      ? Image.network(
                                                        "$ImageUrl${category.iconUrl}",
                                                        width: 56,
                                                        height: 56,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Image.asset(
                                                              'assets/imgs/Sedan2.png',
                                                              width: 56,
                                                              height: 56,
                                                            ),
                                                      )
                                                      : Image.asset(
                                                        'assets/imgs/Sedan2.png',
                                                        width: 56,
                                                        height: 56,
                                                      ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              category.name,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            Text(
                                                              fareDisplay,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              etaDisplay,
                                                              style:
                                                                  const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              "${category.maxPassengers} Pax",
                                                              style:
                                                                  const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      // ensure transportDate
                                                      if (transportDate ==
                                                          null) {
                                                        transportDate =
                                                            DateTime.now().add(
                                                              const Duration(
                                                                hours: 1,
                                                              ),
                                                            );
                                                      }
                                                      final est =
                                                          fareEstimates[index];
                                                      if (est == null) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Fare estimate not available yet',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      bookRide();

                                                      // Navigate to pending assignment screen
                                                      // Navigator.push(
                                                      //   context,
                                                      //   MaterialPageRoute(
                                                      //     builder:
                                                      //         (
                                                      //           _,
                                                      //         ) => PendingDriverAssignmentScreen(
                                                      //           pickup:
                                                      //               widget
                                                      //                   .pickup ??
                                                      //               LatLng(
                                                      //                 0,
                                                      //                 0,
                                                      //               ),
                                                      //           destination:
                                                      //               widget
                                                      //                   .destination ??
                                                      //               LatLng(
                                                      //                 0,
                                                      //                 0,
                                                      //               ),
                                                      //           category:
                                                      //               category,
                                                      //           fare: est.fare,
                                                      //           receiverName:
                                                      //               receiverNameController
                                                      //                   .text,
                                                      //           cargoType:
                                                      //               cargoTypeController
                                                      //                   .text,
                                                      //           details:
                                                      //               detailsController
                                                      //                   .text,
                                                      //           transportDate:
                                                      //               transportDate ??
                                                      //               DateTime.now(),
                                                      //           volume:
                                                      //               double.tryParse(
                                                      //                 volumeController
                                                      //                     .text,
                                                      //               ) ??
                                                      //               0,
                                                      //           weight:
                                                      //               double.tryParse(
                                                      //                 weightController
                                                      //                     .text,
                                                      //               ) ??
                                                      //               0,
                                                      //         ),
                                                      //   ),
                                                      // );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          primaryColor,
                                                      foregroundColor:
                                                          Colors.black87,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text('Select'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    );
                  },
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}

  // import 'dart:convert';

  // import 'package:flutter/material.dart';
  // import 'package:flutter/services.dart';
  // import 'package:flutter_riverpod/flutter_riverpod.dart';
  // import 'package:geocoding/geocoding.dart';
  // import 'package:geolocator/geolocator.dart';
  // import 'package:google_maps_flutter/google_maps_flutter.dart';
  // import 'package:http/http.dart' as http;
  // import 'package:intl/intl.dart';
  // import 'package:niceapp/Container/utils/keys.dart';
  // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
  // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
  // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
  // import 'package:niceapp/View/Screens/Other_Screens/pending_vehicle_assignment.dart';
  // import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
  // import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
  // import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

  // class CargoTransportScreen extends ConsumerStatefulWidget {
  //   //class CargoTransportScreen extends StatefulWidget {
  //   final VehicleCategory category;
  //   final LatLng? pickup;
  //   final LatLng? destination;

  //   const CargoTransportScreen({
  //     super.key,
  //     required this.category,
  //     this.pickup,
  //     this.destination,
  //   });

  //   @override
  //   //class _CargoTransportScreenState extends ConsumerState<CargoTransportScreen>
  //   //State<CargoTransportScreen> createState() => _CargoTransportScreenState();
  //   ConsumerState<CargoTransportScreen> createState() =>
  //       _CargoTransportScreenState();
  // }

  // class _CargoTransportScreenState extends ConsumerState<CargoTransportScreen> {
  //   //class _CargoTransportScreenState extends State<CargoTransportScreen> {
  //   final _formKey = GlobalKey<FormState>();
  //   final TextEditingController senderNameController = TextEditingController();
  //   final TextEditingController receiverNameController = TextEditingController();
  //   final TextEditingController cargoTypeController = TextEditingController();
  //   final TextEditingController weightController = TextEditingController();
  //   final TextEditingController volumeController = TextEditingController();
  //   final TextEditingController detailsController = TextEditingController();

  //   DateTime? transportDate;
  //   final transportDateController = TextEditingController();
  //   //final TextEditingController transportDateController = TextEditingController();

  //   List<VehicleSubCategory> vehicleCategories = [];
  //   List<FareEstimate?> fareEstimates = [];
  //   bool isLoadingCategories = true;
  //   bool showdrag = false;
  //   int selectedIndex = -1;

  //   String? fromLocation;
  //   String? toLocation;
  //   double distanceInKm = 0.0;

  //   List<Map<String, dynamic>> nearbyTransporters = [];

  //   @override
  //   void initState() {
  //     super.initState();
  //     transportDateController.text = '';
  //     _initializeLocationNames();
  //     WidgetsBinding.instance.addPostFrameCallback((_) async {
  //       final categories = await fetchVehicleSubCategories(widget.category.index);
  //       fareEstimates = List<FareEstimate?>.filled(categories.length, null);

  //       setState(() {
  //         vehicleCategories = categories;
  //         fareEstimates = List<FareEstimate?>.filled(categories.length, null);
  //         isLoadingCategories = false;

  //         if (categories.isNotEmpty) {
  //           selectedIndex = 0;
  //           ref.read(selectedCategoryProvider.notifier).state = categories[0];
  //         }
  //       });
  //       if (widget.pickup != null && widget.destination != null) {
  //         for (int i = 0; i < categories.length; i++) {
  //           final category = categories[i];
  //           try {
  //             final estimate = await FareService.getFareEstimate(
  //               categoryId: category.id,
  //               pickupLat: widget.pickup!.latitude,
  //               pickupLng: widget.pickup!.longitude,
  //               destLat: widget.destination!.latitude,
  //               destLng: widget.destination!.longitude,
  //               countryCode: "KE",
  //             );
  //             print('Received estimate for ${category.name}: $estimate');
  //             setState(() {
  //               fareEstimates[i] = estimate;
  //             });
  //           } catch (e) {
  //             print('Failed to load fare for category ${category.name}: $e');
  //           }
  //         }
  //       }
  //     });
  //   }

  //   Future<void> _initializeLocationNames() async {
  //     if (widget.pickup != null) {
  //       final fromName = await _getPlaceName(widget.pickup!);
  //       setState(() => fromLocation = fromName);
  //     }

  //     if (widget.destination != null) {
  //       final toName = await _getPlaceName(widget.destination!);
  //       setState(() => toLocation = toName);
  //     }

  //     if (widget.pickup != null && widget.destination != null) {
  //       // final distance = Distance().as(
  //       //   LengthUnit.Kilometer,
  //       //   widget.pickup!,
  //       //   widget.destination!,
  //       // );
  //       final distance = Geolocator.distanceBetween(
  //         widget.pickup!.latitude,
  //         widget.pickup!.longitude,
  //         widget.destination!.latitude,
  //         widget.destination!.longitude,
  //       );

  //       var distanceInKm = distance / 1000;

  //       setState(
  //         () => distanceInKm = double.parse(distanceInKm.toStringAsFixed(2)),
  //       );
  //     }
  //   }

  //   Future<void> _selectTransportDate(BuildContext context) async {
  //     DateTime? picked = await showDatePicker(
  //       context: context,
  //       initialDate: DateTime.now().add(const Duration(minutes: 30)),
  //       firstDate: DateTime.now(),
  //       lastDate: DateTime.now().add(const Duration(days: 60)),
  //     );

  //     if (picked != null) {
  //       setState(() {
  //         transportDate = picked;
  //         transportDateController.text = DateFormat('yyyy-MM-dd').format(picked);
  //       });
  //     }

  //     // final DateTime? selectedDate = await showDatePicker(
  //     //   context: context,
  //     //   initialDate: DateTime.now().add(Duration(minutes: 30)),
  //     //   firstDate: DateTime.now(),
  //     //   lastDate: DateTime.now().add(Duration(days: 60)),
  //     // );
  //     // if (selectedDate != null) {
  //     //   setState(() {
  //     //     transportDate = selectedDate;
  //     //     transportDateController.text = DateFormat(
  //     //       'yyyy-MM-dd',
  //     //     ).format(selectedDate);
  //     //   });
  //     // }
  //   }

  //   Future<List<VehicleSubCategory>> fetchVehicleSubCategories(int type) async {
  //     final response = await http.get(
  //       Uri.parse(
  //         '$baseUrl/rides/categories?type=$type',
  //       ), // e.g., type=0 for RideBooking
  //     );

  //     if (response.statusCode == 200) {
  //       final List<dynamic> jsonList = json.decode(response.body);

  //       // Flatten all subCategories from all categories
  //       final List<dynamic> allSubCategories =
  //           jsonList
  //               .expand((category) => category['subCategories'] ?? [])
  //               .toList();

  //       return allSubCategories
  //           .map((e) => VehicleSubCategory.fromJson(e))
  //           .toList();
  //     } else {
  //       throw Exception('Failed to load vehicle categories');
  //     }
  //   }

  //   Future<String> _getPlaceName(LatLng coords) async {
  //     try {
  //       final placemarks = await placemarkFromCoordinates(
  //         coords.latitude,
  //         coords.longitude,
  //       );
  //       final place = placemarks.first;
  //       return "${place.name}, ${place.locality}, ${place.country}";
  //     } catch (e) {
  //       return "Location not found";
  //     }
  //   }

  //   void _showTransporterOptions() {
  //     showModalBottomSheet(
  //       context: context,
  //       shape: const RoundedRectangleBorder(
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //       ),
  //       builder: (_) {
  //         return Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child:
  //               nearbyTransporters.isEmpty
  //                   ? const Text("No nearby transporters found.")
  //                   : Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       const Text(
  //                         "Nearby Transporters",
  //                         style: TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 10),
  //                       ...nearbyTransporters.map((transporter) {
  //                         return Card(
  //                           child: ListTile(
  //                             title: Text(transporter['name']),
  //                             subtitle: Text(
  //                               "Distance: ${transporter['distance_km']} km",
  //                             ),
  //                             trailing: const Icon(Icons.chevron_right),
  //                           ),
  //                         );
  //                       }),
  //                     ],
  //                   ),
  //         );
  //       },
  //     );
  //   }

  //   // void dispose() {
  //   //   transportDateController.dispose();
  //   //   super.dispose();
  //   // }

  //   @override
  //   Widget build(BuildContext context) {
  //     final selectedCategory = ref.watch(selectedCategoryProvider);
  //     final selectedFare =
  //         (selectedIndex >= 0 && selectedIndex < fareEstimates.length)
  //             ? fareEstimates[selectedIndex]?.fare ?? 0.0
  //             : 0.0;
  //     return Scaffold(
  //       appBar: AppBar(
  //         title: const Text('Cargo Transport'),
  //         centerTitle: true,
  //         backgroundColor: Colors.white,
  //         elevation: 1,
  //         foregroundColor: Colors.black,
  //       ),
  //       body: Stack(
  //         children: [
  //           SafeArea(
  //             child: Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //               child: Form(
  //                 key: _formKey,
  //                 child: ListView(
  //                   children: [
  //                     const Text(
  //                       'Book Cargo Transport',
  //                       style: TextStyle(
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 20),

  //                     // Pickup (read-only)
  //                     TextFormField(
  //                       controller: TextEditingController(
  //                         text: fromLocation ?? '',
  //                       ),
  //                       readOnly: true,
  //                       decoration: InputDecoration(
  //                         labelText: "Pickup Location",
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),

  //                     // Destination (editable)
  //                     TextFormField(
  //                       controller: TextEditingController(text: toLocation ?? ''),
  //                       onTap: () async {
  //                         final result = await Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder:
  //                                 (context) => const WhereToScreen(
  //                                   category: VehicleCategory.cargo,
  //                                 ),
  //                           ),
  //                         );
  //                         if (result != null && result is Map<String, dynamic>) {
  //                           setState(() {
  //                             fromLocation = result['from'];
  //                             toLocation = result['to'];
  //                           });
  //                           await _initializeLocationNames();
  //                           await fetchVehicleSubCategories(
  //                             widget.category.index,
  //                           );
  //                         }
  //                       },
  //                       readOnly: true,
  //                       decoration: InputDecoration(
  //                         labelText: "Destination Location",
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                       ),
  //                     ),

  //                     const SizedBox(height: 20),

  //                     // _buildTextField(senderNameController, 'Sender Name'),
  //                     _buildTextField(receiverNameController, 'Receiver Name'),
  //                     _buildTextField(cargoTypeController, 'Type of Cargo'),
  //                     _buildTextField(
  //                       weightController,
  //                       'Weight (Kg)',
  //                       keyboardType: const TextInputType.numberWithOptions(
  //                         decimal: true,
  //                       ),
  //                       inputFormatters: [
  //                         FilteringTextInputFormatter.allow(
  //                           RegExp(r'^\d+\.?\d{0,2}'),
  //                         ),
  //                       ],
  //                     ),
  //                     _buildTextField(
  //                       volumeController,
  //                       'Volume (e.g. 5 cubic meters)',
  //                       keyboardType: const TextInputType.numberWithOptions(
  //                         decimal: true,
  //                       ),
  //                       inputFormatters: [
  //                         FilteringTextInputFormatter.allow(
  //                           RegExp(r'^\d+\.?\d{0,2}'),
  //                         ),
  //                       ],
  //                     ),
  //                     GestureDetector(
  //                       onTap: () => _selectTransportDate(context),
  //                       child: AbsorbPointer(
  //                         child: _buildTextField(
  //                           transportDateController,
  //                           'Transportation Date',
  //                           //Icons.date_range,
  //                         ),
  //                       ),
  //                     ),

  //                     _buildTextField(
  //                       detailsController,
  //                       'Additional Details (Optional)',
  //                       maxLines: 3,
  //                       required: false,
  //                     ),

  //                     // const SizedBox(height: 20),
  //                     // const Divider(),

  //                     // const Text(
  //                     //   'Delivery Route',
  //                     //   style: TextStyle(
  //                     //     fontSize: 18,
  //                     //     fontWeight: FontWeight.w600,
  //                     //   ),
  //                     // ),
  //                     // const SizedBox(height: 12),

  //                     // if (distanceInKm != null)
  //                     //   Padding(
  //                     //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //                     //     child: Text(
  //                     //     "Distance: $distanceInKm km",
  //                     //       style: const TextStyle(
  //                     //         fontSize: 16,
  //                     //         fontWeight: FontWeight.w500,
  //                     //       ),
  //                     //     ),
  //                     //   ),
  //                     // const SizedBox(height: 12),

  //                     // _buildInfoRow('From', fromLocation),
  //                     // const SizedBox(height: 10),
  //                     // _buildInfoRow('To', toLocation),
  //                     // const SizedBox(height: 10),
  //                     FilledButton.icon(
  //                       onPressed: () async {
  //                         // final result = await Navigator.push(
  //                         //   context,
  //                         //   MaterialPageRoute(
  //                         //     builder:
  //                         //         (context) => const WhereToScreen(
  //                         //           category: VehicleCategory.cargo,
  //                         //         ),
  //                         //   ),
  //                         // );

  //                         // if (result != null && result is Map<String, dynamic>) {
  //                         //   setState(() {
  //                         //     fromLocation = result['from'];
  //                         //     toLocation = result['to'];
  //                         //   });

  //                         // Calculate distance & fetch transporters
  //                         // showdrag = true;
  //                         // //await _initializeLocationNames();
  //                         // await fetchVehicleSubCategories(widget.category.index);
  //                         setState(() => showdrag = true);
  //                         await fetchVehicleSubCategories(widget.category.index);
  //                       },

  //                       icon: const Icon(Icons.location_on),
  //                       label: const Text("Search Transport"),
  //                       style: FilledButton.styleFrom(
  //                         backgroundColor: Colors.grey[700],
  //                         foregroundColor: Colors.white,
  //                         padding: const EdgeInsets.symmetric(vertical: 14),
  //                       ),
  //                     ),
  //                     //final Spacer();
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),

  //           if (showdrag)
  //             DraggableScrollableSheet(
  //               initialChildSize: 0.4, // 40% of screen height
  //               minChildSize:
  //                   0.25, // Never collapse below 25% (ensures 1 category is visible)
  //               maxChildSize: 0.8, // Optional, can grow up to 80%
  //               builder: (context, scrollController) {
  //                 return Container(
  //                   decoration: const BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.vertical(
  //                       top: Radius.circular(20),
  //                     ),
  //                     boxShadow: [
  //                       BoxShadow(color: Colors.black26, blurRadius: 10),
  //                     ],
  //                   ),
  //                   child: Column(
  //                     children: [
  //                       Expanded(
  //                         child: ListView.builder(
  //                           controller: scrollController,
  //                           //itemCount: vehicleCategories.length,
  //                           itemCount:
  //                               isLoadingCategories
  //                                   ? 0
  //                                   : vehicleCategories.length,
  //                           padding: const EdgeInsets.all(12),

  //                           itemBuilder: (context, index) {
  //                             final category = vehicleCategories[index];
  //                             final name = category.name;
  //                             final passengers = category.maxPassengers;
  //                             final isSelected = selectedIndex == index;
  //                             //new

  //                             // if (fareEstimates.isNotEmpty &&
  //                             //     index < fareEstimates.length) {
  //                             //   final estimate = fareEstimates[index];
  //                             //   // proceed
  //                             // } else {
  //                             //   // Handle empty or invalid state gracefully
  //                             // }
  //                             final estimate = fareEstimates[index];

  //                             final fareDisplay =
  //                                 estimate != null
  //                                     ? "${estimate.currency} ${estimate.fare.toStringAsFixed(2)}"
  //                                     : "Loading...";

  //                             // FareEstimate? estimate;
  //                             // String fareDisplay = "Loading...";

  //                             // if (fareEstimates.isNotEmpty &&
  //                             //     index < fareEstimates.length) {
  //                             //   estimate = fareEstimates[index];
  //                             //   fareDisplay =
  //                             //       "${"Kes"} ${estimate!.fare.toStringAsFixed(2)}";
  //                             // } else {
  //                             //   // Optionally handle fallback
  //                             //   estimate = null;
  //                             //   fareDisplay = "Loading...";
  //                             // }

  //                             final timeAway =
  //                                 estimate != null
  //                                     ? "${estimate.timeEstimate} mins"
  //                                     : "Estimating...";

  //                             return GestureDetector(
  //                               onTap: () {
  //                                 setState(() {
  //                                   selectedIndex = index;
  //                                 });
  //                                 ref
  //                                     .read(selectedCategoryProvider.notifier)
  //                                     .state = category;

  //                                 //  ref.read(selectedCategoryProvider.notifier).state = category;
  //                               },
  //                               child: Container(
  //                                 margin: const EdgeInsets.only(bottom: 12),
  //                                 padding: const EdgeInsets.all(8),
  //                                 decoration: BoxDecoration(
  //                                   color: Colors.white,
  //                                   border: Border.all(
  //                                     color:
  //                                         isSelected
  //                                             ? Colors.grey
  //                                             : Colors.transparent,
  //                                     width: 2,
  //                                   ),
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                                 child: Row(
  //                                   children: [
  //                                     category.iconUrl != null &&
  //                                             category.iconUrl!.isNotEmpty
  //                                         ? Image.network(
  //                                           "$ImageUrl${category.iconUrl}",
  //                                           //category.iconUrl!,
  //                                           width: 60,
  //                                           height: 60,
  //                                           errorBuilder: (
  //                                             context,
  //                                             error,
  //                                             stackTrace,
  //                                           ) {
  //                                             return Image.asset(
  //                                               'assets/imgs/Sedan2.png', // your fallback image
  //                                               width: 60,
  //                                               height: 60,
  //                                             );
  //                                           },
  //                                         )
  //                                         : Image.asset(
  //                                           'assets/imgs/Sedan2.png',
  //                                           width: 60,
  //                                           height: 60,
  //                                         ),

  //                                     const SizedBox(width: 12),
  //                                     Expanded(
  //                                       child: Column(
  //                                         crossAxisAlignment:
  //                                             CrossAxisAlignment.start,
  //                                         children: [
  //                                           Row(
  //                                             mainAxisAlignment:
  //                                                 MainAxisAlignment.spaceBetween,
  //                                             children: [
  //                                               Text(
  //                                                 name,
  //                                                 style: const TextStyle(
  //                                                   fontWeight: FontWeight.bold,
  //                                                   fontSize: 16,
  //                                                 ),
  //                                               ),
  //                                               Text(
  //                                                 fareDisplay,
  //                                                 style: const TextStyle(
  //                                                   fontWeight: FontWeight.bold,
  //                                                   fontSize: 16,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                           const SizedBox(height: 4),
  //                                           // Text(
  //                                           //   "$timeAway",
  //                                           //   style: const TextStyle(
  //                                           //     color: Colors.grey,
  //                                           //     fontSize: 13,
  //                                           //   ),
  //                                           // ),
  //                                           Text(
  //                                             timeAway,
  //                                             style: const TextStyle(
  //                                               color: Colors.grey,
  //                                               fontSize: 13,
  //                                             ),
  //                                           ),
  //                                           const SizedBox(height: 4),
  //                                           Text(
  //                                             "$passengers Passengers",
  //                                             style: const TextStyle(
  //                                               color: Colors.grey,
  //                                               fontSize: 13,
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                       ),
  //                       Consumer(
  //                         builder: (context, ref, child) {
  //                           final selected = ref.watch(selectedCategoryProvider);
  //                           final index = selectedIndex;
  //                           final isEnabled = selected != null;
  //                           final category = selected?.name ?? 'N/A';

  //                           return Padding(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 12,
  //                               vertical: 12,
  //                             ),
  //                             child: SizedBox(
  //                               width: double.infinity,
  //                               child: ElevatedButton(
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: Colors.green.shade600,
  //                                   foregroundColor: Colors.white,
  //                                 ),
  //                                 onPressed:
  //                                     isEnabled &&
  //                                             index >= 0 &&
  //                                             index < fareEstimates.length
  //                                         ? () {
  //                                           if (transportDate == null) {
  //                                             transportDate =
  //                                                 DateTime.timestamp();
  //                                           }
  //                                           final estimate = fareEstimates[index];
  //                                           if (estimate != null) {
  //                                             Navigator.push(
  //                                               context,
  //                                               MaterialPageRoute(
  //                                                 builder:
  //                                                     (
  //                                                       _,
  //                                                     ) => PendingDriverAssignmentScreen(
  //                                                       pickup: widget.pickup!,
  //                                                       destination:
  //                                                           widget.destination!,
  //                                                       category: selected!,
  //                                                       fare: estimate.fare,
  //                                                       receiverName:
  //                                                           receiverNameController
  //                                                               .text,
  //                                                       cargoType:
  //                                                           cargoTypeController
  //                                                               .text,
  //                                                       details:
  //                                                           detailsController
  //                                                               .text,
  //                                                       transportDate:
  //                                                           transportDate!,

  //                                                       volume:
  //                                                           double.tryParse(
  //                                                             volumeController
  //                                                                 .text,
  //                                                           ) ??
  //                                                           0,
  //                                                       weight:
  //                                                           double.tryParse(
  //                                                             weightController
  //                                                                 .text,
  //                                                           ) ??
  //                                                           0,
  //                                                     ),
  //                                               ),
  //                                             );
  //                                           } else {
  //                                             ScaffoldMessenger.of(
  //                                               context,
  //                                             ).showSnackBar(
  //                                               const SnackBar(
  //                                                 content: Text(
  //                                                   "Fare estimate not available",
  //                                                 ),
  //                                               ),
  //                                             );
  //                                           }
  //                                         }
  //                                         : null,
  //                                 child: Text("Select $category"),
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               },
  //             ),
  //         ],
  //       ),
  //     );
  //   }

  //   Widget _buildTextField(
  //     TextEditingController controller,
  //     String label, {
  //     int maxLines = 1,
  //     bool required = true,
  //     TextInputType? keyboardType,
  //     List<TextInputFormatter>? inputFormatters,
  //   }) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 6),
  //       child: TextFormField(
  //         controller: controller,
  //         keyboardType: keyboardType,
  //         inputFormatters: inputFormatters,
  //         maxLines: maxLines,
  //         validator:
  //             required
  //                 ? (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Required';
  //                   }
  //                   return null;
  //                 }
  //                 : null,
  //         decoration: InputDecoration(
  //           labelText: label,
  //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //         ),
  //       ),
  //     );
  //   }

  //   Widget _buildInfoRow(String label, String? value) {
  //     return Container(
  //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.grey.shade300),
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       child: Row(
  //         children: [
  //           Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Text(
  //               value ?? 'Not selected',
  //               style: TextStyle(
  //                 color: value == null ? Colors.grey : Colors.black,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }
//}
