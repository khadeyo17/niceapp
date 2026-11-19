// import 'dart:async';
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/error_notification.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   final SplashLogics _logics = SplashLogics();

//   @override
//   void initState() {
//     super.initState();
//     _startInitialization();
//   }

//   void _startInitialization() async {
//     // Start permission & initialization checks without blocking UI
//     _logics.checkPermissions(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background splash image/color
//           Container(color: Colors.white),
//           // App logo or animation
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: const [
//                 FlutterLogo(size: 100),
//                 SizedBox(height: 20),
//                 Text(
//                   "Trippo",
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 CircularProgressIndicator(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SplashLogics {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   /// Permission check
//   void checkPermissions(BuildContext context) async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.whileInUse ||
//           permission == LocationPermission.always) {
//         // Run initialization in background
//         _initializeUser(context);
//       } else {
//         _showPermissionError(context);
//       }
//     } catch (e) {
//       _showError(context, e.toString());
//     }
//   }

//   /// Non-blocking user initialization
//   void _initializeUser(BuildContext context) async {
//     final user = _auth.currentUser;
//     if (user == null) {
//       _navigate(context, Routes().register);
//       return;
//     }

//     final uid = user.uid;
//     final email = user.email ?? '';
//     final phone = user.phoneNumber ?? '';

//     try {
//       // Run backend check and Firestore check in parallel
//       final backendFuture = http.get(
//         Uri.parse('$baseUrl/passengerauth/check-user/$uid'),
//         headers: {'Content-Type': 'application/json'},
//       );
//       final firestoreFuture =
//           FirebaseFirestore.instance.collection('users').doc(uid).get();

//       final results = await Future.wait([backendFuture, firestoreFuture]);
//       final backendResponse = results[0] as http.Response;
//       final firestoreDoc = results[1] as DocumentSnapshot;

//       bool hasBackendData = false;
//       if (backendResponse.statusCode == 200) {
//         final backendData = jsonDecode(backendResponse.body);
//         final phoneFromBackend = backendData['phone'];
//         hasBackendData =
//             phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;
//       }

//       // Firestore creation if not exists
//       if (!firestoreDoc.exists) {
//         FirebaseFirestore.instance.collection('users').doc(uid).set({
//           'uid': uid,
//           'phone': phone,
//           'email': email,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       // Update FCM token in background
//       if (hasBackendData) {
//         final token = await user.getIdToken();
//         final fcmToken = await FirebaseMessaging.instance.getToken();
//         http.post(
//           Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//           body: jsonEncode({'token': token, 'fcmToken': fcmToken}),
//         );
//       }

//       // Navigate immediately when ready
//       _navigate(context, hasBackendData ? Routes().home : Routes().register);
//     } catch (e) {
//       _showError(context, e.toString());
//       _navigate(context, Routes().register);
//     }
//   }

//   void _showPermissionError(BuildContext context) async {
//     if (!context.mounted) return;
//     ErrorNotification().showError(
//       context,
//       "Location access is required to run Trippo.",
//     );
//     await Future.delayed(const Duration(seconds: 2));
//     SystemChannels.platform.invokeMethod("SystemNavigator.pop");
//   }

//   void _showError(BuildContext context, String message) {
//     if (!context.mounted) return;
//     ErrorNotification().showError(context, message);
//   }

//   void _navigate(BuildContext context, String routeName) {
//     if (!context.mounted) return;
//     GoRouter.of(context).goNamed(routeName);
//   }
// }

// // import 'dart:async';
// // import 'dart:convert';

// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/cupertino.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:niceapp/Container/utils/error_notification.dart';
// // import 'package:niceapp/Container/utils/keys.dart';
// // import 'package:niceapp/View/Routes/routes.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
// // import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

// // // class SplashLogics {
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //   void initializeUser(BuildContext context) async {
// // //     final User? user = _auth.currentUser;

// // //     if (user != null) {
// // //       final uid = user.uid;
// // //       final phone = user.phoneNumber ?? '';
// // //       final email = user.email ?? '';
// // //       final token = await user.getIdToken();
// // //       final fcmToken = await FirebaseMessaging.instance.getToken();

// // //       bool hasBackendData = false;
// // //       bool hasFirestoreData = false;
// // //       try {
// // //         // 1️⃣ Check Backend
// // //         final response = await http.get(
// // //           Uri.parse('$baseUrl/passengerauth/check-user/$uid'),
// // //           headers: {
// // //             'Content-Type': 'application/json',
// // //            // 'Authorization': 'Bearer $token',
// // //           },
// // //         );

// // //         // String? fullNameFromBackend;
// // //         String? phoneFromBackend;

// // //         if (response.statusCode == 200) {
// // //           final backendData = jsonDecode(response.body);
// // //           //fullNameFromBackend = backendData['fullName'];
// // //           phoneFromBackend = backendData['phone'];

// // //           hasBackendData =
// // //               // fullNameFromBackend != null &&
// // //               // fullNameFromBackend.trim().isNotEmpty &&
// // //               phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;

// // //           // 2️⃣ Check Firestore
// // //           final userRef = FirebaseFirestore.instance
// // //               .collection('users')
// // //               .doc(uid);
// // //           final userDoc = await userRef.get();

// // //           if (!userDoc.exists) {
// // //             await userRef.set({
// // //               'uid': uid,
// // //               'phone': phone,
// // //               'email': email,
// // //               'createdAt': FieldValue.serverTimestamp(),
// // //             });
// // //           }

// // //           if (hasBackendData) {
// // //             final response = await http.post(
// // //               Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
// // //               headers: {
// // //                 'Content-Type': 'application/json',
// // //                 'Authorization': 'Bearer $token',
// // //               },
// // //               body: jsonEncode({
// // //                 'token': token, // Firebase ID token
// // //                 'fcmToken': fcmToken, // Device's FCM token
// // //               }),
// // //             );
// // //             if (response.statusCode == 200) {
// // //               Timer(const Duration(seconds: 3), () {
// // //                 context.goNamed(Routes().home);
// // //               });
// // //               //context.goNamed(Routes().home);
// // //             } else {
// // //               Future.delayed(const Duration(seconds: 3), () {
// // //                 if (!context.mounted) return;
// // //                 context.goNamed(Routes().home);
// // //               });
// // //               //debugPrint("Failed to validate token, contact amini support");
// // //             }
// // //           } else {
// // //             debugPrint("Failed to validate user, contact amini support");
// // //           }
// // //           //context.goNamed(Routes().home);
// // //         } else {
// // //           Future.delayed(const Duration(seconds: 3), () {
// // //             if (!context.mounted) return;
// // //             context.goNamed(Routes().register);
// // //           });
// // //           //  context.goNamed(Routes().profilesetupscreen);
// // //         }
// // //       } catch (e) {
// // //         debugPrint("Backend or Firestore check failed: $e");
// // //         // Optionally: navigate to error screen or retry
// // //       }
// // //       // Future.delayed(const Duration(seconds: 3), () {
// // //       //   if (!context.mounted) return;
// // //       //   context.goNamed(Routes().home);
// // //       // });
// // //       // Timer(const Duration(seconds: 3), () {
// // //       //   context.goNamed(Routes().home);
// // //       // });
// // //     } else {
// // //       Future.delayed(const Duration(seconds: 3), () {
// // //         if (!context.mounted) return;
// // //         context.goNamed(Routes().register);
// // //       });
// // //     }
// // //   }

// // //   Future<void> handleExistingRide(BuildContext context) async {
// // //     final user = FirebaseAuth.instance.currentUser;
// // //     if (user == null) return;

// // //     final idToken = await user.getIdToken();
// // //     final url = '$baseUrl/passengerrides/passenger/current/${user.uid}';

// // //     final response = await http.get(
// // //       Uri.parse(url),
// // //       headers: {
// // //         'Content-Type': 'application/json',
// // //         //'Authorization': 'Bearer $idToken',
// // //       },
// // //     );

// // //     if (response.statusCode == 200) {
// // //       final decoded = jsonDecode(response.body);
// // //       final RideHistory ride = RideHistory.fromPassengerJson(decoded);

// // //       // If driver assigned but trip not completed
// // //       if (ride.contactName != null && ride.status != 'Completed') {
// // //         Navigator.push(
// // //           context,
// // //           MaterialPageRoute(
// // //             builder:
// // //                 (_) => DriverConfirmationScreen(
// // //                   driverId: ride.driverId!,
// // //                   pickup: LatLng(ride.pickupLatitude, ride.pickupLongitude),
// // //                   rideId: ride.id,
// // //                   regnumber: ride.registrationNumber,
// // //                   vehicleMake: ride.vehicleMake,
// // //                   vehicleModel: ride.vehicleModel,
// // //                   photoUrl: ride.photoUrl,
// // //                   Phone: ride.contactPhone,
// // //                   drivername: ride.contactName,
// // //                 ),
// // //           ),
// // //         );

// // //         // Navigator.pushReplacement(
// // //         //   context,
// // //         //   MaterialPageRoute(
// // //         //     builder:
// // //         //         (_) => DriverConfirmationScreen(
// // //         //           driver: ride.driver!,
// // //         //           pickup: LatLng(ride.pickupLatitude, ride.pickupLongitude),
// // //         //           rideId: ride.id,
// // //         //         ),
// // //         //   ),
// // //         // );

// // //         // Navigator.pushReplacement(
// // //         //   context,
// // //         //   MaterialPageRoute(
// // //         //     builder:
// // //         //         (_) => DriverConfirmationScreen(
// // //         //           driver: ride.driver!,
// // //         //           pickup: LatLng(ride.pickupLatitude, ride.pickupLongitude),
// // //         //           rideId: ride.id,
// // //         //         ),
// // //         //   ),
// // //         // );
// // //       }

// // //       // Handle other states like en-route, trip started, etc.
// // //     }
// // //   }

// // //   void checkPermissions(BuildContext context) async {
// // //     try {
// // //       LocationPermission permission = await Geolocator.checkPermission();

// // //       if (permission == LocationPermission.denied) {
// // //         await Geolocator.requestPermission();
// // //         LocationPermission permission2 = await Geolocator.checkPermission();
// // //         if (context.mounted &&
// // //             (permission2 == LocationPermission.whileInUse ||
// // //                 permission2 == LocationPermission.always)) {
// // //           initializeUser(context);
// // //         } else {
// // //           if (context.mounted) {
// // //             ErrorNotification().showError(
// // //               context,
// // //               "Location Access is required to run Trippo.",
// // //             );
// // //           }
// // //           await Future.delayed(const Duration(seconds: 2));
// // //           SystemChannels.platform.invokeMethod("SystemNavigator.pop");
// // //         }
// // //         return;
// // //       } else if (context.mounted &&
// // //           (permission == LocationPermission.whileInUse ||
// // //               permission == LocationPermission.always)) {
// // //         initializeUser(context);
// // //         return;
// // //       }

// // //       if (permission == LocationPermission.deniedForever ||
// // //           permission == LocationPermission.unableToDetermine) {
// // //         if (context.mounted) {
// // //           ErrorNotification().showError(
// // //             context,
// // //             "Location Access is required to run Trippo.",
// // //           );
// // //           await Future.delayed(const Duration(seconds: 2));
// // //           SystemChannels.platform.invokeMethod("SystemNavigator.pop");
// // //         }
// // //         return;
// // //       }
// // //     } catch (e) {
// // //       if (context.mounted) {
// // //         ErrorNotification().showError(context, "An Error Occurred $e");
// // //       }
// // //     }
// // //   }
// // // }
// // class SplashLogics {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   void initializeUser(BuildContext context) async {
// //     final user = _auth.currentUser;

// //     if (user == null) {
// //       _navigateTo(context, Routes().register);
// //       return;
// //     }

// //     final uid = user.uid;
// //     final email = user.email ?? '';
// //     final phone = user.phoneNumber ?? '';

// //     try {
// //       // Run backend check and Firestore check in parallel
// //       final backendFuture = http.get(
// //         Uri.parse('$baseUrl/passengerauth/check-user/$uid'),
// //         headers: {'Content-Type': 'application/json'},
// //       );

// //       final firestoreRef = FirebaseFirestore.instance
// //           .collection('users')
// //           .doc(uid);
// //       final firestoreFuture = firestoreRef.get();

// //       final results = await Future.wait([backendFuture, firestoreFuture]);
// //       final backendResponse = results[0] as http.Response;
// //       final firestoreDoc = results[1] as DocumentSnapshot;

// //       bool hasBackendData = false;
// //       if (backendResponse.statusCode == 200) {
// //         final backendData = jsonDecode(backendResponse.body);
// //         final phoneFromBackend = backendData['phone'];
// //         hasBackendData =
// //             phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;
// //       }

// //       // Create Firestore document if not exists
// //       if (!firestoreDoc.exists) {
// //         await firestoreRef.set({
// //           'uid': uid,
// //           'phone': phone,
// //           'email': email,
// //           'createdAt': FieldValue.serverTimestamp(),
// //         });
// //       }

// //       // Update FCM token if backend data valid
// //       if (hasBackendData) {
// //         final token = await user.getIdToken();
// //         final fcmToken = await FirebaseMessaging.instance.getToken();

// //         http.post(
// //           Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
// //           headers: {
// //             'Content-Type': 'application/json',
// //             'Authorization': 'Bearer $token',
// //           },
// //           body: jsonEncode({'token': token, 'fcmToken': fcmToken}),
// //         );
// //       }

// //       _navigateTo(context, hasBackendData ? Routes().home : Routes().register);
// //     } catch (e) {
// //       debugPrint("Initialization failed: $e");
// //       _navigateTo(context, Routes().register);
// //     }
// //   }

// //   void checkPermissions(BuildContext context) async {
// //     try {
// //       LocationPermission permission = await Geolocator.checkPermission();

// //       if (permission == LocationPermission.denied) {
// //         permission = await Geolocator.requestPermission();
// //       }

// //       if (permission == LocationPermission.whileInUse ||
// //           permission == LocationPermission.always) {
// //         initializeUser(context);
// //       } else {
// //         if (context.mounted) {
// //           ErrorNotification().showError(
// //             context,
// //             "Location access is required to run Trippo.",
// //           );
// //         }
// //         await Future.delayed(const Duration(seconds: 2));
// //         SystemChannels.platform.invokeMethod("SystemNavigator.pop");
// //       }
// //     } catch (e) {
// //       if (context.mounted) {
// //         ErrorNotification().showError(context, "An error occurred: $e");
// //       }
// //     }
// //   }

// //   void _navigateTo(BuildContext context, String routeName) {
// //     if (!context.mounted) return;
// //     GoRouter.of(context).goNamed(routeName);
// //   }
// // }
