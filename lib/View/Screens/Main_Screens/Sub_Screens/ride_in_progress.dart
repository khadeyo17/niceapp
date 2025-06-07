import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'dart:async';

import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

class RideInProgressScreen extends ConsumerStatefulWidget {
  final ll.LatLng driverStart;
  final ll.LatLng pickup;

  const RideInProgressScreen({
    super.key,
    required this.driverStart,
    required this.pickup,
  });

  @override
  ConsumerState<RideInProgressScreen> createState() =>
      _RideInProgressScreenState();
}

class _RideInProgressScreenState extends ConsumerState<RideInProgressScreen> {
  final MapController mapController = MapController();
  StreamSubscription<ll.LatLng>? movementSub;

  Stream<ll.LatLng> simulateDriverMovement({
    required ll.LatLng from,
    required ll.LatLng to,
    int steps = 20,
    Duration interval = const Duration(seconds: 2),
  }) async* {
    double latStep = (to.latitude - from.latitude) / steps;
    double lngStep = (to.longitude - from.longitude) / steps;

    for (int i = 0; i <= steps; i++) {
      yield ll.LatLng(
        from.latitude + (i * latStep),
        from.longitude + (i * lngStep),
      );
      await Future.delayed(interval);
    }
  }

  @override
  void initState() {
    super.initState();

    movementSub = simulateDriverMovement(
      from: widget.driverStart,
      to: widget.pickup,
    ).listen((position) {
      ref.read(driverPositionProvider.notifier).state = position;

      mapController.move(position, mapController.zoom);
    });
  }

  @override
  void dispose() {
    movementSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverPosition = ref.watch(driverPositionProvider);

    List<Marker> markers = [
      Marker(
        point: widget.pickup,
        width: 40,
        height: 40,
        builder:
            (ctx) =>
                const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    ];

    if (driverPosition != null) {
      markers.add(
        Marker(
          point: driverPosition,
          width: 40,
          height: 40,
          builder:
              (ctx) => const Icon(
                Icons.directions_car,
                color: Colors.green,
                size: 40,
              ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Driver En Route")),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(center: widget.pickup, zoom: 14.0),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
