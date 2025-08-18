import 'package:niceapp/View/Routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';

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

      final idToken = await user.getIdToken();
      //email = user.email ?? "";

      final profileRes = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
      );

      if (profileRes.statusCode == 200) {
        final data = json.decode(profileRes.body);

        _nameController.text = data['fullname'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        _emailController.text = data['email'] ?? "";
      } else {
        throw Exception("Failed to load profile: ${profileRes.body}");
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      setState(() => isLoading = true);

      final body = jsonEncode({
        "email": _emailController.text.trim(), // ✅ FIXED
        "firebaseId": user!.uid,
      });

      final response = await http.put(
        Uri.parse("$baseUrl/auth/update-profile"),
        headers: {
          "Authorization": "Bearer $idToken", // ✅ Add token if needed
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        setState(() => isEditing = false);
      } else {
        throw Exception("Update failed: ${response.body}");
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
    PassengerLocationLive().startSendingLocation();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: false, // 🔒 Disable editing
                      style: const TextStyle(color: Colors.grey), // Text color
                      decoration: InputDecoration(
                        labelText: "Phone (Username)",
                        labelStyle: const TextStyle(color: Colors.grey),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        filled: true,
                        fillColor:
                            Colors.grey.shade100, // Light grey background
                      ),
                    ),

                    // Full Name (Editable)
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      enabled: false, // 🔒 Disable editing
                      style: const TextStyle(color: Colors.grey), // Text color
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: const TextStyle(color: Colors.grey),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        filled: true,
                        fillColor:
                            Colors.grey.shade100, // Light grey background
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: isEditing,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // // Email (Editable)
                    // TextField(
                    //   controller: _emailController,
                    //   enabled: isEditing,
                    //   style: TextStyle(color: textColor),
                    //   decoration: InputDecoration(
                    //     labelText: 'Email',
                    //     labelStyle: TextStyle(color: textColor),
                    //     border: const OutlineInputBorder(),
                    //   ),
                    // ),
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
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.grey[700],
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

                    if (!isEditing) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
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

                    // ElevatedButton.icon(
                    //   onPressed: logout,
                    //   icon: const Icon(Icons.logout, color: Colors.black),
                    //   label: const Text(
                    //     "Logout",
                    //     style: TextStyle(color: Colors.black),
                    //   ),
                    //   style: ElevatedButton.styleFrom(
                    //     foregroundColor: Colors.black,
                    //     backgroundColor: Colors.blue,
                    //     padding: const EdgeInsets.symmetric(
                    //       vertical: 14,
                    //       horizontal: 30,
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
    );
  }
}
