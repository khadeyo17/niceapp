import 'package:flutter/material.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';

class GeneralPaymentSuccessScreen extends StatelessWidget {
  final VehicleCategory serviceType;
  final double amount;

  const GeneralPaymentSuccessScreen({
    super.key,
    required this.serviceType,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Close any previous loading dialogs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white10,
      appBar: AppBar(
        title: const Text("Booking Confirmed"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Success!",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Your ${serviceType.displayName} payment has been confirmed.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text("Paid Amount"),
                      subtitle: Text("KES ${amount.toStringAsFixed(2)}"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransportServicesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text("Return to Home"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
