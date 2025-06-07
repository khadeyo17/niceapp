// // // signup_screen.dart
// // import 'package:flutter/material.dart';
// // import 'login_screen.dart';

// // class SignupScreen extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Padding(
// //         padding: EdgeInsets.all(20),
// //         child: Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Text('Create an Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// //               SizedBox(height: 20),
// //               TextField(
// //                 decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
// //               ),
// //               SizedBox(height: 10),
// //               TextField(
// //                 decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
// //               ),
// //               SizedBox(height: 10),
// //               TextField(
// //                 decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
// //                 obscureText: true,
// //               ),
// //               SizedBox(height: 20),
// //               ElevatedButton(
// //                 onPressed: () {
// //                   Navigator.pop(context); // Go back to login
// //                 },
// //                 child: Text('Sign Up'),
// //               ),
// //               TextButton(
// //                 onPressed: () {
// //                   Navigator.pop(context);
// //                 },
// //                 child: Text("Already have an account? Login"),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// //import 'login_screen.dart';

// class SignupScreen extends StatefulWidget {
//   final VoidCallback toggleTheme;

//   SignupScreen({required this.toggleTheme});
//   @override
//   _SignupScreenState createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   bool _isLoading = false;
//   String? _errorMessage;

//   void _signup() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });

//       try {
//         UserCredential userCredential = await _auth
//             .createUserWithEmailAndPassword(
//               email: _emailController.text.trim(),
//               password: _passwordController.text.trim(),
//             );

//         // Update the user's display name
//         await userCredential.user?.updateDisplayName(
//           _nameController.text.trim(),
//         );

//         // Navigate to HomeScreen upon successful signup
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => HomeScreen(toggleTheme: widget.toggleTheme),
//           ),
//         );
//       } on FirebaseAuthException catch (e) {
//         setState(() {
//           _errorMessage = e.message;
//         });
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Create an Account',
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 20),
//                   TextFormField(
//                     controller: _nameController,
//                     decoration: InputDecoration(
//                       labelText: 'Full Name',
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your full name';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 10),
//                   TextFormField(
//                     controller: _emailController,
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your email';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 10),
//                   TextFormField(
//                     controller: _passwordController,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       border: OutlineInputBorder(),
//                     ),
//                     obscureText: true,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 20),
//                   if (_errorMessage != null)
//                     Text(_errorMessage!, style: TextStyle(color: Colors.red)),
//                   SizedBox(height: 10),
//                   _isLoading
//                       ? CircularProgressIndicator()
//                       : ElevatedButton(
//                         onPressed: _signup,
//                         child: Text('Sign Up'),
//                       ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: Text("Already have an account? Login"),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
