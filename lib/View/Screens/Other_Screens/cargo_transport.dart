import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/pending_vehicle_assignment.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

class CargoTransportScreen extends ConsumerStatefulWidget {
  //class CargoTransportScreen extends StatefulWidget {
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
  //class _CargoTransportScreenState extends ConsumerState<CargoTransportScreen>
  //State<CargoTransportScreen> createState() => _CargoTransportScreenState();
  ConsumerState<CargoTransportScreen> createState() =>
      _CargoTransportScreenState();
}

class _CargoTransportScreenState extends ConsumerState<CargoTransportScreen> {
  //class _CargoTransportScreenState extends State<CargoTransportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController cargoTypeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  DateTime? transportDate;
  final transportDateController = TextEditingController();
  //final TextEditingController transportDateController = TextEditingController();

  List<VehicleSubCategory> vehicleCategories = [];
  List<FareEstimate?> fareEstimates = [];
  bool isLoadingCategories = true;
  bool showdrag = false;
  int selectedIndex = -1;

  String? fromLocation;
  String? toLocation;
  double distanceInKm = 0.0;

  List<Map<String, dynamic>> nearbyTransporters = [];

  @override
  void initState() {
    super.initState();
    transportDateController.text = '';
    _initializeLocationNames();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categories = await fetchVehicleSubCategories(widget.category.index);
      fareEstimates = List<FareEstimate?>.filled(categories.length, null);

      setState(() {
        vehicleCategories = categories;
        fareEstimates = List<FareEstimate?>.filled(categories.length, null);
        isLoadingCategories = false;

        if (categories.isNotEmpty) {
          selectedIndex = 0;
          ref.read(selectedCategoryProvider.notifier).state = categories[0];
        }
      });
      if (widget.pickup != null && widget.destination != null) {
        for (int i = 0; i < categories.length; i++) {
          final category = categories[i];
          try {
            final estimate = await FareService.getFareEstimate(
              categoryId: category.id,
              pickupLat: widget.pickup!.latitude,
              pickupLng: widget.pickup!.longitude,
              destLat: widget.destination!.latitude,
              destLng: widget.destination!.longitude,
              countryCode: "KE",
            );
            print('Received estimate for ${category.name}: $estimate');
            setState(() {
              fareEstimates[i] = estimate;
            });
          } catch (e) {
            print('Failed to load fare for category ${category.name}: $e');
          }
        }
      }
    });
  }

  Future<void> _initializeLocationNames() async {
    if (widget.pickup != null) {
      final fromName = await _getPlaceName(widget.pickup!);
      setState(() => fromLocation = fromName);
    }

    if (widget.destination != null) {
      final toName = await _getPlaceName(widget.destination!);
      setState(() => toLocation = toName);
    }

    if (widget.pickup != null && widget.destination != null) {
      // final distance = Distance().as(
      //   LengthUnit.Kilometer,
      //   widget.pickup!,
      //   widget.destination!,
      // );
      final distance = Geolocator.distanceBetween(
        widget.pickup!.latitude,
        widget.pickup!.longitude,
        widget.destination!.latitude,
        widget.destination!.longitude,
      );

      var distanceInKm = distance / 1000;

      setState(
        () => distanceInKm = double.parse(distanceInKm.toStringAsFixed(2)),
      );
    }
  }

  Future<void> _selectTransportDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
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

    // final DateTime? selectedDate = await showDatePicker(
    //   context: context,
    //   initialDate: DateTime.now().add(Duration(minutes: 30)),
    //   firstDate: DateTime.now(),
    //   lastDate: DateTime.now().add(Duration(days: 60)),
    // );
    // if (selectedDate != null) {
    //   setState(() {
    //     transportDate = selectedDate;
    //     transportDateController.text = DateFormat(
    //       'yyyy-MM-dd',
    //     ).format(selectedDate);
    //   });
    // }
  }

  Future<List<VehicleSubCategory>> fetchVehicleSubCategories(int type) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/rides/categories?type=$type',
      ), // e.g., type=0 for RideBooking
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      // Flatten all subCategories from all categories
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
      final place = placemarks.first;
      return "${place.name}, ${place.locality}, ${place.country}";
    } catch (e) {
      return "Location not found";
    }
  }

  void _showTransporterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              nearbyTransporters.isEmpty
                  ? const Text("No nearby transporters found.")
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Nearby Transporters",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...nearbyTransporters.map((transporter) {
                        return Card(
                          child: ListTile(
                            title: Text(transporter['name']),
                            subtitle: Text(
                              "Distance: ${transporter['distance_km']} km",
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      }),
                    ],
                  ),
        );
      },
    );
  }

  // void dispose() {
  //   transportDateController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedFare =
        (selectedIndex >= 0 && selectedIndex < fareEstimates.length)
            ? fareEstimates[selectedIndex]?.fare ?? 0.0
            : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Transport'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Book Cargo Transport',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pickup (read-only)
                    TextFormField(
                      controller: TextEditingController(
                        text: fromLocation ?? '',
                      ),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Pickup Location",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Destination (editable)
                    TextFormField(
                      controller: TextEditingController(text: toLocation ?? ''),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const WhereToScreen(
                                  category: VehicleCategory.cargo,
                                ),
                          ),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            fromLocation = result['from'];
                            toLocation = result['to'];
                          });
                          await _initializeLocationNames();
                          await fetchVehicleSubCategories(
                            widget.category.index,
                          );
                        }
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Destination Location",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // _buildTextField(senderNameController, 'Sender Name'),
                    _buildTextField(receiverNameController, 'Receiver Name'),
                    _buildTextField(cargoTypeController, 'Type of Cargo'),
                    _buildTextField(
                      weightController,
                      'Weight (Kg)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    _buildTextField(
                      volumeController,
                      'Volume (e.g. 5 cubic meters)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _selectTransportDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          transportDateController,
                          'Transportation Date',
                          //Icons.date_range,
                        ),
                      ),
                    ),

                    _buildTextField(
                      detailsController,
                      'Additional Details (Optional)',
                      maxLines: 3,
                      required: false,
                    ),

                    // const SizedBox(height: 20),
                    // const Divider(),

                    // const Text(
                    //   'Delivery Route',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                    // const SizedBox(height: 12),

                    // if (distanceInKm != null)
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(vertical: 8.0),
                    //     child: Text(
                    //     "Distance: $distanceInKm km",
                    //       style: const TextStyle(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //   ),
                    // const SizedBox(height: 12),

                    // _buildInfoRow('From', fromLocation),
                    // const SizedBox(height: 10),
                    // _buildInfoRow('To', toLocation),
                    // const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        // final result = await Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder:
                        //         (context) => const WhereToScreen(
                        //           category: VehicleCategory.cargo,
                        //         ),
                        //   ),
                        // );

                        // if (result != null && result is Map<String, dynamic>) {
                        //   setState(() {
                        //     fromLocation = result['from'];
                        //     toLocation = result['to'];
                        //   });

                        // Calculate distance & fetch transporters
                        // showdrag = true;
                        // //await _initializeLocationNames();
                        // await fetchVehicleSubCategories(widget.category.index);
                        setState(() => showdrag = true);
                        await fetchVehicleSubCategories(widget.category.index);
                      },

                      icon: const Icon(Icons.location_on),
                      label: const Text("Search Transport"),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    //final Spacer();
                  ],
                ),
              ),
            ),
          ),

          if (showdrag)
            DraggableScrollableSheet(
              initialChildSize: 0.4, // 40% of screen height
              minChildSize:
                  0.25, // Never collapse below 25% (ensures 1 category is visible)
              maxChildSize: 0.8, // Optional, can grow up to 80%
              builder: (context, scrollController) {
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
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          //itemCount: vehicleCategories.length,
                          itemCount:
                              isLoadingCategories
                                  ? 0
                                  : vehicleCategories.length,
                          padding: const EdgeInsets.all(12),

                          itemBuilder: (context, index) {
                            final category = vehicleCategories[index];
                            final name = category.name;
                            final passengers = category.maxPassengers;
                            final isSelected = selectedIndex == index;
                            //new

                            // if (fareEstimates.isNotEmpty &&
                            //     index < fareEstimates.length) {
                            //   final estimate = fareEstimates[index];
                            //   // proceed
                            // } else {
                            //   // Handle empty or invalid state gracefully
                            // }
                            final estimate = fareEstimates[index];

                            final fareDisplay =
                                estimate != null
                                    ? "${estimate.currency} ${estimate.fare.toStringAsFixed(2)}"
                                    : "Loading...";

                            // FareEstimate? estimate;
                            // String fareDisplay = "Loading...";

                            // if (fareEstimates.isNotEmpty &&
                            //     index < fareEstimates.length) {
                            //   estimate = fareEstimates[index];
                            //   fareDisplay =
                            //       "${"Kes"} ${estimate!.fare.toStringAsFixed(2)}";
                            // } else {
                            //   // Optionally handle fallback
                            //   estimate = null;
                            //   fareDisplay = "Loading...";
                            // }

                            final timeAway =
                                estimate != null
                                    ? "${estimate.timeEstimate} mins"
                                    : "Estimating...";

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = category;

                                //  ref.read(selectedCategoryProvider.notifier).state = category;
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.grey
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    category.iconUrl != null &&
                                            category.iconUrl!.isNotEmpty
                                        ? Image.network(
                                          "$ImageUrl${category.iconUrl}",
                                          //category.iconUrl!,
                                          width: 60,
                                          height: 60,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Image.asset(
                                              'assets/imgs/Sedan2.png', // your fallback image
                                              width: 60,
                                              height: 60,
                                            );
                                          },
                                        )
                                        : Image.asset(
                                          'assets/imgs/Sedan2.png',
                                          width: 60,
                                          height: 60,
                                        ),

                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                fareDisplay,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Text(
                                          //   "$timeAway",
                                          //   style: const TextStyle(
                                          //     color: Colors.grey,
                                          //     fontSize: 13,
                                          //   ),
                                          // ),
                                          Text(
                                            timeAway,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$passengers Passengers",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final selected = ref.watch(selectedCategoryProvider);
                          final index = selectedIndex;
                          final isEnabled = selected != null;
                          final category = selected?.name ?? 'N/A';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed:
                                    isEnabled &&
                                            index >= 0 &&
                                            index < fareEstimates.length
                                        ? () {
                                          if (transportDate == null) {
                                            transportDate =
                                                DateTime.timestamp();
                                          }
                                          final estimate = fareEstimates[index];
                                          if (estimate != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      _,
                                                    ) => PendingDriverAssignmentScreen(
                                                      pickup: widget.pickup!,
                                                      destination:
                                                          widget.destination!,
                                                      category: selected!,
                                                      fare: estimate.fare,
                                                      receiverName:
                                                          receiverNameController
                                                              .text,
                                                      cargoType:
                                                          cargoTypeController
                                                              .text,
                                                      details:
                                                          detailsController
                                                              .text,
                                                      transportDate:
                                                          transportDate!,

                                                      volume:
                                                          double.tryParse(
                                                            volumeController
                                                                .text,
                                                          ) ??
                                                          0,
                                                      weight:
                                                          double.tryParse(
                                                            weightController
                                                                .text,
                                                          ) ??
                                                          0,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Fare estimate not available",
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                        : null,
                                child: Text("Select $category"),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator:
            required
                ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                }
                : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'Not selected',
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
