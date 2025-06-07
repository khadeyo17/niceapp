// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
//import 'where_to_screen.dart';

class BreakdownScreen extends StatefulWidget {
  const BreakdownScreen({super.key});

  @override
  _BreakdownScreenState createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends State<BreakdownScreen> {
  final TextEditingController detailsController = TextEditingController();
  LatLng? selectedLocation;
  LatLng? destinationLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Breakdown Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Breakdown Assistance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Breakdown Details'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(-1.286389, 36.817223), // Default to Nairobi
                  zoom: 12.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      if (selectedLocation == null) {
                        selectedLocation = point;
                      } else {
                        destinationLocation = point;
                      }
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  if (selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation!,
                          builder:
                              (ctx) => const Icon(
                                Icons.location_pin,
                                color: Colors.blue,
                                size: 40,
                              ),
                        ),
                      ],
                    ),
                  if (destinationLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destinationLocation!,
                          builder:
                              (ctx) => const Icon(
                                Icons.flag,
                                color: Colors.green,
                                size: 40,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WhereToScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request Assistance'),
            ),
          ],
        ),
      ),
    );
  }
}
