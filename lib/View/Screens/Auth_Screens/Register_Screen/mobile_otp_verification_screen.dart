import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'profile_setup_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
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
    listenForCode(); // Start listening for SMS autofill
  }

  @override
  void dispose() {
    cancel(); // Stop listening when screen closes
    super.dispose();
  }

  @override
  void codeUpdated() {
    final incomingCode = code;
    if (incomingCode != null && incomingCode.length == 6) {
      setState(() {
        otpCode = incomingCode;
      });
      verifyOTP();
    }
  }

  // Future<void> verifyOTP() async {
  //   if (_isVerifying) return; // Prevent multiple calls
  //   if (widget.verificationId.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Verification ID is missing. Please retry."),
  //       ),
  //     );
  //     return;
  //   }

  //   if (otpCode.length < 6) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Enter a valid 6-digit OTP")),
  //     );
  //     return;
  //   }

  //   setState(() => isLoading = true);
  //   _isVerifying = true;

  //   try {
  //     final credential = PhoneAuthProvider.credential(
  //       verificationId: widget.verificationId,
  //       smsCode: otpCode,
  //     );

  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //     await Future.delayed(Duration(seconds: 1)); // simulate async work

  //     if (!mounted) return; // widget is no longer active
  //     context.goNamed(Routes().profilesetupscreen);
  //   } on FirebaseAuthException catch (e) {
  //     setState(() => isLoading = false);
  //     _isVerifying = false;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Verification failed: ${e.code} - ${e.message}"),
  //       ),
  //     );
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     _isVerifying = false;
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
  //   }
  // }

  Future<void> verifyOTP() async {
    if (_isVerifying) return;
    if (widget.verificationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification ID is missing. Please retry."),
        ),
      );
      return;
    }

    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 6-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);
    _isVerifying = true;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final data = userDoc.data();

        if (!mounted) return;

        if (data != null &&
            data['firstName'] != null &&
            data['lastName'] != null &&
            data['email'] != null) {
          // User profile is complete
          context.goNamed(Routes().home);
        } else {
          // Incomplete profile
          context.goNamed(Routes().profilesetupscreen);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      _isVerifying = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Verification failed: ${e.code} - ${e.message}"),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      _isVerifying = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, //backgroundColor: Colors.grey[100]
      body: Stack(
        children: [
          // White Panel covering fullscreen
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            margin: const EdgeInsets.only(top: 120),
          ),
          // AppBar-style back and title
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => context.goNamed(Routes().register),
            ),
          ),
          // Main Content
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 120),
                  Text(
                    "Verify OTP",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter the 6-digit code sent to",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PinFieldAutoFill(
                    codeLength: 6,
                    decoration: BoxLooseDecoration(
                      gapSpace: 10,
                      strokeWidth: 2,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                      bgColorBuilder: FixedColorBuilder(Colors.grey.shade200),
                      strokeColorBuilder: FixedColorBuilder(Colors.blue),
                      radius: const Radius.circular(8),
                    ),
                    currentCode: otpCode,
                    onCodeChanged: (code) {
                      if (code != null && code.length == 6) {
                        setState(() => otpCode = code);
                        verifyOTP();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text("Verify"),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // Optionally re-send OTP logic here
                    },
                    child: const Text(
                      "Send OTP Again",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text("Verify OTP"),
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back),
  //         onPressed: () => context.goNamed(Routes().register),
  //       ),
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text("Enter the 6-digit code sent to ${widget.phoneNumber}."),
  //           const SizedBox(height: 20),

  //           // PinFieldAutoFill(
  //           //   codeLength: 6,
  //           //   decoration: UnderlineDecoration(
  //           //     textStyle: const TextStyle(fontSize: 20, color: Colors.black),
  //           //     colorBuilder: FixedColorBuilder(Colors.blue),
  //           //   ),
  //           //   currentCode: otpCode,
  //           //   onCodeChanged: (code) {
  //           //     if (code != null && code.length == 6) {
  //           //       setState(() => otpCode = code);
  //           //       verifyOTP();
  //           //     }
  //           //   },
  //           // ),
  //           PinFieldAutoFill(
  //             codeLength: 6,
  //             decoration: BoxLooseDecoration(
  //               gapSpace: 10,
  //               strokeWidth: 2,
  //               textStyle: const TextStyle(fontSize: 20, color: Colors.black),
  //               bgColorBuilder: FixedColorBuilder(Colors.grey.shade200),
  //               strokeColorBuilder: FixedColorBuilder(Colors.blue),
  //               radius: const Radius.circular(8),
  //             ),
  //             currentCode: otpCode,
  //             onCodeChanged: (code) {
  //               if (code != null && code.length == 6) {
  //                 setState(() => otpCode = code);
  //                 verifyOTP();
  //               }
  //             },
  //           ),

  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: isLoading ? null : verifyOTP,
  //             child:
  //                 isLoading
  //                     ? const CircularProgressIndicator(color: Colors.white)
  //                     : const Text("Verify"),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:sms_autofill/sms_autofill.dart';
// //import 'profile_setup_screen.dart';

// class OTPVerificationScreen extends StatefulWidget {
//   final String verificationId;
//   final String phoneNumber;

//   const OTPVerificationScreen({
//     super.key,
//     required this.verificationId,
//     required this.phoneNumber,
//   });

//   @override
//   State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
// }

// class _OTPVerificationScreenState extends State<OTPVerificationScreen>
//     with CodeAutoFill {
//   String otpCode = '';
//   bool isLoading = false;
//   bool _isVerifying = false;

//   // Resend OTP fields
//   late String currentVerificationId;
//   int _resendToken = 0;
//   bool canResend = false;
//   int resendCooldown = 60;
//   Timer? _resendTimer;

//   // void registerSmsListener() {
//   //   listenForCode(); // From CodeAutoFill
//   //   unregisterListener(); // This will work only if you import correctly
//   // }

//   @override
//   void initState() {
//     super.initState();
//     currentVerificationId = widget.verificationId;
//     listenForCode();
//     //unregisterListener(this);
//     startResendCooldown();
//   }

//   @override
//   void dispose() {
//     cancel();
//     _resendTimer?.cancel();
//     super.dispose();
//   }

//   void startResendCooldown() {
//     setState(() {
//       canResend = false;
//       resendCooldown = 60;
//     });

//     _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (resendCooldown <= 1) {
//         timer.cancel();
//         setState(() => canResend = true);
//       } else {
//         setState(() => resendCooldown--);
//       }
//     });
//   }

//   void codeUpdated() {
//     final incomingCode = code;
//     if (incomingCode != null && incomingCode.length == 6) {
//       setState(() => otpCode = incomingCode);
//       verifyOTP();
//     }
//   }

//   Future<void> resendOTP() async {
//     setState(() => isLoading = true);

//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: widget.phoneNumber,
//       forceResendingToken: _resendToken,
//       timeout: const Duration(seconds: 60),
//       verificationCompleted: (PhoneAuthCredential credential) {},
//       verificationFailed: (FirebaseAuthException e) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Resend failed: ${e.message}")));
//         setState(() => isLoading = false);
//       },
//       codeSent: (String newVerificationId, int? resendToken) {
//         setState(() {
//           currentVerificationId = newVerificationId;
//           _resendToken = resendToken ?? 0;
//           isLoading = false;
//         });
//         startResendCooldown();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("OTP resent successfully.")),
//         );
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {},
//     );
//   }

//   Future<void> verifyOTP() async {
//     if (_isVerifying) return;
//     if (currentVerificationId.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Verification ID is missing.")),
//       );
//       return;
//     }

//     if (otpCode.length < 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Enter a valid 6-digit OTP")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);
//     _isVerifying = true;

//     try {
//       final credential = PhoneAuthProvider.credential(
//         verificationId: currentVerificationId,
//         smsCode: otpCode,
//       );

//       final userCredential = await FirebaseAuth.instance.signInWithCredential(
//         credential,
//       );
//       final user = userCredential.user;

//       if (user != null) {
//         final userDoc =
//             await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(user.uid)
//                 .get();

//         final data = userDoc.data();

//         if (!mounted) return;

//         if (data != null &&
//             data['firstName'] != null &&
//             data['lastName'] != null &&
//             data['email'] != null) {
//           context.goNamed(Routes().home);
//         } else {
//           context.goNamed(Routes().profilesetupscreen);
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       setState(() => isLoading = false);
//       _isVerifying = false;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Verification failed: ${e.message}")),
//       );
//     } catch (e) {
//       setState(() => isLoading = false);
//       _isVerifying = false;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Verify OTP"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text("Enter the 6-digit code sent to ${widget.phoneNumber}."),
//             const SizedBox(height: 20),
//             // PinFieldAutoFill(
//             //   codeLength: 6,
//             //   decoration: UnderlineDecoration(
//             //     textStyle: const TextStyle(fontSize: 20, color: Colors.black),
//             //     colorBuilder: FixedColorBuilder(Colors.blue),
//             //   ),
//             //   onCodeChanged: (code) {
//             //     if (code != null && code.length == 6) {
//             //       otpCode = code;
//             //       verifyOTP(); // auto-submit when complete
//             //     }
//             //   },
//             // ),
//             PinFieldAutoFill(
//               codeLength: 6,
//               decoration: UnderlineDecoration(
//                 textStyle: const TextStyle(fontSize: 20, color: Colors.black),
//                 colorBuilder: FixedColorBuilder(Colors.blue),
//               ),
//               currentCode: otpCode,
//               onCodeChanged: (code) {
//                 if (code != null && code.length == 6) {
//                   setState(() => otpCode = code);
//                   verifyOTP();
//                 }
//               },
//             ),

//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: isLoading ? null : verifyOTP,
//               child:
//                   isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Verify"),
//             ),
//             const SizedBox(height: 20),
//             TextButton(
//               onPressed: canResend ? resendOTP : null,
//               child: Text(
//                 canResend ? "Resend OTP" : "Resend OTP in $resendCooldown sec",
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
