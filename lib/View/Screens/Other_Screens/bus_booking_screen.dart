import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

class BusBookingScreen extends StatefulWidget {
  const BusBookingScreen({super.key});

  @override
  _BusBookingScreenState createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  final TextEditingController passengerNameController = TextEditingController();
  final TextEditingController numPassengersController = TextEditingController();
  final TextEditingController travelDateController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  LatLng? selectedLocation;

  late GoogleMapController mapController;

  Future<void> submitBooking() async {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    final data = {
      "passengerName": passengerNameController.text,
      "numPassengers": int.tryParse(numPassengersController.text) ?? 1,
      "travelDate": travelDateController.text,
      "details": detailsController.text,
      "latitude": selectedLocation!.latitude,
      "longitude": selectedLocation!.longitude,
    };

    // Replace this URL with your actual backend endpoint
    final response = await http.post(
      Uri.parse('https://yourapi.com/api/bus-booking'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit booking')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        title: const Text('Bus Booking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book a Bus Ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passengerNameController,
              decoration: const InputDecoration(labelText: 'Passenger Name'),
            ),
            TextFormField(
              controller: numPassengersController,
              decoration: const InputDecoration(
                labelText: 'Number of Passengers',
              ),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: travelDateController,
              decoration: const InputDecoration(labelText: 'Travel Date'),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                FocusScope.of(
                  context,
                ).requestFocus(FocusNode()); // Prevent keyboard
                final pickedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  travelDateController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(pickedDate);
                }
              },
            ),
            TextFormField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional Details (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-1.286389, 36.817223),
                  zoom: 12.0,
                ),
                onMapCreated: (controller) {
                  mapController = controller;
                },
                onTap: (LatLng position) {
                  setState(() {
                    selectedLocation = position;
                  });
                },
                markers:
                    selectedLocation != null
                        ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: selectedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueYellow,
                            ),
                          ),
                        }
                        : {},
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: submitBooking,
              icon: const Icon(Icons.send, color: Colors.yellow),
              label: const Text('Submit Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WhereToScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, color: Colors.yellow),
              label: const Text('Proceed to Destination Selection'),
              style: OutlinedButton.styleFrom(foregroundColor: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
