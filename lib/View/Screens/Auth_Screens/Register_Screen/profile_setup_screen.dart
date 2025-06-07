import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkIfProfileExists();
  }

  Future<void> checkIfProfileExists() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      context.goNamed(Routes().register);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
      // );
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data();
        final email = data?['email'] ?? '';
        final firstName = data?['firstName'] ?? '';
        final lastName = data?['lastName'] ?? '';

        // Pre-fill if partial data exists
        emailController.text = email;
        firstNameController.text = firstName;
        lastNameController.text = lastName;

        // If complete, navigate
        if (email.isNotEmpty && firstName.isNotEmpty && lastName.isNotEmpty) {
          if (mounted) {
            context.goNamed(Routes().home);
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => const TransportServicesScreen(),
            //   ),
            // );
          }
          return;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error checking profile: $e")));
    }

    setState(() => isLoading = false);
  }

  Future<void> saveProfileAndContinue() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'uid': user.uid,
    });

    if (mounted) {
      context.goNamed(Routes().home);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Set Up Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Enter Your Profile Information"),

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
            ElevatedButton(
              onPressed: saveProfileAndContinue,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
