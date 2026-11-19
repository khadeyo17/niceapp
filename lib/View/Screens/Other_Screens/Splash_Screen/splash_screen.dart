import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/error_notification.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashLogics _logics = SplashLogics();

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  void _startInitialization() async {
    // Start permission & initialization checks without blocking UI
    _logics.checkPermissions(context);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              //colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              colors: [Color(0xFF000000), Color(0xFF1C1C1C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 👇 Replace with your actual logo if needed
              Image.asset('assets/imgs/logo.png', width: 120, height: 120),
              // const SizedBox(height: 20),
              // Text(
              //   "Amini",
              //   style: TextStyle(
              //     fontSize: 48,
              //     fontFamily: "bold",
              //     color: Colors.white,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashLogics {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Permission check
  // void checkPermissions(BuildContext context) async {
  //   try {
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //     }

  //     if (permission == LocationPermission.whileInUse ||
  //         permission == LocationPermission.always) {
  //       // Run initialization in background
  //       _initializeUser(context);
  //     } else {
  //       _showPermissionError(context);
  //     }
  //   } catch (e) {
  //     _showError(context, e.toString());
  //   }
  // }
  // Future<bool> checkPermissions(BuildContext context) async {
  //   try {
  //     // 1️⃣ Location permission
  //     var locationStatus = await Permission.location.status;
  //     if (!locationStatus.isGranted) {
  //       locationStatus = await Permission.location.request();
  //     }

  //     // 2️⃣ Notifications permission (iOS only, ignored on Android)
  //     var notifStatus = await Permission.notification.status;
  //     if (!notifStatus.isGranted) {
  //       notifStatus = await Permission.notification.request();
  //     }

  //     // 3️⃣ Storage permission (if your app uploads files/images)
  //     var storageStatus = await Permission.storage.status;
  //     if (!storageStatus.isGranted) {
  //       storageStatus = await Permission.storage.request();
  //     }

  //     // Check if any permission is denied permanently
  //     if (locationStatus.isDenied ||
  //         locationStatus.isPermanentlyDenied ||
  //         notifStatus.isDenied ||
  //         storageStatus.isDenied) {
  //       await _showPermissionError(context);
  //       return false;
  //     }
  //     _initializeUser(context);

  //     return true;
  //   } catch (e) {
  //     _showError(context, e.toString());
  //     return false;
  //   }
  // }

  void checkPermissions(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        if (context.mounted) {
          ErrorNotification().showError(
            context,
            "Location access is required to run Amini driver.",
          );
          await Future.delayed(const Duration(seconds: 2));
          SystemChannels.platform.invokeMethod(
            "SystemNavigator.exitApplication",
          );
        }
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _initializeUser(context);
      }
    } catch (e) {
      if (context.mounted) {
        ErrorNotification().showError(context, "An error occurred: $e");
      }
    }
  }

  Future<void> _showPermissionError(BuildContext context) async {
    if (!context.mounted) return;
    // Show a dialog with option to go to app settings
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Permissions Required"),
            content: const Text(
              "This app needs Location, Notifications, and Storage permissions to function properly. Please grant them in settings.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
    );
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Permission Error: $message"),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Non-blocking user initialization
  void _initializeUser(BuildContext context) async {
    final user = _auth.currentUser;
    //final user = await _auth.authStateChanges().first;

    if (user == null) {
      _navigate(context, Routes().register);
      return;
    }

    final isConnected = await _checkNetwork();
    if (!isConnected) {
      if (context.mounted) {
        ErrorNotification().showError(
          context,
          "No internet connection. Please reconnect and restart the app.",
        );
        return;
      }
    }

    final uid = user.uid;
    final email = user.email ?? '';
    final phone = user.phoneNumber ?? '';
    final token = await user.getIdToken();
    final fcmToken = await FirebaseMessaging.instance.getToken();

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/passengerauth/check-user"),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token', // ✅ Use token here
        },
      );

      if (response.statusCode == 200) {
        final backendData = jsonDecode(response.body);
        //final phoneFromBackend = backendData['phone'];

        // 🔥 Validate essential backend fields
        final bool hasBackendData =
            backendData.isNotEmpty &&
            backendData['phone'] != null &&
            backendData['phone'].toString().trim().isNotEmpty;

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        if (!(await userRef.get()).exists) {
          await userRef.set({
            'uid': uid,
            'phone': phone,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (hasBackendData) {
          await http.post(
            Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'token': token, 'fcmToken': fcmToken}),
          );
          context.goNamed(Routes().home);
        } else {
          context.goNamed(Routes().register);
        }
      } else {
        context.goNamed(Routes().register);
      }
    } catch (e) {
      debugPrint("Backend or Firestore check failed: $e");
    }
    //String baser = baseUrl;
    //     try {
    //       // Run backend check and Firestore check in parallel
    //       final response = http.get(
    //          Uri.parse("$baseUrl/passengerauth/check-user"),
    //         headers: {
    //           HttpHeaders.contentTypeHeader: 'application/json',
    //           HttpHeaders.authorizationHeader: 'Bearer $token', // ✅ Use token here
    //         },
    //       );
    // if (response. == 200) {
    //         final backendData = jsonDecode(response.body);
    //         //final phoneFromBackend = backendData['phone'];

    //         // 🔥 Validate essential backend fields
    //         final bool hasBackendData =
    //             backendData.isNotEmpty &&
    //             backendData['phone'] != null &&
    //             backendData['phone'].toString().trim().isNotEmpty;

    //         // if (!hasBackendUser) {
    //         //   if (context.mounted) context.goNamed(Routes().register);
    //         //   return;
    //         // }

    //         //   final hasBackendData =
    //         //       phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;

    //           final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    //           if (!(await userRef.get()).exists) {
    //             await userRef.set({
    //               'uid': uid,
    //               'phone': phone,
    //               'email': email,
    //               'createdAt': FieldValue.serverTimestamp(),
    //             });
    //           }

    //         if (hasBackendData) {
    //           await http.post(
    //             Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
    //             headers: {
    //               'Content-Type': 'application/json',
    //               'Authorization': 'Bearer $token',
    //             },
    //             body: jsonEncode({'token': token, 'fcmToken': fcmToken}),
    //           );
    //           context.goNamed(Routes().home);
    //         } else {
    //           context.goNamed(Routes().profilesetupscreen);
    //         }
    //       } else {
    //         context.goNamed(Routes().profilesetupscreen);
    //       }

    //       // final firestoreFuture =
    //       //     FirebaseFirestore.instance.collection('users').doc(uid).get();

    //       // final results = await Future.wait([backendFuture, firestoreFuture]);
    //       // final backendResponse = results[0] as http.Response;
    //       // final firestoreDoc = results[1] as DocumentSnapshot;

    //          final backendData = jsonDecode(backendFuture.body);
    //         //final phoneFromBackend = backendData['phone'];

    //         // 🔥 Validate essential backend fields
    //         final bool hasBackendData =
    //             backendData.isNotEmpty &&
    //             backendData['phone'] != null &&
    //             backendData['phone'].toString().trim().isNotEmpty;

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
  }

  // Future<bool> _checkNetwork() async {
  //   try {
  //     // Step 1: Check basic connectivity (Wi-Fi, Mobile, etc.)
  //     final connectivityResult = await Connectivity().checkConnectivity();
  //     if (connectivityResult == ConnectivityResult.none) return false;

  //     // Step 2: Confirm actual internet access (DNS check)
  //     final result = await InternetAddress.lookup(
  //       'example.com',
  //     ).timeout(const Duration(seconds: 3));

  //     return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  //   } catch (_) {
  //     return false;
  //   }
  // }
  Future<bool> _checkNetwork() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // void _showPermissionError(BuildContext context) async {
  //   if (!context.mounted) return;
  //   ErrorNotification().showError(
  //     context,
  //     "Location access is required to run Trippo.",
  //   );
  //   await Future.delayed(const Duration(seconds: 2));
  //   SystemChannels.platform.invokeMethod("SystemNavigator.pop");
  // }

  // void _showError(BuildContext context, String message) {
  //   if (!context.mounted) return;
  //   ErrorNotification().showError(context, message);
  // }

  void _navigate(BuildContext context, String routeName) {
    if (!context.mounted) return;
    GoRouter.of(context).goNamed(routeName);
  }
}

// // import 'package:flutter/material.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/Splash_Screen/splash_logics.dart';

// // class SplashScreen extends StatefulWidget {
// //   const SplashScreen({super.key});

// //   @override
// //   State<SplashScreen> createState() => _SplashScreenState();
// // }

// // class _SplashScreenState extends State<SplashScreen> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     SplashLogics().checkPermissions(context);
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     Size size = MediaQuery.sizeOf(context);
// //     return Scaffold(
// //       body: SafeArea(
// //         child: SizedBox(
// //           width: size.width,
// //           height: size.height,
// //           child: Center(
// //             child: Text(
// //               "amini",
// //               style: Theme.of(
// //                 context,
// //               ).textTheme.bodySmall!.copyWith(fontFamily: "bold", fontSize: 54),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // class SplashScreen extends StatefulWidget {
// //   @override
// //   _SplashScreenState createState() => _SplashScreenState();
// // }

// // class _SplashScreenState extends State<SplashScreen> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     Future.delayed(Duration(seconds: 5), () {
// //       context.go('/login'); // Navigate to login screen after 3 seconds
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.blueGrey,
// //       body: Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Text(
// //               'amini!',
// //               style: TextStyle(
// //                 fontSize: 24,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: 20),
// //             CircularProgressIndicator(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:niceapp/View/Screens/Other_Screens/Splash_Screen/splash_logics.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     SplashLogics().checkPermissions(context);
//     //SplashLogics().handleExistingRide(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
//           width: size.width,
//           height: size.height,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 👇 Replace with your actual logo if needed
//               Image.asset('assets/imgs/logo.png', width: 120, height: 120),
//               // const SizedBox(height: 20),
//               // Text(
//               //   "Amini",
//               //   style: TextStyle(
//               //     fontSize: 48,
//               //     fontFamily: "bold",
//               //     color: Colors.white,
//               //     fontWeight: FontWeight.bold,
//               //   ),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
