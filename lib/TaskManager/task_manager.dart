import 'package:flutter/widgets.dart';

class FloatingTask {
  //final String id;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  FloatingTask({
    // required this.id,
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

ValueNotifier<List<FloatingTask>> taskManager = ValueNotifier([]);
