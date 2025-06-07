// mobile_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/mobile_otp_verification_screen.dart';

class MobileEntryScreen extends StatefulWidget {
  const MobileEntryScreen({Key? key}) : super(key: key);

  @override
  State<MobileEntryScreen> createState() => _MobileEntryScreenState();
}

class _MobileEntryScreenState extends State<MobileEntryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  // Country codes example (you can expand)
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'name': 'USA'},
    {'code': '+254', 'name': 'Kenya'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+91', 'name': 'India'},
  ];

  String _selectedCode = '+254';
  String _otpDeliveryMethod = 'sms'; // 'sms' or 'whatsapp'

  String _verificationId = '';
  bool _isSendingOTP = false;

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '$_selectedCode${_phoneController.text.trim()}';

    if (_otpDeliveryMethod == 'whatsapp') {
      // WhatsApp OTP sending is custom — show info for now
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'WhatsApp OTP requested for $phone.\n'
            'Implement backend service to send WhatsApp OTP.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSendingOTP = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto sign-in
          await _auth.signInWithCredential(credential);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Phone automatically verified & signed in"),
            ),
          );
          // TODO: Navigate to landing page after sign in
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification failed: ${e.message}")),
          );
          setState(() => _isSendingOTP = false);
        },
        codeSent: (verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isSendingOTP = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => OTPVerificationScreen(
                    verificationId: verificationId,
                    phoneNumber: phone,
                  ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send OTP: $e")));
      setState(() => _isSendingOTP = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Phone Number")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Country code dropdown + phone input
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCode,
                    items:
                        _countryCodes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['code'],
                                child: Text('${c['name']} (${c['code']})'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCode = val);
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        // Simple phone number validation: digits only, length check
                        final digitsOnly = RegExp(r'^\d+$');
                        if (!digitsOnly.hasMatch(value.trim())) {
                          return 'Enter digits only';
                        }
                        if (value.trim().length < 6) {
                          return 'Too short';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Choose OTP delivery method
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send OTP via:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('SMS (normal phone message)'),
                    leading: Radio<String>(
                      value: 'sms',
                      groupValue: _otpDeliveryMethod,
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _otpDeliveryMethod = val);
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('WhatsApp'),
                    leading: Radio<String>(
                      value: 'whatsapp',
                      groupValue: _otpDeliveryMethod,
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _otpDeliveryMethod = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSendingOTP ? null : _sendOTP,
                child:
                    _isSendingOTP
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class OTPVerificationScreen extends StatefulWidget {
//   final String verificationId;
//   final String phoneNumber;

//   const OTPVerificationScreen({
//     Key? key,
//     required this.verificationId,
//     required this.phoneNumber,
//     //required this.phoneNumber,
//   }) : super(key: key);

//   @override
//   State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
// }

// class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
//   final TextEditingController _otpController = TextEditingController();
//   bool _isVerifying = false;

//   Future<void> _verifyOTP() async {
//     final code = _otpController.text.trim();
//     if (code.length != 6) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Enter valid 6-digit OTP')));
//       return;
//     }

//     setState(() => _isVerifying = true);
//     try {
//       final credential = PhoneAuthProvider.credential(
//         verificationId: widget.verificationId,
//         smsCode: code,
//       );

//       await FirebaseAuth.instance.signInWithCredential(credential);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Phone number verified and signed in')),
//       );

//       // TODO: Navigate to landing page or main app screen
//     } on FirebaseAuthException catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to verify OTP: ${e.message}')),
//       );
//     } finally {
//       setState(() => _isVerifying = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Verify OTP for ${widget.phoneNumber}')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(
//               controller: _otpController,
//               keyboardType: TextInputType.number,
//               maxLength: 6,
//               decoration: const InputDecoration(
//                 labelText: 'Enter OTP',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isVerifying ? null : _verifyOTP,
//               child:
//                   _isVerifying
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text('Verify OTP'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
