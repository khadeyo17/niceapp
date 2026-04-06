import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Cargo/driver_assignment_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

// const String baseUrl =
//     'https://your-api-url.com'; // TODO: Replace with your actual API base URL

class PendingDriverAssignmentScreen extends StatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final VehicleSubCategory category;

  final double? fare;
  final String? receiverName;
  final String? cargoType;
  final double? weight;
  final String? details;
  final double? volume;
  final double? distance;
  final DateTime transportDate;
  final String? phone;

  const PendingDriverAssignmentScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.category,
    this.fare,
    this.cargoType,
    this.details,
    this.receiverName,
    required this.transportDate,
    this.volume,
    this.weight,
    this.distance,
    this.phone,
  });

  @override
  State<PendingDriverAssignmentScreen> createState() =>
      _PendingDriverAssignmentScreenState();
}

class _PendingDriverAssignmentScreenState
    extends State<PendingDriverAssignmentScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;
  String? pickupAddress;
  String? destinationAddress;
  double? distanceKm;

  @override
  void initState() {
    super.initState();
    _initializeAddresses();
  }

  Future<void> _initializeAddresses() async {
    pickupAddress = await ReverseGeocodingService.getNameFromLatLng(
      widget.pickup,
    );
    destinationAddress = await ReverseGeocodingService.getNameFromLatLng(
      widget.destination,
    );
    //final Distance distance = Distance();
    distanceKm = Geolocator.distanceBetween(
      widget.pickup.latitude,
      widget.pickup.longitude,
      widget.destination.latitude,
      widget.destination.longitude,
    ); // distanceKm = distance.as(
    //   LengthUnit.Kilometer,
    //   widget.pickup,
    //   widget.destination,
    // );
    setState(() {});
  }

  Future<void> bookRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("User is not authenticated");
      return null;
    }

    final idToken = await user.getIdToken();
    final url = '$baseUrl/rides/cargo/book';

    final pickupLat = widget.pickup.latitude;
    final pickupLng = widget.pickup.longitude;
    final destLat = widget.destination.latitude;
    final destLng = widget.destination.longitude;
    final subCategoryId = widget.category;
    final scheduledTime = widget.transportDate;

    final pickupAddress = await ReverseGeocodingService.getNameFromLatLng(
      LatLng(pickupLat, pickupLng),
    );
    final destinationAddress = await ReverseGeocodingService.getNameFromLatLng(
      LatLng(destLat, destLng),
    );

    final body = {
      "receiverName": widget.receiverName,
      "cargoType": widget.cargoType,
      "weight": widget.weight,
      "details": widget.details,
      "volume": widget.volume,
      "transportDate": widget.transportDate.toIso8601String(),

      "firebaseIdToken": idToken,
      "pickupLocation": pickupAddress,
      "destination": destinationAddress,
      "pickupLat": pickupLat,
      "pickupLng": pickupLng,
      "destLat": destLat,
      "destLng": destLng,
      "subCategoryId": subCategoryId,
      "scheduledTime": scheduledTime?.toIso8601String(),
    };
    if (!mounted) return;
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        // Add this if you use Firebase Auth:
        // 'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      //print('Ride booked successfully: $responseData');
      //final responseData = jsonDecode(response.body);
      final rideId = responseData['rideId'];
      //rideId2 = responseData['rideId'];
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (BuildContext dialogContext) {
      //     // 👇 Capture the dialogContext so you can close it later
      //     _dialogContext = dialogContext;
      //     return AlertDialog(
      //       title: Text("Finding you a driver..."),
      //       content: Column(
      //         mainAxisSize: MainAxisSize.min,
      //         children: const [
      //           CircularProgressIndicator(),
      //           SizedBox(height: 10),
      //           Text("Please wait while we assign a driver."),
      //         ],
      //       ),
      //     );
      //   },
      // );
      // if (scheduledTime == null) {
      //   showFindingDriverDialog(context);
      //   await pollForDriverAssignment(rideId);
      // } else {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => RideHistoryScreen()),
      //   );
      // }
      // Navigate to trip screen if needed
    } else {
      print('Failed to book ride: ${response.statusCode}');
      print(response.body);
    }
  }

  Future<void> _createRide() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final url = Uri.parse(
      '$baseUrl/rides/create',
    ); // Replace with your endpoint

    final body = {
      "pickup": {"lat": widget.pickup.latitude, "lng": widget.pickup.longitude},
      "destination": {
        "lat": widget.destination.latitude,
        "lng": widget.destination.longitude,
      },
      "categoryId": widget.category.id,
      "fare": widget.fare,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Replace with your actual keys returned from backend
        final String rideId = data['rideId'];
        final String status = data['status'];

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder:
        //         // (_) => DriverAssignmentScreen(
        //   //rideId: rideId,
        //   status: "Pending Vehicle Assignment", //status,
        //   pickup: widget.pickup,
        //   destination: widget.destination,
        //   category: widget.category,
        //   //fare: widget.fare,
        //   // vehicleInfo: null,
        // ),
        // ),
        // );
      } else {
        setState(() {
          _errorMessage = "Failed to create ride. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error. Please check your connection.";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.pickup;
    final destination = widget.destination;
    final category = widget.category;
    final fare = widget.fare;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Confirm Transport"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: const Text("Pickup Location"),
                  subtitle: Text(pickupAddress ?? 'Loading...'),
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.flag, color: Colors.green),
                  title: const Text("Destination"),
                  subtitle: Text(destinationAddress ?? 'Loading...'),
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.directions_car,
                    color: Colors.green,
                  ),
                  title: const Text("Vehicle Category"),
                  subtitle: Text(category.name),
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.route, color: Colors.green),
                  title: const Text("Distance"),
                  subtitle: Text(
                    distanceKm != null
                        ? "${distanceKm!.toStringAsFixed(2)} km"
                        : 'Calculating...',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.black),
                  title: const Text("Estimated Fare"),
                  //subtitle: Text("KES ${fare.toStringAsFixed(2)}"),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _createRide,
                  icon:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting ? "Confirming..." : "Confirm Transport",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // SingleChildScrollView(
              //   padding: const EdgeInsets.only(bottom: 16),
              //   child: Container(
              //     width: double.infinity,
              //     margin: const EdgeInsets.symmetric(
              //       horizontal: 16,
              //       vertical: 8,
              //     ),
              //     child: Card(
              //       elevation: 4,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       child: Padding(
              //         padding: const EdgeInsets.all(16.0),
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               "Cargo Details",
              //               style: Theme.of(
              //                 context,
              //               ).textTheme.titleLarge?.copyWith(
              //                 fontWeight: FontWeight.bold,
              //                 color: Colors.blueGrey[800],
              //               ),
              //             ),
              //             const Divider(thickness: 1, height: 20),
              //             const SizedBox(height: 4),
              //             _buildDetailRow(
              //               "Receiver",
              //               widget.receiverName ?? 'N/A',
              //             ),
              //             _buildDetailRow(
              //               "Cargo Type",
              //               widget.cargoType ?? 'N/A',
              //             ),
              //             _buildDetailRow("Weight", "${widget.weight} kg"),
              //             _buildDetailRow("Volume", "${widget.volume} m³"),
              //             _buildDetailRow(
              //               "Transport Date",
              //               DateFormat(
              //                 'yyyy-MM-dd',
              //               ).format(widget.transportDate),
              //             ),
              //             _buildDetailRow("Extra Info", widget.details),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[900]))),
      ],
    ),
  );
}
