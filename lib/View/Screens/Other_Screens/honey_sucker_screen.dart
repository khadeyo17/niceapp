import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/order_details_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

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
  BuildContext? _dialogContext;
  int? rideId2;
  double? selectedPrice;

  final List<String> deliveryPeriods = [
    'Within 2 Hours',
    'Same Day',
    'Next Day',
    'Within 3 Days',
  ];
  DateTime? selectedDate;
  TimeOfDay? deliveryTime;

  int numberOfTrucks = 0;
  double totalPrice = 0.0;
  final StreamController<bool> _driverLinkedController =
      StreamController<bool>.broadcast();

  @override
  void dispose() {
    detailsController.dispose();
    priceController.dispose();
    _driverLinkedController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // _checkPendingOrders();
    fetchSubcategories();
    _fetchCurrentLocation();

    if (widget.destination != null) {
      selectedLatLng = widget.destination;
      _getAddressFromLatLng(widget.destination!);
    }

    selectedDate = DateTime.now();
    deliveryTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(minutes: 10)),
    );

    // Wait until build context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingOrders();
    });
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
          _checkPendingOrders();
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
    const maxAttempts = 12;
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(pollingInterval);

      final response = await http.get(
        Uri.parse('$baseUrl/rides/passenger/current/$firebaseId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['driver'] != null &&
            data['driver']['driverName'] != null &&
            data['driver']['driverName'] != 'N/A') {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

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
              'eta': data['eta'] ?? 5,
            },
          );
          return;
        }
      }

      attempts++;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
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
      print("User is not authenticated");
      return;
    }

    final requestBody = {
      "firebaseId": user.uid,
      "destLat": selectedLatLng!.latitude,
      "destLng": selectedLatLng!.longitude,
      "destination": displayAddress ?? '',
      "subCategoryId": selectedSubcategory?.id,
      "scheduledTime": selectedDate?.toIso8601String(),
      "fare": totalPrice.toStringAsFixed(2),
    };

    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse('$baseUrl/rides/exhauster/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final rideId = responseData['rideId'];
        rideId2 = responseData['rideId'];

        final int orderId =
            responseData['orderId'] != null
                ? int.tryParse(responseData['orderId'].toString()) ?? 0
                : 0;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => OrderDetailsScreen(
                  serviceType: widget.category,
                  rideId: rideId,
                  destination: selectedLatLng,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book ride: ${response.statusCode}'),
          ),
        );
        debugPrint('Failed to book ride: ${response.statusCode}');
        debugPrint(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
      debugPrint('Error booking ride: $e');
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
        final dbRef = FirebaseDatabase.instance.ref(
          "rideRequests/${requestId.toString()}",
        );
        final dbSnapshot = await dbRef.get();

        if (dbSnapshot.exists) {
          final requestData = dbSnapshot.value as Map;

          if (requestData['rideId'] != null) {
            final realRideId = requestData['rideId'];
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

  Future<void> _checkPendingOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final categoryType = widget.category.index;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/pendingOrder/${user.uid}/$categoryType'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double destLat =
            (data['destinationLat'] as num?)?.toDouble() ?? 0.0;
        final double destLng =
            (data['destinationLng'] as num?)?.toDouble() ?? 0.0;
        final int rideId = data['rideId'];

        if (rideId > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => OrderDetailsScreen(
                      rideId: rideId,
                      serviceType: widget.category,
                      destination: LatLng(destLat, destLng),
                    ),
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking pending orders: $e');
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

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => displayAddress = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => displayAddress = "Permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => displayAddress = "Permission permanently denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      selectedLatLng = LatLng(position.latitude, position.longitude);
      _getAddressFromLatLng(selectedLatLng!);
    } catch (e) {
      debugPrint("Error fetching location: $e");
      setState(() => displayAddress = "Unable to fetch location");
    }
  }

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
        displayAddress = address;
      });
    } catch (e) {
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
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header image
                    Container(
                      height: MediaQuery.of(context).size.height * 0.24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.25),
                          width: 1.5,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/imgs/exhaustertrack.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Destination picker card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: InkWell(
                        onTap: _openDestinationPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Collection Location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      displayAddress ??
                                          'Tap to select destination on map',
                                      style: TextStyle(
                                        color:
                                            displayAddress == null
                                                ? Colors.grey[700]
                                                : Colors.black87,
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
                    ),

                    const SizedBox(height: 18),

                    // Quantity selector
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Select Quantity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subcategories.length,
                        itemBuilder: (context, index) {
                          final sub = subcategories[index];
                          final isSelected = selectedSubcategory?.id == sub.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                if (selectedLatLng == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select collection location first.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  selectedSubcategory = sub;
                                  selectedPrice = sub.baseFare;
                                  totalPrice = selectedSubcategory!.baseFare;
                                  priceController.text =
                                      'KES ${totalPrice.toStringAsFixed(2)}';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.orangeAccent
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.orangeAccent.shade700
                                            : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: Colors.orangeAccent
                                                  .withOpacity(0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        sub.name,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      // const SizedBox(height: 4),
                                      // Text(
                                      //   'KES ${sub.baseFare.toStringAsFixed(0)}',
                                      //   style: TextStyle(
                                      //     color:
                                      //         isSelected
                                      //             ? Colors.white70
                                      //             : Colors.black54,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price & details card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Price',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  priceController.text.isNotEmpty
                                      ? priceController.text
                                      : 'KES 0.00',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // ElevatedButton.icon(
                                //   onPressed:
                                //       selectedSubcategory == null
                                //           ? null
                                //           : () {
                                //             setState(() {
                                //               // placeholder increment - you can show quantity dialog here later
                                //               numberOfTrucks++;
                                //               totalPrice =
                                //                   selectedSubcategory!.baseFare;
                                //               //      *
                                //               // numberOfTrucks;
                                //               priceController.text =
                                //                   'KES ${totalPrice.toStringAsFixed(2)}';
                                //             });
                                //           },
                                //   icon: const Icon(Icons.add_shopping_cart),
                                //   label: const Text('Add Truck'),
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.orangeAccent,
                                //     foregroundColor: Colors.white,
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(10),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // if (numberOfTrucks > 0)
                            //   Text(
                            //     '${numberOfTrucks} truck(s) selected',
                            //     style: const TextStyle(color: Colors.black87),
                            //   ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Date & time card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final now = DateTime.now();
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? now,
                                    firstDate: now,
                                    lastDate: now.add(const Duration(days: 30)),
                                  );
                                  if (pickedDate == null) return;
                                  final pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        deliveryTime ?? TimeOfDay.now(),
                                  );
                                  if (pickedTime == null) return;
                                  setState(() {
                                    selectedDate = pickedDate;
                                    deliveryTime = pickedTime;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Collection Date & Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${DateFormat('yyyy-MM-dd').format(selectedDate!)} ${deliveryTime!.format(context)}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (selectedLatLng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please select destination first.",
                                ),
                              ),
                            );
                            return;
                          }
                          if (selectedSubcategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select quantity."),
                              ),
                            );
                            return;
                          }
                          bookRide();
                        },
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text(
                            "Order now",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.45),
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
// import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:geocoding/geocoding.dart';
// import 'package:intl/intl.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
// import 'package:niceapp/View/Screens/Other_Screens/order_details_screen.dart';
// import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';

// class HoneySuckerScreen extends StatefulWidget {
//   final VehicleCategory category;
//   final LatLng? destination;

//   const HoneySuckerScreen({super.key, required this.category, this.destination});

//   @override
//   State<HoneySuckerScreen> createState() => _HoneySuckerScreenState();
// }

// class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
//   final TextEditingController detailsController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   List<Subcategory> subcategories = [];
//   Subcategory? selectedSubcategory;
//   bool _isLoading = false;
//   LatLng? selectedLatLng;
//   String? displayAddress;
//   BuildContext? _dialogContext;
//   int? rideId2;
//   //Map<String, double> priceMap = {};
//   double? selectedPrice;

//   String? selectedDeliveryPeriod;
//   final List<String> deliveryPeriods = [
//     'Within 2 Hours',
//     'Same Day',
//     'Next Day',
//     'Within 3 Days',
//   ];
//   DateTime? selectedDate;
//   TimeOfDay? deliveryTime;
//   // TimeOfDay? timeTo;

//   int numberOfTrucks = 0; // add this at the top of your state
//   double totalPrice = 0.0;
//   final StreamController<bool> _driverLinkedController =
//       StreamController<bool>.broadcast();

//   @override
//   void dispose() {
//     detailsController.dispose();
//     priceController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _checkPendingOrders();

//     fetchSubcategories();

//     if (widget.destination != null) {
//       selectedLatLng = widget.destination;
//       _getAddressFromLatLng(widget.destination!);
//     }
//     //_initializeDefaultSchedule();

//     selectedDate = DateTime.now();
//     deliveryTime = TimeOfDay.fromDateTime(
//       DateTime.now().add(const Duration(minutes: 10)),
//     );
//   }

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
//           // // Optional: select the first one by default
//           // if (subcategories.isNotEmpty) {
//           //  // selectedSubcategory = subcategories[0];
//           // }
//         });
//       } else {
//         debugPrint('Failed to load subcategories: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching subcategories: $e');
//     }
//   }

//   Future<void> _pollDriverAssignment(
//     BuildContext context,
//     String firebaseId,
//   ) async {
//     const pollingInterval = Duration(seconds: 5);
//     const maxAttempts = 12; // 1 minute (12 x 5s)
//     int attempts = 0;

//     while (attempts < maxAttempts) {
//       await Future.delayed(pollingInterval);

//       final response = await http.get(
//         Uri.parse('$baseUrl/rides/passenger/current/$firebaseId'),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         // Check if driver has been assigned
//         if (data['driver'] != null &&
//             data['driver']['driverName'] != null &&
//             data['driver']['driverName'] != 'N/A') {
//           if (Navigator.canPop(context)) {
//             Navigator.pop(context); // ✅ Dismiss "Searching..." dialog
//           }

//           // Push to driver assignment screen with info
//           Navigator.pushReplacementNamed(
//             context,
//             '/driverAssignment',
//             arguments: {
//               'driverName': data['driver']['driverName'],
//               'driverContact': data['driver']['driverPhone'],
//               'vehicle': {
//                 'make': data['driver']['vehicleMake'],
//                 'model': data['driver']['vehicleModel'],
//                 'color': data['driver']['vehicleColour'],
//                 'registration': data['driver']['registrationNumber'],
//               },
//               'eta':
//                   data['eta'] ??
//                   5, // You can replace this with backend ETA when ready
//             },
//           );
//           return;
//         }
//       }

//       attempts++;
//     }

//     if (Navigator.canPop(context)) {
//       Navigator.pop(context); // Dismiss "Searching..." if polling ends
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('No driver found yet. Please try again later.'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   ///working
//   // Future<void> bookRide() async {
//   //   final user = FirebaseAuth.instance.currentUser;

//   //   if (user == null) {
//   //     _closeFindingDriverDialog();
//   //     print("User is not authenticated");
//   //     return;
//   //   }

//   //   final idToken = await user.getIdToken();

//   //   final scheduledTime = null;
//   //   final requestBody = {
//   //     "firebaseIdToken": user.uid,
//   //     "destLat": selectedLatLng!.latitude,
//   //     "destLng": selectedLatLng!.longitude,
//   //     "destination": displayAddress ?? '',
//   //     "notes": detailsController.text,
//   //     "subCategoryId": selectedSubcategory?.id,
//   //     "scheduledTime": null,
//   //   };

//   //   try {
//   //     setState(() => _isLoading = true);

//   //     final response = await http.post(
//   //       Uri.parse('$baseUrl/rides/exhauster/request'),
//   //       headers: {'Content-Type': 'application/json'},
//   //       body: jsonEncode(requestBody),
//   //     );

//   //     setState(() => _isLoading = false);

//   //     // if (response.statusCode == 200) {
//   //     //   final responseData = jsonDecode(response.body);
//   //     //   final rideId = responseData['rideId'];
//   //     //   //rideId2 = responseData['rideId'];

//   //     //   //await pollForDriverAssignment(rideId);

//   //     //   if (scheduledTime == null) {
//   //     //     await pollForDriverAssignment(rideId);
//   //     //   } else {
//   //     //     _closeFindingDriverDialog();
//   //     //     Navigator.pushReplacement(
//   //     //       context,
//   //     //       MaterialPageRoute(builder: (_) => RideHistoryScreen()),
//   //     //     );
//   //     //   }
//   //     // }
//   //     // else {
//   //     //   _closeFindingDriverDialog();
//   //     //   ScaffoldMessenger.of(context).showSnackBar(
//   //     //     SnackBar(
//   //     //       content: Text('Failed to book ride: ${response.statusCode}'),
//   //     //     ),
//   //     //   );
//   //     //   print('Failed to book ride: ${response.statusCode}');
//   //     //   print(response.body);
//   //     // }
//   //     if (response.statusCode == 200) {
//   //       final responseData = jsonDecode(response.body);
//   //       final rideId = responseData['rideId'];
//   //       rideId2 = responseData['rideId'];

//   //       if (scheduledTime == null) {
//   //         await pollForDriverAssignment(rideId);
//   //       } else {
//   //         _closeFindingDriverDialog();
//   //         Navigator.pushReplacement(
//   //           context,
//   //           MaterialPageRoute(builder: (_) => RideHistoryScreen()),
//   //         );
//   //       }
//   //     }
//   //     else {
//   //       _closeFindingDriverDialog();
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(
//   //           content: Text('Failed to book ride: ${response.statusCode}'),
//   //         ),
//   //       );
//   //       print('Failed to book ride: ${response.statusCode}');
//   //       print(response.body);
//   //     }
//   //   } catch (e) {
//   //     _closeFindingDriverDialog();
//   //     ScaffoldMessenger.of(
//   //       context,
//   //     ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
//   //     print('Error booking ride: $e');
//   //   }
//   // }
//   Future<void> bookRide() async {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       //_closeFindingDriverDialog();
//       print("User is not authenticated");
//       return;
//     }

//     //final idToken = await user.getIdToken();

//     //final scheduledTime = null;
//     final requestBody = {
//       "firebaseId": user.uid,
//       "destLat": selectedLatLng!.latitude,
//       "destLng": selectedLatLng!.longitude,
//       "destination": displayAddress ?? '',
//       // "notes": detailsController.text,
//       "subCategoryId": selectedSubcategory?.id,
//       "scheduledTime": selectedDate?.toIso8601String(),
//       "fare": totalPrice.toStringAsFixed(2),
//       // "noOfTrucks": numberOfTrucks, // int.parse(truckCountController.text),
//     };

//     try {
//       setState(() => _isLoading = true);

//       final response = await http.post(
//         Uri.parse('$baseUrl/rides/exhauster/request'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       setState(() => _isLoading = false);
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         final rideId = responseData['rideId'];
//         rideId2 = responseData['rideId'];

//         final String orderNumber = responseData['orderNumber'] ?? "WB-Unknown";
//         // final int orderId = responseData['orderId']; // ?? "WB-Unknown";

//         final int orderId =
//             responseData['orderId'] != null
//                 ? int.tryParse(responseData['orderId'].toString()) ?? 0
//                 : 0;

//         // Navigate to OrderDetailsScreen with API order number
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => OrderDetailsScreen(
                 
//                   serviceType: widget.category,
//                   rideId: rideId,
//                   destination: selectedLatLng,
//                 ),
//           ),
//         );

//         // if (scheduledTime == null) {
//         //   await pollForDriverAssignment(rideId);
//         // }
//         //  else
//         //  {
//         //   _closeFindingDriverDialog();
//         //   Navigator.pushReplacement(
//         //     context,
//         //     MaterialPageRoute(builder: (_) => RideHistoryScreen()),
//         //   );
//         // }
//       } else {
//         // _closeFindingDriverDialog();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to book ride: ${response.statusCode}'),
//           ),
//         );
//         print('Failed to book ride: ${response.statusCode}');
//         print(response.body);
//       }
//     } catch (e) {
//       //  _closeFindingDriverDialog();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
//       print('Error booking ride: $e');
//     }
//   }

//   void _closeFindingDriverDialog() {
//     if (_dialogContext != null && Navigator.canPop(_dialogContext!)) {
//       Navigator.pop(_dialogContext!);
//     }
//   }
//   // Future<void> _pickDate(BuildContext context) async {
//   //   final now = DateTime.now();
//   //   final picked = await showDatePicker(
//   //     context: context,
//   //     initialDate: _selectedDate ?? now,
//   //     firstDate: now,
//   //     lastDate: now.add(const Duration(days: 60)), // 60-day max
//   //   );

//   //   if (picked != null) {
//   //     setState(() => _selectedDate = picked);
//   //   }
//   // }

//   // Future<void> _pickTime(BuildContext context) async {
//   //   final picked = await showTimePicker(
//   //     context: context,
//   //     initialTime: _selectedTime ?? TimeOfDay.now(),
//   //   );

//   //   if (picked != null) {
//   //     setState(() => _selectedTime = picked);
//   //   }
//   // }
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
//             final url = '$baseUrl/rides/myrides/$realRideId';
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
//                           //pickup: widget.pickup,
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

//   void _openDestinationPicker() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => WhereToScreen(category: VehicleCategory.exhauster),
//       ),
//     );

//     if (result != null && result is LatLng) {
//       setState(() {
//         selectedLatLng = result;
//       });

//       _getAddressFromLatLng(result);
//     }
//   }

//   Future<void> _checkPendingOrders() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final categoryType = widget.category.index;

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/rides/pendingOrder/${user.uid}/$categoryType'),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final double destLat =
//             (data['destinationLat'] as num?)?.toDouble() ?? 0.0;
//         final double destLng =
//             (data['destinationLng'] as num?)?.toDouble() ?? 0.0;

//         final int rideId = data['rideId'];

//         // final int rideId =
//         //     data['truck']?['rideId'] != null
//         //         ? int.tryParse(data['truck']['rideId'].toString()) ?? 0
//         //         : 0;

//         if (rideId > 0) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder:
//                     (_) => OrderDetailsScreen(
//                       rideId: rideId,
//                       serviceType: widget.category,
//                       destination: LatLng(destLat, destLng),
//                     ),
//               ),
//             );
//           });
//         }
//         // // Check if there is a pending order
//         // if (orderId!=null) {
//         //   final int orderId = data['orderId'];
//         //   //  != null
//         //   //     ? int.tryParse(data['orderId'].toString()) ?? 0
//         //   //     : 0;

//         //   // Navigate to OrderDetailsScreen

//         // }
//       }
//       // else {
//       //   debugPrint('Failed to fetch current orders: ${response.statusCode}');
//       // }
//     } catch (e) {
//       debugPrint('Error checking pending orders: $e');
//     }
//   }

//   // Declare variables at the top of your State class
//   // DateTime? selectedDate;
//   // TimeOfDay? timeFrom;
//   // TimeOfDay? timeTo;

//   // --- Date Picker ---

//   // --- Date Picker ---

//   void _initializeDefaultSchedule() {
//     final now = DateTime.now();
//     //final fromTime = now.add(const Duration(minutes: 10));
//     //final toTime = fromTime.add(const Duration(hours: 1));

//     setState(() {
//       selectedDate = now;
//       //timeFrom = TimeOfDay.fromDateTime(fromTime);
//       //timeTo = TimeOfDay.fromDateTime(toTime);
//     });
//   }

//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) setState(() => selectedDate = picked);
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

//       // ...
//       body: SafeArea(
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     /// 🌊 Header Image
//                     Container(
//                       height: MediaQuery.of(context).size.height * 0.25,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.blueAccent.withOpacity(0.3),
//                           width: 1.5,
//                         ),
//                         image: const DecorationImage(
//                           image: AssetImage('assets/imgs/exhaustertrack.jpg'),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     /// 📍 Destination Picker
//                     const Text(
//                       "Select Collection Location",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     InkWell(
//                       onTap: _openDestinationPicker,
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade400),
//                           borderRadius: BorderRadius.circular(12),
//                           color: Colors.grey.shade100,
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(
//                               Icons.location_on_outlined,
//                               color: Colors.black,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 displayAddress ??
//                                     'Tap to select destination on map',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color:
//                                       displayAddress == null
//                                           ? Colors.grey[700]
//                                           : Colors.black87,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 25),

//                     /// 🚰 Quantity Selector
//                     const Text(
//                       "Select Quantity",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     SizedBox(
//                       height: 60,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: subcategories.length,
//                         itemBuilder: (context, index) {
//                           final sub = subcategories[index];
//                           final isSelected = selectedSubcategory?.id == sub.id;
//                           return GestureDetector(
//                             onTap: () {
//                               if (selectedLatLng == null) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       "Please select collection location first.",
//                                     ),
//                                   ),
//                                 );
//                                 return;
//                               }

//                               setState(() {
//                                 selectedSubcategory = sub;
//                                 selectedPrice = sub.baseFare;
//                                 // numberOfTrucks = 0;
//                                 //numberOfTrucks = int.tryParse(value) ?? 0;
//                                 //  totalPrice = selectedPrice!;
//                                 totalPrice = selectedSubcategory!.baseFare;
//                                 // numberOfTrucks;
//                                 priceController.text =
//                                     'KES ${totalPrice.toStringAsFixed(2)}';
//                               });
//                             },
//                             child: Container(
//                               margin: const EdgeInsets.only(right: 12),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 color:
//                                     isSelected
//                                         ? Colors.blueAccent
//                                         : Colors.grey[200],
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                   color:
//                                       isSelected
//                                           ? Colors.blueAccent
//                                           : Colors.grey.shade300,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   sub.name,
//                                   style: TextStyle(
//                                     color:
//                                         isSelected
//                                             ? Colors.white
//                                             : Colors.black87,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),

//                     const SizedBox(height: 25),

//                     /// 🚛 Number of Trucks
//                     // TextFormField(
//                     //   enabled: selectedSubcategory != null,
//                     //   keyboardType: TextInputType.number,
//                     //   decoration: InputDecoration(
//                     //     labelText: 'Number of Trucks',
//                     //     prefixIcon: const Icon(Icons.fire_truck_outlined),
//                     //     border: const OutlineInputBorder(),
//                     //     hintText:
//                     //         selectedSubcategory == null
//                     //             ? 'Select quantity first'
//                     //             : 'Enter number of trucks',
//                     //   ),
//                     //   onChanged: (value) {
//                     //     if (selectedSubcategory == null) {
//                     //       ScaffoldMessenger.of(context).showSnackBar(
//                     //         const SnackBar(
//                     //           content: Text("Please select quantity first."),
//                     //         ),
//                     //       );
//                     //       return;
//                     //     }

//                     //     setState(() {
//                     //       numberOfTrucks = int.tryParse(value) ?? 0;
//                     //       totalPrice =
//                     //           (selectedSubcategory!.baseFare * numberOfTrucks);
//                     //       priceController.text =
//                     //           'KES ${totalPrice.toStringAsFixed(2)}';
//                     //     });
//                     //   },
//                     // ),

//                     // const SizedBox(height: 25),

//                     /// 💰 Price Estimate
//                     // TextFormField(
//                     //   controller: priceController,
//                     //   readOnly: true,
//                     //   decoration: const InputDecoration(
//                     //     labelText: 'Estimated Price',
//                     //     prefixIcon: Icon(Icons.attach_money),
//                     //     border: OutlineInputBorder(),
//                     //   ),
//                     // ),
//                     TextFormField(
//                       controller: priceController,
//                       readOnly: true,
//                       decoration: const InputDecoration(
//                         labelText: 'Estimated Price',
//                         prefixIcon: Icon(Icons.attach_money),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),

//                     // const SizedBox(height: 6),
//                     // Text(
//                     //   selectedSubcategory != null && numberOfTrucks > 0
//                     //       ? '${selectedSubcategory!.name} × $numberOfTrucks Truck(s) = KES ${totalPrice.toStringAsFixed(2)}'
//                     //       : 'KES 0.00',
//                     //   style: TextStyle(
//                     //     fontWeight: FontWeight.bold,
//                     //     color:
//                     //         selectedSubcategory != null && numberOfTrucks > 0
//                     //             ? Colors.green
//                     //             : Colors.grey,
//                     //     fontSize: 16,
//                     //   ),
//                     // ),
//                     const SizedBox(height: 25),

//                     const SizedBox(height: 25),
//                     Text(
//                       'Collection Date & Time',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     GestureDetector(
//                       onTap: () async {
//                         final now = DateTime.now();

//                         // Pick Date
//                         final pickedDate = await showDatePicker(
//                           context: context,
//                           initialDate: selectedDate,
//                           firstDate: now,
//                           lastDate: now.add(const Duration(days: 30)),
//                         );
//                         if (pickedDate == null) return;

//                         // Pick Time
//                         final pickedTime = await showTimePicker(
//                           context: context,
//                           initialTime: deliveryTime!,
//                         );
//                         if (pickedTime == null) return;

//                         setState(() {
//                           selectedDate = pickedDate;
//                           deliveryTime = pickedTime;
//                         });
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           "${DateFormat('yyyy-MM-dd').format(selectedDate!)} "
//                           "${deliveryTime!.format(context)}",
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 25),

//                     /// 🧾 Checkout Button
//                     ElevatedButton.icon(
//                       onPressed: () async {
//                         if (selectedLatLng == null) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("Please select destination first."),
//                             ),
//                           );
//                           return;
//                         }
//                         if (selectedSubcategory == null) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("Please select quantity."),
//                             ),
//                           );
//                           return;
//                         }
//                         // if (numberOfTrucks <= 0) {
//                         //   ScaffoldMessenger.of(context).showSnackBar(
//                         //     const SnackBar(
//                         //       content: Text("Please enter number of trucks."),
//                         //     ),
//                         //   );
//                         //   return;
//                         // }
//                         bookRide();
//                         // Navigator.push(
//                         //   context,
//                         //   MaterialPageRoute(
//                         //     builder:
//                         //         (_) => OrderDetailsScreen(
//                         //           orderNo: "WB-2025-0106",
//                         //           deliveryAddress: displayAddress ?? "Unknown",
//                         //           scheduledFor: "6th Oct 2025, 3:00 PM",
//                         //           totalAmount: totalPrice,
//                         //           paymentStatus: "Pending",
//                         //         ),
//                         //   ),
//                         // );
//                       },
//                       icon: const Icon(Icons.shopping_cart_checkout),
//                       label: const Text("Checkout"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size.fromHeight(50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             if (_isLoading)
//               Container(
//                 color: Colors.black.withOpacity(0.5),
//                 child: const Center(
//                   child: CircularProgressIndicator(color: Colors.white),
//                   //           ),
//                   //         ),
//                   //     ],
//                   //   ),
//                   // );
//                 ),
//               ),
//           ],
//         ),
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
// // import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';

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
// //   final TextEditingController priceController = TextEditingController();
// //   List<Subcategory> subcategories = [];
// //   Subcategory? selectedSubcategory;
// //   bool _isLoading = false;
// //   LatLng? selectedLatLng;
// //   String? displayAddress;
// //   BuildContext? _dialogContext;
// //   int? rideId2;
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

// //     if (widget.destination != null) {
// //       selectedLatLng = widget.destination;
// //       _getAddressFromLatLng(widget.destination!);
// //     }
// //   }

// //   Future<void> bookRide() async {
// //     final user = FirebaseAuth.instance.currentUser;

// //     if (user == null) {
// //       _closeFindingDriverDialog();
// //       print("User is not authenticated");
// //       return;
// //     }

// //     final idToken = await user.getIdToken();
// //     // final token = await FirebaseAuth.instance.currentUser?.getIdToken();
// //     // if (token == null) {
// //     //   ScaffoldMessenger.of(context).showSnackBar(
// //     //     const SnackBar(
// //     //       content: Text('Authentication error'),
// //     //       backgroundColor: Colors.red,
// //     //     ),
// //     //   );
// //     //   return;
// //     // }
// //     final scheduledTime = null;
// //     final requestBody = {
// //       "firebaseIdToken": user.uid,
// //       "destLat": selectedLatLng!.latitude,
// //       "destLng": selectedLatLng!.longitude,
// //       "destination": displayAddress ?? '',
// //       "notes": detailsController.text,
// //       "subCategoryId": selectedSubcategory?.id,
// //       "scheduledTime": null,
// //     };

// //     try {
// //       setState(() => _isLoading = true);

// //       final response = await http.post(
// //         Uri.parse('$baseUrl/rides/exhauster/request'),
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode(requestBody),
// //       );

// //       setState(() => _isLoading = false);

// //       // if (response.statusCode == 200) {
// //       //   final responseData = jsonDecode(response.body);
// //       //   final rideId = responseData['rideId'];
// //       //   //rideId2 = responseData['rideId'];

// //       //   //await pollForDriverAssignment(rideId);

// //       //   if (scheduledTime == null) {
// //       //     await pollForDriverAssignment(rideId);
// //       //   } else {
// //       //     _closeFindingDriverDialog();
// //       //     Navigator.pushReplacement(
// //       //       context,
// //       //       MaterialPageRoute(builder: (_) => RideHistoryScreen()),
// //       //     );
// //       //   }
// //       // }
// //       // else {
// //       //   _closeFindingDriverDialog();
// //       //   ScaffoldMessenger.of(context).showSnackBar(
// //       //     SnackBar(
// //       //       content: Text('Failed to book ride: ${response.statusCode}'),
// //       //     ),
// //       //   );
// //       //   print('Failed to book ride: ${response.statusCode}');
// //       //   print(response.body);
// //       // }
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
// //             final url = '$baseUrl/rides/myrides/$realRideId';
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
// //                           //pickup: widget.pickup,
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

// //   // Future<void> _pollDriverAssignment(
// //   //   BuildContext context,
// //   //   String firebaseId,
// //   // ) async {
// //   //   const pollingInterval = Duration(seconds: 5);
// //   //   const maxAttempts = 12; // 1 minute (12 x 5s)
// //   //   int attempts = 0;

// //   //   while (attempts < maxAttempts) {
// //   //     await Future.delayed(pollingInterval);

// //   //     final response = await http.get(
// //   //       Uri.parse('$baseUrl/rides/passenger/current/$firebaseId'),
// //   //     );

// //   //     if (response.statusCode == 200) {
// //   //       final data = jsonDecode(response.body);

// //   //       // Check if driver has been assigned
// //   //       if (data['driver'] != null &&
// //   //           data['driver']['driverName'] != null &&
// //   //           data['driver']['driverName'] != 'N/A') {
// //   //         if (Navigator.canPop(context)) {
// //   //           Navigator.pop(context); // ✅ Dismiss "Searching..." dialog
// //   //         }

// //   //         // Push to driver assignment screen with info
// //   //         Navigator.pushReplacementNamed(
// //   //           context,
// //   //           '/driverAssignment',
// //   //           arguments: {
// //   //             'driverName': data['driver']['driverName'],
// //   //             'driverContact': data['driver']['driverPhone'],
// //   //             'vehicle': {
// //   //               'make': data['driver']['vehicleMake'],
// //   //               'model': data['driver']['vehicleModel'],
// //   //               'color': data['driver']['vehicleColour'],
// //   //               'registration': data['driver']['registrationNumber'],
// //   //             },
// //   //             'eta':
// //   //                 data['eta'] ??
// //   //                 5, // You can replace this with backend ETA when ready
// //   //           },
// //   //         );
// //   //         return;
// //   //       }
// //   //     }

// //   //     attempts++;
// //   //   }

// //   //   if (Navigator.canPop(context)) {
// //   //     Navigator.pop(context); // Dismiss "Searching..." if polling ends
// //   //   }

// //   //   ScaffoldMessenger.of(context).showSnackBar(
// //   //     const SnackBar(
// //   //       content: Text('No driver found yet. Please try again later.'),
// //   //       backgroundColor: Colors.red,
// //   //     ),
// //   //   );
// //   // }

// //   void _openDestinationPicker() async {
// //     final result = await Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) => WhereToScreen(category: VehicleCategory.exhauster),
// //       ),
// //     );

// //     if (result != null && result is LatLng) {
// //       setState(() {
// //         selectedLatLng = result;
// //       });

// //       _getAddressFromLatLng(result);
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

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Exhauster Service'),
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
// //                     'Request Exhauster',
// //                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// //                   ),
// //                   const SizedBox(height: 24),
// //                   DropdownButtonFormField<Subcategory>(
// //                     value: selectedSubcategory,
// //                     isExpanded: true,
// //                     hint: const Text('Select Quantity'),
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
// //                       labelText: "Quantity",
// //                       border: OutlineInputBorder(),
// //                       prefixIcon: Icon(Icons.plumbing),
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
// //                   const SizedBox(height: 20),
// //                   InkWell(
// //                     onTap: _openDestinationPicker,
// //                     child: Container(
// //                       padding: const EdgeInsets.all(16),
// //                       decoration: BoxDecoration(
// //                         border: Border.all(color: Colors.grey.shade400),
// //                         borderRadius: BorderRadius.circular(12),
// //                         color: Colors.grey.shade100,
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           const Icon(
// //                             Icons.location_on_outlined,
// //                             color: Colors.black,
// //                           ),
// //                           const SizedBox(width: 12),
// //                           Expanded(
// //                             child: Text(
// //                               displayAddress ??
// //                                   'Tap to select destination on map',
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 color:
// //                                     displayAddress == null
// //                                         ? Colors.grey[700]
// //                                         : Colors.black87,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 24),
// //                   ElevatedButton.icon(
// //                     onPressed: () async {
// //                       // if (mounted) {
// //                       //   showFindingDriverDialog(context);
// //                       //   await bookRide();
// //                       // }
// //                       if (mounted) {
// //                         // Instead of dialog, push full screen
// //                         // Navigator.push(
// //                         //   context,
// //                         //   MaterialPageRoute(
// //                         //     builder:
// //                         //         (_) => FindingDriverScreen(
// //                         //           onCancel: () async {
// //                         //             // TODO: cancel ride request via API
// //                         //             print("Ride canceled by passenger");
// //                         //           },
// //                         //         ),
// //                         //   ),
// //                         // );

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

// // class Subcategory {
// //   final int id;
// //   final String name;
// //   final double baseFare;
// //   final double? pricePerKilometer;

// //   Subcategory({
// //     required this.id,
// //     required this.name,
// //     required this.baseFare,
// //     this.pricePerKilometer,
// //   });

// //   factory Subcategory.fromJson(Map<String, dynamic> json) {
// //     return Subcategory(
// //       id: json['id'],
// //       name: json['name'],
// //       baseFare: (json['baseFare'] as num).toDouble(),
// //       pricePerKilometer: (json['baseFare'] as num).toDouble(),
// //     );
// //   }
// // }



// //                     // onPressed: () async {
// //                     //   if (selectedSubcategory == null ||
// //                     //       selectedLatLng == null) {
// //                     //     ScaffoldMessenger.of(context).showSnackBar(
// //                     //       const SnackBar(
// //                     //         content: Text(
// //                     //           'Please complete all required fields',
// //                     //         ),
// //                     //         backgroundColor: Colors.red,
// //                     //       ),
// //                     //     );
// //                     //     return;
// //                     //   }

// //                     //   final token =
// //                     //       await FirebaseAuth.instance.currentUser?.getIdToken();
// //                     //   if (token == null) {
// //                     //     ScaffoldMessenger.of(context).showSnackBar(
// //                     //       const SnackBar(
// //                     //         content: Text('Authentication error'),
// //                     //         backgroundColor: Colors.red,
// //                     //       ),
// //                     //     );
// //                     //     return;
// //                     //   }

// //                     //   final requestBody = {
// //                     //     "firebaseIdToken": token,
// //                     //     "destLat": selectedLatLng!.latitude,
// //                     //     "destLng": selectedLatLng!.longitude,
// //                     //     "destination": displayAddress ?? '',
// //                     //     "notes": detailsController.text,
// //                     //     "subCategoryId": selectedSubcategory?.id,
// //                     //     "scheduledTime": null,
// //                     //   };

// //                     //   try {
// //                     //     setState(() => _isLoading = true);

// //                     //     final response = await http.post(
// //                     //       Uri.parse('$baseUrl/rides/exhauster/book'),
// //                     //       headers: {'Content-Type': 'application/json'},
// //                     //       body: jsonEncode(requestBody),
// //                     //     );

// //                     //     setState(() => _isLoading = false);

// //                     //     if (response.statusCode == 200) {
// //                     //       final data = jsonDecode(response.body);
// //                     //       final rideId = data['rideId'];

// //                     //       if (rideId != null && mounted) {
// //                     //         Navigator.push(
// //                     //           context,
// //                     //           MaterialPageRoute(
// //                     //             builder:
// //                     //                 (_) => DriverAssignmentsScreen(
// //                     //                   destination: selectedLatLng!,
// //                     //                   rideId: rideId,
// //                     //                   category: selectedSubcategory!,
// //                     //                   fare: selectedPrice ?? 0,
// //                     //                 ),
// //                     //           ),
// //                     //         );
// //                     //       }
// //                     //     } else {
// //                     //       ScaffoldMessenger.of(context).showSnackBar(
// //                     //         SnackBar(
// //                     //           content: Text('Booking failed: ${response.body}'),
// //                     //           backgroundColor: Colors.red,
// //                     //         ),
// //                     //       );
// //                     //     }
// //                     //   } catch (e) {
// //                     //     setState(() => _isLoading = false);
// //                     //     ScaffoldMessenger.of(context).showSnackBar(
// //                     //       const SnackBar(
// //                     //         content: Text(
// //                     //           'Unexpected error. Please try again.',
// //                     //         ),
// //                     //         backgroundColor: Colors.red,
// //                     //       ),
// //                     //     );
// //                     //   }
// //                     // },
// // // import 'dart:convert';

// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:latlong2/latlong.dart';
// // // import 'package:geocoding/geocoding.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// // // class HoneySuckerScreen extends StatefulWidget {
// // //   final VehicleCategory category;
// // //   final LatLng? destination;

// // //   const HoneySuckerScreen({
// // //     super.key,
// // //     required this.category,
// // //     this.destination,
// // //   });

// // //   @override
// // //   State<HoneySuckerScreen> createState() => _HoneySuckerScreenState();
// // // }

// // // class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
// // //   final TextEditingController detailsController = TextEditingController();
// // //   List<String> waterSubcategories = [];
// // //   String? selectedSubcategory;

// // //   LatLng? selectedLatLng;
// // //   String? displayAddress;
// // //   bool isLoading = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchSubcategories();

// // //     if (widget.destination != null) {
// // //       selectedLatLng = widget.destination;
// // //       _getAddressFromLatLng(widget.destination!);
// // //     }
// // //   }

// // //   Future<void> fetchSubcategories() async {
// // //     setState(() => isLoading = true);
// // //     try {
// // //       final response = await http.get(
// // //         Uri.parse('https://yourapi.com/api/water-subcategories'),
// // //       );

// // //       if (response.statusCode == 200) {
// // //         final data = jsonDecode(response.body);
// // //         setState(() {
// // //           waterSubcategories = List<String>.from(data);
// // //         });
// // //       }
// // //     } catch (e) {
// // //       debugPrint('Error fetching subcategories: $e');
// // //     } finally {
// // //       setState(() => isLoading = false);
// // //     }
// // //   }

// // //   Future<void> _getAddressFromLatLng(LatLng latLng) async {
// // //     try {
// // //       final placemarks = await placemarkFromCoordinates(
// // //         latLng.latitude,
// // //         latLng.longitude,
// // //       );
// // //       if (placemarks.isNotEmpty) {
// // //         final place = placemarks.first;
// // //         setState(() {
// // //           displayAddress =
// // //               "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
// // //         });
// // //       } else {
// // //         setState(() {
// // //           displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// // //         });
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// // //       });
// // //       debugPrint("Reverse geocoding failed: $e");
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Exhauster Service'),
// // //         centerTitle: true,
// // //         backgroundColor: Colors.white,
// // //         elevation: 1,
// // //         foregroundColor: Colors.black87,
// // //       ),
// // //       body: SafeArea(
// // //         child:
// // //             isLoading
// // //                 ? const Center(child: CircularProgressIndicator())
// // //                 : SingleChildScrollView(
// // //                   padding: const EdgeInsets.symmetric(
// // //                     horizontal: 20,
// // //                     vertical: 16,
// // //                   ),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       const Text(
// // //                         'Request Exhauster',
// // //                         style: TextStyle(
// // //                           fontSize: 24,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                       const SizedBox(height: 24),

// // //                       /// Quantity Dropdown
// // //                       DropdownButtonFormField<String>(
// // //                         value: selectedSubcategory,
// // //                         isExpanded: true,
// // //                         hint: const Text('Select Quantity'),
// // //                         items:
// // //                             waterSubcategories.map((subcategory) {
// // //                               return DropdownMenuItem<String>(
// // //                                 value: subcategory,
// // //                                 child: Text(subcategory),
// // //                               );
// // //                             }).toList(),
// // //                         onChanged:
// // //                             (value) =>
// // //                                 setState(() => selectedSubcategory = value),
// // //                         decoration: const InputDecoration(
// // //                           labelText: "Quantity",
// // //                           border: OutlineInputBorder(),
// // //                           prefixIcon: Icon(Icons.water_drop_outlined),
// // //                         ),
// // //                       ),

// // //                       const SizedBox(height: 20),

// // //                       /// Additional Notes
// // //                       TextFormField(
// // //                         controller: detailsController,
// // //                         decoration: const InputDecoration(
// // //                           labelText: 'Additional Details (Optional)',
// // //                           border: OutlineInputBorder(),
// // //                           prefixIcon: Icon(Icons.description_outlined),
// // //                         ),
// // //                         maxLines: 3,
// // //                       ),

// // //                       const SizedBox(height: 20),

// // //                       /// Destination Picker
// // //                       InkWell(
// // //                         onTap: () async {
// // //                           final result = await Navigator.push(
// // //                             context,
// // //                             MaterialPageRoute(
// // //                               builder:
// // //                                   (context) => WhereToScreen(
// // //                                     category: VehicleCategory.exhauster,
// // //                                   ),
// // //                             ),
// // //                           );

// // //                           if (result != null && result is LatLng) {
// // //                             setState(() {
// // //                               selectedLatLng = result;
// // //                             });
// // //                             _getAddressFromLatLng(result);
// // //                           }
// // //                         },
// // //                         child: Container(
// // //                           padding: const EdgeInsets.all(16),
// // //                           decoration: BoxDecoration(
// // //                             border: Border.all(color: Colors.grey.shade300),
// // //                             borderRadius: BorderRadius.circular(12),
// // //                             color: Colors.grey.shade100,
// // //                           ),
// // //                           child: Row(
// // //                             children: [
// // //                               const Icon(
// // //                                 Icons.location_on_outlined,
// // //                                 color: Colors.blueAccent,
// // //                               ),
// // //                               const SizedBox(width: 12),
// // //                               Expanded(
// // //                                 child: Text(
// // //                                   displayAddress ??
// // //                                       'Tap to select destination on map',
// // //                                   style: TextStyle(
// // //                                     fontSize: 16,
// // //                                     color:
// // //                                         displayAddress == null
// // //                                             ? Colors.grey
// // //                                             : Colors.black87,
// // //                                   ),
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                       ),

// // //                       const SizedBox(height: 24),

// // //                       /// Submit Button (optional)
// // //                       ElevatedButton.icon(
// // //                         onPressed: () {
// // //                           if (selectedSubcategory == null ||
// // //                               selectedLatLng == null) {
// // //                             ScaffoldMessenger.of(context).showSnackBar(
// // //                               const SnackBar(
// // //                                 content: Text(
// // //                                   'Please complete all required fields',
// // //                                 ),
// // //                                 backgroundColor: Colors.red,
// // //                               ),
// // //                             );
// // //                             return;
// // //                           }

// // //                           // Submit request logic
// // //                           debugPrint("Submitting request...");
// // //                         },
// // //                         icon: const Icon(Icons.send),
// // //                         label: const Text("Submit Request"),
// // //                         style: ElevatedButton.styleFrom(
// // //                           padding: const EdgeInsets.symmetric(vertical: 16),
// // //                           backgroundColor: Colors.blueAccent,
// // //                           textStyle: const TextStyle(
// // //                             fontSize: 16,
// // //                             fontWeight: FontWeight.bold,
// // //                           ),
// // //                           minimumSize: const Size.fromHeight(48),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // import 'dart:convert';
// // // // import 'package:flutter/foundation.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:latlong2/latlong.dart';
// // // // import 'package:geocoding/geocoding.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

// // // // class HoneySuckerScreen extends StatefulWidget {
// // // //   final VehicleCategory category;
// // // //   final LatLng? destination;
// // // //   const HoneySuckerScreen({
// // // //     super.key,
// // // //     required this.category,
// // // //     this.destination,
// // // //   });

// // // //   @override
// // // //   State<HoneySuckerScreen> createState() => _HoneySuckerScreenState();
// // // // }

// // // // class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
// // // //   final TextEditingController detailsController = TextEditingController();
// // // //   List<String> waterSubcategories = [];
// // // //   String? selectedSubcategory;

// // // //   LatLng? selectedLatLng;
// // // //   String? displayAddress;
// // // //   bool isLoading = false;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchSubcategories();

// // // //     if (widget.destination != null) {
// // // //       selectedLatLng = widget.destination;
// // // //       _getAddressFromLatLng(widget.destination!);
// // // //     }
// // // //   }

// // // //   Future<void> fetchSubcategories() async {
// // // //     setState(() => isLoading = true);
// // // //     try {
// // // //       final response = await http.get(
// // // //         Uri.parse(
// // // //           'https://yourapi.com/api/water-subcategories',
// // // //         ), // Replace with your endpoint
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         final data = jsonDecode(response.body);
// // // //         setState(() {
// // // //           waterSubcategories = List<String>.from(data);
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('Error fetching subcategories: $e');
// // // //     } finally {
// // // //       setState(() => isLoading = false);
// // // //     }
// // // //   }

// // // //   Future<void> _getAddressFromLatLng(LatLng latLng) async {
// // // //     try {
// // // //       final placemarks = await placemarkFromCoordinates(
// // // //         latLng.latitude,
// // // //         latLng.longitude,
// // // //       );
// // // //       if (placemarks.isNotEmpty) {
// // // //         final place = placemarks.first;
// // // //         setState(() {
// // // //           displayAddress =
// // // //               "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
// // // //         });
// // // //       } else {
// // // //         setState(() {
// // // //           displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         displayAddress = 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}';
// // // //       });
// // // //       debugPrint("Reverse geocoding failed: $e");
// // // //     }
// // // //   }

// // // //   // Future<void> selectDestination() async {
// // // //   //   final result = await Navigator.push(
// // // //   //     context,
// // // //   //     MaterialPageRoute(
// // // //   //       builder:
// // // //   //           (context) =>
// // // //   //               const WhereToScreen(category: VehicleCategory.waterBowser),
// // // //   //     ),
// // // //   //   );

// // // //   //   if (result != null && result is Map<String, dynamic>) {
// // // //   //     final latLng = result['latlng'] as LatLng?;
// // // //   //     final name = result['name'] as String?;

// // // //   //     setState(() {
// // // //   //       selectedLatLng = latLng;
// // // //   //       displayAddress =
// // // //   //           name ??
// // // //   //           (latLng != null
// // // //   //               ? 'Lat: ${latLng.latitude}, Lng: ${latLng.longitude}'
// // // //   //               : null);
// // // //   //     });
// // // //   //   }
// // // //   // }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text('Exhauster Service'),
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
// // // //                 'Request Exhauster',
// // // //                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// // // //               ),
// // // //               const SizedBox(height: 20),
// // // //               DropdownButtonFormField<String>(
// // // //                 value: selectedSubcategory,
// // // //                 isExpanded: true,
// // // //                 hint: const Text('Select Quantity'),
// // // //                 items:
// // // //                     waterSubcategories.map((subcategory) {
// // // //                       return DropdownMenuItem<String>(
// // // //                         value: subcategory,
// // // //                         child: Text(subcategory),
// // // //                       );
// // // //                     }).toList(),
// // // //                 onChanged:
// // // //                     (value) => setState(() => selectedSubcategory = value),
// // // //                 decoration: const InputDecoration(
// // // //                   border: OutlineInputBorder(),
// // // //                   prefixIcon: Icon(Icons.water_drop),
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
// // // //                 maxLines: 3,
// // // //               ),
// // // //               const SizedBox(height: 16),
// // // //               InkWell(
// // // //                 onTap: () async {
// // // //                   final result = await Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(
// // // //                       builder:
// // // //                           (context) => WhereToScreen(
// // // //                             category: VehicleCategory.exhauster,
// // // //                           ),
// // // //                     ),
// // // //                   );

// // // //                   if (result != null && result is LatLng) {
// // // //                     setState(() {
// // // //                       selectedLatLng = result;
// // // //                     });
// // // //                     _getAddressFromLatLng(result);
// // // //                   }
// // // //                 },

// // // //                 //onTap: selectDestination,
// // // //                 child: Container(
// // // //                   padding: const EdgeInsets.all(14),
// // // //                   decoration: BoxDecoration(
// // // //                     border: Border.all(color: Colors.grey.shade400),
// // // //                     borderRadius: BorderRadius.circular(8),
// // // //                   ),
// // // //                   child: Row(
// // // //                     children: [
// // // //                       const Icon(
// // // //                         Icons.location_on_outlined,
// // // //                         color: Colors.blue,
// // // //                       ),
// // // //                       const SizedBox(width: 12),
// // // //                       Expanded(
// // // //                         child: Text(
// // // //                           displayAddress ?? 'Tap to select destination on map',
// // // //                           style: TextStyle(
// // // //                             color:
// // // //                                 displayAddress == null
// // // //                                     ? Colors.grey
// // // //                                     : Colors.black87,
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ],
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

// // // // // ignore: file_names
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_map/flutter_map.dart';
// // // // import 'package:latlong2/latlong.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// // // // //import 'where_to_screen.dart';

// // // // class HoneySuckerScreen extends StatefulWidget {
// // // //   const HoneySuckerScreen({super.key, required VehicleCategory category});

// // // //   @override
// // // //   _HoneySuckerScreenState createState() => _HoneySuckerScreenState();
// // // // }

// // // // class _HoneySuckerScreenState extends State<HoneySuckerScreen> {
// // // //   final TextEditingController detailsController = TextEditingController();
// // // //   LatLng? selectedLocation;
// // // //   LatLng? destinationLocation;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: Colors.white,
// // // //       appBar: AppBar(
// // // //         title: const Text('Honey Sucker Services'),
// // // //         centerTitle: true,
// // // //         backgroundColor: Colors.white,
// // // //         elevation: 0,
// // // //         foregroundColor: Colors.black,
// // // //       ),
// // // //       body: Padding(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             const Text(
// // // //               'Request Honey Sucker Service',
// // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             TextFormField(
// // // //               controller: detailsController,
// // // //               decoration: const InputDecoration(labelText: 'Service Details'),
// // // //               maxLines: 3,
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             Expanded(
// // // //               child: FlutterMap(
// // // //                 options: MapOptions(
// // // //                   center: LatLng(-1.286389, 36.817223), // Default to Nairobi
// // // //                   zoom: 12.0,
// // // //                   onTap: (tapPosition, point) {
// // // //                     setState(() {
// // // //                       if (selectedLocation == null) {
// // // //                         selectedLocation = point;
// // // //                       } else {
// // // //                         destinationLocation = point;
// // // //                       }
// // // //                     });
// // // //                   },
// // // //                 ),
// // // //                 children: [
// // // //                   TileLayer(
// // // //                     urlTemplate:
// // // //                         "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
// // // //                     subdomains: ['a', 'b', 'c'],
// // // //                   ),
// // // //                   if (selectedLocation != null)
// // // //                     MarkerLayer(
// // // //                       markers: [
// // // //                         Marker(
// // // //                           point: selectedLocation!,
// // // //                           builder:
// // // //                               (ctx) => const Icon(
// // // //                                 Icons.location_pin,
// // // //                                 color: Colors.blue,
// // // //                                 size: 40,
// // // //                               ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   if (destinationLocation != null)
// // // //                     MarkerLayer(
// // // //                       markers: [
// // // //                         Marker(
// // // //                           point: destinationLocation!,
// // // //                           builder:
// // // //                               (ctx) => const Icon(
// // // //                                 Icons.flag,
// // // //                                 color: Colors.green,
// // // //                                 size: 40,
// // // //                               ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             ElevatedButton(
// // // //               onPressed: () {
// // // //                 Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(
// // // //                     builder:
// // // //                         (context) => const WhereToScreen(
// // // //                           category: VehicleCategory.exhauster,
// // // //                         ),
// // // //                   ),
// // // //                 );
// // // //               },
// // // //               style: ElevatedButton.styleFrom(
// // // //                 backgroundColor: Colors.lightBlueAccent,
// // // //                 foregroundColor: Colors.white,
// // // //               ),
// // // //               child: const Text('Request Service'),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
