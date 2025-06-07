import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RideHistory> rides = [
      RideHistory("March 25, 2025", "Nairobi CBD", "Westlands", "KES 450"),
      RideHistory("March 24, 2025", "Kilimani", "Karen", "KES 700"),
      RideHistory("March 23, 2025", "Juja", "Thika", "KES 500"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride History"),
        backgroundColor: Colors.blue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return RideHistoryTile(
            ride: ride,
            onTap: () {
              GoRouter.of(context).go('/ride-history/details');
            },
          );
        },
      ),
    );
  }
}

class RideHistory {
  final String date;
  final String pickup;
  final String destination;
  final String price;

  RideHistory(this.date, this.pickup, this.destination, this.price);
}

class RideHistoryTile extends StatelessWidget {
  final RideHistory ride;
  final VoidCallback onTap;

  const RideHistoryTile({super.key, required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue, // blue background
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.directions_car, color: Colors.blue),
        ),
        title: Text(
          ride.date,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "${ride.pickup} → ${ride.destination}",
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        trailing: Text(
          ride.price,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
