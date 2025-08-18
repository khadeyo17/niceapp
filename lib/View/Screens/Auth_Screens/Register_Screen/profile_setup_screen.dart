import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  //final bool isOwner;
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  //final TextEditingController dealerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // final List<String> registrationOptions = [
  //   "Register as Driver only",
  //   "Register as Vehicle Owner only",
  //   "Register as Both Driver and Vehicle Owner",
  // ];

  //String selectedOption = "Register as Driver only";

  //bool isLoading = true;

  @override
  void initState() {
    super.initState();

    //checkIfProfileExists();
  }

  // Future<void> checkIfProfileExists() async {
  //   final user = FirebaseAuth.instance.currentUser;

  //   if (user == null) {
  //     context.goNamed(Routes().register);
  //     // Navigator.pushReplacement(
  //     //   context,
  //     //   MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
  //     // );
  //     return;
  //   }

  //   try {
  //     final doc =
  //         await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(user.uid)
  //             .get();

  //     if (doc.exists) {
  //       final data = doc.data();
  //       final email = data?['email'] ?? '';
  //       final firstName = data?['firstName'] ?? '';
  //       final lastName = data?['lastName'] ?? '';

  //       // Pre-fill if partial data exists
  //       emailController.text = email;
  //       firstNameController.text = firstName;
  //       lastNameController.text = lastName;

  //       // If complete, navigate
  //       if (email.isNotEmpty && firstName.isNotEmpty && lastName.isNotEmpty) {
  //         if (mounted) {
  //           context.goNamed(Routes().home);
  //         }
  //         return;
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Error checking profile: $e")));
  //   }
  //   setState(() => isLoading = false);
  // }

  Future<void> saveProfileAndContinue() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    //final dealerName = lastNameController.text.trim();
    final email = emailController.text.trim();

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid name and email")),
      );
      return;
    }

    //setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        context.goNamed(Routes().register);
        return;
      }

      // 1️⃣ Get Firebase ID token
      // final idToken = await user.getIdToken();
      final idToken = await user.getIdToken(true);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      // 2️⃣ Send to backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': idToken,
          'role': 0,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': user.phoneNumber ?? user.uid,
          //'dealerName': dealerName,
          'email': email,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend error: ${response.body}');
      }

      // 3️⃣ Mirror into Firestore for client‐side reads
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': user.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) context.goNamed(Routes().home);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    } finally {
      //if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (isLoading) {
    //   return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Set Up Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // const Text("Enter Your Profile Information"),
            // DropdownButtonFormField<String>(
            //   value: selectedOption,
            //   items:
            //       registrationOptions.map((String value) {
            //         return DropdownMenuItem<String>(
            //           value: value,
            //           child: Text(value),
            //         );
            //       }).toList(),
            //   onChanged: (value) {
            //     setState(() {
            //       selectedOption = value!;
            //     });
            //   },
            //   decoration: const InputDecoration(
            //     labelText: 'Register As',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                hintText: "First Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                hintText: "Last Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ElevatedButton(
            //   onPressed: saveProfileAndContinue,
            //   child: const Text("Continue"),
            // ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    // fontco: col
                  ),
                ),
                onPressed: saveProfileAndContinue,
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
