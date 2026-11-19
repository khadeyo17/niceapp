import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/resources/colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String method;

  const OTPVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.method,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with CodeAutoFill {
  String otpCode = '';
  bool isLoading = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void codeUpdated() {
    final incomingCode = code;

    if (incomingCode != null && incomingCode.length == 6 && !_isVerifying) {
      otpCode = incomingCode;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        verifyOTP();
      });
    }
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  // @override
  // void codeUpdated() {
  //   final incomingCode = code;
  //   if (incomingCode != null && incomingCode.length == 6) {
  //     setState(() => otpCode = incomingCode);
  //     verifyOTP();
  //   }
  // }

  Future<void> handlePostLogin(User? user) async {
    if (user == null) return;

    final uid = user.uid;
    final phone = user.phoneNumber ?? '';
    final email = user.email ?? '';
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

        // if (!hasBackendUser) {
        //   if (context.mounted) context.goNamed(Routes().register);
        //   return;
        // }
        //   final hasBackendData =
        //       phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;

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
          context.goNamed(Routes().profilesetupscreen);
        }
      } else {
        context.goNamed(Routes().profilesetupscreen);
      }
    } catch (e) {
      debugPrint("Backend or Firestore check failed: $e");
    }
  }

  // Future<void> handlePostLogin(User? user) async {
  //   if (user == null) return;

  //   final uid = user.uid;
  //   final phone = user.phoneNumber ?? '';
  //   final email = user.email ?? '';
  //   final token = await user.getIdToken();
  //   final fcmToken = await FirebaseMessaging.instance.getToken();

  //   try {
  //     final response = await http.get(
  //       // Uri.parse('$baseUrl/passengerauth/check-user/$uid'),
  //       // headers: {
  //       //   'Content-Type': 'application/json',
  //       //   'Authorization': 'Bearer $token',
  //       // },
  //       Uri.parse("$baseUrl/passengerauth/check-user"),
  //       headers: {
  //         HttpHeaders.contentTypeHeader: 'application/json',
  //         HttpHeaders.authorizationHeader: 'Bearer $token', // ✅ Use token here
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final backendData = jsonDecode(response.body);
  //       final phoneFromBackend = backendData['phone'];
  //       final hasBackendData =
  //           phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;

  //       if (!hasBackendData) {
  //         // User exists in Firebase but NOT in backend -> block navigation
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text(
  //               "You are not registered in the system. Contact support.",
  //             ),
  //           ),
  //         );
  //         return;
  //       }

  //       // Ensure user exists in Firestore for app-side usage
  //       final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  //       if (!(await userRef.get()).exists) {
  //         await userRef.set({
  //           'uid': uid,
  //           'phone': phone,
  //           'email': email,
  //           'createdAt': FieldValue.serverTimestamp(),
  //         });
  //       }

  //       // Update FCM token in backend
  //       await http.post(
  //         Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Authorization': 'Bearer $token',
  //         },
  //         body: jsonEncode({'token': token, 'fcmToken': fcmToken}),
  //       );

  //       // Only now navigate to home
  //       context.goNamed(Routes().home);
  //     } else if (response.statusCode == 404) {
  //       // User not found in backend
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("User not found in backend. Cannot proceed."),
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Backend check failed. Try again later."),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint("Backend or Firestore check failed: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Error connecting to backend.")),
  //     );
  //   }
  // }

  Future<void> verifyOTP() async {
    if (_isVerifying) return;
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 6-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);
    _isVerifying = true;

    try {
      if (widget.method == 'sms') {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpCode,
        );
        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        await handlePostLogin(userCredential.user);
      } else if (widget.method == 'whatsapp') {
        final response = await http.post(
          Uri.parse("$baseUrl/passengerauth/VerifyWhatsappOTP"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': widget.phoneNumber, 'otp': otpCode}),
        );

        final body = jsonDecode(response.body);
        if (body['verified'] != true || body['firebaseToken'] == null) {
          throw Exception(body['error'] ?? 'Verification failed');
        }

        final userCredential = await FirebaseAuth.instance
            .signInWithCustomToken(body['firebaseToken'] as String);
        await handlePostLogin(userCredential.user);
      }
    } 
    catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 4),
      content: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE5484D).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF6B6B),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Failed',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    ),
  );
} finally {
  if (mounted) {
    setState(() {
      isLoading = false;
      _isVerifying = false;
    });
  }
}
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Verify OTP"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 🔥 ICON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF015ACE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 28),
            ),

            const SizedBox(height: 20),

            const Text(
              "Verification Code",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Enter the 6-digit code sent to",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 5),

            Text(
              widget.phoneNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // 🔥 OTP BOXES
            PinFieldAutoFill(
              codeLength: 6,
              currentCode: otpCode,
              decoration: BoxLooseDecoration(
                strokeColorBuilder: FixedColorBuilder(Colors.black),
                bgColorBuilder: FixedColorBuilder(Colors.grey.shade100),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                gapSpace: 10,
                radius: const Radius.circular(10),
              ),
              onCodeChanged: (code) {
                if (code != null && code.length == 6 && !_isVerifying) {
                  otpCode = code;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    verifyOTP();
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            // 🔥 BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF015ACE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          "Verify",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔁 RESEND
            TextButton(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        // TODO: resend OTP
                      },
              child: const Text(
                "Resend Code",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/////workingwell
// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:sms_autofill/sms_autofill.dart';

// class OTPVerificationScreen extends StatefulWidget {
//   final String verificationId;
//   final String phoneNumber;
//   final String method;

//   const OTPVerificationScreen({
//     super.key,
//     required this.verificationId,
//     required this.phoneNumber,
//     required this.method,
//   });

//   @override
//   State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
// }

// class _OTPVerificationScreenState extends State<OTPVerificationScreen>
//     with CodeAutoFill {
//   String otpCode = '';
//   bool isLoading = false;
//   bool _isVerifying = false;

//   @override
//   void initState() {
//     super.initState();
//     listenForCode(); // Start listening for SMS autofill
//   }

//   @override
//   void dispose() {
//     cancel(); // Stop listening when screen closes
//     super.dispose();
//   }

//   @override
//   void codeUpdated() {
//     final incomingCode = code;
//     if (incomingCode != null && incomingCode.length == 6) {
//       setState(() {
//         otpCode = incomingCode;
//       });
//       verifyOTP();
//     }
//   }

//   Future<void> handlePostLogin(User? user) async {
//     if (user == null) return;

//     final uid = user.uid;
//     final phone = user.phoneNumber ?? '';
//     final email = user.email ?? '';
//     final token = await user.getIdToken();
//     final fcmToken = await FirebaseMessaging.instance.getToken();

//     bool hasBackendData = false;

//     try {
//       // 1️⃣ Check Backend
//       final response = await http.get(
//         Uri.parse('$baseUrl/passengerauth/check-user/$uid'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       // String? fullNameFromBackend;
//       String? phoneFromBackend;

//       if (response.statusCode == 200) {
//         final backendData = jsonDecode(response.body);
//         //fullNameFromBackend = backendData['fullName'];
//         phoneFromBackend = backendData['phone'];

//         hasBackendData =
//             // fullNameFromBackend != null &&
//             // fullNameFromBackend.trim().isNotEmpty &&
//             phoneFromBackend != null && phoneFromBackend.trim().isNotEmpty;

//         // 2️⃣ Check Firestore
//         final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
//         final userDoc = await userRef.get();

//         if (!userDoc.exists) {
//           await userRef.set({
//             'uid': uid,
//             'phone': phone,
//             'email': email,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }

//         final firestoreData = (await userRef.get()).data();
//         // hasFirestoreData =
//         //     firestoreData != null &&
//         //     firestoreData['firstName'] != null &&
//         //     firestoreData['lastName'] != null &&
//         //     firestoreData['email'] != null;

//         //   3️⃣ Route Based on Results
//         if (hasBackendData) {
//           final response = await http.post(
//             Uri.parse('$baseUrl/passengerauth/update-fcm-token'),
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode({
//               'token': token, // Firebase ID token
//               'fcmToken': fcmToken, // Device's FCM token
//             }),
//           );
//           if (response.statusCode == 200) {
//             context.goNamed(Routes().home);
//           } else {
//             context.goNamed(
//               Routes().home,
//             ); //debugPrint("Failed to validate token, contact amini support");
//           }
//         } else {
//           debugPrint("Failed to validate user, contact amini support");
//         }
//         //context.goNamed(Routes().home);
//       } else {
//         context.goNamed(Routes().profilesetupscreen);
//       }
//     } catch (e) {
//       debugPrint("Backend or Firestore check failed: $e");
//       // Optionally: navigate to error screen or retry
//     }
//   }

//   Future<void> verifyOTP() async {
//     if (_isVerifying) return;
//     if (otpCode.length < 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Enter a valid 6-digit OTP")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);
//     _isVerifying = true;

//     try {
//       if (widget.method == 'sms') {
//         // Firebase SMS verification
//         if (widget.verificationId.isEmpty) {
//           throw Exception("Verification ID is missing.");
//         }
//         final credential = PhoneAuthProvider.credential(
//           verificationId: widget.verificationId,
//           smsCode: otpCode,
//         );
//         final userCredential = await FirebaseAuth.instance.signInWithCredential(
//           credential,
//         );
//         await handlePostLogin(userCredential.user);
//       } else if (widget.method == 'whatsapp') {
//         // Backend WhatsApp verification → returns firebaseCustomToken
//         final response = await http.post(
//           Uri.parse("$baseUrl/passengerauth/VerifyWhatsappOTP"),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({'phone': widget.phoneNumber, 'otp': otpCode}),
//         );

//         if (response.statusCode != 200) {
//           final err =
//               jsonDecode(response.body)['error'] ?? 'Verification failed';
//           throw Exception(err);
//         }

//         final body = jsonDecode(response.body);
//         if (body['verified'] != true || body['firebaseToken'] == null) {
//           throw Exception(body['error'] ?? 'Verification failed');
//         }

//         // Sign in with the custom token
//         final userCredential = await FirebaseAuth.instance
//             .signInWithCustomToken(body['firebaseToken'] as String);

//         await handlePostLogin(userCredential.user);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Verification failed: $e")));
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           _isVerifying = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: Colors.white, //backgroundColor: Colors.grey[100]
//       body: Stack(
//         children: [
//           // White Panel covering fullscreen
//           Container(
//             height: height,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(30),
//               ),
//             ),
//             margin: const EdgeInsets.only(top: 120),
//           ),
//           // AppBar-style back and title
//           SafeArea(
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.grey),
//               onPressed: () => context.goNamed(Routes().register),
//             ),
//           ),
//           // Main Content
//           Align(
//             alignment: Alignment.center,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 120),
//                   Text(
//                     "Verify OTP",
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     "Enter the 6-digit code sent to",
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     widget.phoneNumber,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   PinFieldAutoFill(
//                     codeLength: 6,
//                     decoration: BoxLooseDecoration(
//                       gapSpace: 10,
//                       strokeWidth: 2,
//                       textStyle: const TextStyle(
//                         fontSize: 20,
//                         color: Colors.black,
//                       ),
//                       bgColorBuilder: FixedColorBuilder(Colors.grey.shade200),
//                       strokeColorBuilder: FixedColorBuilder(Colors.blue),
//                       radius: const Radius.circular(8),
//                     ),
//                     currentCode: otpCode,
//                     onCodeChanged: (code) {
//                       if (code != null && code.length == 6) {
//                         setState(() => otpCode = code);
//                         verifyOTP();
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: isLoading ? null : verifyOTP,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 40,
//                         vertical: 12,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child:
//                         isLoading
//                             ? const CircularProgressIndicator(
//                               color: Colors.white,
//                             )
//                             : const Text("Verify"),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () {
//                       // Optionally re-send OTP logic here
//                     },
//                     child: const Text(
//                       "Send OTP Again",
//                       style: TextStyle(color: Colors.blue),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
