import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'fare_estimate_model.dart';

class FareService {
  static Future<FareEstimate> getFareEstimate({
    required int categoryId,
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    String countryCode = "KE",
  }) async {
    final uri = Uri.parse(
      '$baseUrl/vehicles/fare/estimate'
      '?categoryId=$categoryId'
      '&pickupLat=$pickupLat'
      '&pickupLng=$pickupLng'
      '&destLat=$destLat'
      '&destLng=$destLng'
      '&countryCode=$countryCode',
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
}
