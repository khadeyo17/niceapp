import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';

final selectedCategoryProvider = StateProvider<VehicleSubCategory?>(
  (ref) => null,
);

final availableDriversProvider = StateProvider<List<Driver>>((ref) => []);

final linkedDriverProvider = StateProvider<Driver?>((ref) => null);
final estimatedFareProvider = StateProvider<double?>((ref) => null);
final rideConfirmedProvider = StateProvider<bool>((ref) => false);
// class Driver {
//   final String name;
//   final String vehicle;
//   final LatLng location;

//   Driver({required this.name, required this.vehicle, required this.location});
// }

// class Driver {
//   final String name;
//   final String vehicle;
//   final String category;
//   final LatLng location;
//   final String registrationNumber;
//   final String color;
//   final String photoUrl;
//   final String phoneNumber;

//   Driver({
//     required this.name,
//     required this.vehicle,
//     required this.category,
//     required this.location,
//     required this.registrationNumber,
//     required this.color,
//     required this.photoUrl,
//     required this.phoneNumber,
//   });
// }

// class Driver {
//   final String name;
//   final String vehicle;
//   final String category;
//   final LatLng location;
//   final String registrationNumber;
//   final String color;
//   final String photoUrl;
//   final String phoneNumber;

//   Driver({
//     required this.name,
//     required this.vehicle,
//     required this.category,
//     required this.location,
//     required this.registrationNumber,
//     required this.color,
//     required this.photoUrl,
//     required this.phoneNumber,
//   });

//   factory Driver.fromJson(Map<String, dynamic> json) {
//     return Driver(
//       name: json['name'],
//       vehicle: json['vehicle'],
//       category: json['category'],
//       location: LatLng(json['location']['lat'], json['location']['lng']),
//       registrationNumber: json['registrationNumber'],
//       color: json['color'],
//       photoUrl: json['photoUrl'],
//       phoneNumber: json['phoneNumber'],
//     );
//   }
// }

class Driver {
  final String id;
  final String name;
  final String vehicle;
  final String category;
  final LatLng location;
  final String registrationNumber;
  final String color;
  final String photoUrl;
  final String phoneNumber;

  Driver({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.category,
    required this.location,
    required this.registrationNumber,
    required this.color,
    required this.photoUrl,
    required this.phoneNumber,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['firebaseId'] ?? 'Unknown',
      name: json['firstName'] ?? 'Unknown',
      vehicle: '${json['vehicleMake'] ?? ''} ${json['vehicleModel'] ?? ''}',
      category: 'N/A',
      location: LatLng(
        (json['latitude'] ?? 0.0).toDouble(),
        (json['longitude'] ?? 0.0).toDouble(),
      ),
      // location: LatLng(
      //   (json['latitude'] as num).toDouble(),
      //   (json['longitude'] as num).toDouble(),
      // ),
      registrationNumber: json['registrationNumber'] ?? '',
      color: json['vehicleColour'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}
