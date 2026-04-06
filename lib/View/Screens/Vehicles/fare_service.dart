import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'fare_estimate_model.dart';

Future<FareEstimate> getFareEstimate({
  required int categoryId,
  required double pickupLat,
  required double pickupLng,
  required double destLat,
  required double destLng,
  double waitingMinutes = 0,
  double distanceKm = 0,
  double durationMinutes = 0,
  String countryCode = "KE",
  List<Map<String, double>>? stops, // optional stops
}) async {
  print("Calculated Road Distance: $distanceKm km");
  print("Calculated Duration: $durationMinutes min");
  print("Waiting Duration: $waitingMinutes min");

  // Encode stops as JSON if present
  final stopsParam =
      stops != null && stops.isNotEmpty
          ? '&stops=${Uri.encodeComponent(jsonEncode(stops))}'
          : '';

  // Build API URL including stops
  final uri = Uri.parse(
    '$baseUrl/vehicles/fare/estimate'
    '?categoryId=$categoryId'
    '&pickupLat=$pickupLat'
    '&pickupLng=$pickupLng'
    '&destLat=$destLat'
    '&destLng=$destLng'
    '&distanceKm=$distanceKm'
    '&durationMinutes=$durationMinutes'
    '&waitingMinutes=$waitingMinutes'
    '&countryCode=$countryCode'
    '$stopsParam', // append stops if any
  );

  final response = await http.get(uri);

  print("Fare API URL: $uri");
  print("Fare API status: ${response.statusCode}");
  print("Fare API body: ${response.body}");

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    return FareEstimate.fromJson(jsonData);
  } else {
    throw Exception('Failed to fetch fare estimate');
  }
}

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'fare_estimate_model.dart';

// class FareService {
//   static Future<FareEstimate> getFareEstimate({
//     required int categoryId,
//     required double pickupLat,
//     required double pickupLng,
//     required double destLat,
//     required double destLng,
//     double waitingMinutes = 0,
//     double distanceKm = 0,
//     double durationMinutes = 0,
//     String countryCode = "KE", List<Map<String, double>>? stops,
//   }) async {
//     print("Calculated Road Distance: $distanceKm km");
//     print("Calculated Duration: $durationMinutes min");
//     print("Waiting Duration: $waitingMinutes min");

//     // Step 2: Send road distance + duration + waiting time to backend
//     final uri = Uri.parse(
//       '$baseUrl/vehicles/fare/estimate'
//       '?categoryId=$categoryId'
//       '&pickupLat=$pickupLat'
//       '&pickupLng=$pickupLng'
//       '&destLat=$destLat'
//       '&destLng=$destLng'
//       '&distanceKm=$distanceKm'
//       '&durationMinutes=$durationMinutes'
//       '&waitingMinutes=$waitingMinutes'
//       '&countryCode=$countryCode',
//     );

//     final response = await http.get(uri);
//     print("Fare API URL: $uri");
//     print("Fare API status: ${response.statusCode}");
//     print("Fare API body: ${response.body}");

//     if (response.statusCode == 200) {
//       final jsonData = jsonDecode(response.body);
//       return FareEstimate.fromJson(jsonData);
//     } else {
//       throw Exception('Failed to fetch fare estimate');
//     }
//   }
// }
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import 'package:niceapp/Container/utils/keys.dart';
// // import 'fare_estimate_model.dart';

// // class FareService {
// //   static Future<FareEstimate> getFareEstimate({
// //     required int categoryId,
// //     required double pickupLat,
// //     required double pickupLng,
// //     required double destLat,
// //     required double destLng,
// //     String countryCode = "KE",
// //   }) async {
// //     // Step 1: Call Google Directions API for road distance & duration
// //     final directionsUrl =
// //         "https://maps.googleapis.com/maps/api/directions/json"
// //         "?origin=$pickupLat,$pickupLng"
// //         "&destination=$destLat,$destLng"
// //         "&key=$mapKey"; // store your API key in utils/keys.dart

// //     final directionsResponse = await http.get(Uri.parse(directionsUrl));
// //     if (directionsResponse.statusCode != 200) {
// //       throw Exception("Failed to fetch route details");
// //     }

// //     final directionsData = jsonDecode(directionsResponse.body);
// //     final route = directionsData["routes"][0]["legs"][0];

// //     final double distanceKm = route["distance"]["value"] / 1000.0; // meters → km
// //     final double durationMinutes = route["duration"]["value"] / 60.0; // seconds → minutes

// //     print("Calculated Road Distance: $distanceKm km");
// //     print("Calculated Duration: $durationMinutes min");

// //     // Step 2: Send road distance + duration to backend
// //     final uri = Uri.parse(
// //       '$baseUrl/vehicles/fare/estimate'
// //       '?categoryId=$categoryId'
// //       '&pickupLat=$pickupLat'
// //       '&pickupLng=$pickupLng'
// //       '&destLat=$destLat'
// //       '&destLng=$destLng'
// //       '&distanceKm=$distanceKm'
// //       '&durationMinutes=$durationMinutes'
// //       '&countryCode=$countryCode',
// //     );

// //     final response = await http.get(uri);
// //     print("Fare API URL: $uri");
// //     print("Fare API status: ${response.statusCode}");
// //     print("Fare API body: ${response.body}");

// //     if (response.statusCode == 200) {
// //       final jsonData = jsonDecode(response.body);
// //       return FareEstimate.fromJson(jsonData);
// //     } else {
// //       throw Exception('Failed to fetch fare estimate');
// //     }
// //   }
// // }
// // // import 'dart:convert';
// // // import 'package:http/http.dart' as http;
// // // import 'package:niceapp/Container/utils/keys.dart';
// // // import 'fare_estimate_model.dart';

// // // class FareService {
// // //   static Future<FareEstimate> getFareEstimate({
// // //     required int categoryId,
// // //     required double pickupLat,
// // //     required double pickupLng,
// // //     required double destLat,
// // //     required double destLng,
// // //     String countryCode = "KE",
// // //   }) async {
// // //     final uri = Uri.parse(
// // //       '$baseUrl/vehicles/fare/estimate'
// // //       '?categoryId=$categoryId'
// // //       '&pickupLat=$pickupLat'
// // //       '&pickupLng=$pickupLng'
// // //       '&destLat=$destLat'
// // //       '&destLng=$destLng'
// // //       '&countryCode=$countryCode',
// // //     );
// // //     final response = await http.get(uri);
// // //     print("Fare API URL: $uri");
// // //     print("Fare API status: ${response.statusCode}");
// // //     print("Fare API body: ${response.body}");
// // //     if (response.statusCode == 200) {
// // //       final jsonData = jsonDecode(response.body);
// // //       return FareEstimate.fromJson(jsonData);
// // //     } else {
// // //       throw Exception('Failed to fetch fare estimate');
// // //     }
// // //   }
// // // }
