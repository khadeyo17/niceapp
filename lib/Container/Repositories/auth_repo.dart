// import 'dart:convert';
// import 'dart:io';

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher_string.dart';

import '../../View/Routes/routes.dart';
import '../utils/error_notification.dart';

final globalAuthRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());

class AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;

  // Future<bool> startPhoneVerification({
  //   required String phone,
  //   required String method, // "sms" or "whatsapp"
  //   //required String email,
  //   //required String firstName,
  //   //required String lastName,
  //   required BuildContext context,
  // }) async {
  //   try {
  //     if (method == "whatsapp") {
  //       final whatsappUrl = Uri.parse("https://wa.me/$phone");
  //       if (await canLaunchUrl(whatsappUrl)) {
  //         await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  //       } else {
  //         throw "Could not launch WhatsApp";
  //       }
  //       return false;
  //     }

  //     await _auth.verifyPhoneNumber(
  //       phoneNumber: phone,
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         await _auth.signInWithCredential(credential);
  //         if (context.mounted) {
  //           context.goNamed(Routes().home);
  //         }
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Verification failed: ${e.message}")),
  //         );
  //       },
  //       codeSent: (String verificationId, int? resendToken) {
  //         _verificationId = verificationId;
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text("OTP code sent to $phone")));

  //         if (context.mounted) {
  //           context.goNamed(
  //             'otp',
  //             extra: {'verificationId': verificationId, 'phoneNumber': phone},
  //           );
  //         }
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         _verificationId = verificationId;
  //       },
  //     );

  //     return true;
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Error: $e")));
  //     return false;
  //   }
  // }

  /// Call this after code is sent, with the entered OTP

  Future<String?> startPhoneVerification({
    required String phone,
    required String method,
    required BuildContext context,
  }) async {
    final completer = Completer<String?>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
        completer.complete(null);
      },
      codeSent: (String verificationId, int? resendToken) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("OTP code sent to $phone")));
        completer.complete(verificationId); // ✅ return the actual ID
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return completer.future;
  }

  // Future<bool> startPhoneVerification({
  //   required String phone,
  //   required String method,
  //   required BuildContext context,
  // }) async {
  //   try {
  //     await FirebaseAuth.instance.verifyPhoneNumber(
  //       phoneNumber: phone,
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         await FirebaseAuth.instance.signInWithCredential(credential);
  //         if (context.mounted) context.goNamed('home');
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
  //       },
  //       codeSent: (String verificationId, int? resendToken) {
  //         print("codeSent: $verificationId");
  //         print("PHONE: $phone");

  //         if (context.mounted) {
  //           context.goNamed(
  //             'otp',
  //             extra: {'verificationId': verificationId, 'phoneNumber': phone},
  //           );
  //         }
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         print("codeAutoRetrievalTimeout: $verificationId");
  //       },
  //     );
  //     return true;
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Error: $e")));
  //     return false;
  //   }
  // }

  Future<void> loginWithPhoneNumber({
    required String verificationId,
    required String smsCode,
    required BuildContext context,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        //final idToken = await user.getIdToken();
        if (context.mounted) {
          context.goNamed(Routes().home);
        }
      } else {
        ErrorNotification().showError(context, "Login failed. Try again.");
      }
    } on FirebaseAuthException catch (e) {
      ErrorNotification().showError(context, "Login error: ${e.message}");
    } catch (e) {
      ErrorNotification().showError(context, "Unexpected error: $e");
    }
  }

  // Other existing methods: registerWithEmailPhonePassword, loginWithEmailPassword, signInWithGoogle...
}

// import 'dart:convert';
// import 'dart:io';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher_string.dart';
// //import 'package:url_launcher/url_launcher.dart' show launchUrl, canLaunchUrl, LaunchMode;

// import '../../View/Routes/routes.dart';
// import '../utils/error_notification.dart';

// final globalAuthRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());

// class AuthRepo {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   Future<bool> startPhoneVerification({
//     required String phone,
//     required String method, // "sms" or "whatsapp"
//     required String email,
//     required String firstName,
//     required String lastName,
//     required BuildContext context,
//   }) async {
//     try {
//       if (method == "whatsapp") {
//         final whatsappUrl = Uri.parse("https://wa.me/$phone");
//         if (await canLaunchUrl(whatsappUrl)) {
//           await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
//         } else {
//           throw "Could not launch WhatsApp";
//         }
//         return false; // don't proceed to OTP screen
//       }

//       // Firebase SMS OTP logic
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phone,
//         verificationCompleted: (PhoneAuthCredential credential) {
//           // Auto-retrieval or instant verification (rare)
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Verification failed: ${e.message}")),
//           );
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           // Store verificationId in shared/global state if needed
//           print("Verification ID: $verificationId");
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           print("Auto retrieval timeout: $verificationId");
//         },
//       );

//       return true;
//     } catch (e) {
//       print("startPhoneVerification error: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//       return false;
//     }
//   }

//   Future<bool> registerWithEmailPhonePassword({
//     required String fullName,
//     required String email,
//     required String phone,
//     required String password,
//     required BuildContext context,
//   }) async {
//     try {
//       // Step 1: Check if user exists in backend
//       // final checkResponse = await http.get(
//       //   Uri.parse("$baseUrl/auth/check-user-by-email?email=$email"),
//       //   headers: {'Content-Type': 'application/json'},
//       // );

//       // if (checkResponse.statusCode == 200) {
//       //   final data = jsonDecode(checkResponse.body);
//       //   final exists = data['exists'] as bool;

//       //   if (exists) {
//       //     ScaffoldMessenger.of(context).showSnackBar(
//       //       SnackBar(content: Text('User already exists. Please log in.')),
//       //     );
//       //     return false;
//       //   }
//       // } else if (checkResponse.statusCode != 404) {
//       //   ScaffoldMessenger.of(context).showSnackBar(
//       //     SnackBar(content: Text('Error checking user. Try again later.')),
//       //   );
//       //   return false;
//       // }

//       // Step 2: Register with Firebase
//       final credential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       final user = credential.user;
//       if (user != null) {
//         await user.sendEmailVerification();

//         // Step 3: Create user in backend

//         final idToken = await user.getIdToken();

//         if (context.mounted) {
//           context.goNamed(Routes().login);
//           //context.go('/vehicle-onboarding');
//         }
//         // final response = await http.post(
//         //   Uri.parse('$baseUrl/auth/firebase-login'),
//         //   headers: {
//         //     HttpHeaders.contentTypeHeader: 'application/json',
//         //     HttpHeaders.authorizationHeader: 'Bearer $idToken',
//         //   },
//         //   body: jsonEncode({
//         //     "fullName": user.displayName ?? "",
//         //     "email": user.email,
//         //     "phoneNumber": user.phoneNumber ?? "",
//         //     "role": "Driver",
//         //     "token": idToken,
//         //   }),
//         // );
//         // if (response.statusCode == 201 || response.statusCode == 200) {
//         //   return true;
//         // } else {
//         //   ScaffoldMessenger.of(context).showSnackBar(
//         //     SnackBar(content: Text('Failed to create user in backend.')),
//         //   );
//         //   return false;
//         // }
//       }
//     } on FirebaseAuthException catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Registration failed: ${e.message}')),
//       );
//       return false;
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('An unexpected error occurred: $e')),
//       );
//       return false;
//     }
//     return false;
//   }

//   Future<void> loginWithEmailPassword({
//     required String email,
//     required String password,
//     required BuildContext context,
//   }) async {
//     try {
//       final userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       final user = userCredential.user;
//       final firebaseId = userCredential.user?.uid;

//       if (user == null) {
//         ErrorNotification().showError(context, "Login failed. Try again.");
//         return;
//       }

//       await user.reload();

//       if (!user.emailVerified) {
//         ErrorNotification().showError(
//           context,
//           "Please verify your email before logging in.",
//         );
//         return;
//       }

//       // ✅ Get Firebase ID token
//       //final idToken = await user.getIdToken();

//       // ✅ Send token to your backend for authentication
//       // final authResponse = await http.post(
//       //   Uri.parse("http://192.168.100.160:7047/api/auth/firebase-login"),
//       //   //headers: {'Content-Type': 'application/json'},
//       //   //body: jsonEncode({'token': idToken}),
//       // );
//       // final authResponse = await http.get(
//       //   Uri.parse("$baseUrl/auth/check-user/${user.uid}"),
//       //   headers: {HttpHeaders.authorizationHeader: 'Bearer $idToken'},
//       // );

//       // if (authResponse.statusCode == 200) {
//       // ✅ Now check if user has a vehicle
//       // final vehicleResponse = await http.get(
//       //   Uri.parse("$baseUrl/api/driver-vehicles/by-driver/$firebaseId"),
//       //   headers: {'Content-Type': 'application/json'},
//       // );

//       // if (vehicleResponse.statusCode == 200 ||
//       //     vehicleResponse.statusCode == 201) {
//       //   final hasVehicle = jsonDecode(vehicleResponse.body)['hasVehicle'];

//       //   if (hasVehicle == true) {
//       //     // ✅ Navigate to main screen
//       //     if (context.mounted) {
//       //       context.goNamed(Routes().navigationScreen);
//       //       //context.go('/main-navigation');
//       //     }
//       //   } else {
//       //     // 🚗 Navigate to vehicle onboarding
//       //     if (context.mounted) {
//       //       context.goNamed(Routes().driverConfig);
//       //       //context.go('/vehicle-onboarding');
//       //     }
//       //   }
//       // } else {
//       //   // ErrorNotification().showError(
//       //   //   context,
//       //   //   'Failed to check vehicle status.',
//       //   // );

//       if (context.mounted) {
//         context.goNamed(Routes().home);
//         //context.go('/vehicle-onboarding');
//       }
//       // } else {
//       //   ErrorNotification().showError(
//       //     context,
//       //     'Backend login failed. (${authResponse.statusCode})',
//       //   );
//       // }
//     } on FirebaseAuthException catch (e) {
//       await _auth.signOut();
//       ErrorNotification().showError(context, e.message ?? 'Login failed');
//     } catch (e) {
//       await _auth.signOut();
//       ErrorNotification().showError(context, 'Unexpected error: $e');
//     }
//   }

//   Future<void> signInWithGoogle(BuildContext context) async {
//     try {
//       final googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) return;

//       final googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final authResult = await FirebaseAuth.instance.signInWithCredential(
//         credential,
//       );
//       final user = authResult.user;
//       final idToken = await user?.getIdToken();

//       // final response = await http.post(
//       //   Uri.parse("$baseUrl/auth/firebase-login"),
//       //   headers: {
//       //     HttpHeaders.contentTypeHeader: 'application/json',
//       //     HttpHeaders.authorizationHeader: 'Bearer $idToken',
//       //   },
//       //   body: jsonEncode({
//       //     "email": user?.email,
//       //     "phone": user?.phoneNumber ?? '',
//       //     "category"
//       //             "role":
//       //         "Driver",
//       //   }),
//       // );
//       // if (response.statusCode == 200 && context.mounted) {
//       //   context.goNamed(Routes().home);
//       // } else if (context.mounted) {
//       //   ErrorNotification().showError(
//       //     context,
//       //     'Backend error: ${response.body}',
//       //   );
//       // }
//     } catch (e) {
//       if (context.mounted) {
//         ErrorNotification().showError(context, "Google sign-in failed: $e");
//       }
//     }
//   }
// }

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// //import '../../View/Routes/app_routes.dart';
// import '../utils/error_notification.dart';

// /// [authRepoProvider] used to cache the [AuthRepo] class to prevent it from creating multiple instances

// final globalAuthRepoProvider = Provider<AuthRepo>((ref) {
//   return AuthRepo();
// });

// /// [AuthRepo] provides functions used for authentication purposes

// class AuthRepo {
//   void loginUser(email, password, BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       if (context.mounted) {
//         context.goNamed(Routes().home);
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ErrorNotification().showError(context, "An Error Occurred $e");
//       }
//     }
//   }

//   void registerUser(email, password, BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       if (context.mounted) {
//         context.goNamed(Routes().home);
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ErrorNotification().showError(context, "An Error Occurred $e");
//       }
//     }
//   }
// }
