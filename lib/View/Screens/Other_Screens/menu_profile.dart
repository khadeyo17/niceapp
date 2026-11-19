import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Update these imports to match your project
import 'package:niceapp/Container/utils/keys.dart';

class MenuProfileScreen extends StatefulWidget {
  const MenuProfileScreen({super.key});

  @override
  State<MenuProfileScreen> createState() => _MenuProfileScreenState();
}

class _MenuProfileScreenState extends State<MenuProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool isLoading = true;
  bool isEditing = false;

  File? _profileImage;
  String? _profileImageUrl;

  static const Color primaryBlue = Color(0xFF015ACE);

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // FETCH PROFILE
  // ============================================================

  Future<void> fetchUserProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final idToken = await user.getIdToken();

      final profileRes = await http.get(
        Uri.parse('$baseUrl/passengerauth/profile'),
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

        _profileImageUrl =
            data['profilePhoto'] != null
                ? "$baseUrldoc${data['profilePhoto']}"
                : null;
      } else {
        throw Exception(
          "Failed to load profile: ${profileRes.body}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to load profile"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateUserProfile() async {
    if (!mounted) return;

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final idToken = await user.getIdToken();

      setState(() {
        isLoading = true;
      });

      final body = jsonEncode({
        "email": _emailController.text.trim(),
        "firebaseId": user.uid,
      });

      final response = await http.put(
        Uri.parse("$baseUrl/passengerauth/update-profile"),
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          "Update failed: ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error updating profile"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final image = File(pickedFile.path);

        if (mounted) {
          setState(() {
            _profileImage = image;
          });
        }

        await _uploadProfilePhoto(image);
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  // ============================================================
  // IMAGE SOURCE
  // ============================================================

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: primaryBlue,
                  ),
                  title: Text(
                    "Take a Photo",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: primaryBlue,
                  ),
                  title: Text(
                    "Choose from Gallery",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    "Cancel",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // UPLOAD PROFILE PHOTO
  // ============================================================

  Future<void> _uploadProfilePhoto(File imageFile) async {
    try {
      final user = _auth.currentUser;

      if (user == null) return;

      final idToken = await user.getIdToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/passengerauth/upload-profile-photo'),
      );

      request.headers['Authorization'] = 'Bearer $idToken';

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ),
      );

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        final resStr =
            await response.stream.bytesToString();

        final data = jsonDecode(resStr);

        if (!mounted) return;

        setState(() {
          _profileImageUrl =
              "$baseUrldoc${data['path']}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile photo updated"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint(
          "Upload failed: ${response.statusCode}",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload profile photo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error uploading profile photo: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error uploading profile photo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,

        title: Text(
          "Profile",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,

        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(
                isEditing
                    ? Icons.close
                    : Icons.edit_outlined,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  isEditing = !isEditing;
                });
              },
            ),
        ],
      ),

      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: primaryBlue,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    // ==================================================
                    // PROFILE PHOTO
                    // ==================================================

                    GestureDetector(
                      onTap:
                          isEditing
                              ? _showImageSourceActionSheet
                              : null,

                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [

                          CircleAvatar(
                            radius: 58,
                            backgroundColor:
                                Colors.grey.shade200,

                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(
                                      _profileImage!,
                                    )
                                    : (_profileImageUrl != null
                                            ? NetworkImage(
                                              _profileImageUrl!,
                                            )
                                            : const NetworkImage(
                                              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                            ))
                                        as ImageProvider,
                          ),

                          if (isEditing)
                            Container(
                              decoration:
                                  const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding:
                                  const EdgeInsets.all(7),
                              child: const Icon(
                                Icons.camera_alt,
                                color: primaryBlue,
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // NAME
                    // ==================================================

                    Text(
                      _nameController.text.isEmpty
                          ? "User"
                          : _nameController.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // PHONE
                    // ==================================================

                    _buildField(
                      "Phone",
                      _phoneController,
                      enabled: false,
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    _buildField(
                      "Email",
                      _emailController,
                      enabled: isEditing,
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // SAVE BUTTON
                    // ==================================================

                    if (isEditing)
                      _buildButton(
                        onPressed: updateUserProfile,
                        label: "Save Profile",
                        icon: Icons.save_outlined,
                      ),
                  ],
                ),
              ),
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,

      style: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),

      decoration: InputDecoration(
        labelText: label,

        labelStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton.icon(
        onPressed: onPressed,

        icon: const Icon(
          Icons.save_outlined,
          color: Colors.white,
          size: 21,
        ),

        label: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}