import 'package:flutter/material.dart';
import 'payments_screen.dart';
import 'wallet_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transportServices = [
      {
        'title': 'Ride Booking',
        'icon': Icons.card_travel,
        'color': Colors.orange.withOpacity(0.85),
        'onTap': () {
          // Define navigation for Ride Booking here if you have a screen
        },
      },
      {
        'title': 'Bus Booking',
        'icon': Icons.directions_bus,
        'color': Colors.blue.withOpacity(0.85),
        'onTap': () {
          // Define navigation for Bus Booking here if you have a screen
        },
      },
      {
        'title': 'Honey Sucker',
        'icon': Icons.water_damage,
        'color': Colors.teal.withOpacity(0.85),
        'onTap': () {},
      },
      {
        'title': 'Movers',
        'icon': Icons.local_shipping,
        'color': Colors.purple.withOpacity(0.85),
        'onTap': () {},
      },
      {
        'title': 'Cargo Transport',
        'icon': Icons.local_mall,
        'color': Colors.red.withOpacity(0.85),
        'onTap': () {},
      },
      {
        'title': 'Car Hire',
        'icon': Icons.car_rental,
        'color': Colors.green.withOpacity(0.85),
        'onTap': () {},
      },
      {
        'title': 'Ambulance',
        'icon': Icons.health_and_safety,
        'color': Colors.redAccent.withOpacity(0.85),
        'onTap': () {},
      },
      {
        'title': 'Water Bowser',
        'icon': Icons.water,
        'color': Colors.lightBlue.withOpacity(0.85),
        'onTap': () {},
      },
      {
        'title': 'Breakdown',
        'icon': Icons.car_repair,
        'color': Colors.brown.withOpacity(0.85),
        'onTap': () {},
      },
    ];

    final List<Map<String, dynamic>> financialServices = [
      {
        'title': 'Payments',
        'icon': Icons.payment,
        'color': Colors.blue.withOpacity(0.85),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentScreen()),
          );
        },
      },
      {
        'title': 'Wallet',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green.withOpacity(0.85),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          );
        },
      },
    ];

    final List<Map<String, dynamic>> combinedServices = [
      ...transportServices,
      ...financialServices,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Services"),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.orange.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            itemCount: combinedServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final service = combinedServices[index];
              return _buildServiceTile(
                title: service['title'],
                icon: service['icon'],
                color: service['color'],
                onTap: service['onTap'],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 40,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: color.withOpacity(0.5),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
