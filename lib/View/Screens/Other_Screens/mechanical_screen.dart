import 'package:flutter/material.dart';

class MechanicalScreen extends StatelessWidget {
  const MechanicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanical Services'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Welcome to Mechanical Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
