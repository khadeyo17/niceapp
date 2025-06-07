// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';



class CargoTransportScreen extends StatefulWidget {
  const CargoTransportScreen({super.key});

  @override
  _CargoTransportScreenState createState() => _CargoTransportScreenState();
}

class _CargoTransportScreenState extends State<CargoTransportScreen> {
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController cargoTypeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Cargo Transport'),
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
              'Cargo Transport Booking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: senderNameController,
              decoration: const InputDecoration(labelText: 'Sender Name'),
            ),
            TextFormField(
              controller: receiverNameController,
              decoration: const InputDecoration(labelText: 'Receiver Name'),
            ),
            TextFormField(
              controller: cargoTypeController,
              decoration: const InputDecoration(labelText: 'Type of Cargo'),
            ),
            TextFormField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (Kg)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Additional Details (Optional)'),
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
                      selectedLocation = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  if (selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation!,
                          builder: (ctx) => const Icon(
                            Icons.location_pin,
                            color: Colors.blue,
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
                  MaterialPageRoute(builder: (context) => const WhereToScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Proceed to Destination Selection'),
            ),
          ],
        ),
      ),
    );
  }
}