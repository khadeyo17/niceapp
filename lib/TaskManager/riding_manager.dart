import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FloatingRideManager {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String stage, VoidCallback onTap) {
    if (_entry != null) return; // already shown

    _entry = OverlayEntry(
      builder:
          (ctx) => Positioned(
            bottom: 80,
            right: 20,
            child: GestureDetector(
              onTap: onTap,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        stage, // e.g. "Driver Accepted" / "Ride in Progress"
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
