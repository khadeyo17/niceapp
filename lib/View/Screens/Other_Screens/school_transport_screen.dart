import 'package:flutter/material.dart';

class SchoolTransportScreen extends StatelessWidget {
  const SchoolTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Transport'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Welcome to School Transport Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
