// ignore: file_names
import 'package:flutter/material.dart';

class CarHireScreen extends StatefulWidget {
  const CarHireScreen({super.key});

  @override
  _CarHireScreenState createState() => _CarHireScreenState();
}

class _CarHireScreenState extends State<CarHireScreen> {
  final TextEditingController carTypeController = TextEditingController();
  final TextEditingController rentalDurationController =
      TextEditingController();
  final TextEditingController pickupLocationController =
      TextEditingController();
  final TextEditingController dropoffLocationController =
      TextEditingController();
  final TextEditingController additionalNotesController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Car Hire Services'),
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
              'Request Car Hire Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: carTypeController,
              decoration: const InputDecoration(
                labelText: 'Preferred Car Type',
              ),
            ),
            TextFormField(
              controller: rentalDurationController,
              decoration: const InputDecoration(
                labelText: 'Rental Duration (e.g., 2 days, 1 week)',
              ),
            ),
            TextFormField(
              controller: pickupLocationController,
              decoration: const InputDecoration(labelText: 'Pickup Location'),
            ),
            TextFormField(
              controller: dropoffLocationController,
              decoration: const InputDecoration(labelText: 'Dropoff Location'),
            ),
            TextFormField(
              controller: additionalNotesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement request logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request Car Hire'),
            ),
          ],
        ),
      ),
    );
  }
}
