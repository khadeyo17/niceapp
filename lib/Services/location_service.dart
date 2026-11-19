
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';

class LocationService {
  /// Public method accessible from any screen.
  /// Finds the nearest named place, then falls back to reverse geocoding.
  // Future<String> getPlaceName(LatLng position) async {
  //   try {
  //     // 1. Find nearest named place.
  //     final nearbyPlace = await _findNearestPlace(position);

  //     if (nearbyPlace != null) {
  //       final name =
  //           nearbyPlace['displayName']?['text']?.toString() ?? '';

  //       final formattedAddress =
  //           nearbyPlace['formattedAddress']?.toString() ?? '';

  //       if (name.isNotEmpty) {
  //         if (formattedAddress.isNotEmpty &&
  //             !formattedAddress.toLowerCase().contains(
  //               name.toLowerCase(),
  //             )) {
  //           return '$name, $formattedAddress';
  //         }

  //         return name;
  //       }
  //     }

  //     // 2. Fall back to readable street address.
  //     final address = await _getReadableAddress(position);

  //     if (address != null && address.isNotEmpty) {
  //       return address;
  //     }

  //     return 'Unknown location';
  //   } catch (e, stackTrace) {
  //     debugPrint('Error getting place name: $e');
  //     debugPrintStack(stackTrace: stackTrace);

  //     return 'Unknown location';
  //   }
  // }
  Future<String> getPlaceName(LatLng position) async {
  try {
    // 1. Find the nearest named place.
    final nearbyPlace = await _findNearestPlace(position);

    if (nearbyPlace != null) {
      final name =
          nearbyPlace['displayName']?['text']?.toString().trim() ?? '';

      if (name.isNotEmpty) {
        return name;
      }
    }

    // 2. Fall back to a short readable address.
    final address = await _getReadableAddress(position);

    if (address != null && address.isNotEmpty) {
      final parts = address.split(',');

      return parts.first.trim();
    }

    return 'Unknown location';
  } catch (e, stackTrace) {
    debugPrint('Error getting place name: $e');
    debugPrintStack(stackTrace: stackTrace);

    return 'Unknown location';
  }
}

  /// Searches for nearby named places using Places API (New).
  Future<Map<String, dynamic>?> _findNearestPlace(
      LatLng location) async {
    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchNearby',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': mapKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.primaryType',
        },
        body: jsonEncode({
          'maxResultCount': 10,
          'rankPreference': 'DISTANCE',
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'radius': 100.0,
            },
          },
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
          'Nearby Places error: ${response.statusCode}',
        );
        debugPrint(response.body);
        return null;
      }

      final data = jsonDecode(response.body);
      final List places = data['places'] ?? [];

      if (places.isEmpty) {
        debugPrint('No nearby places found.');
        return null;
      }

      Map<String, dynamic>? nearestPlace;
      double shortestDistance = double.infinity;

      for (final item in places) {
        final place = Map<String, dynamic>.from(item);

        final placeLocation = place['location'];

        if (placeLocation == null) continue;

        final latitude =
            (placeLocation['latitude'] as num?)?.toDouble();

        final longitude =
            (placeLocation['longitude'] as num?)?.toDouble();

        if (latitude == null || longitude == null) continue;

        final distance = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          latitude,
          longitude,
        );

        final name =
            place['displayName']?['text']?.toString() ?? '';

        if (name.isEmpty) continue;

        debugPrint(
          'Nearby place: $name - '
          '${distance.toStringAsFixed(1)}m',
        );

        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestPlace = place;
        }
      }

      if (nearestPlace != null && shortestDistance <= 80) {
        nearestPlace['_distance'] = shortestDistance;
        return nearestPlace;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Nearby place lookup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Converts GPS coordinates into a readable address.
  Future<String?> _getReadableAddress(LatLng location) async {
    try {
      final url = Uri.https(
        'geocode.googleapis.com',
        '/v4/geocode/location',
        {
          'location.latitude': location.latitude.toString(),
          'location.longitude': location.longitude.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'X-Goog-Api-Key': mapKey,
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
          'Reverse geocoding error: ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];

      const preferredTypes = [
        'street_address',
        'premise',
        'subpremise',
        'route',
        'neighborhood',
        'sublocality',
        'locality',
      ];

      for (final type in preferredTypes) {
        for (final item in results) {
          final result = Map<String, dynamic>.from(item);

          final address =
              result['formattedAddress']?.toString() ??
              result['formatted_address']?.toString() ??
              '';

          final types = (result['types'] as List? ?? [])
              .map((e) => e.toString())
              .toList();

          if (address.isEmpty) continue;
          if (types.contains('plus_code')) continue;

          if (types.contains(type)) {
            return address;
          }
        }
      }

      // Final fallback: any readable non-Plus-Code result.
      for (final item in results) {
        final result = Map<String, dynamic>.from(item);

        final address =
            result['formattedAddress']?.toString() ??
            result['formatted_address']?.toString() ??
            '';

        if (address.isEmpty) continue;

        if (RegExp(
          r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,}',
          caseSensitive: false,
        ).hasMatch(address.trim())) {
          continue;
        }

        return address;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Reverse geocoding failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
