// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'mobile_entry_screen.dart'; // import your new screen

// class LetsGetStartedScreen extends StatelessWidget {
//   const LetsGetStartedScreen({Key? key}) : super(key: key);

//   Future<void> signInWithGoogle(BuildContext context) async {
//     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//     final googleAuth = await googleUser?.authentication;

//     if (googleAuth == null) return;

//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     await FirebaseAuth.instance.signInWithCredential(credential);

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Signed in with Google")));

//     // TODO: Navigate to Landing Page
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Let's Get Started")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const Text("Sign in with", style: TextStyle(fontSize: 20)),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const MobileEntryScreen(),
//                       ),
//                     );
//                   },
//                   child: const Text("Phone / Email"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async => await signInWithGoogle(context),
//                   child: const Text("Google"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// lets_get_started_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'mobile_entry_screen.dart';

class LetsGetStartedScreen extends StatelessWidget {
  const LetsGetStartedScreen({Key? key}) : super(key: key);

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      if (googleAuth == null) return;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signed in with Google")));

      // TODO: Navigate to Landing Page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's Get Started")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Sign in with", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MobileEntryScreen(),
                      ),
                    );
                  },
                  child: const Text("Phone"),
                ),
                ElevatedButton(
                  onPressed: () async => await signInWithGoogle(context),
                  child: const Text("Google"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
