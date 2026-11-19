import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Vehicles/general_success_screen.dart';

class GeneralPaymentScreen extends StatefulWidget {
  final VehicleCategory
  serviceType; // e.g., Passenger Ride, Water Bowser, Movers
  final int? rideId;
  final double amount;

  const GeneralPaymentScreen({
    super.key,
    required this.serviceType,
    required this.amount,
    this.rideId,
  });

  @override
  State<GeneralPaymentScreen> createState() => _GeneralPaymentScreenState();
}

class _GeneralPaymentScreenState extends State<GeneralPaymentScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null) {
      phoneController.text = user!.phoneNumber!;
    }
  }

  Future<void> initiateMpesaPayment() async {
    setState(() => isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in.")));
        return;
      }

      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$baseUrl/payments/mpesa/riderequest/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "rideId": widget.rideId,
          "amount": widget.amount,
          "phoneNumber": phoneController.text.trim().replaceFirst('+', ''),
          "firebaseId": user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final transactionId = body['transactionId'];

        // Optional callback for backend confirmation
        await http.post(
          Uri.parse('$baseUrl/payments/mpesa/riderequest/callback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "transactionId": transactionId,
            "rideId": widget.rideId,
          }),
        );

        // Poll payment status
        bool confirmed = false;
        for (int i = 0; i < 12; i++) {
          await Future.delayed(const Duration(seconds: 8));
          final statusResponse = await http.get(
            Uri.parse('$baseUrl/payments/status/$transactionId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            if (statusData['status'] == 'Success') {
              confirmed = true;
              break;
            }
          }
        }

        if (confirmed && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => GeneralPaymentSuccessScreen(
                    serviceType: widget.serviceType,
                    amount: widget.amount,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment not confirmed.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pay for ${widget.serviceType}"),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.serviceType} Summary",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      title: const Text("Amount"),
                      subtitle: Text("KES ${widget.amount.toStringAsFixed(2)}"),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              "Enter your phone number to receive STK push:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.payment),
                label: Text(isProcessing ? "Processing..." : "Pay with M-Pesa"),
                onPressed: isProcessing ? null : initiateMpesaPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
