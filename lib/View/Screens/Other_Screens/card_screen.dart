import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({
    super.key,
    required this.baseUrl,
  });

  final String baseUrl;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final cardNumberController = TextEditingController();
  final cardHolderController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  bool _showCvv = false;
  bool _isSaving = false;

  String _cardType = "Card";

  static const primaryBlue = Color(0xFF015ACE);
  static const darkBlue = Color(0xFF003B8F);
  static const darkText = Color(0xFF172033);
  static const background = Color(0xFFF7F9FC);

  @override
  void dispose() {
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARD TYPE
  // ============================================================

  String _detectCardType(String number) {
    final value = number.replaceAll(' ', '');

    if (value.isEmpty) {
      return "Card";
    }

    if (value.startsWith('4')) {
      return "Visa";
    }

    if (value.length >= 2) {
      final prefix = int.tryParse(value.substring(0, 2));

      if (prefix != null && prefix >= 51 && prefix <= 55) {
        return "Mastercard";
      }
    }

    if (value.length >= 4) {
      final prefix4 = int.tryParse(value.substring(0, 4));

      if (prefix4 != null &&
          prefix4 >= 2221 &&
          prefix4 <= 2720) {
        return "Mastercard";
      }
    }

    return "Card";
  }

  // ============================================================
  // FORMAT CARD NUMBER
  // ============================================================

  String _formatCardNumber(String value) {
    final digits = value.replaceAll(' ', '');

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }

      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  // ============================================================
  // FORMAT EXPIRY
  // ============================================================

  String _formatExpiry(String value) {
    final digits = value.replaceAll('/', '');

    if (digits.length <= 2) {
      return digits;
    }

    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }

  // ============================================================
  // API ERROR
  // ============================================================

  String _getApiError(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data["message"]?.toString() ??
            data["Message"]?.toString() ??
            "Unable to add your card. Please try again.";
      }
    } catch (_) {
      // Ignore invalid JSON
    }

    switch (response.statusCode) {
      case 400:
        return "Please check your card details and try again.";

      case 401:
        return "Your session has expired. Please sign in again.";

      case 409:
        return "This card is already registered.";

      case 422:
        return "The card details could not be verified.";

      default:
        return "Unable to add your card. Please try again.";
    }
  }

  // ============================================================
  // SAVE CARD
  // ============================================================

  Future<void> _saveCard() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception(
          "Your session has expired. Please sign in again.",
        );
      }

      final idToken = await firebaseUser.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          "Unable to verify your account. Please sign in again.",
        );
      }

      final cardNumber =
          cardNumberController.text.replaceAll(' ', '');

      final expiry =
          expiryController.text.trim();

      final cvv =
          cvvController.text.trim();

      final cardHolder =
          cardHolderController.text.trim();

      // ========================================================
      // SEND TO YOUR BACKEND
      //
      // IMPORTANT:
      // Your backend should tokenize the card using the payment
      // provider and NEVER store PAN/CVV.
      // ========================================================

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/wallet/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'cardNumber': cardNumber,
          'cardHolderName': cardHolder,
          'expiry': expiry,
          'cvv': cvv,
          'brand': _cardType,
        }),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(_getApiError(response));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Card added successfully.",
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Return the saved card response to Wallet.
      try {
        final data = jsonDecode(response.body);

        Navigator.pop(context, data);
      } catch (_) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Add card error: $e");

      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // CARD PREVIEW
  // ============================================================

  Widget _buildCardPreview() {
    final number = cardNumberController.text.trim();
    final expiry = expiryController.text.trim();
    final holder = cardHolderController.text.trim();

    final displayNumber = number.isEmpty
        ? "•••• •••• •••• ••••"
        : number;

    return Container(
      width: double.infinity,
      height: 205,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            darkBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.contactless_rounded,
                color: Colors.white,
                size: 28,
              ),
              const Spacer(),
              Text(
                _cardType,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            displayNumber,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CARD HOLDER",
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      holder.isEmpty
                          ? "YOUR NAME"
                          : holder.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "EXPIRES",
                    style: GoogleFonts.nunitoSans(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    expiry.isEmpty ? "MM/YY" : expiry,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,

      filled: true,
      fillColor: const Color(0xFFF8FAFD),

      labelStyle: GoogleFonts.nunitoSans(
        color: Colors.grey.shade600,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      floatingLabelStyle: GoogleFonts.nunitoSans(
        color: primaryBlue,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),

      hintStyle: GoogleFonts.nunitoSans(
        color: Colors.grey.shade500,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E7EF),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE53935),
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE53935),
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,

        title: Text(
          "Add Card",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                _buildCardPreview(),

                const SizedBox(height: 28),

                Text(
                  "Card details",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Enter your debit or credit card details.",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // CARD NUMBER
                // =================================================

                TextFormField(
                  controller: cardNumberController,
                  keyboardType: TextInputType.number,

                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),

                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],

                  decoration: _inputDecoration(
                    label: "Card number",
                    hint: "1234 5678 9012 3456",
                    prefixIcon: const Icon(
                      Icons.credit_card_rounded,
                    ),
                  ),

                  onChanged: (value) {
                    final formatted =
                        _formatCardNumber(value);

                    if (formatted !=
                        cardNumberController.text) {
                      cardNumberController
                        ..text = formatted
                        ..selection =
                            TextSelection.fromPosition(
                          TextPosition(
                            offset: formatted.length,
                          ),
                        );
                    }

                    setState(() {
                      _cardType =
                          _detectCardType(value);
                    });
                  },

                  validator: (value) {
                    final number =
                        value?.replaceAll(' ', '') ?? '';

                    if (number.isEmpty) {
                      return "Enter your card number";
                    }

                    if (number.length < 13) {
                      return "Enter a valid card number";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // =================================================
                // CARD HOLDER
                // =================================================

                TextFormField(
                  controller: cardHolderController,
                  textCapitalization:
                      TextCapitalization.words,

                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),

                  decoration: _inputDecoration(
                    label: "Cardholder name",
                    hint: "John Doe",
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                    ),
                  ),

                  onChanged: (_) {
                    setState(() {});
                  },

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Enter the cardholder name";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // =================================================
                // EXPIRY + CVV
                // =================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: expiryController,
                        keyboardType:
                            TextInputType.number,

                        style: GoogleFonts.nunitoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],

                        decoration: _inputDecoration(
                          label: "Expiry",
                          hint: "MM/YY",
                          prefixIcon: const Icon(
                            Icons.calendar_month_outlined,
                          ),
                        ),

                        onChanged: (value) {
                          final formatted =
                              _formatExpiry(value);

                          if (formatted !=
                              expiryController.text) {
                            expiryController
                              ..text = formatted
                              ..selection =
                                  TextSelection
                                      .fromPosition(
                                TextPosition(
                                  offset:
                                      formatted.length,
                                ),
                              );
                          }

                          setState(() {});
                        },

                        validator: (value) {
                          if (value == null ||
                              value.length != 5) {
                            return "MM/YY";
                          }

                          final parts =
                              value.split('/');

                          final month =
                              int.tryParse(parts[0]);

                          if (month == null ||
                              month < 1 ||
                              month > 12) {
                            return "Invalid month";
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextFormField(
                        controller: cvvController,
                        obscureText: !_showCvv,
                        keyboardType:
                            TextInputType.number,

                        style: GoogleFonts.nunitoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],

                        decoration: _inputDecoration(
                          label: "CVV",
                          hint: "123",
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showCvv = !_showCvv;
                              });
                            },
                            icon: Icon(
                              _showCvv
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.length < 3) {
                            return "Invalid CVV";
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // =================================================
                // SECURITY
                // =================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: primaryBlue,
                        size: 21,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          "Your card is securely processed. "
                          "AMINI does not store your full card "
                          "number or CVV.",
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =================================================
                // SAVE
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed:
                        _isSaving ? null : _saveCard,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,

                      disabledBackgroundColor:
                          primaryBlue.withOpacity(0.55),

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                "Save Card",
                                style:
                                    GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(width: 9),

                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                Center(
                  child: Text(
                    "🔒 Secure payment",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class AddCardScreen extends StatefulWidget {
//   const AddCardScreen({super.key});

//   @override
//   State<AddCardScreen> createState() => _AddCardScreenState();
// }

// class _AddCardScreenState extends State<AddCardScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final cardNumberController = TextEditingController();
//   final cardHolderController = TextEditingController();
//   final expiryController = TextEditingController();
//   final cvvController = TextEditingController();

//   bool _showCvv = false;
//   bool _isSaving = false;

//   String _cardType = "Card";

//   @override
//   void dispose() {
//     cardNumberController.dispose();
//     cardHolderController.dispose();
//     expiryController.dispose();
//     cvvController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // CARD TYPE
//   // ============================================================

//   String _detectCardType(String number) {
//     final value = number.replaceAll(' ', '');

//     if (value.isEmpty) {
//       return "Card";
//     }

//     // Visa
//     if (value.startsWith('4')) {
//       return "Visa";
//     }

//     // Mastercard
//     if (value.length >= 2) {
//       final prefix = int.tryParse(value.substring(0, 2));

//       if (prefix != null && prefix >= 51 && prefix <= 55) {
//         return "Mastercard";
//       }
//     }

//     // Mastercard 2-series
//     if (value.length >= 4) {
//       final prefix4 = int.tryParse(value.substring(0, 4));

//       if (prefix4 != null &&
//           prefix4 >= 2221 &&
//           prefix4 <= 2720) {
//         return "Mastercard";
//       }
//     }

//     return "Card";
//   }

//   // ============================================================
//   // FORMAT CARD NUMBER
//   // ============================================================

//   String _formatCardNumber(String value) {
//     final digits = value.replaceAll(' ', '');

//     final buffer = StringBuffer();

//     for (int i = 0; i < digits.length; i++) {
//       if (i > 0 && i % 4 == 0) {
//         buffer.write(' ');
//       }

//       buffer.write(digits[i]);
//     }

//     return buffer.toString();
//   }

//   // ============================================================
//   // EXPIRY FORMAT
//   // ============================================================

//   String _formatExpiry(String value) {
//     final digits = value.replaceAll('/', '');

//     if (digits.length <= 2) {
//       return digits;
//     }

//     return '${digits.substring(0, 2)}/${digits.substring(2)}';
//   }

//   // ============================================================
//   // SAVE CARD
//   // ============================================================

//   Future<void> _saveCard() async {
//     FocusScope.of(context).unfocus();

//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       final cardNumber =
//           cardNumberController.text.replaceAll(' ', '');

//       final expiry =
//           expiryController.text.trim();

//       final cvv =
//           cvvController.text.trim();

//       final cardHolder =
//           cardHolderController.text.trim();

//       /*
//        * IMPORTANT:
//        *
//        * Do NOT send/store the raw card details directly
//        * in your own database.
//        *
//        * Instead:
//        *
//        * 1. Send card details to your payment provider.
//        * 2. Payment provider tokenizes the card.
//        * 3. Your backend stores the token.
//        * 4. Your app only receives safe card information,
//        *    e.g.:
//        *
//        * {
//        *   "token": "...",
//        *   "brand": "Visa",
//        *   "last4": "4242"
//        * }
//        *
//        * Replace this delay with your payment-provider API.
//        */

//       await Future.delayed(
//         const Duration(seconds: 1),
//       );

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "Card added successfully",
//           ),
//         ),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       debugPrint("Error adding card: $e");

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "Unable to add card. Please try again.",
//           ),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
//       }
//     }
//   }


//   Widget _buildCardPreview() {
//     final number =
//         cardNumberController.text.trim();

//     final expiry =
//         expiryController.text.trim();

//     final holder =
//         cardHolderController.text.trim();

//     final displayNumber =
//         number.isEmpty
//             ? "•••• •••• •••• ••••"
//             : number;

//     return Container(
//       width: double.infinity,
//       height: 205,
//       padding: const EdgeInsets.all(22),

//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(22),

//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Color(0xFF015ACE),
//             Color(0xFF003B8F),
//           ],
//         ),

//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF015ACE)
//                 .withOpacity(0.25),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),

//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [

//           Row(
//             children: [

//               const Icon(
//                 Icons.contactless_rounded,
//                 color: Colors.white,
//                 size: 28,
//               ),

//               const Spacer(),

//               Text(
//                 _cardType,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),

//           const Spacer(),

//           Text(
//             displayNumber,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 21,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 1.8,
//             ),
//           ),

//           const SizedBox(height: 20),

//           Row(
//             children: [

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "CARD HOLDER",
//                       style: TextStyle(
//                         color: Colors.white60,
//                         fontSize: 9,
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       holder.isEmpty
//                           ? "YOUR NAME"
//                           : holder.toUpperCase(),
//                       maxLines: 1,
//                       overflow:
//                           TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight:
//                             FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "EXPIRES",
//                     style: TextStyle(
//                       color: Colors.white60,
//                       fontSize: 9,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     expiry.isEmpty
//                         ? "MM/YY"
//                         : expiry,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _inputDecoration({
//     required String label,
//     String? hint,
//     Widget? prefixIcon,
//     Widget? suffixIcon,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: prefixIcon,
//       suffixIcon: suffixIcon,

//       filled: true,
//       fillColor: const Color(0xFFF7F7F7),

//       labelStyle: const TextStyle(
//         color: Colors.black54,
//       ),

//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide.none,
//       ),

//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(
//           color: Colors.grey.shade200,
//         ),
//       ),

//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(
//           color: Color(0xFF015ACE),
//           width: 1.5,
//         ),
//       ),

//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(
//           color: Colors.red,
//         ),
//       ),

//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(
//           color: Colors.red,
//         ),
//       ),

//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 17,
//       ),
//     );
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,

//         title: const Text(
//           "Add Card",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//         ),

//         centerTitle: true,
//       ),

//       body: SafeArea(
//         child: Form(
//           key: _formKey,

//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(
//               16,
//               16,
//               16,
//               32,
//             ),

//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [

//                 // ==================================================
//                 // CARD PREVIEW
//                 // ==================================================

//                 _buildCardPreview(),

//                 const SizedBox(height: 28),

//                 const Text(
//                   "Card details",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),

//                 const SizedBox(height: 6),

//                 const Text(
//                   "Enter your debit or credit card details.",
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.black54,
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ==================================================
//                 // CARD NUMBER
//                 // ==================================================

//                 TextFormField(
//                   controller:
//                       cardNumberController,

//                   keyboardType:
//                       TextInputType.number,

//                   inputFormatters: [
//                     FilteringTextInputFormatter
//                         .digitsOnly,

//                     LengthLimitingTextInputFormatter(
//                       16,
//                     ),
//                   ],

//                   decoration: _inputDecoration(
//                     label: "Card number",
//                     hint: "1234 5678 9012 3456",
//                     prefixIcon: const Icon(
//                       Icons.credit_card_rounded,
//                     ),
//                   ),

//                   onChanged: (value) {
//                     final formatted =
//                         _formatCardNumber(value);

//                     if (formatted !=
//                         cardNumberController
//                             .text) {
//                       cardNumberController
//                         ..text = formatted
//                         ..selection =
//                             TextSelection
//                                 .fromPosition(
//                           TextPosition(
//                             offset:
//                                 formatted.length,
//                           ),
//                         );
//                     }

//                     setState(() {
//                       _cardType =
//                           _detectCardType(value);
//                     });
//                   },

//                   validator: (value) {
//                    final number =
//     value?.replaceAll(' ', '') ?? '';

//                     if (number.isEmpty) {
//                       return "Enter your card number";
//                     }

//                     if (number.length < 13) {
//                       return "Enter a valid card number";
//                     }

//                     return null;
//                   },
//                 ),

//                 const SizedBox(height: 14),

//                 // ==================================================
//                 // CARD HOLDER
//                 // ==================================================

//                 TextFormField(
//                   controller:
//                       cardHolderController,

//                   textCapitalization:
//                       TextCapitalization.words,

//                   decoration: _inputDecoration(
//                     label: "Cardholder name",
//                     hint: "John Doe",
//                     prefixIcon: const Icon(
//                       Icons.person_outline_rounded,
//                     ),
//                   ),

//                   onChanged: (_) {
//                     setState(() {});
//                   },

//                   validator: (value) {
//                     if (value == null ||
//                         value.trim().isEmpty) {
//                       return "Enter the cardholder name";
//                     }

//                     return null;
//                   },
//                 ),

//                 const SizedBox(height: 14),

//                 // ==================================================
//                 // EXPIRY + CVV
//                 // ==================================================

//                 Row(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [

//                     // EXPIRY

//                     Expanded(
//                       child: TextFormField(
//                         controller:
//                             expiryController,

//                         keyboardType:
//                             TextInputType.number,

//                         inputFormatters: [
//                           FilteringTextInputFormatter
//                               .digitsOnly,

//                           LengthLimitingTextInputFormatter(
//                             4,
//                           ),
//                         ],

//                         decoration:
//                             _inputDecoration(
//                           label: "Expiry",
//                           hint: "MM/YY",
//                           prefixIcon:
//                               const Icon(
//                             Icons
//                                 .calendar_month_outlined,
//                           ),
//                         ),

//                         onChanged: (value) {
//                           final formatted =
//                               _formatExpiry(
//                             value,
//                           );

//                           if (formatted !=
//                               expiryController
//                                   .text) {
//                             expiryController
//                               ..text = formatted
//                               ..selection =
//                                   TextSelection
//                                       .fromPosition(
//                                 TextPosition(
//                                   offset:
//                                       formatted
//                                           .length,
//                                 ),
//                               );
//                           }

//                           setState(() {});
//                         },

//                         validator: (value) {
//                           if (value == null ||
//                               value.length !=
//                                   5) {
//                             return "MM/YY";
//                           }

//                           return null;
//                         },
//                       ),
//                     ),

//                     const SizedBox(width: 12),

//                     // CVV

//                     Expanded(
//                       child: TextFormField(
//                         controller:
//                             cvvController,

//                         obscureText:
//                             !_showCvv,

//                         keyboardType:
//                             TextInputType.number,

//                         inputFormatters: [
//                           FilteringTextInputFormatter
//                               .digitsOnly,

//                           LengthLimitingTextInputFormatter(
//                             4,
//                           ),
//                         ],

//                         decoration:
//                             _inputDecoration(
//                           label: "CVV",
//                           hint: "123",
//                           prefixIcon:
//                               const Icon(
//                             Icons.lock_outline,
//                           ),
//                           suffixIcon:
//                               IconButton(
//                             onPressed: () {
//                               setState(() {
//                                 _showCvv =
//                                     !_showCvv;
//                               });
//                             },
//                             icon: Icon(
//                               _showCvv
//                                   ? Icons
//                                       .visibility_off_outlined
//                                   : Icons
//                                       .visibility_outlined,
//                             ),
//                           ),
//                         ),

//                         validator: (value) {
//                           if (value == null ||
//                               value.length <
//                                   3) {
//                             return "Invalid CVV";
//                           }

//                           return null;
//                         },
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 24),

//                 // ==================================================
//                 // SECURITY NOTICE
//                 // ==================================================

//                 Container(
//                   width: double.infinity,
//                   padding:
//                       const EdgeInsets.all(14),

//                   decoration: BoxDecoration(
//                     color: const Color(
//                       0xFF015ACE,
//                     ).withOpacity(0.06),

//                     borderRadius:
//                         BorderRadius.circular(
//                       14,
//                     ),
//                   ),

//                   child: Row(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,

//                     children: [

//                       const Icon(
//                         Icons
//                             .verified_user_outlined,
//                         color:
//                             Color(0xFF015ACE),
//                         size: 21,
//                       ),

//                       const SizedBox(width: 10),

//                       const Expanded(
//                         child: Text(
//                           "Your card details are securely processed. "
//                           "AMINI does not store your CVV.",
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.black54,
//                             height: 1.4,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // ==================================================
//                 // SAVE CARD
//                 // ==================================================

//                 SizedBox(
//                   width: double.infinity,
//                   height: 54,

//                   child: ElevatedButton(
//                     onPressed:
//                         _isSaving
//                             ? null
//                             : _saveCard,

//                     style:
//                         ElevatedButton.styleFrom(
//                       backgroundColor:
//                           const Color(
//                         0xFF015ACE,
//                       ),

//                       foregroundColor:
//                           Colors.white,

//                       disabledBackgroundColor:
//                           Colors.grey.shade400,

//                       elevation: 0,

//                       shape:
//                           RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.circular(
//                           14,
//                         ),
//                       ),
//                     ),

//                     child: _isSaving
//                         ? const SizedBox(
//                             width: 22,
//                             height: 22,
//                             child:
//                                 CircularProgressIndicator(
//                               strokeWidth: 2.5,
//                               color:
//                                   Colors.white,
//                             ),
//                           )
//                         : const Text(
//                             "Save Card",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight:
//                                   FontWeight.w700,
//                             ),
//                           ),
//                   ),
//                 ),

//                 const SizedBox(height: 14),

//                 const Center(
//                   child: Text(
//                     "🔒 Secure payment",
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.black45,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }