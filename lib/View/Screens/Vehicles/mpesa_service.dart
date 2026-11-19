// mpesa_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:niceapp/Container/utils/keys.dart';

class MpesaService {
  static Future<String?> getIdToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  static Future<bool> initiateMpesaPayment({
    required String busId,
    required String seatNumber,
    required DateTime travelDate,
    required double amount,
    required String phoneNumber,
  }) async {
    final token = await getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/payments/mpesa/initiate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "busId": busId,
        "seatNumber": seatNumber,
        "travelDate": travelDate.toIso8601String(),
        "amount": amount,
        "phoneNumber": phoneNumber.trim(),
        "firebaseIdToken": token,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> bookSeat({
    required String busId,
    required String seatNumber,
    required DateTime travelDate,
  }) async {
    final token = await getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/passengerrides/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "busId": busId,
        "seatNumber": seatNumber,
        "travelDate": travelDate.toIso8601String(),
        "firebaseIdToken": token,
      }),
    );

    return response.statusCode == 200;
  }
}

// payment_screen.dart

class PaymentScreen extends StatefulWidget {
  final String busId;
  final String seatNumber;
  final DateTime travelDate;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.busId,
    required this.seatNumber,
    required this.travelDate,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
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

  Future<void> handlePaymentAndBooking() async {
    setState(() => isProcessing = true);

    final paymentSuccess = await MpesaService.initiateMpesaPayment(
      busId: widget.busId,
      seatNumber: widget.seatNumber,
      travelDate: widget.travelDate,
      amount: widget.amount,
      phoneNumber: phoneController.text,
    );

    if (paymentSuccess) {
      final bookingSuccess = await MpesaService.bookSeat(
        busId: widget.busId,
        seatNumber: widget.seatNumber,
        travelDate: widget.travelDate,
      );

      setState(() => isProcessing = false);

      if (bookingSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Booking successful")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment success, but booking failed")),
        );
      }
    } else {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seat: ${widget.seatNumber}"),
            Text("Amount: KES ${widget.amount}"),
            const SizedBox(height: 20),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label:
                    isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Pay with M-Pesa"),
                onPressed: isProcessing ? null : handlePaymentAndBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (Optional) payment_list_screen.dart

class PaymentListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> paymentHistory = const [
    {"date": "2024-06-01", "amount": 500.0, "status": "Success"},
    {"date": "2024-06-10", "amount": 400.0, "status": "Failed"},
    {"date": "2024-06-15", "amount": 300.0, "status": "Success"},
  ];

  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment History")),
      body: ListView.builder(
        itemCount: paymentHistory.length,
        itemBuilder: (_, index) {
          final payment = paymentHistory[index];
          return ListTile(
            leading: Icon(
              payment['status'] == 'Success' ? Icons.check_circle : Icons.error,
              color: payment['status'] == 'Success' ? Colors.green : Colors.red,
            ),
            title: Text("KES ${payment['amount']}"),
            subtitle: Text(payment['date']),
            trailing: Text(payment['status']),
          );
        },
      ),
    );
  }
}
