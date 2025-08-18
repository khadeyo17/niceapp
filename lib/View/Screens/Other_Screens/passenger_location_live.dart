import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> savePassengerLocation(String passengerId) async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    DatabaseReference ref = FirebaseDatabase.instance.ref(
      'passengers/$passengerId/location',
    );

    await ref.set({
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    print('Location updated successfully.');
  } catch (e) {
    print('Failed to save location: $e');
  }
}

class PassengerLocationLive {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<Position>? _positionStream;

  void startSendingLocation() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('User not logged in.');
      return;
    }

    final String passengerId = user.uid;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permission permanently denied.');
      return;
    }

    // Start listening to location stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    _positionStream!.listen(
      (Position position) {
        FirebaseDatabase.instance.ref('passengers/$passengerId/location').set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onError: (e) {
        print('Location update error: $e');
      },
    );
  }

  void stopSendingLocation() {
    _positionStream =
        null; // Optionally, you can cancel the subscription instead
  }
}
