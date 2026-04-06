import 'package:flutter/material.dart';
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

class ComplaintScreen extends StatefulWidget {
  final RideHistory ride;

  const ComplaintScreen({super.key, required this.ride});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _controller = TextEditingController();

  void submitComplaint() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    // 🔥 You can send to API here later
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Complaint submitted")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Tell us what went wrong",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Describe your issue...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitComplaint,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
