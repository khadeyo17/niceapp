import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Vehicles/create_ride.dart';

// Future<void> createRide(RideCreateDto ride) async {
//   const String url = '$baseUrl/rides/create'; // replace with your real API

//   final response = await http.post(
//     Uri.parse(url),
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode(ride.toJson()),
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     print('✅ Ride created: ${data['rideId']}');
//     // Optional: handle driver info from data['driver']
//   } else {
//     print('Failed to create ride: ${response.statusCode}');
//     print(response.body);
//   }
// }

// Future<Map<String, dynamic>?> createRide(RideCreateDto ride) async {
//   const String url = '$baseUrl/rides/passenger/book';
//   print(jsonEncode(ride.toJson()));
//   final response = await http.post(
//     Uri.parse(url),
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode(ride.toJson()),
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     return data; // ✅ OK: return Map
//   } else {
//     print('No driver available: ${response.statusCode}');
//     print(response.body);
//     return null;
//   }
// }

// Future<Driver?> createRide(RideCreateDto ride) async {
//   const String url = '$baseUrl/rides/create';
//   print(jsonEncode(ride.toJson()));
//   final response = await http.post(
//     Uri.parse(url),
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode(ride.toJson()),
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     return data;//final driverJson = data['driver'];
//     //return Driver.fromJson(driverJson); // ✅ Return a Driver
//   } else {
//     print('Failed to create ride: ${response.statusCode}');
//     print(response.body);
//     return null;
//   }
// }
