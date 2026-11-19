
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;

  Future<void> saveProfileAndContinue() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (firstName.isEmpty ||
    lastName.isEmpty ||
    email.isEmpty ||
    !emailRegex.hasMatch(email)) {
  String message;

  if (firstName.isEmpty) {
    message = "Please enter your first name.";
  } else if (lastName.isEmpty) {
    message = "Please enter your last name.";
  } else if (email.isEmpty) {
    message = "Please enter your email address.";
  } else {
    message = "Please enter a valid email address.";
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF015ACE),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  return;
}


    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        context.goNamed(Routes().register);
        return;
      }

      final idToken = await user.getIdToken(true);
      final fcmToken = await FirebaseMessaging.instance.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/passengerauth/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': idToken,
          'role': 0,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': user.phoneNumber ?? user.uid,
          'email': email,
          'fcmToken': fcmToken,
        }),
      );

      // if (response.statusCode != 200) {
      //   throw Exception('Backend error: ${response.body}');
      // }
    if (response.statusCode != 200) {
      String message = "Something went wrong. Please try again.";

      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          message = data["message"]?.toString() ??
              data["Message"]?.toString() ??
              message;
        }
      } catch (_) {
        // Keep default message
      }

      throw Exception(message);
    }

    // Success
    if (!mounted) return;

    // Continue to next screen
    //context.go('/home');

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': user.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) context.goNamed(Routes().home);
  } catch (error) {
    if (!mounted) return;

    // SHOW ERROR HERE
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF015ACE),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'firstName': firstName,
  //       'lastName': lastName,
  //       'email': email,
  //       'phone': user.phoneNumber ?? '',
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     if (mounted) context.goNamed(Routes().home);
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
  //   } 
  //   finally {
  //     if (mounted) setState(() => isLoading = false);
  //   }
  // }

// InputDecoration _inputDecoration(String hint) {
//   const primaryBlue = Color(0xFF015ACE);
//   const textColor = Color(0xFF172033);

//   return InputDecoration(
//     hintText: hint,

//     hintStyle: GoogleFonts.nunitoSans(
//       fontSize: 14,
//       fontWeight: FontWeight.w500,
//       color: Colors.grey.shade500,
//     ),

//     filled: true,
//     fillColor: const Color(0xFFF8FAFD),

//     enabledBorder: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: const BorderSide(
//         color: Color(0xFFE2E7EF),
//         width: 1,
//       ),
//     ),

//     focusedBorder: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: const BorderSide(
//         color: primaryBlue,
//         width: 1.5,
//       ),
//     ),

//     contentPadding: const EdgeInsets.symmetric(
//       vertical: 16,
//       horizontal: 16,
//     ),

//     // Text entered by the user
//     // is controlled by the TextField style.
//   );
// }


  @override
Widget build(BuildContext context) {
  const primaryBlue = Color(0xFF015ACE);
  const accentYellow = Color(0xFFF0D000);
  const darkText = Color(0xFF172033);
  const secondaryText = Color(0xFF6B7280);

  return Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),

    appBar: AppBar(
      title: Text(
        "Set Up Profile",
        style: GoogleFonts.spaceGrotesk(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: darkText,
    ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [

          const SizedBox(height: 15),

          // =========================================================
          // HEADER
          // =========================================================

          Center(
            child: Column(
              children: [

                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.18),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Profile Setup",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Fill in your details to continue",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE8ECF2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Column(
              children: [

               

                // FIRST NAME
                TextField(
                  controller: firstNameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                  decoration: _inputDecoration(
                    "First Name",
                    icon: Icons.person_outline_rounded,
                  ),
                ),

                const SizedBox(height: 16),

                // LAST NAME
                TextField(
                  controller: lastNameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                  decoration: _inputDecoration(
                    "Last Name",
                    icon: Icons.person_outline_rounded,
                  ),
                ),
const SizedBox(height: 16),
 // EMAIL
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                  decoration: _inputDecoration(
                    "Email",
                    icon: Icons.email_outlined,
                  ),
                ),

                

              ],
            ),
          ),

          const SizedBox(height: 30),

          // =========================================================
          // NEXT BUTTON
          // =========================================================

          SizedBox(
            width: double.infinity,
            height: 56,

            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : saveProfileAndContinue,

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor:
                    primaryBlue.withOpacity(0.55),
                foregroundColor: Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          "Next Step",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 10),

                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 21,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // =========================================================
          // STEP INDICATOR
          // =========================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 7),

              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

InputDecoration _inputDecoration(
  String label, {
  IconData? icon,
}) 
{
  const primaryBlue = Color(0xFF015ACE);

  return InputDecoration(
    labelText: label,

    labelStyle: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade600,
    ),

    floatingLabelStyle: GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: primaryBlue,
    ),

    prefixIcon: icon == null
        ? null
        : Icon(
            icon,
            color: Colors.grey.shade500,
            size: 21,
          ),

    filled: true,
    fillColor: const Color(0xFFF8FAFD),

    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 17,
    ),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE2E7EF),
      ),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE2E7EF),
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: primaryBlue,
        width: 1.5,
      ),
    ),
  );
}
}
