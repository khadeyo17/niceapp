import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/Container/Repositories/auth_repo.dart';
import 'package:niceapp/View/Routes/routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final zipCodeController = TextEditingController(text: '+254');

  String otpMethod = "sms"; // default
  bool isLoading = false;
  String selectedCountry = 'Kenya';

  final Map<String, String> countryCodes = {
    'Kenya': '+254',
    'Uganda': '+256',
    'Tanzania': '+255',
  };

  Future<void> sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      String cleanedPhone = phoneController.text;
      if (cleanedPhone.startsWith("0")) {
        cleanedPhone = cleanedPhone.substring(1);
      }
      final fullPhone = "${zipCodeController.text}$cleanedPhone";

      if (otpMethod == "whatsapp") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("WhatsApp OTP not supported yet. Defaulting to SMS."),
          ),
        );
      }

      final verificationId = await ref
          .read(globalAuthRepoProvider)
          .startPhoneVerification(
            phone: fullPhone,
            method: "sms",
            context: context,
          );

      setState(() => isLoading = false);

      if (verificationId != null && mounted) {
        context.goNamed(
          Routes().otp,
          extra: {'verificationId': verificationId, 'phoneNumber': fullPhone},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(
                Icons.phone_android,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your phone number to get started",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Country Dropdown
              DropdownButtonFormField<String>(
                value: selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    countryCodes.keys.map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCountry = value;
                      zipCodeController.text = countryCodes[value]!;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Phone Input
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: zipCodeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Code',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator:
                          (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator:
                          (val) =>
                              val == null || val.length < 9
                                  ? 'Enter valid number'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OTP Method
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Send OTP via:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  RadioListTile<String>(
                    value: "sms",
                    groupValue: otpMethod,
                    title: const Text("SMS"),
                    onChanged: (val) => setState(() => otpMethod = val!),
                  ),
                  RadioListTile<String>(
                    value: "whatsapp",
                    groupValue: otpMethod,
                    title: const Text("WhatsApp"),
                    onChanged: (val) => setState(() => otpMethod = val!),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label:
                    isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text("Send OTP"),
                onPressed: isLoading ? null : sendOTP,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.goNamed(Routes().login),
                child: const Text("Already have an account? Log In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
