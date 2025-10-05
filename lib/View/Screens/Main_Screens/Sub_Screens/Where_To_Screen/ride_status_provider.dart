import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Possible ride statuses
enum RideStatus { none, assigned, inProgress }

class RideInfo {
  final String rideId;
  final RideStatus status;
  final String driverId;
  final String? riderName;
  final String? mobile;
  final LatLng pickup;
  final LatLng destination;
  final LatLng? driverlocation;

  RideInfo({
    required this.rideId,
    required this.status,
    this.driverId = "",
    required this.pickup,
    required this.destination,
    this.driverlocation,
    this.mobile,
    this.riderName,
  });
}

/// Helper to parse LatLng from Firebase value
LatLng parseLatLng(dynamic value) {
  if (value is Map) {
    final lat = value['lat'] ?? 0.0;
    final lng = value['lng'] ?? 0.0;
    return LatLng(lat.toDouble(), lng.toDouble());
  } else if (value is String) {
    // e.g., "lat,lng"
    final parts = value.split(',');
    if (parts.length == 2) {
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }
  }
  return LatLng(0, 0);
}

/// StreamProvider that listens to Firebase for ride info
final rideStatusStreamProvider = StreamProvider.family<RideInfo, String>((
  ref,
  userId,
) {
  final ridesRef = FirebaseDatabase.instance.ref("rides");

  return ridesRef.orderByChild("riderId").equalTo(userId).onValue.map((event) {
    if (!event.snapshot.exists) {
      return RideInfo(
        rideId: "",
        status: RideStatus.none,
        pickup: LatLng(0, 0),
        destination: LatLng(0, 0),
      );
    }

    final rides = Map<String, dynamic>.from(event.snapshot.value as Map);

    // Find first active ride (assigned or in-progress)
    final entry = rides.entries.lastWhere(
      (ride) =>
          ride.value["status"] == "assigned" ||
          ride.value["status"] == "in_progress",
      orElse: () => MapEntry("", {}),
    );

    if (entry.key.isEmpty) {
      return RideInfo(
        rideId: "",
        status: RideStatus.none,
        pickup: LatLng(0, 0),
        destination: LatLng(0, 0),
      );
    }

    // final status = entry.value["status"];
    // final driverId = entry.value["driverId"] ?? "";
    // final pickup = parseLatLng(entry.value["pickup"]);
    // final destination = parseLatLng(entry.value["destination"]);

    // if (status == "assigned") {
    //   return RideInfo(
    //     rideId: entry.key,
    //     status: RideStatus.assigned,
    //     driverId: driverId,
    //     pickup: pickup,
    //     destination: destination,
    //   );
    // }

    // if (status == "in_progress") {
    //   return RideInfo(
    //     rideId: entry.key,
    //     status: RideStatus.inProgress,
    //     driverId: driverId,
    //     pickup: pickup,
    //     destination: destination,
    //   );
    // }

    // return RideInfo(
    //   rideId: "",
    //   status: RideStatus.none,
    //   pickup: LatLng(0, 0),
    //   destination: LatLng(0, 0),
    // );
    final status = entry.value["status"];
    final driverId = entry.value["driverId"] ?? "";
    final pickup = parseLatLng(entry.value["pickup"]);
    final destination = parseLatLng(entry.value["destination"]);
    final driverlocation = parseLatLng(entry.value["driverlocation"]);

    if (status == "assigned") {
      return RideInfo(
        rideId: entry.key,
        status: RideStatus.assigned,
        driverId: driverId,
        pickup: pickup,
        destination: destination,
        driverlocation: driverlocation,
      );
    }

    if (status == "in_progress") {
      return RideInfo(
        rideId: entry.key,
        status: RideStatus.inProgress,
        driverId: driverId,
        pickup: pickup,
        destination: destination,
        driverlocation: driverlocation,
      );
    }

    return RideInfo(
      rideId: "",
      status: RideStatus.none,
      pickup: LatLng(0, 0),
      destination: LatLng(0, 0),
      driverlocation: LatLng(0, 0),
    );
  });
});
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:latlong2/latlong.dart';

// /// Possible ride statuses
// enum RideStatus { none, assigned, inProgress }

// /// Model that holds ride info including extra fields
// class RideInfo {
//   final String rideId;
//   final RideStatus status;
//   final String driverId;
//   final LatLng pickup;
//   final LatLng destination;

//   RideInfo({
//     required this.rideId,
//     required this.status,
//     this.driverId = "",
//     this.pickup,
//     this.destination,
//   });
// }

// /// StreamProvider that listens to Firebase for ride info
// final rideStatusStreamProvider = StreamProvider.family<RideInfo, String>((
//   ref,
//   userId,
// ) {
//   final ridesRef = FirebaseDatabase.instance.ref("rides");

//   return ridesRef.orderByChild("riderId").equalTo(userId).onValue.map((event) {
//     if (!event.snapshot.exists) {
//       return RideInfo(rideId: "", status: RideStatus.none);
//     }

//     final rides = Map<String, dynamic>.from(event.snapshot.value as Map);

//     // Find first active ride (assigned or in-progress)
//     final entry = rides.entries.firstWhere(
//       (ride) =>
//           ride.value["status"] == "assigned" ||
//           ride.value["status"] == "in-progress",
//       orElse: () => MapEntry("", {}),
//     );

//     if (entry.key.isEmpty) {
//       return RideInfo(rideId: "", status: RideStatus.none);
//     }

//     final status = entry.value["status"];
//     final driverId = entry.value["driverId"] ?? "";
//     final pickup = entry.value["pickup"] ?? "";
//     final destination = entry.value["destination"] ?? "";

//     if (status == "assigned") {
//       return RideInfo(
//         rideId: entry.key,
//         status: RideStatus.assigned,
//         driverId: driverId,
//         pickup: pickup,
//         destination: destination,
//       );
//     }

//     if (status == "in-progress") {
//       return RideInfo(
//         rideId: entry.key,
//         status: RideStatus.inProgress,
//         driverId: driverId,
//         pickup: pickup,
//         destination: destination,
//       );
//     }

//     return RideInfo(rideId: "", status: RideStatus.none);
//   });
// });
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:firebase_database/firebase_database.dart';

// // /// Possible ride statuses
// // enum RideStatus { none, assigned, inProgress }

// // /// Model that holds both rideId and status
// // class RideInfo {
// //   final String rideId;
// //   final RideStatus status;

// //   RideInfo({required this.rideId, required this.status});
// // }

// // /// StreamProvider that listens to Firebase for ride info
// // final rideStatusStreamProvider = StreamProvider.family<RideInfo, String>((
// //   ref,
// //   userId,
// // ) {
// //   final ridesRef = FirebaseDatabase.instance.ref("rides");

// //   return ridesRef.orderByChild("riderId").equalTo(userId).onValue.map((event) {
// //     if (!event.snapshot.exists) {
// //       return RideInfo(rideId: "", status: RideStatus.none);
// //     }

// //     final rides = Map<String, dynamic>.from(event.snapshot.value as Map);

// //     // Find first active ride (assigned or in-progress)
// //     final entry = rides.entries.firstWhere(
// //       (ride) =>
// //           ride.value["status"] == "assigned" ||
// //           ride.value["status"] == "in-progress",
// //       orElse: () => MapEntry("", {}),
// //     );

// //     if (entry.key.isEmpty) {
// //       return RideInfo(rideId: "", status: RideStatus.none);
// //     }

// //     final status = entry.value["status"];
// //     if (status == "assigned") {
// //       return RideInfo(rideId: entry.key, status: RideStatus.assigned);
// //     }
// //     if (status == "in-progress") {
// //       return RideInfo(rideId: entry.key, status: RideStatus.inProgress);
// //     }

// //     return RideInfo(rideId: "", status: RideStatus.none);
// //   });
// // });

// // // import 'package:firebase_database/firebase_database.dart';
// // // import 'package:flutter/material.dart';

// // // class RideStatusNotifier extends ChangeNotifier {
// // //   String? _rideStatus;
// // //   String? get rideStatus => _rideStatus;

// // //   DatabaseReference? _rideRef;
// // //   Stream<DatabaseEvent>? _rideStream;

// // //   void startListening(String userId) {
// // //     // Stop old listener if any
// // //     _rideRef?.onValue.drain();
// // //     _rideRef = FirebaseDatabase.instance.ref("rides");

// // //     _rideStream = _rideRef!
// // //         .orderByChild("riderId")
// // //         .equalTo(userId)
// // //         .onValue;

// // //     _rideStream!.listen((event) {
// // //       if (!event.snapshot.exists) {
// // //         _rideStatus = null;
// // //       } else {
// // //         final rides = Map<String, dynamic>.from(
// // //           event.snapshot.value as Map,
// // //         );

// // //         final activeRide = rides.values.firstWhere(
// // //           (ride) =>
// // //               ride["status"] == "assigned" || ride["status"] == "in-progress",
// // //           orElse: () => null,
// // //         );

// // //         _rideStatus = activeRide?["status"];
// // //       }

// // //       notifyListeners();
// // //     });
// // //   }

// // //   void stopListening() {
// // //     _rideRef?.onDisconnect();
// // //     _rideRef = null;
// // //     _rideStatus = null;
// // //     notifyListeners();
// // //   }
// // // }
