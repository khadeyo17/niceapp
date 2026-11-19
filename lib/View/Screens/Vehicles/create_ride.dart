import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';

class RideCreateDto {
  final String firebaseIdToken;
  final String pickupLocation;
  final String destination;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final int subCategoryId;
  //final int rideId;
  //final int? subCategoryId;

  RideCreateDto({
    required this.firebaseIdToken,
    required this.pickupLocation,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
    required this.subCategoryId,
    required this.destLat,
    required this.destLng,
    //required this.rideId,
    //this.subCategoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      "firebaseIdToken": firebaseIdToken,
      "pickupLocation": pickupLocation,
      "destination": destination,
      "pickupLat": pickupLat,
      "pickupLng": pickupLng,
      "destLat": destLat,
      "destLng": destLng,
      "subCategoryId": subCategoryId,
      // "rideId": rideId,
      // "subCategoryId": subCategoryId,
    };
  }
}
