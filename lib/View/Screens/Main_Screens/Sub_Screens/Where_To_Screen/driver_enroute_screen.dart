import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';

class DriverEnRouteScreen extends StatelessWidget {
  final Driver driver;
  final LatLng pickup;
  final VoidCallback onCancel;

  const DriverEnRouteScreen({
    super.key,
    required this.driver,
    required this.pickup,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver En Route"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(center: pickup, zoom: 14.0),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickup,
                    width: 40,
                    height: 40,
                    builder:
                        (_) => const Icon(
                          Icons.location_pin,
                          color: Colors.green,
                          size: 35,
                        ),
                  ),
                  Marker(
                    point: driver.location,
                    width: 40,
                    height: 40,
                    builder:
                        (_) => const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 35,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Container(
          //     padding: const EdgeInsets.all(16.0),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: const BorderRadius.vertical(
          //         top: Radius.circular(20),
          //       ),
          //       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          //     ),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         ListTile(
          //           leading: CircleAvatar(
          //             backgroundImage: NetworkImage(driver.photoUrl),
          //             radius: 25,
          //           ),
          //           title: Text(driver.name),
          //           subtitle: Text(
          //             "${driver.vehicle} | ${driver.registrationNumber}",
          //           ),

          //           // trailing: IconButton(
          //           //   icon: const Icon(Icons.phone, color: Colors.green),
          //           //   onPressed: () async {
          //           //     final Uri callUri = Uri(
          //           //       scheme: 'tel',
          //           //       path: driver.phoneNumber,
          //           //     );
          //           //     if (await canLaunchUrl(callUri)) {
          //           //       await launchUrl(callUri);
          //           //     } else {
          //           //       ScaffoldMessenger.of(context).showSnackBar(
          //           //         const SnackBar(content: Text('Cannot place call.')),
          //           //       );
          //           //     }
          //           //   },
          //           // ),
          //           // trailing: Row(
          //           //   mainAxisSize: MainAxisSize.min,
          //           //   children: [
          //           //     IconButton(
          //           //       icon: const Icon(Icons.phone, color: Colors.green),
          //           //       onPressed: () async {
          //           //         final Uri callUri = Uri(
          //           //           scheme: 'tel',
          //           //           path: driver.phoneNumber,
          //           //         );
          //           //         if (await canLaunchUrl(callUri)) {
          //           //           await launchUrl(callUri);
          //           //         } else {
          //           //           ScaffoldMessenger.of(context).showSnackBar(
          //           //             const SnackBar(
          //           //               content: Text('Cannot place call.'),
          //           //             ),
          //           //           );
          //           //         }
          //           //       },
          //           //     ),
          //           //     IconButton(
          //           //       icon: const Icon(Icons.message, color: Colors.blue),
          //           //       onPressed: () async {
          //           //         final Uri smsUri = Uri(
          //           //           scheme: 'sms',
          //           //           path: driver.phoneNumber,
          //           //         );
          //           //         if (await canLaunchUrl(smsUri)) {
          //           //           await launchUrl(smsUri);
          //           //         } else {
          //           //           ScaffoldMessenger.of(context).showSnackBar(
          //           //             const SnackBar(
          //           //               content: Text('Cannot send message.'),
          //           //             ),
          //           //           );
          //           //         }
          //           //       },
          //           //     ),
          //           //   ],
          //           // ),
          //           trailing: Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               IconButton(
          //                 icon: const Icon(Icons.phone, color: Colors.green),
          //                 onPressed: () async {
          //                   final Uri callUri = Uri(
          //                     scheme: 'tel',
          //                     path: driver.phoneNumber,
          //                   );
          //                   if (await canLaunchUrl(callUri)) {
          //                     await launchUrl(callUri);
          //                   } else {
          //                     ScaffoldMessenger.of(context).showSnackBar(
          //                       const SnackBar(
          //                         content: Text('Cannot place call.'),
          //                       ),
          //                     );
          //                   }
          //                 },
          //               ),
          //               IconButton(
          //                 icon: const Icon(Icons.message, color: Colors.blue),
          //                 onPressed: () async {
          //                   final Uri smsUri = Uri(
          //                     scheme: 'sms',
          //                     path: driver.phoneNumber,
          //                   );
          //                   if (await canLaunchUrl(smsUri)) {
          //                     await launchUrl(smsUri);
          //                   } else {
          //                     ScaffoldMessenger.of(context).showSnackBar(
          //                       const SnackBar(
          //                         content: Text('Cannot send message.'),
          //                       ),
          //                     );
          //                   }
          //                 },
          //               ),
          //               IconButton(
          //                 icon: const Icon(
          //                   Icons.wechat_sharp,
          //                   color: Colors.teal,
          //                 ),
          //                 onPressed: () async {
          //                   final phone = driver.phoneNumber
          //                       .replaceAll('+', '')
          //                       .replaceAll(' ', '');
          //                   final Uri whatsappUri = Uri.parse(
          //                     "https://wa.me/$phone",
          //                   );

          //                   if (await canLaunchUrl(whatsappUri)) {
          //                     await launchUrl(
          //                       whatsappUri,
          //                       mode: LaunchMode.externalApplication,
          //                     );
          //                   } else {
          //                     ScaffoldMessenger.of(context).showSnackBar(
          //                       const SnackBar(
          //                         content: Text('Cannot open WhatsApp.'),
          //                       ),
          //                     );
          //                   }
          //                 },
          //               ),
          //             ],
          //           ),
          //         ),
          //         const SizedBox(height: 10),
          //         SizedBox(
          //           width: double.infinity,
          //           child: ElevatedButton.icon(
          //             icon: const Icon(Icons.cancel),
          //             label: const Text("Cancel Ride"),
          //             onPressed: () => _showCancelDialog(context),
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: Colors.red,
          //               padding: const EdgeInsets.symmetric(vertical: 16.0),
          //               textStyle: const TextStyle(fontSize: 18),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(driver.photoUrl),
                        radius: 25,
                      ),
                      title: Text(driver.name),
                      subtitle: Text(
                        "${driver.vehicle} | ${driver.registrationNumber}",
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () async {
                              final Uri callUri = Uri(
                                scheme: 'tel',
                                path: driver.phoneNumber,
                              );
                              if (await canLaunchUrl(callUri)) {
                                await launchUrl(callUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot place call.'),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed: () async {
                              final Uri smsUri = Uri(
                                scheme: 'sms',
                                path: driver.phoneNumber,
                              );
                              if (await canLaunchUrl(smsUri)) {
                                await launchUrl(smsUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot send message.'),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.wechat_sharp,
                              color: Colors.teal,
                            ),
                            onPressed: () async {
                              final phone = driver.phoneNumber
                                  .replaceAll('+', '')
                                  .replaceAll(' ', '');
                              final Uri whatsappUri = Uri.parse(
                                "https://wa.me/$phone",
                              );
                              if (await canLaunchUrl(whatsappUri)) {
                                await launchUrl(
                                  whatsappUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot open WhatsApp.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancel Ride"),
                        onPressed: () => _showCancelDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                // onCancel(); // 🔥 This now triggers the same onCancel logic
              },
              child: const Text("Confirm Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showCancelOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CancelRideBottomSheet(onCancel: onCancel),
    );
  }
}

class CancelRideBottomSheet extends StatelessWidget {
  final VoidCallback onCancel;

  const CancelRideBottomSheet({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final reasons = [
      "Driver taking too long",
      "Booked by mistake",
      "Change of plans",
      "Other",
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Cancel Ride",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...reasons.map(
            (reason) => ListTile(
              title: Text(reason),
              onTap: () {
                Navigator.pop(context);
                onCancel();
              },
            ),
          ),
        ],
      ),
    );
  }
}
