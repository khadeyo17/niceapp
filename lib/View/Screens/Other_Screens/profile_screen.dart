// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Profile"),
//         backgroundColor: isDarkMode ? Colors.black : Colors.white,
//         elevation: 2,
//         iconTheme: IconThemeData(
//           color: isDarkMode ? Colors.white : Colors.black,
//         ),
//         titleTextStyle: TextStyle(
//           color: isDarkMode ? Colors.white : Colors.black,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: isDarkMode ? Colors.black : Colors.orange.shade50,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             /// Profile Picture & Name
//             Center(
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: AssetImage(
//                       'assets/images/profile_pic.png',
//                     ), // Replace with network image if needed
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "John Doe",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: isDarkMode ? Colors.white : Colors.black,
//                     ),
//                   ),
//                   Text(
//                     "johndoe@example.com",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// Profile Options
//             ProfileOption(
//               icon: Icons.person,
//               title: "Edit Profile",
//               onTap: () => GoRouter.of(context).go('/profile/edit'),
//               isDarkMode: isDarkMode,
//             ),
//             ProfileOption(
//               icon: Icons.payment,
//               title: "Payment Methods",
//               onTap: () => GoRouter.of(context).go('/profile/payments'),
//               isDarkMode: isDarkMode,
//             ),
//             ProfileOption(
//               icon: Icons.notifications,
//               title: "Notifications",
//               onTap: () => GoRouter.of(context).go('/profile/notifications'),
//               isDarkMode: isDarkMode,
//             ),
//             ProfileOption(
//               icon: Icons.help_outline,
//               title: "Help Center",
//               onTap: () => GoRouter.of(context).go('/profile/help'),
//               isDarkMode: isDarkMode,
//             ),

//             /// Logout Button
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 onPressed: () {
//                   // Handle logout logic
//                   GoRouter.of(context).go('/login');
//                 },
//                 child: const Text("Logout"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Reusable Profile Option Tile
// class ProfileOption extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final VoidCallback onTap;
//   final bool isDarkMode;

//   const ProfileOption({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.onTap,
//     required this.isDarkMode,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: isDarkMode ? Colors.orangeAccent : Colors.redAccent,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//           color: isDarkMode ? Colors.white : Colors.black,
//         ),
//       ),
//       trailing: const Icon(
//         Icons.arrow_forward_ios,
//         size: 16,
//         color: Colors.grey,
//       ),
//       onTap: onTap,
//     );
//   }
// }
import 'package:niceapp/View/Routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:niceapp/Container/utils/keys.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String email = "";
  bool isLoading = true;
  bool isEditing = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> fetchUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String firebaseUid = user.uid;

      final response = await http.get(
        Uri.parse('$baseUrl/driver-vehicles/driverprofile/$firebaseUid'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final firstName = data['firstName'] ?? "";
        final lastName = data['lastName'] ?? "";
        _nameController.text = "$firstName $lastName";
        _phoneController.text = data['phone'] ?? "";
        _emailController.text = data['email'] ?? "";
        email = data['email'] ?? "";
      } else {
        throw Exception("Failed to load profile");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUserProfile() async {
    try {
      setState(() => isLoading = true);

      final body = jsonEncode({
        "email": _emailController.text.trim(),
        "fullName": _nameController.text.trim(),
      });

      final response = await http.put(
        Uri.parse("$baseUrl/auth/update-profile"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        setState(() => isEditing = false);
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void logout() async {
    await _auth.signOut();
    if (mounted) {
      context.goNamed(Routes().login);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.cancel : Icons.edit),
            color: Colors.yellow,
            onPressed: () {
              setState(() => isEditing = !isEditing);
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        'https://www.example.com/user-profile-image.jpg',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number (Read-Only)
                    TextField(
                      controller: _phoneController,
                      enabled: false,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name (Editable)
                    TextField(
                      controller: _nameController,
                      enabled: isEditing,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email (Editable)
                    TextField(
                      controller: _emailController,
                      enabled: isEditing,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (isEditing)
                      ElevatedButton.icon(
                        onPressed: updateUserProfile,
                        icon: const Icon(Icons.save, color: Colors.black),
                        label: const Text(
                          "Save Profile",
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 30,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, color: Colors.black),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
