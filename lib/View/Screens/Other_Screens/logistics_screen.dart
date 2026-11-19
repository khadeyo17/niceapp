// logistics_screen.dart
import 'package:flutter/material.dart';

class LogisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logistics')),
      body: Center(
        child: Icon(Icons.local_shipping, size: 100, color: Colors.orange),
      ),
    );
  }
}
