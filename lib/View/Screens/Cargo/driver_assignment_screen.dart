import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

class DriverAssignmentScreen extends StatelessWidget {
  final String status;
  final LatLng pickup;
  final LatLng destination;
  final VehicleSubCategory category;
  final double fare;

  const DriverAssignmentScreen({
    super.key,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.category,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    // Simulate driver details only if status is "Vehicle Assigned"
    final bool isAssigned = status == "Vehicle Assigned";

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Assignment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Transport Status",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(status, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(height: 32),
            Text("Pickup: ${pickup.latitude}, ${pickup.longitude}"),
            Text(
              "Destination: ${destination.latitude}, ${destination.longitude}",
            ),
            Text("Category: ${category.name}"),
            Text("Fare: ${fare.toStringAsFixed(2)}"),
            const SizedBox(height: 20),

            if (isAssigned) ...[
              const Divider(height: 32),
              const Text(
                "Assigned Vehicle & Driver",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.car_rental),
                title: const Text("Reg No."),
                subtitle: const Text("KDJ 123P"),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Driver Name"),
                subtitle: const Text("John Doe"),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Mobile Number"),
                subtitle: const Text("+254 712 345678"),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("ETA (Driver Arrival)"),
                subtitle: const Text("15 mins"),
              ),
              ListTile(
                leading: const Icon(Icons.timelapse),
                title: const Text("ETA (Goods Arrival)"),
                subtitle: const Text("45 mins"),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Transport Date"),
                subtitle: Text(
                  DateTime.now().toLocal().toString().split(".")[0],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
