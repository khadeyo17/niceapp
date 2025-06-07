import 'package:google_maps_flutter/google_maps_flutter.dart';

class Direction {
  String? humanReadableAddress;
  String? locationName;
  String? locationId;
  double? locationLongitude;
  double? locationLatitude;

  Direction({
    this.humanReadableAddress,
    this.locationName,
    this.locationId,
    this.locationLongitude,
    this.locationLatitude,
  });
  // Add this getter to return a LatLng object
  LatLng get latLng {
    if (locationLatitude != null && locationLongitude != null) {
      return LatLng(locationLatitude!, locationLongitude!);
    }
    return const LatLng(0.0, 0.0); // Default location if null
  }
}
