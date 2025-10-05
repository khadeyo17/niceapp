import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Vehicles/bus_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String busId;
  final String seatNumber;
  final int rideId;
  final DateTime travelDate;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.busId,
    required this.seatNumber,
    required this.travelDate,
    required this.amount,
    required this.rideId,
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
        Uri.parse('$baseUrl/payments/mpesa/initiate'),
        headers: {
          'Content-Type': 'application/json',
          //'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "busId": widget.busId,
          "seatNumber": widget.seatNumber,
          "travelDate": widget.travelDate.toIso8601String(),
          "amount": widget.amount,
          "phoneNumber": phoneController.text.trim().replaceFirst('+', ''),
          "firebaseId": user.uid,
          "rideId": widget.rideId,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final transactionId = body['transactionId'];

        final callbackResponse = await http.post(
          Uri.parse('$baseUrl/payments/mpesaupdate/callback'),
          headers: {
            'Content-Type': 'application/json',
            // 'Authorization': 'Bearer $token', // Optional
          },
          body: jsonEncode({
            "transactionId": transactionId,
            "rideId": widget.rideId,
            // match exact value
          }),
        );
        if (callbackResponse.statusCode != 200) {
          throw Exception("Callback failed: ${callbackResponse.body}");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment simulated. Callback successful."),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("STK Push sent. Waiting for confirmation..."),
          ),
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        // Polling every 5 seconds
        bool confirmed = false;
        for (int i = 0; i < 12; i++) {
          await Future.delayed(const Duration(seconds: 8));

          final statusResponse = await http.get(
            Uri.parse('$baseUrl/payments/status/$transactionId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            final status = statusData['status'];
            if (status == 'Success') {
              confirmed = true;
              if (confirmed && mounted) {
                await Future.delayed(const Duration(seconds: 10));

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BookingSuccessScreen(
                          seatNumber: widget.seatNumber,
                          travelDate: widget.travelDate,
                          amount: widget.amount,
                        ),
                  ),
                );
              }
            }

            // if (status == 'Success') {
            //   confirmed = true;
            //   if (confirmed) {
            //     Navigator.pushReplacement(
            //       context,
            //       MaterialPageRoute(
            //         builder:
            //             (_) => BookingSuccessScreen(
            //               seatNumber: widget.seatNumber,
            //               travelDate: widget.travelDate,
            //               amount: widget.amount,
            //             ),
            //       ),
            //     );
            //   }
            // }
          }
        }

        Navigator.pop(context); // Close loading
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Payment Exception: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> completeBooking(String? token) async {
    final bookingResponse = await http.post(
      Uri.parse('$baseUrl/rides/bus/book'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "busId": widget.busId,
        "seatNumber": widget.seatNumber,
        "travelDate": widget.travelDate.toIso8601String(),
        "firebaseIdToken": token,
      }),
    );

    if (bookingResponse.statusCode == 200) {
      //  Navigator.push(
      //                     context,
      //                     MaterialPageRoute(
      //                       builder:
      //                           (_) => PaymentScreen(
      //                             busId: widget.bus['id'].toString(),
      //                             seatNumber: selectedSeat!,
      //                             travelDate: widget.travelDate,
      //                             amount: selectedFare,
      //                           ),
      //                     ),
      //                   );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => BookingSuccessScreen(
                seatNumber: widget.seatNumber,
                travelDate: widget.travelDate,
                amount: widget.amount,
              ),
        ),
      );

      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text("Booking successful")));
      // Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: ${bookingResponse.body}")),
      );
    }

    setState(() => isProcessing = false);
  }

  // Future<void> initiateMpesaPayment() async {
  //   setState(() => isProcessing = true);

  //   final token = await FirebaseAuth.instance.currentUser?.getIdToken();

  //   final mpesaResponse = await http.post(
  //     Uri.parse('$baseUrl/payments/mpesa/initiate'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       "busId": widget.busId,
  //       "seatNumber": widget.seatNumber,
  //       "travelDate": widget.travelDate.toIso8601String(),
  //       "amount": widget.amount,
  //       "phoneNumber": phoneController.text.trim(),
  //       "firebaseIdToken": token,
  //     }),
  //   );

  //   if (mpesaResponse.statusCode == 200) {
  //     // Payment success, now call the booking API
  //     final bookingResponse = await http.post(
  //       Uri.parse('$baseUrl/rides/bookings'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         "busId": widget.busId,
  //         "seatNumber": widget.seatNumber,
  //         "travelDate": widget.travelDate.toIso8601String(),
  //         "firebaseIdToken": token,
  //       }),
  //     );

  //     setState(() => isProcessing = false);

  //     if (bookingResponse.statusCode == 200) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text("Booking successful")));
  //       Navigator.pop(context); // Exit screen on success
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             "Payment was successful but booking failed: ${bookingResponse.body}",
  //           ),
  //         ),
  //       );
  //     }
  //   } else {
  //     setState(() => isProcessing = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Payment failed: ${mpesaResponse.body}")),
  //     );
  //   }
  // }

  // Future<void> initiateMpesaPayment() async {
  //   setState(() => isProcessing = true);

  //   final token = await FirebaseAuth.instance.currentUser?.getIdToken();

  //   final response = await http.post(
  //     Uri.parse('$baseUrl/payments/mpesa/initiate'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       "busId": widget.busId,
  //       "seatNumber": widget.seatNumber,
  //       "travelDate": widget.travelDate.toIso8601String(),
  //       "amount": widget.amount,
  //       "phoneNumber": phoneController.text.trim(),
  //       "firebaseIdToken": token,
  //     }),
  //   );

  //   setState(() => isProcessing = false);

  //   if (response.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("STK Push sent to your phone")),
  //     );
  //     Navigator.pop(context); // Go back after success
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Payment failed: ${response.body}")),
  //     );
  //   }
  // }

  //   @override
  //   Widget build(BuildContext context) {
  //     return Scaffold(
  //       appBar: AppBar(title: const Text("Confirm Payment")),
  //       body: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Seat: ${widget.seatNumber}",
  //               style: const TextStyle(fontSize: 16),
  //             ),
  //             Text(
  //               "Amount: KES ${widget.amount}",
  //               style: const TextStyle(fontSize: 16),
  //             ),
  //             const SizedBox(height: 20),
  //             TextFormField(
  //               controller: phoneController,
  //               decoration: const InputDecoration(
  //                 labelText: "Phone Number",
  //                 border: OutlineInputBorder(),
  //               ),
  //               keyboardType: TextInputType.phone,
  //             ),
  //             const SizedBox(height: 30),
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton.icon(
  //                 icon: const Icon(Icons.payment),
  //                 label:
  //                     isProcessing
  //                         ? const CircularProgressIndicator(color: Colors.white)
  //                         : const Text("Pay with M-Pesa"),
  //                 onPressed: isProcessing ? null : initiateMpesaPayment,
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.green,
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Payment"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
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
                    const Text(
                      "Booking Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "Seat: ${widget.seatNumber}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "Amount: KES ${widget.amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "Travel Date: ${widget.travelDate.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
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
