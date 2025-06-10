// // driver_confirmation_screen.dart
// import 'package:flutter/material.dart';
// import 'driver_provider.dart'; // Ensure this has the Driver model

// class DriverConfirmationScreen extends StatelessWidget {
//   final Driver driver;
//   final VoidCallback onConfirm;

//   const DriverConfirmationScreen({
//     super.key,
//     required this.driver,
//     required this.onConfirm,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Confirm Driver")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Driver Name: ${driver.name}", style: TextStyle(fontSize: 18)),
//             SizedBox(height: 10),
//             Text("Vehicle: ${driver.vehicle}", style: TextStyle(fontSize: 18)),
//             // Add more info as needed, like color or reg number
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: onConfirm,
//                 child: const Text("Confirm and Start Ride"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'driver_provider.dart';

// class DriverConfirmationScreen extends StatelessWidget {
//   final Driver driver;
//   final VoidCallback onConfirm;

//   const DriverConfirmationScreen({
//     super.key,
//     required this.driver,
//     required this.onConfirm,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Confirm Driver")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: NetworkImage(driver.photoUrl),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "Driver Name: ${driver.name}",
//               style: const TextStyle(fontSize: 18),
//             ),
//             Text(
//               "Car Make/Model: ${driver.vehicle}",
//               style: const TextStyle(fontSize: 18),
//             ),
//             Text(
//               "Registration No: ${driver.registrationNumber}",
//               style: const TextStyle(fontSize: 18),
//             ),
//             Text(
//               "Car Color: ${driver.color}",
//               style: const TextStyle(fontSize: 18),
//             ),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: onConfirm,
//                 child: const Text("Confirm and Start Ride"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_enroute_screen.dart';
// import 'driver_provider.dart';

// class DriverConfirmationScreen extends StatelessWidget {
//   final Driver driver;
//   final VoidCallback onConfirm;
//   final LatLng pickup;

//   const DriverConfirmationScreen({
//     super.key,
//     required this.driver,
//     required this.onConfirm,
//     required this.pickup,
//   });
//   void _showCancelDialog(BuildContext parentContext) {
//     final List<String> reasons = [
//       "Driver delayed",
//       "Changed my mind",
//       "Found alternative transport",
//       "Incorrect location",
//       "Other",
//     ];

//     String selectedReason = reasons[0];

//     if (!parentContext.mounted) return; // ensure context is still valid

//     showDialog(
//       context: parentContext,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Cancel Ride"),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text("Select a reason:"),
//                   DropdownButton<String>(
//                     value: selectedReason,
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() {
//                           selectedReason = value;
//                         });
//                       }
//                     },
//                     items:
//                         reasons.map((reason) {
//                           return DropdownMenuItem(
//                             value: reason,
//                             child: Text(reason),
//                           );
//                         }).toList(),
//                   ),
//                 ],
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context), // Close dialog
//               child: const Text("Back"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context); // Close dialog
//                 Navigator.pop(parentContext); // Pop to previous screen
//                 // Call your cancellation logic here
//                 print("Ride cancelled due to: $selectedReason");
//               },
//               child: const Text("Confirm Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Confirm Driver"),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage:
//                     driver.photoUrl.isNotEmpty
//                         ? NetworkImage(driver.photoUrl)
//                         : const AssetImage('assets/images/default_driver.png')
//                             as ImageProvider,
//               ),
//             ),
//             const SizedBox(height: 24),
//             _buildDriverInfo("Driver Name", driver.name),
//             _buildDriverInfo("Car Make/Model", driver.vehicle),
//             _buildDriverInfo("Registration No", driver.registrationNumber),
//             _buildDriverInfo("Car Color", driver.color),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   onConfirm(); // update any ride state

//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (_) => DriverEnRouteScreen(
//                             driver: driver,
//                             pickup: pickup, // pass actual LatLng object
//                             // onCancel: () {
//                             //   // Optional: Add cancellation logic
//                             //   showDialog(
//                             //     context: context,
//                             //     builder:
//                             //         (_) => AlertDialog(
//                             //           title: const Text("Cancel Ride"),
//                             //           content: const Text(
//                             //             "Are you sure you want to cancel the ride?",
//                             //           ),
//                             //           actions: [
//                             //             TextButton(
//                             //               onPressed:
//                             //                   () => Navigator.pop(
//                             //                     context,
//                             //                   ), // dismiss dialog
//                             //               child: const Text("No"),
//                             //             ),
//                             //             TextButton(
//                             //               onPressed: () {
//                             //                 Navigator.pop(
//                             //                   context,
//                             //                 ); // close dialog
//                             //                 Navigator.pop(
//                             //                   context,
//                             //                 ); // go back to previous screen
//                             //               },
//                             //               child: const Text("Yes, Cancel"),
//                             //             ),
//                             //           ],
//                             //         ),
//                             //   );
//                             // },
//                             onCancel: () {
//                               _showCancelDialog(context);
//                             },
//                             //   await someAsyncCall();
//                             //   if (context.mounted) {
//                             //     showDialog(
//                             //       context: context,
//                             //       builder:
//                             //           (_) => AlertDialog(
//                             //             title: Text("Cancelled"),
//                             //             content: Text(
//                             //               "Your ride was cancelled.",
//                             //             ),
//                             //             actions: [
//                             //               TextButton(
//                             //                 onPressed:
//                             //                     () => Navigator.pop(context),
//                             //                 child: Text("OK"),
//                             //               ),
//                             //             ],
//                             //           ),
//                             //     );
//                             //   }
//                             // },
//                           ),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16.0),
//                   backgroundColor: Colors.green,
//                   textStyle: const TextStyle(fontSize: 18),
//                 ),
//                 child: const Text("Confirm and Start Ride"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDriverInfo(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Text("$label: $value", style: const TextStyle(fontSize: 18)),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_enroute_screen.dart';
import 'driver_provider.dart';

class DriverConfirmationScreen extends StatelessWidget {
  final Driver driver;
  final VoidCallback onConfirm;

  ///final VoidCallback onCancel;
  final LatLng pickup;

  const DriverConfirmationScreen({
    super.key,
    required this.driver,
    required this.onConfirm,
    required this.pickup,
    //required this.onCancel,
  });

  void _showCancelDialog(BuildContext parentContext) {
    final List<String> reasons = [
      "Driver delayed",
      "Changed my mind",
      "Found alternative transport",
      "Incorrect location",
      "Other",
    ];

    String selectedReason = reasons[0];

    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancel Ride"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select a reason:"),
                  DropdownButton<String>(
                    value: selectedReason,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedReason = value;
                        });
                      }
                    },
                    items:
                        reasons.map((reason) {
                          return DropdownMenuItem(
                            value: reason,
                            child: Text(reason),
                          );
                        }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(parentContext); // Go back to previous screen
                //onCancel(); // 🔥 This now triggers the same onCancel logic
              },
              child: const Text("Confirm Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Driver"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () => _showCancelDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    driver.photoUrl.isNotEmpty
                        ? NetworkImage(driver.photoUrl)
                        : const AssetImage('assets/images/default_driver.png')
                            as ImageProvider,
              ),
            ),
            const SizedBox(height: 24),
            _buildDriverInfo("Driver Name", driver.name),
            _buildDriverInfo("Car Make/Model", driver.vehicle),
            _buildDriverInfo("Registration No", driver.registrationNumber),
            _buildDriverInfo("Car Color", driver.color),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onConfirm(); // e.g. update state or backend

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DriverEnRouteScreen(
                            driver: driver,
                            pickup: pickup,
                            onCancel:
                                () => _showCancelDialog(
                                  context,
                                ), // reuse same dialog
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("Confirm and Start Ride"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text("$label: $value", style: const TextStyle(fontSize: 18)),
    );
  }
}
