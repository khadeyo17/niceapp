import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:niceapp/Container/utils/keys.dart';

class RideIssueService {
  // Replace with your actual API address.
  // Android emulator: http://10.0.2.2:5001
  // Physical phone: use your computer's LAN IP and API port.
  //static const String baseUrl = 'https://YOUR_API_DOMAIN';

  static Future<Map<String, dynamic>> submitIssue({
    required int? rideId,
    required String? reportedByRole,
    required String? vehicleRegistrationNumber,
    required String? driverName,
    required String? passengerName,
    required String? pickup,
    required String? destination,
    required String? description,
    String? passengerId,
    String? driverId,
    String? issueCategory,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please sign in before submitting an issue.');
    }
    passengerId=user.uid;
    final token = await user.getIdToken();

    final body = {
      'rideId': rideId,
      'reportedById': user.uid,
      'reportedByRole': reportedByRole,
      'passengerId': passengerId,
      'driverId': driverId,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'driverName': driverName,
      'passengerName': passengerName,
      'pickup': pickup,
      'destination': destination,
      'issueCategory': issueCategory ?? 'Other',
      'description': description,
    };

    final response = await http
        .post(
          Uri.parse('$baseUrl/passengerrides/reportissue'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final responseBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode == 200 &&
        responseBody['success'] == true) {
      return Map<String, dynamic>.from(responseBody);
    }

    throw Exception(
      responseBody['message'] ?? 'Unable to submit your issue.',
    );
  }

static Future<List<Map<String, dynamic>>> getMyIssues() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('Please sign in to view your issues.');
  }

  final token = await user.getIdToken();

  final uri = Uri.parse('$baseUrl/passengerrides/myissues').replace(
    queryParameters: {
      'firebaseUid': user.uid,
      'role': 'Passenger',
    },
  );

  final response = await http.get(
    uri,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  ).timeout(const Duration(seconds: 30));

  final responseBody = jsonDecode(response.body);

  if (response.statusCode == 200 &&
      responseBody['success'] == true) {
    return List<Map<String, dynamic>>.from(
      responseBody['data'] ?? [],
    );
  }

  throw Exception(
    responseBody['message'] ?? 'Unable to load your issues.',
  );
}

}