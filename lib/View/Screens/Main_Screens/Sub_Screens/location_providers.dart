import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';

// Your Google API Key (keep this in a secure config or .env file in production)
//const String mapKey = "YOUR_GOOGLE_API_KEY";

// Provider for Pickup Location
final pickupLocationProvider = StateProvider<LatLng?>((ref) => null);

// Provider for Current Location
final currentLocationProvider = FutureProvider<LatLng>((ref) async {
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  return LatLng(position.latitude, position.longitude);
});

// Provider for Destination Location
final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

// Provider for Driver's Position
final driverPositionProvider = StateProvider<LatLng?>((ref) => null);

// Provider for Stops List
final stopsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Provider for Pickup Address
final pickupAddressProvider = FutureProvider<String?>((ref) async {
  final pickup = ref.watch(pickupLocationProvider);
  if (pickup == null) return null;

  final address = await ReverseGeocodingService.getNameFromLatLng(pickup);
  return address ?? "Current Location";
});

// Provider for Destination Address
final dropAddressProvider = FutureProvider<String?>((ref) async {
  final destination = ref.watch(destinationLocationProvider);
  if (destination == null) return null;

  final address = await ReverseGeocodingService.getNameFromLatLng(destination);
  return address ?? "Current Location";
});

/////working
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';

// // Provider for Pickup Location
// final pickupLocationProvider = StateProvider<LatLng?>((ref) => null);

// final currentLocationProvider = FutureProvider<LatLng>((ref) async {
//   final position = await Geolocator.getCurrentPosition();
//   return LatLng(position.latitude, position.longitude);
// });

// // Provider for Destination Location
// final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

// // Provider for Stops List
// //final stopsProvider = StateProvider<List<LatLng>>((ref) => []);
// final driverPositionProvider = StateProvider<LatLng?>((ref) => null);
// final stopsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// final pickupAddressProvider = FutureProvider<String?>((ref) async {
//   final pickup = ref.watch(pickupLocationProvider);
//   if (pickup == null) return null;

//   final address = await ReverseGeocodingService.getAddressFromLatLng(pickup);
//   return address ?? "Current Location";
// });

// final dropAddressProvider = FutureProvider<String?>((ref) async {
//   final destination = ref.watch(destinationLocationProvider);
//   if (destination == null) return null;

//   final address = await ReverseGeocodingService.getAddressFromLatLng(
//     destination,
//   );
//   return address ?? "Current Location";
// });

//final driverPositionProvider = StateProvider<ll.LatLng?>((ref) => null);
