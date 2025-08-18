// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';

// class ReverseGeocodingService {
//   static Future<String?> getAddressFromLatLng(LatLng latLng, double longitude) async {
//     final url = Uri.parse(
//       'https://nominatim.openstreetmap.org/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json',
//     );

//     try {
//       final response = await http.get(
//         url,
//         headers: {'User-Agent': 'FlutterApp'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['display_name'] ?? 'Unknown location';
//       } else {
//         print('Reverse geocoding failed: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error during reverse geocoding: $e');
//     }

//     return null;
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:niceapp/Container/utils/keys.dart';

class ReverseGeocodingService {
  static Future<String?> getAddressFromLatLng(
    LatLng latLng,
    // String googleApiKey,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${latLng.latitude},${latLng.longitude}&key=$mapKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        } else {
          print('Google Maps Reverse Geocoding failed: ${data['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during reverse geocoding: $e');
    }

    return null;
  }
}

////working
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';

// class ReverseGeocodingService {
//   static Future<String?> getAddressFromLatLng(LatLng latLng) async {
//     final url = Uri.parse(
//       'https://nominatim.openstreetmap.org/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json',
//     );

//     try {
//       final response = await http.get(
//         url,
//         headers: {'User-Agent': 'FlutterApp'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['display_name'] ?? 'Unknown location';
//       } else {
//         print('Reverse geocoding failed: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error during reverse geocoding: $e');
//     }

//     return null;
//   }
// }
