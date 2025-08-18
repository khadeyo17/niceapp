// class RideHistory {
//   final int id;
//   final String pickupLocation;
//   final String destination;
//   final DateTime requestTime;
//   final DateTime? pickupTime;
//   final DateTime? dropoffTime;
//   final double pickupLatitude;
//   final double pickupLongitude;
//   final double destinationLatitude;
//   final double destinationLongitude;
//   final double fare;
//   final String status;
//    final String contactName;
//   final String contactEmail;
//   final String contactPhone;

//   RideHistory({
//     required this.id,
//     required this.pickupLocation,
//     required this.destination,
//     required this.requestTime,
//     this.pickupTime,
//     this.dropoffTime,
//     required this.pickupLatitude,
//     required this.pickupLongitude,
//     required this.destinationLatitude,
//     required this.destinationLongitude,
//     required this.fare,
//     required this.status,
//     required this.contactName,
//     required this.contactEmail,
//     required this.contactPhone,
//   });

//   factory RideHistory.fromJson(Map<String, dynamic> json, String role) {
//      final contact = role == "Passenger" ? json['Driver'] : json['Passenger'];
//     return RideHistory(
//       id: json['Id'],
//       pickupLocation: json['PickupLocation'],
//       destination: json['Destination'],
// requestTime: DateTime.parse(json['RequestTime']),
// pickupTime:json['PickupTime'] != null? DateTime.parse(json['PickupTime']) : null,
// dropoffTime:json['DropoffTime'] != null? DateTime.parse(json['DropoffTime']): null,
//       pickupLatitude: (json['PickupLatitude'] ?? 0).toDouble(),
//       pickupLongitude: (json['PickupLongitude'] ?? 0).toDouble(),
//       destinationLatitude: (json['DestinationLatitude'] ?? 0).toDouble(),
//       destinationLongitude: (json['DestinationLongitude'] ?? 0).toDouble(),
//       fare: (json['Fare'] ?? 0).toDouble(),
//       status: json['Status'],
//       contactName: contact?['Name'] ?? '',
//       contactEmail: contact?['Email'] ?? '',
//       contactPhone: contact?['PhoneNumber'] ?? '',
//     );
//   }
// }

import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';

class RideHistory {
  final int id;
  final String pickupLocation;
  final String destination;
  final DateTime requestTime;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final double fare;
  final String status;
  final String? driverId;
  final String? contactName;
  final String? contactPhone;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColour;
  final String? registrationNumber;
  final String? photoUrl;
  final String? subCategory;
  final String? vehicleType;
  final int? rating;
  final DateTime? scheduledDate;

  RideHistory({
    required this.id,
    required this.pickupLocation,
    required this.destination,
    required this.requestTime,
    this.pickupTime,
    this.dropoffTime,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.fare,
    required this.status,
    this.driverId,
    this.contactName,
    this.contactPhone,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColour,
    this.registrationNumber,
    this.photoUrl,
    this.subCategory,
    this.vehicleType,
    this.rating,
    this.scheduledDate,

    // "car" or "bike"
  });

  factory RideHistory.fromPassengerJson(Map<String, dynamic> json) {
    return RideHistory(
      id: json['id'],
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      requestTime: DateTime.parse(json['requestTime']),
      // pickupTime:
      //     json['PickupTime'] != null
      //         ? DateTime.parse(json['PickupTime'])
      //         : null,
      pickupTime: () {
        try {
          return json['pickupTime'] != null
              ? DateTime.parse(json['pickupTime'])
              : null;
        } catch (e) {
          print('PickupTime parse error: $e');
          return null;
        }
      }(),

      dropoffTime: () {
        try {
          return json['dropoffTime'] != null
              ? DateTime.parse(json['dropoffTime'])
              : null;
        } catch (e) {
          print('DropoffTime parse error: $e');
          return null;
        }
      }(),

      scheduledDate: () {
        try {
          return json['scheduledDate'] != null
              ? DateTime.parse(json['scheduledDate'])
              : null;
        } catch (e) {
          print('scheduledDate parse error: $e');
          return null;
        }
      }(),
      // dropoffTime:
      //     json['DropoffTime'] != null
      //         ? DateTime.parse(json['DropoffTime'])
      //         : null,
      // requestTime: json['RequestTime'] ?? '',
      // pickupTime: json['PickupTime'],
      // dropoffTime: json['DropoffTime'],
      pickupLatitude: (json['pickupLatitude'] ?? 0).toDouble(),
      pickupLongitude: (json['pickupLongitude'] ?? 0).toDouble(),
      destinationLatitude: (json['destinationLatitude'] ?? 0).toDouble(),
      destinationLongitude: (json['destinationLongitude'] ?? 0).toDouble(),
      fare: (json['fare'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      //driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      driverId: json['driver']?['driverId'],
      contactName: json['driver']?['driverName'],
      contactPhone: json['driver']?['driverPhone'],
      vehicleMake: json['driver']?['vehicleMake'],
      vehicleModel: json['driver']?['vehicleModel'],
      vehicleColour: json['driver']?['rehicleColour'],
      registrationNumber: json['driver']?['registrationNumber'],
      photoUrl: json['photoUrl'] ?? '',
      subCategory: json['subCategory'] ?? '',
      vehicleType: json['vehicleType'] ?? 'car',
      rating: json['rating'] ?? '0',
    );
  }
}
