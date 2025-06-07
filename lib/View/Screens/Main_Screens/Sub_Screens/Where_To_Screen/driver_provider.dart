import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

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

class Driver {
  final String name;
  final String vehicle;
  final String category;
  final LatLng location;

  Driver({
    required this.name,
    required this.vehicle,
    required this.category,
    required this.location,
  });
}
