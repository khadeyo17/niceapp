import 'package:flutter/material.dart';

class AvailableBusesScreen extends StatelessWidget {
  final String origin;
  final String destination;
  final String travelDate;
  final int numPassengers;

  const AvailableBusesScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.travelDate,
    required this.numPassengers,
  });

  @override
  Widget build(BuildContext context) {
    final buses = [
      {'name': 'Modern Coast', 'time': '08:00 AM', 'price': 1200},
      {'name': 'Dreamline Express', 'time': '10:30 AM', 'price': 1500},
      {'name': 'Mash Poa', 'time': '02:00 PM', 'price': 1100},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];
          return Card(
            child: ListTile(
              title: Text('${bus['name']} - ${bus['time']}'),
              subtitle: Text('Ksh ${bus['price']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  // Handle booking here or navigate to payment
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booked ${bus['name']}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Book Now'),
              ),
            ),
          );
        },
      ),
    );
  }
}
