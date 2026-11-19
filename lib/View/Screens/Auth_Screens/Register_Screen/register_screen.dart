import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:niceapp/Container/Repositories/auth_repo.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Routes/routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  String selectedCode = '+254';
  String selectedMethod = 'sms';
  bool isLoading = false;



PhoneNumber phoneNumber = PhoneNumber(isoCode: 'KE');
String completePhone = "";


  final List<String> otpMethods = ['sms', 'whatsapp'];

//   String? validatePhone(String? value) {
//   if (value == null || value.trim().isEmpty) {
//     return 'Phone number is required';
//   }

//   final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

//   if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
//     return 'Phone number must contain only digits';
//   }

//   final expectedLength = countryPhoneLengths[selectedCode];

//   if (expectedLength != null && digitsOnly.length != expectedLength) {
//     return 'Phone number must be $expectedLength digits';
//   }

//   // Accept countries not in the map provided they are 6-15 digits
//   if (expectedLength == null &&
//       (digitsOnly.length < 6 || digitsOnly.length > 15)) {
//     return 'Enter a valid phone number';
//   }

//   return null;
// }

  // String? validatePhone(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'Phone number is required';
  //   }
  //   final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
  //   if (digitsOnly.length != 9) {
  //     return 'Phone number must be 9 digits (e.g. 712345678)';
  //   }
  //   if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
  //     return 'Phone number must contain only digits';
  //   }
  //   return null;
  // }

  @override
  void initState() {
    super.initState();

    // Disable browser reCAPTCHA only for debug/testing
    if (kDebugMode) {
      FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    }
  }




  // Future<void> sendOTP() async {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() => isLoading = true);
  
  // if (completePhone.isEmpty) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text("Please enter a valid phone number"),
  //     ),
  //   );
  //   return;
  // }
  //     // String cleanedPhone = phoneController.text.trim().replaceAll(
  //     //   RegExp(r'\D'),
  //     //   '',
  //     // );
  //     // if (cleanedPhone.startsWith('0')) {
  //     //   cleanedPhone = cleanedPhone.substring(1);
  //     // }

  //     // String fullPhone = '$selectedCode$cleanedPhone';
  //     // String apiPhone = fullPhone;

  //      String fullPhone = phoneNumber.phoneNumber ?? "";
  //      String apiPhone = fullPhone;


  //     if (selectedMethod == 'whatsapp') {
  //       apiPhone = fullPhone;
  //       // 'whatsapp:$fullPhone';
  //     }

  //     String? otp;
  //     try {
  //       var verificationId = await ref
  //           .read(globalAuthRepoProvider)
  //           .startPhoneVerification(
  //             phone: fullPhone,
  //             method: selectedMethod,
  //             context: context,
  //           );

  //       if (selectedMethod == 'whatsapp') {
  //         final response = await http.post(
  //           Uri.parse("$baseUrl/passengerauth/SendWhatsappOTP"),
  //           headers: {'Content-Type': 'application/json'},
  //           body: jsonEncode({'phone': apiPhone, 'method': selectedMethod}),
  //         );

  //         if (response.statusCode != 200) {
  //           throw Exception('Failed to send WhatsApp OTP: ${response.body}');
  //         }

  //         final json = jsonDecode(response.body);
  //         verificationId = json['sid'];
  //         otp = json['otp'];
  //       }

  //       setState(() => isLoading = false);

  //       if (verificationId != null && mounted) {
  //         context.goNamed(
  //           Routes().otp,
  //           extra: {
  //             'verificationId': verificationId,
  //             'phoneNumber': fullPhone,
  //             'method': selectedMethod,
  //             'otp': otp, // Optional
  //           },
  //         );
  //       }
  //     } catch (e) {
  //       setState(() => isLoading = false);
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
  //     }
  //   }
  // }
Future<void> sendOTP() async {
  if (!_formKey.currentState!.validate()) return;

  if (completePhone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter a valid phone number"),
      ),
    );
    return;
  }

  setState(() => isLoading = true);

  //final String fullPhone = completePhone;
  String fullPhone = phoneNumber.phoneNumber ?? "";
  String apiPhone = fullPhone;

  String? otp;

  try {
    var verificationId = await ref
        .read(globalAuthRepoProvider)
        .startPhoneVerification(
          phone: fullPhone,
          method: selectedMethod,
          context: context,
        );

    if (selectedMethod == "whatsapp") {
      final response = await http.post(
        Uri.parse("$baseUrl/passengerauth/SendWhatsappOTP"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phone": apiPhone,
          "method": selectedMethod,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final json = jsonDecode(response.body);

      verificationId = json["sid"];
      otp = json["otp"];
    }

    if (!mounted) return;

    context.goNamed(
      Routes().otp,
      extra: {
        "verificationId": verificationId,
        "phoneNumber": fullPhone,
        "method": selectedMethod,
        "otp": otp,
      },
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
  
  @override
  Widget build(BuildContext context) {


    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  foregroundColor: Colors.black,
  centerTitle: true,
  title: Text(
    "Register",
    style: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
  ),
),
      body: SingleChildScrollView(
        //padding: const EdgeInsets.all(20),
padding: EdgeInsets.symmetric(
  horizontal: MediaQuery.of(context).size.width < 360 ? 12 : 20,
  vertical: 20,
),

        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

             
              _buildWelcomeCard(),
              const SizedBox(height: 25),
              // 🔹 CARD
              _buildCard(
                child: Column(
                  children: [
                  
InternationalPhoneNumberInput(
  initialValue: phoneNumber,
  textFieldController: phoneController,

  selectorConfig: const SelectorConfig(
    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
    showFlags: true,
    useEmoji: true,
    setSelectorButtonAsPrefixIcon: true,
    leadingPadding: 8,
  ),

  onInputChanged: (PhoneNumber number) {
    setState(() {
      phoneNumber = number;
      completePhone = number.phoneNumber ?? "";
    });

    debugPrint("ISO : ${number.isoCode}");
    debugPrint("Dial: ${number.dialCode}");
    debugPrint("Full: ${number.phoneNumber}");
  },

  onInputValidated: (bool value) {
    debugPrint("Valid: $value");
  },

  keyboardType: TextInputType.phone,
  formatInput: true,
  autoValidateMode: AutovalidateMode.onUserInteraction,

  inputDecoration: _inputDecoration("Phone Number"),
),
                    const SizedBox(height: 20),

                    // 🔥 OTP METHOD (MODERN)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "OTP Method",

 style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),

                        // style: TextStyle(
                        //   fontWeight: FontWeight.w600,
                        //   color: Colors.grey[700],
                        // ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children:
                          otpMethods.map((method) {
                            final isSelected = selectedMethod == method;

                            return Expanded(
                              child: GestureDetector(
                                onTap:
                                    () =>
                                        setState(() => selectedMethod = method),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Color(0xFF015ACE)
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
  child: Text(
    method.toUpperCase(),
    style: GoogleFonts.spaceGrotesk(
      color: isSelected ? Colors.white : Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
),
                                ),
                              ),
                            );
                          }).toList(),
                    ),


                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF015ACE),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                         : Text(
    "Send OTP",
    style: GoogleFonts.spaceGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildWelcomeText() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Welcome to AMINI",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      Text(
        "Ride smarter, travel faster.\nAll transport in one app.",
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),

      const SizedBox(height: 12),

      FittedBox(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Start your journey",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}
Widget _buildWelcomeImage() {
  return SizedBox(
    width: 100,
    height: 100,
    child: Image.asset(
      "assets/imgs/taxi.png",
      fit: BoxFit.contain,
    ),
  );
}
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF015ACE).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,

      // 🔥 CLEAN BORDER STYLE
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Color(0xFF015ACE),
        //   gradient: const LinearGradient(
        //      colors: [
        //   Color(0xFF0D47A1), // Dark blue
        //   Color(0xFF42A5F5), // Light blue
        // ],
        //  colors: [Color(0xFF000000), Color(0xFF2C2C2C)],
        //begin: Alignment.topLeft,
        // end: Alignment.bottomRight,
        // ),
        boxShadow: [
          BoxShadow(
            color:Colors.black,// Color(0xFF015ACE).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // TEXT SIDE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Welcome to AMINI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
               const SizedBox(height: 6),
Text(
  "Ride smarter, travel faster.\nAll transport in one app.",
  style: GoogleFonts.nunitoSans(
    color: Colors.white70,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  ),
),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
  "Start your journey",
  style: GoogleFonts.spaceGrotesk(
    color: Colors.black,
    fontWeight: FontWeight.w700,
    fontSize: 12,
  ),
),
                ),
              ],
            ),
          ),

          // 🚗 CAR IMAGE
          SizedBox(
            width: 110,
            height: 110,
            child: Image.asset("assets/imgs/taxi.png", fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
//                     LayoutBuilder(
//   builder: (context, constraints) {
//     if (constraints.maxWidth < 360) {
//       return Column(
//         children: [
//           _buildWelcomeText(),
//           const SizedBox(height: 20),
//           _buildWelcomeImage(),
//         ],
//       );
//     }

//     return Row(
//       children: [
//         Expanded(child: _buildWelcomeText()),
//         const SizedBox(width: 10),
//         _buildWelcomeImage(),
//       ],
//     );
//   },
// )
  // Row(
                    //   children: [
                    //     Expanded(
                    //       flex: 2,
                    //       child: DropdownButtonFormField<String>(
                    //         value: selectedCode,
                    //         items:
                    //             countryCodes.map((code) {
                    //               return DropdownMenuItem(
                    //                 value: code,
                    //                 child: Text(code),
                    //               );
                    //             }).toList(),
                    //         onChanged:
                    //             (val) => setState(() => selectedCode = val!),
                    //         decoration: _inputDecoration("Code"),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 10),
                    //     Expanded(
                    //       flex: 5,
                    //       child: TextFormField(
                    //         controller: phoneController,
                    //         keyboardType: TextInputType.phone,
                    //         validator: validatePhone,
                    //         decoration: _inputDecoration("Phone Number"),
                    //       ),
                    //     ),
                    //   ],
                    // ),


// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/Container/Repositories/auth_repo.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final phoneController = TextEditingController();
//   String selectedCode = '+254';
//   String selectedMethod = 'sms';
//   bool isLoading = false;

//   final List<String> countryCodes = ['+254', '+256', '+255'];
//   final List<String> otpMethods = ['sms', 'whatsapp'];

//   String? validatePhone(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Phone number is required';
//     }

//     final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

//     if (digitsOnly.length != 9) {
//       return 'Phone number must be 9 digits (e.g. 712345678)';
//     }

//     if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
//       return 'Phone number must contain only digits';
//     }

//     return null;
//   }

//   Future<void> sendOTP() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => isLoading = true);

//       String cleanedPhone = phoneController.text.trim().replaceAll(
//         RegExp(r'\D'),
//         '',
//       );
//       if (cleanedPhone.startsWith('0')) {
//         cleanedPhone = cleanedPhone.substring(1);
//       }

//       final fullPhone = '$selectedCode$cleanedPhone';

//       if (selectedMethod == 'whatsapp' &&
//           !RegExp(r'^\+\d{11,13}$').hasMatch(fullPhone)) {
//         setState(() => isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Invalid WhatsApp number format')),
//         );
//         return;
//       }

//       try {
//         final verificationId = await ref
//             .read(globalAuthRepoProvider)
//             .startPhoneVerification(
//               phone: fullPhone,
//               method: selectedMethod,
//               context: context,
//             );

//         setState(() => isLoading = false);

//         if (verificationId != null && mounted) {
//           context.goNamed(
//             Routes().otp,
//             extra: {'verificationId': verificationId, 'phoneNumber': fullPhone},
//           );
//         }
//       } catch (e) {
//         setState(() => isLoading = false);
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final borderRadius = BorderRadius.circular(12);
//     final border = OutlineInputBorder(borderRadius: borderRadius);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Register"),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: Colors.grey[100],
//       body: Center(
//         child: Card(
//           margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//           elevation: 2,
//           shape: RoundedRectangleBorder(borderRadius: borderRadius),
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.phone_android_outlined,
//                     size: 60,
//                     color: Colors.grey,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     "Enter your phone number",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(height: 24),
//                   Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: DropdownButtonFormField<String>(
//                           value: selectedCode,
//                           decoration: InputDecoration(
//                             labelText: 'Code',
//                             border: border,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                             ),
//                           ),
//                           items:
//                               countryCodes
//                                   .map(
//                                     (code) => DropdownMenuItem(
//                                       value: code,
//                                       child: Text(code),
//                                     ),
//                                   )
//                                   .toList(),
//                           onChanged:
//                               (val) => setState(() => selectedCode = val!),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         flex: 5,
//                         child: TextFormField(
//                           controller: phoneController,
//                           keyboardType: TextInputType.phone,
//                           decoration: InputDecoration(
//                             labelText: 'Phone Number',
//                             border: border,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                             ),
//                           ),
//                           validator: validatePhone,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   DropdownButtonFormField<String>(
//                     value: selectedMethod,
//                     decoration: InputDecoration(
//                       labelText: 'OTP Method',
//                       border: border,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                       ),
//                     ),
//                     items:
//                         otpMethods
//                             .map(
//                               (method) => DropdownMenuItem(
//                                 value: method,
//                                 child: Text(method.toUpperCase()),
//                               ),
//                             )
//                             .toList(),
//                     onChanged: (val) => setState(() => selectedMethod = val!),
//                   ),
//                   const SizedBox(height: 30),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isLoading ? null : sendOTP,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.grey[800],
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: borderRadius,
//                         ),
//                       ),
//                       child:
//                           isLoading
//                               ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                               : const Text("Send OTP"),
//                     ),
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




// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/Container/Repositories/auth_repo.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final phoneController = TextEditingController();
//   String selectedCode = '+254';
//   String selectedMethod = 'sms';
//   bool isLoading = false;

//   final List<String> countryCodes = ['+254', '+256', '+255'];
//   final List<String> otpMethods = ['sms', 'whatsapp'];

//   Future<void> sendOTP() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => isLoading = true);

//       String cleanedPhone = phoneController.text.trim();
//       if (cleanedPhone.startsWith('0')) {
//         cleanedPhone = cleanedPhone.substring(1);
//       }

//       final fullPhone = '$selectedCode$cleanedPhone';

//       final verificationId = await ref
//           .read(globalAuthRepoProvider)
//           .startPhoneVerification(
//             phone: fullPhone,
//             method: selectedMethod,
//             context: context,
//           );

//       setState(() => isLoading = false);

//       if (verificationId != null && mounted) {
//         context.goNamed(
//           Routes().otp,
//           extra: {'verificationId': verificationId, 'phoneNumber': fullPhone},
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text("Login with Phone"),
//         centerTitle: true,
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const Icon(
//                 Icons.phone_android,
//                 size: 80,
//                 color: Colors.blueAccent,
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 "Enter your phone number",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//               ),
//               const SizedBox(height: 32),
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: DropdownButtonFormField<String>(
//                       value: selectedCode,
//                       decoration: InputDecoration(
//                         labelText: 'Code',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       items:
//                           countryCodes.map((code) {
//                             return DropdownMenuItem(
//                               value: code,
//                               child: Text(code),
//                             );
//                           }).toList(),
//                       onChanged: (val) => setState(() => selectedCode = val!),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 5,
//                     child: TextFormField(
//                       controller: phoneController,
//                       keyboardType: TextInputType.phone,
//                       decoration: InputDecoration(
//                         labelText: 'Phone Number',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.length < 9
//                                   ? 'Enter valid number'
//                                   : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               DropdownButtonFormField<String>(
//                 value: selectedMethod,
//                 decoration: InputDecoration(
//                   labelText: 'OTP Method',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 items:
//                     otpMethods.map((method) {
//                       return DropdownMenuItem(
//                         value: method,
//                         child: Text(method.toUpperCase()),
//                       );
//                     }).toList(),
//                 onChanged: (val) => setState(() => selectedMethod = val!),
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: isLoading ? null : sendOTP,
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   backgroundColor: Colors.blueAccent,
//                 ),
//                 child:
//                     isLoading
//                         ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                         : const Text("Send OTP"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/Container/Repositories/auth_repo.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final phoneController = TextEditingController();
//   final zipCodeController = TextEditingController(text: '+254');

//   String otpMethod = "sms"; // default
//   bool isLoading = false;
//   String selectedCountry = 'Kenya';

//   final Map<String, String> countryCodes = {
//     'Kenya': '+254',
//     'Uganda': '+256',
//     'Tanzania': '+255',
//   };

//   Future<void> sendOTP() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => isLoading = true);

//       String cleanedPhone = phoneController.text;
//       if (cleanedPhone.startsWith("0")) {
//         cleanedPhone = cleanedPhone.substring(1);
//       }
//       final fullPhone = "${zipCodeController.text}$cleanedPhone";

//       if (otpMethod == "whatsapp") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("WhatsApp OTP not supported yet. Defaulting to SMS."),
//           ),
//         );
//       }

//       final verificationId = await ref
//           .read(globalAuthRepoProvider)
//           .startPhoneVerification(
//             phone: fullPhone,
//             method: "sms",
//             context: context,
//           );

//       setState(() => isLoading = false);

//       if (verificationId != null && mounted) {
//         context.goNamed(
//           Routes().otp,
//           extra: {'verificationId': verificationId, 'phoneNumber': fullPhone},
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           "Register",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const Icon(
//                 Icons.phone_android,
//                 size: 100,
//                 color: Colors.blueAccent,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "Enter your phone number to get started",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),

//               // Country Dropdown
//               DropdownButtonFormField<String>(
//                 value: selectedCountry,
//                 decoration: InputDecoration(
//                   labelText: 'Country',
//                   prefixIcon: const Icon(Icons.public),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 items:
//                     countryCodes.keys.map((country) {
//                       return DropdownMenuItem<String>(
//                         value: country,
//                         child: Text(country),
//                       );
//                     }).toList(),
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() {
//                       selectedCountry = value;
//                       zipCodeController.text = countryCodes[value]!;
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),

//               // Phone Input
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: TextFormField(
//                       controller: zipCodeController,
//                       readOnly: true,
//                       decoration: InputDecoration(
//                         labelText: 'Code',
//                         prefixIcon: const Icon(Icons.flag),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 5,
//                     child: TextFormField(
//                       controller: phoneController,
//                       keyboardType: TextInputType.phone,
//                       decoration: InputDecoration(
//                         labelText: 'Phone Number',
//                         prefixIcon: const Icon(Icons.phone),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.length < 9
//                                   ? 'Enter valid number'
//                                   : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               // OTP Method
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Send OTP via:",
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   RadioListTile<String>(
//                     value: "sms",
//                     groupValue: otpMethod,
//                     title: const Text("SMS"),
//                     onChanged: (val) => setState(() => otpMethod = val!),
//                   ),
//                   RadioListTile<String>(
//                     value: "whatsapp",
//                     groupValue: otpMethod,
//                     title: const Text("WhatsApp"),
//                     onChanged: (val) => setState(() => otpMethod = val!),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.send),
//                 label:
//                     isLoading
//                         ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                         : const Text("Send OTP"),
//                 onPressed: isLoading ? null : sendOTP,
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   backgroundColor: Colors.blueAccent,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextButton(
//                 onPressed: () => context.goNamed(Routes().login),
//                 child: const Text("Already have an account? Log In"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





//old

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/Container/Repositories/auth_repo.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final zipCodeController = TextEditingController(
//     text: "+254",
//   ); // Kenya default
//   final phoneController = TextEditingController();

//   String otpMethod = "sms"; // default
//   bool isLoading = false;

//   String selectedCountry = 'Kenya';

//   final Map<String, String> countryCodes = {
//     'Kenya': '+254',
//     'Uganda': '+256',
//     'Tanzania': '+255',
//   };

//   Future<void> sendOTP() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => isLoading = true);

//       String cleanedPhone = phoneController.text;
//       if (cleanedPhone.startsWith("0")) {
//         cleanedPhone = cleanedPhone.substring(1);
//       }
//       final fullPhone = "${zipCodeController.text}$cleanedPhone";

//       if (otpMethod == "whatsapp") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("WhatsApp OTP not supported yet. Defaulting to SMS."),
//           ),
//         );
//       }

//       final verificationId = await ref
//           .read(globalAuthRepoProvider)
//           .startPhoneVerification(
//             phone: fullPhone,
//             method: "sms",
//             context: context,
//           );

//       setState(() => isLoading = false);

//       if (verificationId != null && mounted) {
//         context.goNamed(
//           Routes().otp,
//           extra: {'verificationId': verificationId, 'phoneNumber': fullPhone},
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           "Register",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const Icon(
//                 Icons.phone_android,
//                 size: 100,
//                 color: Colors.blueAccent,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 "Enter your phone number to get started",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),

//               // Phone Input
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: TextFormField(
//                       controller: zipCodeController,
//                       decoration: InputDecoration(
//                         labelText: 'Code',
//                         prefixIcon: const Icon(Icons.flag),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 5,
//                     child: TextFormField(
//                       controller: phoneController,
//                       keyboardType: TextInputType.phone,
//                       decoration: InputDecoration(
//                         labelText: 'Phone Number',
//                         prefixIcon: const Icon(Icons.phone),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.length < 9
//                                   ? 'Enter valid number'
//                                   : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               // OTP Method
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Send OTP via:",
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   RadioListTile<String>(
//                     value: "sms",
//                     groupValue: otpMethod,
//                     title: const Text("SMS"),
//                     onChanged: (val) => setState(() => otpMethod = val!),
//                   ),
//                   RadioListTile<String>(
//                     value: "whatsapp",
//                     groupValue: otpMethod,
//                     title: const Text("WhatsApp"),
//                     onChanged: (val) => setState(() => otpMethod = val!),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.send),
//                 label:
//                     isLoading
//                         ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                         : const Text("Send OTP"),
//                 onPressed: isLoading ? null : sendOTP,
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   backgroundColor: Colors.blueAccent,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextButton(
//                 onPressed: () => context.goNamed(Routes().login),
//                 child: const Text("Already have an account? Log In"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//Working login

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/Container/Repositories/auth_repo.dart';
// import 'package:niceapp/View/Routes/routes.dart';

// class RegisterScreen extends ConsumerStatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends ConsumerState<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final fullNameController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final passwordController = TextEditingController();

//   bool isLoading = false;

//   Future<void> register(BuildContext context) async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => isLoading = true);

//       final success = await ref
//           .read(globalAuthRepoProvider)
//           .registerWithEmailPhonePassword(
//             fullName: fullNameController.text.trim(),
//             email: emailController.text.trim(),
//             phone: phoneController.text.trim(),
//             password: passwordController.text.trim(),
//             context: context,
//           );

//       setState(() => isLoading = false);
//       if (success && context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Registration successful. Please verify your email."),
//           ),
//         );
//         context.goNamed(Routes().login);
//       }
//     }
//   }

//   Future<void> signInWithGoogle() async {
//     await ref.read(globalAuthRepoProvider).signInWithGoogle(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         title: const Text("Register"),
//         centerTitle: true,
//       ),
//       backgroundColor: Colors.blue[50],
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             children: [
//               const Icon(Icons.person_add_alt_1, size: 100, color: Colors.blue),
//               const SizedBox(height: 10),
//               const Text(
//                 "Create Account",
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: fullNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Full Name',
//                         labelStyle: TextStyle(color: Colors.black),
//                         prefixIcon: Icon(Icons.person, color: Colors.blue),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.isEmpty
//                                   ? "Enter full name"
//                                   : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: emailController,
//                       decoration: const InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: TextStyle(color: Colors.black),
//                         prefixIcon: Icon(Icons.email, color: Colors.blue),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || !val.contains('@')
//                                   ? "Enter valid email"
//                                   : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: phoneController,
//                       decoration: const InputDecoration(
//                         labelText: 'Phone',
//                         labelStyle: TextStyle(color: Colors.black),
//                         prefixIcon: Icon(Icons.phone, color: Colors.blue),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.length < 10
//                                   ? "Enter valid phone"
//                                   : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: passwordController,
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         labelText: 'Password',
//                         labelStyle: TextStyle(color: Colors.black),
//                         prefixIcon: Icon(Icons.lock, color: Colors.blue),
//                       ),
//                       validator:
//                           (val) =>
//                               val == null || val.length < 6
//                                   ? "Password must be 6+ chars"
//                                   : null,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 onPressed: isLoading ? null : () => register(context),
//                 icon: const Icon(Icons.app_registration, color: Colors.white),
//                 label:
//                     isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text(
//                           "Register",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue, //[800],
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Divider(),
//               const Text("OR", style: TextStyle(color: Colors.black)),
//               const SizedBox(height: 10),
//               OutlinedButton.icon(
//                 onPressed: signInWithGoogle,
//                 icon: const Icon(Icons.g_mobiledata, color: Colors.green),
//                 label: const Text("Continue with Google"),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.blue,
//                   minimumSize: const Size(double.infinity, 50),
//                   side: const BorderSide(color: Colors.blue),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               TextButton(
//                 onPressed: () => context.goNamed(Routes().login),
//                 child: const Text(
//                   "Back to Login",
//                   style: TextStyle(color: Colors.blue),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/register_logics.dart';
// import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/register_providers.dart';
// import '../../../Components/all_components.dart';
// import '../../../Routes/routes.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.sizeOf(context);
//     return Scaffold(
//       body: SafeArea(
//         child: InkWell(
//           onTap: () {
//             FocusScope.of(context).unfocus();
//           },
//           child: SizedBox(
//             width: size.width,
//             height: size.height,
//             child: Stack(
//               children: [
//                 // Opacity(
//                 //   opacity: 0.2,
//                 //   child: Container(
//                 //     width: size.width,
//                 //     height: size.height,
//                 //     decoration: const BoxDecoration(
//                 //       image: DecorationImage(
//                 //         fit: BoxFit.cover,
//                 //         image: AssetImage("assets/imgs/main.jpg"),
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),
//                 Container(
//                   width: size.width,
//                   height: size.height,
//                   color: Colors.blueGrey, // Light background
//                 ),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(top: 20.0),
//                       child: Text(
//                         "Register",
//                         style: Theme.of(context).textTheme.bodySmall!.copyWith(
//                           fontFamily: "bold",
//                           fontSize: 20,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.only(
//                           top: 20.0,
//                           left: 20,
//                           right: 20,
//                         ),
//                         child: Form(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Components().returnTextField(
//                                 nameController,
//                                 context,
//                                 false,
//                                 "Enter Name",
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 20.0),
//                                 child: Components().returnTextField(
//                                   emailController,
//                                   context,
//                                   false,
//                                   "Enter Email",
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 20.0),
//                                 child: Components().returnTextField(
//                                   passwordController,
//                                   context,
//                                   true,
//                                   "Enter Password",
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 20.0),
//                                 child: Consumer(
//                                   builder: (context, ref, child) {
//                                     return InkWell(
//                                       onTap:
//                                           ref.watch(registerIsLoadingProvider)
//                                               ? null
//                                               : () =>
//                                                   RegisterLogics().registerUser(
//                                                     context,
//                                                     ref,
//                                                     nameController,
//                                                     emailController,
//                                                     passwordController,
//                                                   ),
//                                       child: Components().mainButton(
//                                         size,
//                                         ref.watch(registerIsLoadingProvider)
//                                             ? "Loading ..."
//                                             : "Register",
//                                         context,
//                                         ref.watch(registerIsLoadingProvider)
//                                             ? Colors.grey
//                                             : Colors.blue,
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               TextButton(
//                                 onPressed: () {
//                                   context.goNamed(Routes().login);
//                                 },
//                                 child: Text(
//                                   "Login.",
//                                   style: Theme.of(
//                                     context,
//                                   ).textTheme.bodySmall!.copyWith(
//                                     fontFamily: "bold",
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//   final Map<String, int> countryPhoneLengths = {
//   '+254': 9,   // Kenya
//   '+255': 9,   // Tanzania
//   '+256': 9,   // Uganda
//   '+250': 9,   // Rwanda
//   '+257': 8,   // Burundi
//   '+211': 9,   // South Sudan
//   '+251': 9,   // Ethiopia
//   '+27': 9,    // South Africa
//   '+234': 10,  // Nigeria
//   '+233': 9,   // Ghana
//   '+20': 10,   // Egypt
//   '+1': 10,    // USA/Canada
//   '+44': 10,   // UK (common mobile)
//   '+33': 9,    // France
//   '+49': 10,   // Germany (common)
//   '+39': 10,   // Italy (common)
//   '+34': 9,    // Spain
//   '+91': 10,   // India
//   '+971': 9,   // UAE
//   '+966': 9,   // Saudi Arabia
//   '+86': 11,   // China
//   '+81': 10,   // Japan
//   '+61': 9,    // Australia
// };

//   //final List<String> countryCodes = ['+254', '+256', '+255'];

//   final List<String> countryCodes = [
//   '+254', // Kenya
//   '+255', // Tanzania
//   '+256', // Uganda
//   '+250', // Rwanda
//   '+257', // Burundi
//   '+211', // South Sudan
//   '+251', // Ethiopia
//   '+27',  // South Africa
//   '+234', // Nigeria
//   '+233', // Ghana
//   '+20',  // Egypt
//   '+1',   // USA/Canada
//   '+44',  // UK
//   '+33',  // France
//   '+49',  // Germany
//   '+39',  // Italy
//   '+34',  // Spain
//   '+91',  // India
//   '+971', // UAE
//   '+966', // Saudi Arabia
//   '+86',  // China
//   '+81',  // Japan
//   '+61',  // Australia
// ];
  