import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// Provider for Pickup Location
final pickupLocationProvider = StateProvider<LatLng?>((ref) => null);

// Provider for Destination Location
final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

// Provider for Stops List
//final stopsProvider = StateProvider<List<LatLng>>((ref) => []);
final driverPositionProvider = StateProvider<LatLng?>((ref) => null);
final stopsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

//final driverPositionProvider = StateProvider<ll.LatLng?>((ref) => null);
