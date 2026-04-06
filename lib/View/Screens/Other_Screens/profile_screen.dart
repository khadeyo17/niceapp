import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';
import 'package:niceapp/View/Screens/Other_Screens/payment_option_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool isEditing = false;
  File? _profileImage;
  String? _profileImageUrl;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    PassengerLocationLive().startSendingLocation();
  }

  Future<void> fetchUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final idToken = await user.getIdToken();

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
        //_profileImageUrl = data['profilePhoto']; // fetch profile photo
        _profileImageUrl =
            data['profilePhoto'] != null
                ? "$baseUrldoc${data['profilePhoto']}" // prepend base URL
                : null;
      } else {
        throw Exception("Failed to load profile: ${profileRes.body}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updateUserProfile() async {
    try {
      final user = _auth.currentUser;
      final idToken = await user?.getIdToken();

      setState(() => isLoading = true);

      final body = jsonEncode({
        "email": _emailController.text.trim(),
        "firebaseId": user!.uid,
      });

      final response = await http.put(
        Uri.parse("$baseUrl/auth/update-profile"),
        headers: {
          "Authorization": "Bearer $idToken",
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
      debugPrint("Update error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
        await _uploadProfilePhoto(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.black),
                  title: const Text("Take a Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.black),
                  title: const Text("Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.redAccent),
                  title: const Text("Cancel"),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _uploadProfilePhoto(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/upload-profile-photo'),
      );

      request.headers['Authorization'] = 'Bearer $idToken';
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = jsonDecode(resStr);
        // setState(
        //   () => _profileImageUrl = data['path'],
        // ); // updated with backend path

        setState(() => _profileImageUrl = "$baseUrldoc${data['path']}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile photo updated")));
      } else {
        debugPrint("Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error uploading profile photo: $e");
    }
  }

  void logout() async {
    await _auth.signOut();
    if (mounted) context.goNamed(Routes().login);
  }

  void openWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.cancel : Icons.edit,
              color: Colors.black,
            ),
            onPressed: () => setState(() => isEditing = !isEditing),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ) // _buildSkeleton() //const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            //backgroundColor: Colors.white,
                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (_profileImageUrl != null
                                            ? NetworkImage(_profileImageUrl!)
                                            : const NetworkImage(
                                              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                            ))
                                        as ImageProvider,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _nameController.text.isEmpty
                          ? "Loading..."
                          : _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildField("Phone", _phoneController, enabled: false),
                    const SizedBox(height: 15),
                    _buildField("Email", _emailController, enabled: isEditing),
                    const SizedBox(height: 30),
                    if (isEditing)
                      _buildButton(
                        onPressed: updateUserProfile,
                        label: "Save Profile",
                        icon: Icons.save,
                        color: Colors.blue,
                      ),
                    if (!isEditing) ...[
                      _buildButton(
                        onPressed: openWallet,
                        label: "Wallet",
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 15),
                      _buildButton(
                        onPressed: logout,
                        label: "Logout",
                        icon: Icons.logout,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(height: 50, color: Colors.white),
          const SizedBox(height: 20),
          Container(height: 60, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Routes/routes.dart';
// import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';
// import 'package:niceapp/View/Screens/Other_Screens/payment_option_screen.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final ImagePicker _picker = ImagePicker();

//   bool isLoading = true;
//   bool isEditing = false;
//   File? _profileImage;
//   String? _profileImageUrl;

//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     fetchUserProfile();
//     PassengerLocationLive().startSendingLocation();
//   }

//   Future<void> fetchUserProfile() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       final idToken = await user.getIdToken();

//       final profileRes = await http.get(
//         Uri.parse('$baseUrl/auth/profile'),
//         headers: {
//           "Authorization": "Bearer $idToken",
//           "Content-Type": "application/json",
//         },
//       );

//       if (profileRes.statusCode == 200) {
//         final data = json.decode(profileRes.body);
//         _nameController.text = data['fullname'] ?? "";
//         _phoneController.text = data['phone'] ?? "";
//         _emailController.text = data['email'] ?? "";
//         _profileImageUrl = data['profilePhoto'];
//       } else {
//         throw Exception("Failed to load profile: ${profileRes.body}");
//       }
//     } catch (e) {
//       debugPrint("Error fetching profile: $e");
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   Future<void> updateUserProfile() async {
//     try {
//       final user = _auth.currentUser;
//       final idToken = await user?.getIdToken();

//       setState(() => isLoading = true);

//       final body = jsonEncode({
//         "email": _emailController.text.trim(),
//         "firebaseId": user!.uid,
//       });

//       final response = await http.put(
//         Uri.parse("$baseUrl/auth/update-profile"),
//         headers: {
//           "Authorization": "Bearer $idToken",
//           "Content-Type": "application/json",
//         },
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profile updated successfully")),
//         );
//         setState(() => isEditing = false);
//       } else {
//         throw Exception("Update failed: ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("Update error: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final pickedFile = await _picker.pickImage(
//         source: source,
//         imageQuality: 85,
//       );
//       if (pickedFile != null) {
//         setState(() => _profileImage = File(pickedFile.path));
//         await _uploadProfilePhoto(File(pickedFile.path));
//       }
//     } catch (e) {
//       debugPrint("Image pick error: $e");
//     }
//   }

//   void _showImageSourceActionSheet() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => SafeArea(
//             child: Wrap(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.camera_alt, color: Colors.black),
//                   title: const Text("Take a Photo"),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickImage(ImageSource.camera);
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.photo_library, color: Colors.black),
//                   title: const Text("Choose from Gallery"),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _pickImage(ImageSource.gallery);
//                   },
//                 ),
//                 const Divider(height: 1),
//                 ListTile(
//                   leading: const Icon(Icons.close, color: Colors.redAccent),
//                   title: const Text("Cancel"),
//                   onTap: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Future<void> _uploadProfilePhoto(File imageFile) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       final idToken = await user.getIdToken();

//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/auth/upload-profile-photo'),
//       );

//       request.headers['Authorization'] = 'Bearer $idToken';
//       request.files.add(
//         await http.MultipartFile.fromPath('photo', imageFile.path),
//       );

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         final resStr = await response.stream.bytesToString();
//         final data = jsonDecode(resStr);
//         setState(() => _profileImageUrl = data['photoUrl']);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Profile photo updated")));
//       } else {
//         debugPrint("Upload failed: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Error uploading profile photo: $e");
//     }
//   }

//   void logout() async {
//     await _auth.signOut();
//     if (mounted) context.goNamed(Routes().login);
//   }

//   void openWallet() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const PaymentServicesScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         title: const Text(
//           "My Profile",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(
//               isEditing ? Icons.cancel : Icons.edit,
//               color: Colors.black,
//             ),
//             onPressed: () => setState(() => isEditing = !isEditing),
//           ),
//         ],
//       ),
//       body:
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 20),
//                     GestureDetector(
//                       onTap: _showImageSourceActionSheet,
//                       child: Stack(
//                         alignment: Alignment.bottomRight,
//                         children: [
//                           CircleAvatar(
//                             radius: 55,
//                             backgroundColor: Colors.white,
//                             backgroundImage:
//                                 _profileImage != null
//                                     ? FileImage(_profileImage!)
//                                     : (_profileImageUrl != null
//                                             ? NetworkImage(_profileImageUrl!)
//                                             : const NetworkImage(
//                                               'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
//                                             ))
//                                         as ImageProvider,
//                           ),
//                           Container(
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                             padding: const EdgeInsets.all(6),
//                             child: const Icon(
//                               Icons.camera_alt,
//                               color: Colors.black,
//                               size: 22,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     Text(
//                       _nameController.text.isEmpty
//                           ? "Loading..."
//                           : _nameController.text,
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const SizedBox(height: 25),
//                     _buildField("Phone", _phoneController, enabled: false),
//                     const SizedBox(height: 15),
//                     // _buildField("Name", _nameController, enabled: false),
//                     // const SizedBox(height: 15),
//                     _buildField("Email", _emailController, enabled: isEditing),
//                     const SizedBox(height: 30),
//                     if (isEditing)
//                       _buildButton(
//                         onPressed: updateUserProfile,
//                         label: "Save Profile",
//                         icon: Icons.save,
//                         color: Colors.black,
//                       ),
//                     if (!isEditing) ...[
//                       _buildButton(
//                         onPressed: openWallet,
//                         label: "Wallet",
//                         icon: Icons.account_balance_wallet_outlined,
//                         color: Colors.black,
//                       ),
//                       const SizedBox(height: 15),
//                       _buildButton(
//                         onPressed: logout,
//                         label: "Logout",
//                         icon: Icons.logout,
//                         color: Colors.redAccent,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//     );
//   }

//   Widget _buildField(
//     String label,
//     TextEditingController controller, {
//     required bool enabled,
//   }) {
//     return TextFormField(
//       controller: controller,
//       enabled: enabled,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Colors.black, width: 1.5),
//         ),
//       ),
//       style: const TextStyle(fontSize: 16, color: Colors.black87),
//     );
//   }

//   Widget _buildButton({
//     required VoidCallback onPressed,
//     required String label,
//     required IconData icon,
//     required Color color,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         icon: Icon(icon, color: Colors.white, size: 22),
//         label: Text(
//           label,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//       ),
//     );
//   }
// }
// // // import 'dart:convert';
// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:go_router/go_router.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:niceapp/Container/utils/keys.dart';
// // // import 'package:niceapp/View/Routes/routes.dart';
// // // import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';
// // // import 'package:niceapp/View/Screens/Other_Screens/payment_option_screen.dart';

// // // class ProfileScreen extends StatefulWidget {
// // //   const ProfileScreen({super.key});

// // //   @override
// // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // }

// // // class _ProfileScreenState extends State<ProfileScreen> {
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //   bool isLoading = true;
// // //   bool isEditing = false;
// // //   File? _profileImage;

// // //   final _nameController = TextEditingController();
// // //   final _phoneController = TextEditingController();
// // //   final _emailController = TextEditingController();

// // //   final ImagePicker _picker = ImagePicker();

// // //   Future<void> fetchUserProfile() async {
// // //     try {
// // //       final user = _auth.currentUser;
// // //       if (user == null) throw Exception("User not logged in");

// // //       final idToken = await user.getIdToken();

// // //       final profileRes = await http.get(
// // //         Uri.parse('$baseUrl/auth/profile'),
// // //         headers: {
// // //           "Authorization": "Bearer $idToken",
// // //           "Content-Type": "application/json",
// // //         },
// // //       );

// // //       if (profileRes.statusCode == 200) {
// // //         final data = json.decode(profileRes.body);
// // //         _nameController.text = data['fullname'] ?? "";
// // //         _phoneController.text = data['phone'] ?? "";
// // //         _emailController.text = data['email'] ?? "";
// // //       } else {
// // //         throw Exception("Failed to load profile: ${profileRes.body}");
// // //       }
// // //     } catch (e) {
// // //       debugPrint("Error fetching profile: $e");
// // //     } finally {
// // //       if (mounted) setState(() => isLoading = false);
// // //     }
// // //   }

// // //   Future<void> updateUserProfile() async {
// // //     try {
// // //       final user = _auth.currentUser;
// // //       final idToken = await user?.getIdToken();

// // //       setState(() => isLoading = true);

// // //       final body = jsonEncode({
// // //         "email": _emailController.text.trim(),
// // //         "firebaseId": user!.uid,
// // //       });

// // //       final response = await http.put(
// // //         Uri.parse("$baseUrl/auth/update-profile"),
// // //         headers: {
// // //           "Authorization": "Bearer $idToken",
// // //           "Content-Type": "application/json",
// // //         },
// // //         body: body,
// // //       );

// // //       if (response.statusCode == 200) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text("Profile updated successfully")),
// // //         );
// // //         setState(() => isEditing = false);
// // //       } else {
// // //         throw Exception("Update failed: ${response.body}");
// // //       }
// // //     } catch (e) {
// // //       debugPrint("Update error: $e");
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
// // //     } finally {
// // //       setState(() => isLoading = false);
// // //     }
// // //   }

// // //   Future<void> _pickImage(ImageSource source) async {
// // //     final pickedFile = await _picker.pickImage(
// // //       source: source,
// // //       imageQuality: 85,
// // //     );

// // //     if (pickedFile != null) {
// // //       setState(() => _profileImage = File(pickedFile.path));
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(const SnackBar(content: Text("Profile photo updated")));
// // //     }
// // //   }

// // //   void _showImageSourceActionSheet() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // //       ),
// // //       builder:
// // //           (context) => SafeArea(
// // //             child: Wrap(
// // //               children: [
// // //                 ListTile(
// // //                   leading: const Icon(Icons.camera_alt, color: Colors.black),
// // //                   title: const Text("Take a Photo"),
// // //                   onTap: () {
// // //                     Navigator.pop(context);
// // //                     _pickImage(ImageSource.camera);
// // //                   },
// // //                 ),
// // //                 ListTile(
// // //                   leading: const Icon(Icons.photo_library, color: Colors.black),
// // //                   title: const Text("Choose from Gallery"),
// // //                   onTap: () {
// // //                     Navigator.pop(context);
// // //                     _pickImage(ImageSource.gallery);
// // //                   },
// // //                 ),
// // //                 const Divider(height: 1),
// // //                 ListTile(
// // //                   leading: const Icon(Icons.close, color: Colors.redAccent),
// // //                   title: const Text("Cancel"),
// // //                   onTap: () => Navigator.pop(context),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //     );
// // //   }

// // //   void logout() async {
// // //     await _auth.signOut();
// // //     if (mounted) context.goNamed(Routes().login);
// // //   }

// // //   void openWallet() {
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(builder: (_) => const PaymentServicesScreen()),
// // //     );
// // //   }

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchUserProfile();
// // //     PassengerLocationLive().startSendingLocation();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.grey[50],
// // //       body:
// // //           isLoading
// // //               ? const Center(child: CircularProgressIndicator())
// // //               : CustomScrollView(
// // //                 slivers: [
// // //                   SliverAppBar(
// // //                     backgroundColor: Colors.black,
// // //                     expandedHeight: 240,
// // //                     pinned: true,
// // //                     flexibleSpace: FlexibleSpaceBar(
// // //                       centerTitle: true,
// // //                       title: Text(
// // //                         _nameController.text.isEmpty
// // //                             ? "My Profile"
// // //                             : _nameController.text,
// // //                         style: const TextStyle(
// // //                           fontWeight: FontWeight.bold,
// // //                           fontSize: 20,
// // //                           color: Colors.white,
// // //                         ),
// // //                       ),
// // //                       background: Stack(
// // //                         alignment: Alignment.center,
// // //                         children: [
// // //                           Container(color: Colors.black),
// // //                           GestureDetector(
// // //                             onTap: _showImageSourceActionSheet,
// // //                             child: Stack(
// // //                               alignment: Alignment.bottomRight,
// // //                               children: [
// // //                                 CircleAvatar(
// // //                                   radius: 60,
// // //                                   backgroundColor: Colors.white,
// // //                                   backgroundImage:
// // //                                       _profileImage != null
// // //                                           ? FileImage(_profileImage!)
// // //                                           : const NetworkImage(
// // //                                                 "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
// // //                                               )
// // //                                               as ImageProvider,
// // //                                 ),
// // //                                 Positioned(
// // //                                   bottom: 0,
// // //                                   right: 6,
// // //                                   child: Container(
// // //                                     decoration: const BoxDecoration(
// // //                                       color: Colors.white,
// // //                                       shape: BoxShape.circle,
// // //                                     ),
// // //                                     padding: const EdgeInsets.all(6),
// // //                                     child: const Icon(
// // //                                       Icons.camera_alt,
// // //                                       color: Colors.black,
// // //                                       size: 20,
// // //                                     ),
// // //                                   ),
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     actions: [
// // //                       IconButton(
// // //                         icon: Icon(
// // //                           isEditing ? Icons.cancel : Icons.edit,
// // //                           color: Colors.white,
// // //                         ),
// // //                         onPressed: () => setState(() => isEditing = !isEditing),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   SliverToBoxAdapter(
// // //                     child: Padding(
// // //                       padding: const EdgeInsets.symmetric(
// // //                         horizontal: 20,
// // //                         vertical: 25,
// // //                       ),
// // //                       child: Column(
// // //                         children: [
// // //                           _buildField(
// // //                             "Phone",
// // //                             _phoneController,
// // //                             enabled: false,
// // //                           ),
// // //                           const SizedBox(height: 15),
// // //                           //_buildField("Name", _nameController, enabled: false),
// // //                           //const SizedBox(height: 15),
// // //                           _buildField(
// // //                             "Email",
// // //                             _emailController,
// // //                             enabled: isEditing,
// // //                           ),
// // //                           const SizedBox(height: 30),

// // //                           if (isEditing)
// // //                             _buildButton(
// // //                               onPressed: updateUserProfile,
// // //                               label: "Save Profile",
// // //                               icon: Icons.save,
// // //                               color: Colors.black,
// // //                             ),

// // //                           if (!isEditing) ...[
// // //                             _buildButton(
// // //                               onPressed: openWallet,
// // //                               label: "Wallet",
// // //                               icon: Icons.account_balance_wallet_outlined,
// // //                               color: Colors.black,
// // //                             ),
// // //                             const SizedBox(height: 15),
// // //                             _buildButton(
// // //                               onPressed: logout,
// // //                               label: "Logout",
// // //                               icon: Icons.logout,
// // //                               color: Colors.redAccent,
// // //                             ),
// // //                           ],
// // //                         ],
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //     );
// // //   }

// // //   Widget _buildField(
// // //     String label,
// // //     TextEditingController controller, {
// // //     required bool enabled,
// // //   }) {
// // //     return TextFormField(
// // //       controller: controller,
// // //       enabled: enabled,
// // //       decoration: InputDecoration(
// // //         labelText: label,
// // //         labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
// // //         filled: true,
// // //         fillColor: Colors.white,
// // //         border: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(14),
// // //           borderSide: BorderSide(color: Colors.grey.shade300),
// // //         ),
// // //         enabledBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(14),
// // //           borderSide: BorderSide(color: Colors.grey.shade300),
// // //         ),
// // //         focusedBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(14),
// // //           borderSide: const BorderSide(color: Colors.black, width: 1.5),
// // //         ),
// // //       ),
// // //       style: const TextStyle(fontSize: 16, color: Colors.black87),
// // //     );
// // //   }

// // //   Widget _buildButton({
// // //     required VoidCallback onPressed,
// // //     required String label,
// // //     required IconData icon,
// // //     required Color color,
// // //   }) {
// // //     return SizedBox(
// // //       width: double.infinity,
// // //       child: ElevatedButton.icon(
// // //         onPressed: onPressed,
// // //         icon: Icon(icon, color: Colors.white, size: 22),
// // //         label: Text(
// // //           label,
// // //           style: const TextStyle(
// // //             fontSize: 18,
// // //             fontWeight: FontWeight.w600,
// // //             color: Colors.white,
// // //           ),
// // //         ),
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: color,
// // //           padding: const EdgeInsets.symmetric(vertical: 16),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(14),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:niceapp/Container/utils/keys.dart';
// // import 'package:niceapp/View/Routes/routes.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';
// // import 'package:niceapp/View/Screens/Other_Screens/payment_option_screen.dart';

// // class ProfileScreen extends StatefulWidget {
// //   const ProfileScreen({super.key});

// //   @override
// //   State<ProfileScreen> createState() => _ProfileScreenState();
// // }

// // class _ProfileScreenState extends State<ProfileScreen> {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   bool isLoading = true;
// //   bool isEditing = false;

// //   final _nameController = TextEditingController();
// //   final _phoneController = TextEditingController();
// //   final _emailController = TextEditingController();

// //   Future<void> fetchUserProfile() async {
// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) throw Exception("User not logged in");

// //       final idToken = await user.getIdToken();

// //       final profileRes = await http.get(
// //         Uri.parse('$baseUrl/auth/profile'),
// //         headers: {
// //           "Authorization": "Bearer $idToken",
// //           "Content-Type": "application/json",
// //         },
// //       );

// //       if (profileRes.statusCode == 200) {
// //         final data = json.decode(profileRes.body);
// //         _nameController.text = data['fullname'] ?? "";
// //         _phoneController.text = data['phone'] ?? "";
// //         _emailController.text = data['email'] ?? "";
// //       } else {
// //         throw Exception("Failed to load profile: ${profileRes.body}");
// //       }
// //     } catch (e) {
// //       debugPrint("Error fetching profile: $e");
// //     } finally {
// //       if (mounted) setState(() => isLoading = false);
// //     }
// //   }

// //   Future<void> updateUserProfile() async {
// //     try {
// //       final user = _auth.currentUser;
// //       final idToken = await user?.getIdToken();

// //       setState(() => isLoading = true);

// //       final body = jsonEncode({
// //         "email": _emailController.text.trim(),
// //         "firebaseId": user!.uid,
// //       });

// //       final response = await http.put(
// //         Uri.parse("$baseUrl/auth/update-profile"),
// //         headers: {
// //           "Authorization": "Bearer $idToken",
// //           "Content-Type": "application/json",
// //         },
// //         body: body,
// //       );

// //       if (response.statusCode == 200) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Profile updated successfully")),
// //         );
// //         setState(() => isEditing = false);
// //       } else {
// //         throw Exception("Update failed: ${response.body}");
// //       }
// //     } catch (e) {
// //       debugPrint("Update error: $e");
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
// //     } finally {
// //       setState(() => isLoading = false);
// //     }
// //   }

// //   void logout() async {
// //     await _auth.signOut();
// //     if (mounted) context.goNamed(Routes().login);
// //   }

// //   void openWallet() {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(builder: (_) => const PaymentServicesScreen()),
// //     );
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchUserProfile();
// //     PassengerLocationLive().startSendingLocation();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       appBar: AppBar(
// //         elevation: 0,
// //         backgroundColor: Colors.white,
// //         foregroundColor: Colors.black,
// //         title: const Text(
// //           "My Profile",
// //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
// //         ),
// //         centerTitle: true,
// //         actions: [
// //           IconButton(
// //             icon: Icon(
// //               isEditing ? Icons.cancel : Icons.edit,
// //               color: Colors.black,
// //             ),
// //             onPressed: () => setState(() => isEditing = !isEditing),
// //           ),
// //         ],
// //       ),
// //       body:
// //           isLoading
// //               ? const Center(child: CircularProgressIndicator())
// //               : SingleChildScrollView(
// //                 padding: const EdgeInsets.all(20),
// //                 child: Column(
// //                   children: [
// //                     const SizedBox(height: 20),
// //                     const CircleAvatar(
// //                       radius: 55,
// //                       backgroundImage: NetworkImage(
// //                         'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
// //                       ),
// //                       backgroundColor: Colors.white,
// //                     ),
// //                     const SizedBox(height: 15),
// //                     Text(
// //                       _nameController.text.isEmpty
// //                           ? "Loading..."
// //                           : _nameController.text,
// //                       style: const TextStyle(
// //                         fontSize: 24,
// //                         fontWeight: FontWeight.w700,
// //                         color: Colors.black,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 25),

// //                     _buildField("Phone", _phoneController, enabled: false),
// //                     const SizedBox(height: 15),
// //                     _buildField("Name", _nameController, enabled: false),
// //                     const SizedBox(height: 15),
// //                     _buildField("Email", _emailController, enabled: isEditing),

// //                     const SizedBox(height: 30),

// //                     if (isEditing)
// //                       _buildButton(
// //                         onPressed: updateUserProfile,
// //                         label: "Save Profile",
// //                         icon: Icons.save,
// //                         color: Colors.black,
// //                       ),

// //                     if (!isEditing) ...[
// //                       _buildButton(
// //                         onPressed: openWallet,
// //                         label: "Wallet",
// //                         icon: Icons.account_balance_wallet_outlined,
// //                         color: Colors.black,
// //                       ),
// //                       const SizedBox(height: 15),
// //                       _buildButton(
// //                         onPressed: logout,
// //                         label: "Logout",
// //                         icon: Icons.logout,
// //                         color: Colors.redAccent,
// //                       ),
// //                     ],
// //                   ],
// //                 ),
// //               ),
// //     );
// //   }

// //   Widget _buildField(
// //     String label,
// //     TextEditingController controller, {
// //     required bool enabled,
// //   }) {
// //     return TextFormField(
// //       controller: controller,
// //       enabled: enabled,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
// //         filled: true,
// //         fillColor: Colors.white,
// //         border: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(14),
// //           borderSide: BorderSide(color: Colors.grey.shade300),
// //         ),
// //         enabledBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(14),
// //           borderSide: BorderSide(color: Colors.grey.shade300),
// //         ),
// //         focusedBorder: OutlineInputBorder(
// //           borderRadius: BorderRadius.circular(14),
// //           borderSide: const BorderSide(color: Colors.black, width: 1.5),
// //         ),
// //       ),
// //       style: const TextStyle(fontSize: 16, color: Colors.black87),
// //     );
// //   }

// //   Widget _buildButton({
// //     required VoidCallback onPressed,
// //     required String label,
// //     required IconData icon,
// //     required Color color,
// //   }) {
// //     return SizedBox(
// //       width: double.infinity,
// //       child: ElevatedButton.icon(
// //         onPressed: onPressed,
// //         icon: Icon(icon, color: Colors.white, size: 22),
// //         label: Text(
// //           label,
// //           style: const TextStyle(
// //             fontSize: 18,
// //             fontWeight: FontWeight.w600,
// //             color: Colors.white,
// //           ),
// //         ),
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: color,
// //           padding: const EdgeInsets.symmetric(vertical: 16),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(14),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // // import 'package:niceapp/View/Routes/routes.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:go_router/go_router.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'dart:convert';
// // // // import 'package:niceapp/Container/utils/keys.dart';
// // // // import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';
// // // // import 'package:niceapp/View/Screens/Other_Screens/payment_option_screen.dart';

// // // // class ProfileScreen extends StatefulWidget {
// // // //   const ProfileScreen({super.key});

// // // //   @override
// // // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // // }

// // // // class _ProfileScreenState extends State<ProfileScreen> {
// // // //   String email = "";
// // // //   bool isLoading = true;
// // // //   bool isEditing = false;

// // // //   final FirebaseAuth _auth = FirebaseAuth.instance;

// // // //   final TextEditingController _nameController = TextEditingController();
// // // //   final TextEditingController _phoneController = TextEditingController();
// // // //   final TextEditingController _emailController = TextEditingController();

// // // //   Future<void> fetchUserProfile() async {
// // // //     try {
// // // //       final user = _auth.currentUser;
// // // //       if (user == null) throw Exception("User not logged in");

// // // //       final idToken = await user.getIdToken();
// // // //       //email = user.email ?? "";

// // // //       final profileRes = await http.get(
// // // //         Uri.parse('$baseUrl/auth/profile'),
// // // //         headers: {
// // // //           "Authorization": "Bearer $idToken",
// // // //           "Content-Type": "application/json",
// // // //         },
// // // //       );

// // // //       if (profileRes.statusCode == 200) {
// // // //         final data = json.decode(profileRes.body);

// // // //         _nameController.text = data['fullname'] ?? "";
// // // //         _phoneController.text = data['phone'] ?? "";
// // // //         _emailController.text = data['email'] ?? "";
// // // //       } else {
// // // //         throw Exception("Failed to load profile: ${profileRes.body}");
// // // //       }
// // // //     } catch (e) {
// // // //       print("Error fetching profile: $e");
// // // //     } finally {
// // // //       if (mounted) {
// // // //         setState(() => isLoading = false);
// // // //       }
// // // //     }
// // // //   }

// // // //   Future<void> updateUserProfile() async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       final idToken = await user?.getIdToken();

// // // //       setState(() => isLoading = true);

// // // //       final body = jsonEncode({
// // // //         "email": _emailController.text.trim(), // ✅ FIXED
// // // //         "firebaseId": user!.uid,
// // // //       });

// // // //       final response = await http.put(
// // // //         Uri.parse("$baseUrl/auth/update-profile"),
// // // //         headers: {
// // // //           "Authorization": "Bearer $idToken", // ✅ Add token if needed
// // // //           "Content-Type": "application/json",
// // // //         },
// // // //         body: body,
// // // //       );

// // // //       if (response.statusCode == 200) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Profile updated successfully")),
// // // //         );
// // // //         setState(() => isEditing = false);
// // // //       } else {
// // // //         throw Exception("Update failed: ${response.body}");
// // // //       }
// // // //     } catch (e) {
// // // //       print("Update error: $e");
// // // //       ScaffoldMessenger.of(
// // // //         context,
// // // //       ).showSnackBar(const SnackBar(content: Text("Error updating profile")));
// // // //     } finally {
// // // //       setState(() => isLoading = false);
// // // //     }
// // // //   }

// // // //   void logout() async {
// // // //     await _auth.signOut();
// // // //     if (mounted) {
// // // //       context.goNamed(Routes().login);
// // // //     }
// // // //   }

// // // //   void paymentservices() async {
// // // //     Navigator.push(
// // // //       context,
// // // //       MaterialPageRoute(builder: (_) => PaymentServicesScreen()),
// // // //     );
// // // //   }

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchUserProfile();
// // // //     PassengerLocationLive().startSendingLocation();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final bool isDark = Theme.of(context).brightness == Brightness.dark;
// // // //     final Color textColor = isDark ? Colors.white : Colors.black;

// // // //     return Scaffold(
// // // //       backgroundColor: Colors.white,
// // // //       appBar: AppBar(
// // // //         title: const Text("My Profile"),
// // // //         centerTitle: true,
// // // //         backgroundColor: Colors.white,
// // // //         elevation: 0,
// // // //         foregroundColor: Colors.black,
// // // //         actions: [
// // // //           IconButton(
// // // //             icon: Icon(isEditing ? Icons.cancel : Icons.edit),
// // // //             color: Colors.yellow,
// // // //             onPressed: () {
// // // //               setState(() => isEditing = !isEditing);
// // // //             },
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       body:
// // // //           isLoading
// // // //               ? const Center(child: CircularProgressIndicator())
// // // //               : Padding(
// // // //                 padding: const EdgeInsets.all(20.0),
// // // //                 child: ListView(
// // // //                   children: [
// // // //                     const SizedBox(height: 20),
// // // //                     const CircleAvatar(
// // // //                       radius: 50,
// // // //                       backgroundImage: NetworkImage(
// // // //                         'https://www.example.com/user-profile-image.jpg',
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 20),

// // // //                     const SizedBox(height: 16),
// // // //                     TextFormField(
// // // //                       controller: _phoneController,
// // // //                       enabled: false, // 🔒 Disable editing
// // // //                       style: const TextStyle(color: Colors.grey), // Text color
// // // //                       decoration: InputDecoration(
// // // //                         labelText: "Phone (Username)",
// // // //                         labelStyle: const TextStyle(color: Colors.grey),
// // // //                         disabledBorder: OutlineInputBorder(
// // // //                           borderSide: BorderSide(color: Colors.grey.shade400),
// // // //                         ),
// // // //                         filled: true,
// // // //                         fillColor:
// // // //                             Colors.grey.shade100, // Light grey background
// // // //                       ),
// // // //                     ),

// // // //                     // Full Name (Editable)
// // // //                     const SizedBox(height: 16),
// // // //                     TextFormField(
// // // //                       controller: _nameController,
// // // //                       enabled: false, // 🔒 Disable editing
// // // //                       style: const TextStyle(color: Colors.grey), // Text color
// // // //                       decoration: InputDecoration(
// // // //                         labelText: "Name",
// // // //                         labelStyle: const TextStyle(color: Colors.grey),
// // // //                         disabledBorder: OutlineInputBorder(
// // // //                           borderSide: BorderSide(color: Colors.grey.shade400),
// // // //                         ),
// // // //                         filled: true,
// // // //                         fillColor:
// // // //                             Colors.grey.shade100, // Light grey background
// // // //                       ),
// // // //                     ),

// // // //                     const SizedBox(height: 16),
// // // //                     TextFormField(
// // // //                       controller: _emailController,
// // // //                       enabled: isEditing,
// // // //                       keyboardType: TextInputType.emailAddress,
// // // //                       decoration: const InputDecoration(
// // // //                         labelText: "Email",
// // // //                         border: OutlineInputBorder(),
// // // //                       ),
// // // //                     ),

// // // //                     // // Email (Editable)
// // // //                     // TextField(
// // // //                     //   controller: _emailController,
// // // //                     //   enabled: isEditing,
// // // //                     //   style: TextStyle(color: textColor),
// // // //                     //   decoration: InputDecoration(
// // // //                     //     labelText: 'Email',
// // // //                     //     labelStyle: TextStyle(color: textColor),
// // // //                     //     border: const OutlineInputBorder(),
// // // //                     //   ),
// // // //                     // ),
// // // //                     const SizedBox(height: 30),
// // // //                     if (isEditing)
// // // //                       ElevatedButton.icon(
// // // //                         onPressed: updateUserProfile,
// // // //                         icon: const Icon(Icons.save, color: Colors.black),
// // // //                         label: const Text(
// // // //                           "Save Profile",
// // // //                           style: TextStyle(color: Colors.white),
// // // //                         ),
// // // //                         style: ElevatedButton.styleFrom(
// // // //                           foregroundColor: Colors.white,
// // // //                           backgroundColor: Colors.grey[700],
// // // //                           padding: const EdgeInsets.symmetric(
// // // //                             vertical: 14,
// // // //                             horizontal: 30,
// // // //                           ),
// // // //                           shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                         ),
// // // //                       ),

// // // //                     const SizedBox(height: 20),

// // // //                     if (!isEditing) ...[
// // // //                       const SizedBox(height: 20),
// // // //                       ElevatedButton.icon(
// // // //                         onPressed: paymentservices,
// // // //                         icon: const Icon(Icons.wallet, color: Colors.white),
// // // //                         label: const Text(
// // // //                           "Payment Services",
// // // //                           style: TextStyle(color: Colors.white),
// // // //                         ),
// // // //                         style: ElevatedButton.styleFrom(
// // // //                           backgroundColor: Colors.grey[700],
// // // //                           padding: const EdgeInsets.symmetric(
// // // //                             vertical: 14,
// // // //                             horizontal: 30,
// // // //                           ),
// // // //                           shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ],

// // // //                     const SizedBox(height: 20),

// // // //                     if (!isEditing) ...[
// // // //                       const SizedBox(height: 20),
// // // //                       ElevatedButton.icon(
// // // //                         onPressed: logout,
// // // //                         icon: const Icon(Icons.logout, color: Colors.white),
// // // //                         label: const Text(
// // // //                           "Logout",
// // // //                           style: TextStyle(color: Colors.white),
// // // //                         ),
// // // //                         style: ElevatedButton.styleFrom(
// // // //                           backgroundColor: Colors.grey[700],
// // // //                           padding: const EdgeInsets.symmetric(
// // // //                             vertical: 14,
// // // //                             horizontal: 30,
// // // //                           ),
// // // //                           shape: RoundedRectangleBorder(
// // // //                             borderRadius: BorderRadius.circular(12),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ],

// // // //                     // ElevatedButton.icon(
// // // //                     //   onPressed: logout,
// // // //                     //   icon: const Icon(Icons.logout, color: Colors.black),
// // // //                     //   label: const Text(
// // // //                     //     "Logout",
// // // //                     //     style: TextStyle(color: Colors.black),
// // // //                     //   ),
// // // //                     //   style: ElevatedButton.styleFrom(
// // // //                     //     foregroundColor: Colors.black,
// // // //                     //     backgroundColor: Colors.blue,
// // // //                     //     padding: const EdgeInsets.symmetric(
// // // //                     //       vertical: 14,
// // // //                     //       horizontal: 30,
// // // //                     //     ),
// // // //                     //     shape: RoundedRectangleBorder(
// // // //                     //       borderRadius: BorderRadius.circular(12),
// // // //                     //     ),
// // // //                     //   ),
// // // //                     // ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //     );
// // // //   }
// // // // }
