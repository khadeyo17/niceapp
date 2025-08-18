// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as ref;
// import 'package:intl/intl.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
// import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

// class UberStyleRideTile extends StatelessWidget {
//   final RideHistory ride;
//   final LatLng? currentLocation;

//   const UberStyleRideTile({
//     super.key,
//     required this.ride,
//     this.currentLocation,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final imageAsset =
//         ride.vehicleType == "bike"
//             ? "assets/imgs/bike.png"
//             : "assets/imgs/aminicar.jpeg";
//     final LatLng? currentLocation;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       shadowColor: Colors.grey.withOpacity(0.2),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.asset(
//                 imageAsset,
//                 height: 45,
//                 width: 45,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "${ride.pickupLocation} → ${ride.destination}",
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "Driver: ${ride.contactName}",
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                   Text(
//                     "Fare: KES ${ride.fare.toStringAsFixed(0)}",
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     ride.dropoffTime != null
//                         ? DateFormat(
//                           'dd MMM yyyy, h:mm a',
//                         ).format(ride.dropoffTime!)
//                         : 'Date: N/A',
//                     style: const TextStyle(fontSize: 11, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 TextButton.icon(
//                   onPressed: () {
//                     if (currentLocation == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Current location not available."),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                       return;
//                     }

//                     final destination = LatLng(
//                       ride.destinationLatitude,
//                       ride.destinationLongitude,
//                     );

//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder:
//                             (_) => HomeScreen(
//                               pickup: currentLocation,
//                               destination: destination,
//                               stops: ref.read(stopsProvider),
//                               category: VehicleCategory.passenger,
//                             ),
//                       ),
//                     );
//                   },
//                   icon: Icon(
//                     Icons.repeat,
//                     color: Colors.blue.shade700,
//                     size: 18,
//                   ),
//                   label: Text(
//                     "Rebook",
//                     style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
//                   ),
//                   style: TextButton.styleFrom(
//                     padding: EdgeInsets.zero,
//                     minimumSize: const Size(50, 30),
//                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );

//     // return Card(
//     //     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//     //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     //     elevation: 1.5,
//     //     color: Colors.white,
//     //     child: Padding(
//     //       padding: const EdgeInsets.all(10),
//     //       child: Column(
//     //         children: [
//     //           Row(
//     //             children: [
//     //               ClipRRect(
//     //                 borderRadius: BorderRadius.circular(8),
//     //                 child: Image.asset(
//     //                   imageAsset,
//     //                   height: 35,
//     //                   width: 35,
//     //                   fit: BoxFit.cover,
//     //                 ),
//     //               ),
//     //               const SizedBox(width: 10),
//     //               Expanded(
//     //                 child: Column(
//     //                   crossAxisAlignment: CrossAxisAlignment.start,
//     //                   children: [
//     //                     Text(
//     //                       "${ride.pickupLocation} → ${ride.destination}",
//     //                       style: const TextStyle(
//     //                         fontSize: 14,
//     //                         fontWeight: FontWeight.w600,
//     //                       ),
//     //                     ),
//     //                     const SizedBox(height: 2),
//     //                     Text(
//     //                       "Driver: ${ride.contactName}",
//     //                       style: const TextStyle(
//     //                         color: Colors.grey,
//     //                         fontSize: 12,
//     //                       ),
//     //                     ),
//     //                     Text(
//     //                       "Fare: KES ${ride.fare.toStringAsFixed(0)}",
//     //                       style: const TextStyle(
//     //                         color: Colors.grey,
//     //                         fontSize: 12,
//     //                       ),
//     //                     ),
//     //                   ],
//     //                 ),
//     //               ),
//     //               Column(
//     //                 crossAxisAlignment: CrossAxisAlignment.end,
//     //                 children: [
//     //                   Text(
//     //                     ride.dropoffTime != null
//     //                         ? DateFormat('dd MMM').format(ride.dropoffTime!)
//     //                         : 'N/A',
//     //                     style: const TextStyle(
//     //                       color: Colors.black54,
//     //                       fontSize: 11,
//     //                     ),
//     //                   ),
//     //                   TextButton.icon(
//     //                     onPressed: () {
//     //                       if (currentLocation == null) {
//     //                         ScaffoldMessenger.of(context).showSnackBar(
//     //                           const SnackBar(
//     //                             content: Text(
//     //                               "Current location not available yet. Please wait.",
//     //                             ),
//     //                             backgroundColor: Colors.red,
//     //                           ),
//     //                         );
//     //                         return;
//     //                       }

//     //                       final destination = LatLng(
//     //                         ride.destinationLatitude,
//     //                         ride.destinationLongitude,
//     //                       );

//     //                       Navigator.push(
//     //                         context,
//     //                         MaterialPageRoute(
//     //                           builder:
//     //                               (_) => HomeScreen(
//     //                                 pickup: currentLocation!,
//     //                                 destination: destination,
//     //                                 stops: ref.read(stopsProvider),
//     //                                 category: VehicleCategory.passenger,
//     //                               ),
//     //                         ),
//     //                       );
//     //                     },
//     //                     icon: Icon(
//     //                       Icons.repeat,
//     //                       color: Colors.blue.shade700,
//     //                       size: 18,
//     //                     ),
//     //                     label: Text(
//     //                       "Rebook",
//     //                       style: TextStyle(
//     //                         color: Colors.blue.shade700,
//     //                         fontSize: 12,
//     //                       ),
//     //                     ),
//     //                     style: TextButton.styleFrom(
//     //                       padding: EdgeInsets.zero,
//     //                       minimumSize: const Size(50, 30),
//     //                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     //                     ),
//     //                   ),
//     //                 ],
//     //               ),
//     //             ],
//     //           ),
//     //         ],
//     //       ),
//     //     ),
//     //   ),

//     // return Card(

//     //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     //   elevation: 2,
//     //   child: ListTile(
//     //     leading: const Icon(Icons.local_taxi, color: Colors.black54),
//     //     title: Text("${ride.pickupLocation} ➜ ${ride.destination}"),
//     //     subtitle: Text(
//     //       "Fare: KES ${ride.fare.toStringAsFixed(0)}\n"
//     //       "Date: ${ride.dropoffTime?.toLocal().toString().split('.').first ?? 'N/A'}",
//     //     ),
//     //     trailing: const Icon(Icons.chevron_right),
//     //     onTap: () {
//     //       // Optionally open details
//     //     },
//     //   ),
//     // );
//   }
// }
