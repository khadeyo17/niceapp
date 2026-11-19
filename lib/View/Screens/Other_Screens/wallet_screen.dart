import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Other_Screens/card_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double walletBalance = 0.0;
  bool isLoading = true;
  //List transactions = [];
  List<WalletTransaction> transactions = [];


  bool _isMobileMoneyPayment(String? paymentMethod) {
  if (paymentMethod == null) {
    return false;
  }

  final method = paymentMethod
      .trim()
      .toLowerCase();

  return method.contains('mpesa') ||
      method.contains('m-pesa') ||
      method.contains('airtel');
}



  @override
  void initState() {
    super.initState();
    fetchWalletData();
  }
  // Future<void> fetchWalletData() async {
  //   setState(() => isLoading = true);
  //   try {
  //     final balanceRes = await http.get(Uri.parse("$baseUrl/wallet/balance"));
  //     final txnRes = await http.get(Uri.parse("$baseUrl/wallet/transactions"));

  //     if (balanceRes.statusCode == 200 && txnRes.statusCode == 200) {
  //       final balanceData = jsonDecode(balanceRes.body);
  //       final txnData = jsonDecode(txnRes.body);

  //       setState(() {
  //         walletBalance = balanceData['balance'] ?? 0.0;
  //         transactions = txnData['transactions'] ?? [];
  //       });
  //     } else {
  //       debugPrint("Failed to load wallet data");
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching wallet data: $e");
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  Future<void> fetchWalletData() async {
  if (!mounted) return;

  setState(() {
    isLoading = true;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("No Firebase user found.");

      if (!mounted) return;

      setState(() {
        walletBalance = 0.0;
        transactions = [];
      });

      return;
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      debugPrint("Firebase token is empty.");

      return;
    }

    final url = Uri.parse(
      '${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}'
      'wallet/transactions?limit=5',
    );

    debugPrint("Wallet URL: $url");

    final txnRes = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint(
      "Wallet transactions status: "
      "${txnRes.statusCode}",
    );

    debugPrint(
      "Wallet transactions response: "
      "${txnRes.body}",
    );

    if (txnRes.statusCode == 200) {
      final txnData =
          jsonDecode(txnRes.body);

      final balanceValue =
          txnData['walletBalance'];

      final balance =
          balanceValue is num
              ? balanceValue.toDouble()
              : double.tryParse(
                    balanceValue?.toString() ?? '0',
                  ) ??
                  0.0;

      final transactionData =
          txnData['transactions'];

      final loadedTransactions =
          transactionData is List
              ? transactionData
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (item) =>
                        WalletTransaction.fromJson(item),
                  )
                  .toList()
              : <WalletTransaction>[];

      if (!mounted) return;

      setState(() {
        walletBalance = balance;
        transactions = loadedTransactions;
      });
    } else {
      debugPrint(
        "Failed to load wallet data: "
        "${txnRes.body}",
      );

      if (!mounted) return;

      setState(() {
        walletBalance = 0.0;
        transactions = [];
      });
    }
  } catch (e, stackTrace) {
    debugPrint(
      "Error fetching wallet data: $e",
    );

    debugPrint(
      stackTrace.toString(),
    );
  } finally {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}


  // Future<void> addMoney() async {
  //   double? selectedAmount;
  //   final amountController = TextEditingController();
  //   final phoneController = TextEditingController();
  //   List<Map<String, dynamic>> paymentModesData = [];
  //   String? selectedPaymentMode;
  //   int? selectedPaymentModeId;

  //   // Fetch payment modes from backend
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     final idToken = await user?.getIdToken();

  //     final response = await http.get(
  //       Uri.parse('$baseUrl/payments/modes'),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $idToken",
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       paymentModesData = List<Map<String, dynamic>>.from(
  //         data['paymentModes'] ?? [],
  //       );
  //       if (paymentModesData.isNotEmpty) {
  //         selectedPaymentMode = paymentModesData[0]['name'];
  //         selectedPaymentModeId = paymentModesData[0]['id'];
  //         // If mobile money, autopopulate phone
  //         if (selectedPaymentMode!.toLowerCase().contains('mpesa') ||
  //             selectedPaymentMode!.toLowerCase().contains('airtel')) {
  //           phoneController.text = user?.phoneNumber ?? '';
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('Failed to fetch payment modes: $e');
  //   }

  //   await showDialog(
  //     context: context,
  //     builder:
  //         (_) => StatefulBuilder(
  //           builder:
  //               (context, setState) => AlertDialog(
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 title: const Text(
  //                   "Add Money",
  //                   style: TextStyle(fontWeight: FontWeight.bold),
  //                 ),
  //                 content: SingleChildScrollView(
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       const Text("Select an amount or enter custom"),
  //                       const SizedBox(height: 12),

  //                       // Preset amounts
  //                       Wrap(
  //                         spacing: 10,
  //                         children:
  //                             [100, 500, 1000, 2000].map((amount) {
  //                               final isSelected = selectedAmount == amount;
  //                               return ChoiceChip(
  //                                 label: Text("Ksh $amount"),
  //                                 selected: isSelected,
  //                                 onSelected: (_) {
  //                                   setState(
  //                                     () => selectedAmount = amount.toDouble(),
  //                                   );
  //                                   amountController.text = amount.toString();
  //                                 },
  //                                 selectedColor: Colors.blueAccent,
  //                                 labelStyle: TextStyle(
  //                                   color:
  //                                       isSelected
  //                                           ? Colors.white
  //                                           : Colors.black,
  //                                   fontWeight: FontWeight.bold,
  //                                 ),
  //                               );
  //                             }).toList(),
  //                       ),

  //                       const SizedBox(height: 12),
  //                       TextField(
  //                         controller: amountController,
  //                         keyboardType: TextInputType.number,
  //                         decoration: const InputDecoration(
  //                           labelText: "Custom Amount",
  //                           border: OutlineInputBorder(),
  //                         ),
  //                         onChanged:
  //                             (val) => selectedAmount = double.tryParse(val),
  //                       ),
  //                       const SizedBox(height: 12),

  //                       // Payment Mode Dropdown
  //                       DropdownButtonFormField<String>(
  //                         value: selectedPaymentMode,
  //                         items:
  //                             paymentModesData
  //                                 .map(
  //                                   (mode) => DropdownMenuItem<String>(
  //                                     value: mode['name'],
  //                                     child: Text(mode['name']),
  //                                   ),
  //                                 )
  //                                 .toList(),
  //                         onChanged: (val) {
  //                           setState(() {
  //                             selectedPaymentMode = val;
  //                             // Auto-fill phone if mobile money
  //                             if (val!.toLowerCase().contains('mpesa') ||
  //                                 val.toLowerCase().contains('airtel')) {
  //                               phoneController.text =
  //                                   FirebaseAuth
  //                                       .instance
  //                                       .currentUser
  //                                       ?.phoneNumber ??
  //                                   '';
  //                             } else {
  //                               phoneController.clear();
  //                             }
  //                           });
  //                         },
  //                         decoration: const InputDecoration(
  //                           labelText: "Payment Method",
  //                           border: OutlineInputBorder(),
  //                         ),
  //                       ),

  //                       const SizedBox(height: 12),

  //                       // Phone input for mobile money
  //                       if (selectedPaymentMode != null &&
  //                           (selectedPaymentMode!.toLowerCase().contains(
  //                                 'mpesa',
  //                               ) ||
  //                               selectedPaymentMode!.toLowerCase().contains(
  //                                 'airtel',
  //                               )))
  //                         TextField(
  //                           controller: phoneController,
  //                           keyboardType: TextInputType.phone,
  //                           decoration: const InputDecoration(
  //                             labelText: "Phone Number",
  //                             border: OutlineInputBorder(),
  //                           ),
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //                 actions: [
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: const Text("Cancel"),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: () async {
  //                       if (selectedAmount == null || selectedAmount! <= 0)
  //                         return;
  //                       final user = FirebaseAuth.instance.currentUser;
  //                       final idToken = await user?.getIdToken();

  //                       final body = {
  //                         "amount": selectedAmount,
  //                         "paymentModeId": selectedPaymentModeId,
  //                         if (phoneController.text.isNotEmpty)
  //                           "phone": phoneController.text,
  //                       };

  //                       final res = await http.post(
  //                         Uri.parse("$baseUrl/wallet/add-money"),
  //                         headers: {
  //                           "Content-Type": "application/json",
  //                           "Authorization": "Bearer $idToken",
  //                         },
  //                         body: jsonEncode(body),
  //                       );

  //                       if (res.statusCode == 200) {
  //                         Navigator.pop(context);
  //                         fetchWalletData();
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(
  //                             content: Text(
  //                               "Ksh ${selectedAmount!.toStringAsFixed(0)} added successfully",
  //                             ),
  //                           ),
  //                         );
  //                       } else {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(
  //                             content: Text("Failed to add money"),
  //                           ),
  //                         );
  //                       }
  //                     },
  //                     child: const Text("Add"),
  //                   ),
  //                 ],
  //               ),
  //         ),
  //   );
  // }

Future<void> addMoney(String paymentMethod) async {
  double? selectedAmount;

  final amountController = TextEditingController();
  final phoneController = TextEditingController();

  bool isProcessing = false;
  String? errorMessage;

  // -----------------------------------------
  // Firebase user
  // -----------------------------------------
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    if (!mounted) return;

    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please sign in before adding money.',
        ),
      ),
    );

    return;
  }

  // -----------------------------------------
  // Get Firebase token
  // -----------------------------------------
  final idToken = await user.getIdToken();

  if (idToken == null || idToken.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(
        content: Text(
          'Authentication failed. Please sign in again.',
        ),
      ),
    );

    return;
  }

  // -----------------------------------------
  // Payment method
  // -----------------------------------------
  final normalizedPaymentMethod =
      paymentMethod.trim();

  final bool isMobileMoney =
      _isMobileMoneyPayment(
    normalizedPaymentMethod,
  );

  // Automatically populate phone
  if (isMobileMoney) {
    phoneController.text =
        user.phoneNumber ?? '';
  }

  if (!mounted) return;

  // -----------------------------------------
  // Show premium dialog
  // -----------------------------------------
  await showDialog(
    context: this.context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          dialogContext,
          setState,
        ) {
          return Dialog(
            backgroundColor: Colors.transparent,

            insetPadding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),

            child: Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 460,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.14),
                    blurRadius: 35,
                    offset:
                        const Offset(0, 15),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(30),

                child:
                    SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      22,
                      22,
                      22,
                      20,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        // =====================================
                        // HEADER
                        // =====================================

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Container(
                              width: 54,
                              height: 54,

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFFFF7D6,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .account_balance_wallet_rounded,
                                color:
                                    Color(
                                  0xFFF0D000,
                                ),
                                size: 28,
                              ),
                            ),

                            const SizedBox(
                              width: 14,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    'Add Money',
                                    style:
                                        GoogleFonts
                                            .spaceGrotesk(
                                      fontSize:
                                          21,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color:
                                          Colors
                                              .black,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    'Top up your AMiNi wallet',
                                    style:
                                        GoogleFonts
                                            .nunitoSans(
                                      fontSize:
                                          13,
                                      color: Colors
                                          .grey
                                          .shade600,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ---------------------------------
                            // CLOSE
                            // ---------------------------------

                            InkWell(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),

                              onTap:
                                  isProcessing
                                      ? null
                                      : () {
                                          Navigator.of(
                                            dialogContext,
                                          ).pop();
                                        },

                              child:
                                  Container(
                                width: 38,
                                height: 38,

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .grey
                                      .shade100,
                                  shape:
                                      BoxShape
                                          .circle,
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .close_rounded,
                                  size: 20,
                                  color: Colors
                                      .black54,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // =====================================
                        // PAYMENT METHOD
                        // =====================================

                        Text(
                          'Payment method',
                          style:
                              GoogleFonts
                                  .spaceGrotesk(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Colors.black87,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.grey
                                    .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                            border:
                                Border.all(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                          ),

                          child: Row(
                            children: [

                              Container(
                                width: 40,
                                height: 40,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),

                                child:
                                    normalizedPaymentMethod
                                            .toLowerCase()
                                            .contains(
                                              'mpesa',
                                            )
                                        ? Image.asset(
                                            "assets/imgs/mpesa.png",
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit
                                                .contain,
                                          )
                                        : Image.asset(
                                            "assets/imgs/airtel.png",
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit
                                                .contain,
                                          ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(
                                      normalizedPaymentMethod,
                                      style: GoogleFonts
                                          .spaceGrotesk(
                                        fontSize:
                                            14,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: Colors
                                            .black,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 2,
                                    ),

                                    Text(
                                      'Top up using $normalizedPaymentMethod',
                                      style: GoogleFonts
                                          .nunitoSans(
                                        fontSize:
                                            12,
                                        color: Colors
                                            .grey
                                            .shade600,
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons
                                    .check_circle_rounded,
                                color:
                                    Color(
                                  0xFF015ACE,
                                ),
                                size: 21,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // =====================================
                        // AMOUNT
                        // =====================================

                        Text(
                          'How much would you like to add?',
                          style:
                              GoogleFonts
                                  .spaceGrotesk(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Colors.black87,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,

                          children: [
                            100,
                            500,
                            1000,
                            2000,
                          ].map(
                            (amount) {

                              final bool selected =
                                  selectedAmount ==
                                      amount
                                          .toDouble();

                              return
                                  GestureDetector(
                                onTap:
                                    isProcessing
                                        ? null
                                        : () {
                                            setState(
                                              () {
                                                selectedAmount =
                                                    amount.toDouble();

                                                amountController
                                                        .text =
                                                    amount.toString();

                                                errorMessage =
                                                    null;
                                              },
                                            );
                                          },

                                child:
                                    AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds:
                                        180,
                                  ),

                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        16,
                                    vertical:
                                        11,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color: selected
                                        ? const Color(
                                            0xFFF0D000,
                                          )
                                        : Colors
                                            .white,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),

                                    border:
                                        Border.all(
                                      color: selected
                                          ? const Color(
                                              0xFFF0D000,
                                            )
                                          : Colors
                                              .grey
                                              .shade300,
                                      width: selected
                                          ? 1.5
                                          : 1,
                                    ),
                                  ),

                                  child: Text(
                                    'KES $amount',
                                    style:
                                        GoogleFonts
                                            .spaceGrotesk(
                                      fontSize:
                                          13,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color:
                                          Colors
                                              .black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // =====================================
                        // CUSTOM AMOUNT
                        // =====================================

                        TextField(
                          controller:
                              amountController,

                          enabled:
                              !isProcessing,

                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),

                          style:
                              GoogleFonts
                                  .spaceGrotesk(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),

                          decoration:
                              InputDecoration(
                            labelText:
                                'Custom Amount',

                            prefixText:
                                'KES ',

                            prefixStyle:
                                GoogleFonts
                                    .spaceGrotesk(
                              fontWeight:
                                  FontWeight.w700,
                              color: Colors
                                  .black87,
                            ),

                            labelStyle:
                                GoogleFonts
                                    .nunitoSans(
                              color: Colors
                                  .grey
                                  .shade600,
                            ),

                            filled: true,

                            fillColor:
                                Colors.grey
                                    .shade50,

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                              borderSide:
                                  BorderSide(
                                color: Colors
                                    .grey
                                    .shade300,
                              ),
                            ),

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                              borderSide:
                                  BorderSide(
                                color: Colors
                                    .grey
                                    .shade300,
                              ),
                            ),

                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xFF015ACE,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),

                          onChanged:
                              (value) {

                            final amount =
                                double.tryParse(
                              value,
                            );

                            setState(() {
                              selectedAmount =
                                  amount;

                              errorMessage =
                                  null;
                            });
                          },
                        ),

                        // =====================================
                        // PHONE NUMBER
                        // =====================================

                        if (isMobileMoney) ...[
                          const SizedBox(
                            height: 20,
                          ),

                          Text(
                            'Phone Number',
                            style: GoogleFonts
                                .spaceGrotesk(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  Colors.black87,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          TextField(
                            controller:
                                phoneController,

                            enabled:
                                !isProcessing,

                            keyboardType:
                                TextInputType
                                    .phone,

                            style: GoogleFonts
                                .spaceGrotesk(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),

                            decoration:
                                InputDecoration(
                              hintText:
                                  'e.g. 0712345678',

                              prefixIcon:
                                  const Icon(
                                Icons
                                    .phone_outlined,
                                color:
                                    Color(
                                  0xFF015ACE,
                                ),
                              ),

                              filled: true,

                              fillColor:
                                  Colors.grey
                                      .shade50,

                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    BorderSide(
                                  color: Colors
                                      .grey
                                      .shade300,
                                ),
                              ),

                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    BorderSide(
                                  color: Colors
                                      .grey
                                      .shade300,
                                ),
                              ),

                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(
                                    0xFF015ACE,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),

                            onChanged: (_) {
                              if (errorMessage !=
                                  null) {
                                setState(() {
                                  errorMessage =
                                      null;
                                });
                              }
                            },
                          ),
                        ],

                        // =====================================
                        // ERROR INSIDE DIALOG
                        // =====================================

                        if (errorMessage != null) ...[
                          const SizedBox(
                            height: 16,
                          ),

                          Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets
                                    .all(13),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFFF7D6,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),

                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFFF0D000,
                                ),
                              ),
                            ),

                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                const Icon(
                                  Icons
                                      .info_outline_rounded,
                                  size: 20,
                                  color:
                                      Colors.black87,
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style:
                                        GoogleFonts
                                            .nunitoSans(
                                      fontSize:
                                          13,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      color: Colors
                                          .black87,
                                      height:
                                          1.4,
                                    ),
                                  ),
                                ),

                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      errorMessage =
                                          null;
                                    });
                                  },

                                  child:
                                      const Icon(
                                    Icons
                                        .close_rounded,
                                    size: 18,
                                    color:
                                        Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 22,
                        ),

                        // =====================================
                        // ADD BUTTON
                        // =====================================

                        SizedBox(
                          width:
                              double.infinity,
                          height: 54,

                          child:
                              ElevatedButton(
                            onPressed:
                                isProcessing ||
                                        selectedAmount ==
                                            null ||
                                        selectedAmount! <=
                                            0
                                    ? null
                                    : () async {

                                        // -----------------------------
                                        // Validate amount
                                        // -----------------------------

                                        if (selectedAmount ==
                                                null ||
                                            selectedAmount! <=
                                                0) {

                                          setState(() {
                                            errorMessage =
                                                'Please enter a valid amount.';
                                          });

                                          return;
                                        }

                                        // -----------------------------
                                        // Validate phone
                                        // -----------------------------

                                        if (isMobileMoney &&
                                            phoneController
                                                .text
                                                .trim()
                                                .isEmpty) {

                                          setState(() {
                                            errorMessage =
                                                'Please enter your phone number.';
                                          });

                                          return;
                                        }

                                        setState(() {
                                          isProcessing =
                                              true;
                                          errorMessage =
                                              null;
                                        });

                                        try {

                                          final currentUser =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser;

                                          if (currentUser ==
                                              null) {
                                            throw Exception(
                                              'User is not authenticated.',
                                            );
                                          }

                                          final token =
                                              await currentUser
                                                  .getIdToken();

                                          if (token ==
                                                  null ||
                                              token
                                                  .isEmpty) {
                                            throw Exception(
                                              'Authentication token is unavailable.',
                                            );
                                          }

                                          // -----------------------------------------
                                          // Request body
                                          // -----------------------------------------

                                          final body = {
                                            'amount':
                                                selectedAmount,

                                            'paymentMethod':
                                                normalizedPaymentMethod,

                                            if (phoneController
                                                .text
                                                .trim()
                                                .isNotEmpty)
                                              'phone':
                                                  phoneController
                                                      .text
                                                      .trim(),
                                          };

                                          debugPrint(
                                            'Add Money Body: '
                                            '${jsonEncode(body)}',
                                          );

                                          final url =
                                              Uri.parse(
                                            '${baseUrl}/wallet/add-money',
                                          );

                                          debugPrint(
                                            'Add Money URL: '
                                            '$url',
                                          );

                                          // -----------------------------------------
                                          // POST
                                          // -----------------------------------------

                                          final response =
                                              await http.post(
                                            url,

                                            headers: {
                                              'Accept':
                                                  'application/json',

                                              'Content-Type':
                                                  'application/json',

                                              'Authorization':
                                                  'Bearer $token',
                                            },

                                            body:
                                                jsonEncode(
                                              body,
                                            ),
                                          );

                                          debugPrint(
                                            'Add Money Status: '
                                            '${response.statusCode}',
                                          );

                                          debugPrint(
                                            'Add Money Response: '
                                            '${response.body}',
                                          );

                                          // =========================================
                                          // SUCCESS
                                          // =========================================

                                          if (response
                                                  .statusCode ==
                                              200) {

                                            if (!context
                                                .mounted) {
                                              return;
                                            }

                                            Navigator.of(
                                              dialogContext,
                                            ).pop(
                                              true,
                                            );

                                            return;
                                          }

                                          // =========================================
                                          // BACKEND ERROR
                                          // =========================================

                                          String message =
                                              'Failed to add money.';

                                          try {

                                            final errorData =
                                                jsonDecode(
                                              response.body,
                                            );

                                            if (errorData
                                                is Map) {

                                              message =
                                                  errorData[
                                                              'message']
                                                          ?.toString() ??
                                                      errorData[
                                                              'Message']
                                                          ?.toString() ??
                                                      errorData[
                                                              'error']
                                                          ?.toString() ??
                                                      errorData[
                                                              'title']
                                                          ?.toString() ??
                                                      message;
                                            }

                                          } catch (_) {
                                            // Keep default
                                          }

                                          if (!context
                                              .mounted) {
                                            return;
                                          }

                                          setState(() {
                                            isProcessing =
                                                false;
                                            errorMessage =
                                                message;
                                          });

                                        } catch (e) {

                                          debugPrint(
                                            'Add money error: '
                                            '$e',
                                          );

                                          if (!context
                                              .mounted) {
                                            return;
                                          }

                                          setState(() {
                                            isProcessing =
                                                false;

                                            errorMessage =
                                                'Unable to process your request. Please check your details and try again.';
                                          });
                                        }
                                      },

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF015ACE,
                              ),

                              disabledBackgroundColor:
                                  Colors.grey
                                      .shade300,

                              foregroundColor:
                                  Colors.white,

                              elevation: 0,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                            ),

                            child:
                                isProcessing
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,

                                        children: [

                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  Colors.white,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 10,
                                          ),

                                          Text(
                                            'Processing...',
                                            style:
                                                GoogleFonts
                                                    .spaceGrotesk(
                                              fontSize:
                                                  15,
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                              color:
                                                  Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Add Money',
                                        style:
                                            GoogleFonts
                                                .spaceGrotesk(
                                          fontSize:
                                              15,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          color:
                                              Colors.white,
                                        ),
                                      ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // =====================================
                        // SECURE NOTE
                        // =====================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [

                            Icon(
                              Icons
                                  .lock_outline_rounded,
                              size: 14,
                              color:
                                  Colors.grey
                                      .shade500,
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Text(
                              'Secure wallet funding',
                              style:
                                  GoogleFonts
                                      .nunitoSans(
                                fontSize: 11,
                                color: Colors
                                    .grey
                                    .shade500,
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // amountController.dispose();
  // phoneController.dispose();
}







 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),

    appBar: AppBar(
      title: Text(
        'My Wallet',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),

    body: isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF015ACE),
            ),
          )
        : RefreshIndicator(
            color: const Color(0xFF015ACE),
            onRefresh: fetchWalletData,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =====================================================
                  // AMINI BALANCE
                  // =====================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF015ACE),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF015ACE)
                              .withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons
                                    .account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Text(
                              "AMINI Balance",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),

                            const Spacer(),

                            IconButton(
                              onPressed: fetchWalletData,
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        Text(
                          "Ksh ${walletBalance.toStringAsFixed(2)}",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Available balance",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // PAYMENT METHODS
                  // =====================================================

                  Text(
                    "Payment Methods",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Choose how you'd like to top up your AMINI Balance.",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 16),


_buildWalletPaymentMethod(
  title: "M-Pesa",
  subtitle: "Top up using M-Pesa",
  logo: Image.asset(
    "assets/imgs/mpesa.png",
    width: 34,
    height: 34,
    fit: BoxFit.contain,
  ),
  onTap: () => addMoney("M-Pesa"),
),

const SizedBox(height: 10),

_buildWalletPaymentMethod(
  title: "Airtel Money",
  subtitle: "Top up using Airtel Money",
  logo: Image.asset(
    "assets/imgs/airtel.png",
    width: 34,
    height: 34,
    fit: BoxFit.contain,
  ),
  onTap: () => addMoney("Airtel Money"),
),


                  const SizedBox(height: 10),

                  // =====================================================
                  // DEBIT / CREDIT CARD
                  // =====================================================

                  _buildWalletPaymentMethod(
                    title: "Debit / Credit Card",
                    subtitle:
                        "Visa, Mastercard and other cards",
                    logo: const Icon(
                      Icons.credit_card_rounded,
                      size: 32,
                      color: Color(0xFF015ACE),
                    ),
                    showArrow: true,
                    onTap: () {
                      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddCardScreen(
      baseUrl: baseUrl,
    ),
  ),
);
                    },
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // CASH - DISABLED
                  // =====================================================

                  _buildWalletPaymentMethod(
                    title: "Cash",
                    subtitle:
                        "Cash cannot be used to top up your wallet",
                    logo: const Icon(
                      Icons.payments_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                    enabled: false,
                  ),

                  const SizedBox(height: 16),



                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 54,
                  //   child: ElevatedButton.icon(
                  //     onPressed: addMoney,
                  //     icon: const Icon(
                  //       Icons.add_rounded,
                  //     ),
                  //     label: Text(
                  //       "Add Funds",
                  //       style: GoogleFonts.spaceGrotesk(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w700,
                  //       ),
                  //     ),

                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor:
                  //           const Color(0xFF015ACE),
                  //       foregroundColor: Colors.white,
                  //       elevation: 0,

                  //       shape:
                  //           RoundedRectangleBorder(
                  //         borderRadius:
                  //             BorderRadius.circular(14),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  // const SizedBox(height: 28),

                  // =====================================================
                  // VOUCHER
                  // =====================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF015ACE,
                                ).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons
                                    .confirmation_number_outlined,
                                color: Color(0xFF015ACE),
                                size: 21,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Text(
                              "Have a voucher?",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Enter your voucher code to add funds to your AMINI Balance.",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [

                            Expanded(
                              child: TextField(
                                textCapitalization:
                                    TextCapitalization
                                        .characters,

                                decoration:
                                    InputDecoration(
                                  hintText:
                                      "Voucher code",

                                  hintStyle:
                                      GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    color:
                                        Colors.black38,
                                  ),

                                  filled: true,
                                  fillColor:
                                      const Color(
                                    0xFFF7F7F7,
                                  ),

                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(12),
                                    borderSide:
                                        BorderSide.none,
                                  ),

                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 14,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            SizedBox(
                              height: 50,

                              child:
                                  ElevatedButton(
                                onPressed: () {
                                  // TODO:
                                  // Connect this to your
                                  // voucher API.
                                },

                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      const Color(
                                    0xFF015ACE,
                                  ),
                                  foregroundColor:
                                      Colors.white,
                                  elevation: 0,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(12),
                                  ),
                                ),

                                child: Text(
                                  "Apply",
                                  style:
                                      GoogleFonts
                                          .spaceGrotesk(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =====================================================
                  // TRANSACTION HISTORY
                  // =====================================================

                 Text(
  "Transaction History",
  style: GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
),

const SizedBox(height: 14),
const SizedBox(height: 14),

if (transactions.isEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 42,
          color: Colors.grey,
        ),

        const SizedBox(height: 10),

        Text(
          "No transactions yet.",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    ),
  )
else
  Column(
    children: transactions
        .map(
          (transaction) => _buildTransactionItem(transaction),
        )
        .toList(),
  ),



             
                ],
              ),
            ),
          ),
  );
}

Widget _buildTransactionItem(WalletTransaction transaction) {
  final bool isCredit = transaction.amount >= 0;

  final String amountText =
      '${isCredit ? '+' : '-'} KES ${transaction.amount.abs().toStringAsFixed(2)}';

  final String dateText = transaction.date == null
      ? ''
      : '${transaction.date!.day.toString().padLeft(2, '0')}/'
        '${transaction.date!.month.toString().padLeft(2, '0')}/'
        '${transaction.date!.year} • '
        '${transaction.date!.hour.toString().padLeft(2, '0')}:'
        '${transaction.date!.minute.toString().padLeft(2, '0')}';

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCredit
                ? Colors.green.withOpacity(0.10)
                : Colors.grey.withOpacity(0.10),
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isCredit
                ? Colors.green
                : Colors.black87,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.purpose,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                transaction.transactionRef.isEmpty
                    ? dateText
                    : '${transaction.transactionRef} • $dateText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Text(
          amountText,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isCredit
                ? Colors.green
                : Colors.black,
          ),
        ),
      ],
    ),
  );
}
Widget _buildWalletPaymentMethod({
  required String title,
  required String subtitle,
  required Widget logo,
  VoidCallback? onTap,
  bool enabled = true,
  bool showArrow = false,
}) {
  return InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(16),

    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: enabled
            ? Colors.white
            : const Color(0xFFF1F1F1),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFF5F7FA)
                  : Colors.grey.shade200,

              borderRadius:
                  BorderRadius.circular(12),
            ),

            alignment: Alignment.center,

            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: logo,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: enabled
                        ? Colors.black54
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),


          if (!enabled)
            const Icon(
              Icons.lock_outline,
              size: 20,
              color: Colors.grey,
            )
          else if (showArrow)
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Colors.black45,
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Colors.black45,
            ),
        ],
      ),
    ),
  );
}
}


class WalletTransaction {
  final DateTime? date;
  final String transactionRef;
  final String purpose;
  final double amount;

  WalletTransaction({
    required this.date,
    required this.transactionRef,
    required this.purpose,
    required this.amount,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      transactionRef: json['transactionRef']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? 'Transaction',
      amount: _toDouble(json['amount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool get isCredit => amount >= 0;
  bool get isDebit => amount < 0;
}
                      // Wallet Balance Card
                      // Container(
                      //   width: double.infinity,
                      //   padding: const EdgeInsets.all(24),
                      //   decoration: BoxDecoration(
                      //     gradient: const LinearGradient(
                      //       colors: [Colors.blueAccent, Colors.lightBlue],
                      //       begin: Alignment.topLeft,
                      //       end: Alignment.bottomRight,
                      //     ),
                      //     borderRadius: BorderRadius.circular(20),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.blueAccent.withOpacity(0.3),
                      //         blurRadius: 12,
                      //         offset: const Offset(0, 6),
                      //       ),
                      //     ],
                      //   ),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       const Text(
                      //         "Wallet Balance",
                      //         style: TextStyle(
                      //           color: Colors.white70,
                      //           fontSize: 16,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 8),
                      //       Text(
                      //         "Ksh ${walletBalance.toStringAsFixed(2)}",
                      //         style: const TextStyle(
                      //           fontSize: 32,
                      //           fontWeight: FontWeight.bold,
                      //           color: Colors.white,
                      //         ),
                      //       ),
                      //       Align(
                      //         alignment: Alignment.topRight,
                      //         child: IconButton(
                      //           icon: const Icon(
                      //             Icons.refresh,
                      //             color: Colors.white,
                      //           ),
                      //           onPressed: fetchWalletData,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
  // Future<void> addMoney() async {
  //   final amountController = TextEditingController();
  //   await showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text("Add Money"),
  //           content: TextField(
  //             controller: amountController,
  //             keyboardType: TextInputType.number,
  //             decoration: const InputDecoration(
  //               labelText: "Amount (Ksh)",
  //               border: OutlineInputBorder(),
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text("Cancel"),
  //             ),
  //             ElevatedButton(
  //               onPressed: () async {
  //                 final amount = double.tryParse(amountController.text);
  //                 if (amount != null && amount > 0) {
  //                   final res = await http.post(
  //                     Uri.parse("$baseUrl/wallet/add-money"),
  //                     headers: {"Content-Type": "application/json"},
  //                     body: jsonEncode({"amount": amount}),
  //                   );
  //                   if (res.statusCode == 200) {
  //                     Navigator.pop(context);
  //                     fetchWalletData();
  //                   }
  //                 }
  //               },
  //               child: const Text("Add"),
  //             ),
  //           ],
  //         ),
  //   );
  // }

// // ignore: file_names
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class WalletScreen extends StatefulWidget {
//   const WalletScreen({super.key});

//   @override
//   _WalletScreenState createState() => _WalletScreenState();
// }

// class _WalletScreenState extends State<WalletScreen> {
//   double walletBalance = 0.0;
//   bool isLoading = true;
//   List transactions = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchWalletData();
//   }

//   Future<void> fetchWalletData() async {
//     setState(() => isLoading = true);
//     try {
//       final balanceRes = await http.get(
//         Uri.parse("https://api.example.com/wallet/balance"),
//       );
//       final txnRes = await http.get(
//         Uri.parse("https://api.example.com/wallet/transactions"),
//       );

//       if (balanceRes.statusCode == 200 && txnRes.statusCode == 200) {
//         final balanceData = jsonDecode(balanceRes.body);
//         final txnData = jsonDecode(txnRes.body);

//         setState(() {
//           walletBalance = balanceData['balance'] ?? 0.0;
//           transactions = txnData['transactions'] ?? [];
//         });
//       }
//     } catch (e) {
//       debugPrint("Error fetching wallet data: $e");
//     }
//     setState(() => isLoading = false);
//   }

//   Future<void> addMoney() async {
//     // Example: Add Ksh 1000
//     final res = await http.post(
//       Uri.parse("https://api.example.com/wallet/add-money"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"amount": 1000}),
//     );

//     if (res.statusCode == 200) {
//       fetchWalletData(); // refresh
//     }
//   }

//   Future<void> withdrawMoney() async {
//     // Example: Withdraw Ksh 500
//     final res = await http.post(
//       Uri.parse("https://api.example.com/wallet/withdraw"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"amount": 500}),
//     );

//     if (res.statusCode == 200) {
//       fetchWalletData(); // refresh
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('My Wallet'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black,
//       ),
//       body:
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : RefreshIndicator(
//                 onRefresh: fetchWalletData,
//                 child: SingleChildScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Wallet Balance Card
//                       Container(
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Colors.blueAccent, Colors.lightBlue],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.blueAccent.withOpacity(0.3),
//                               blurRadius: 12,
//                               offset: const Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Wallet Balance",
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               "Ksh ${walletBalance.toStringAsFixed(2)}",
//                               style: const TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             Align(
//                               alignment: Alignment.topRight,
//                               child: IconButton(
//                                 icon: const Icon(
//                                   Icons.refresh,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: fetchWalletData,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       // Action Buttons
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton.icon(
//                             onPressed: addMoney,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             icon: const Icon(Icons.add_circle),
//                             label: const Text("Add Money"),
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: withdrawMoney,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.redAccent,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             icon: const Icon(Icons.remove_circle),
//                             label: const Text("Withdraw"),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 32),

//                       const Text(
//                         "Transaction History",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 12),

//                       transactions.isEmpty
//                           ? const Center(
//                             child: Text(
//                               "No transactions yet.",
//                               style: TextStyle(color: Colors.black54),
//                             ),
//                           )
//                           : ListView.separated(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             itemCount: transactions.length,
//                             separatorBuilder:
//                                 (_, __) => Divider(color: Colors.grey[300]),
//                             itemBuilder: (context, index) {
//                               final txn = transactions[index];
//                               final isCredit = txn['type'] == 'credit';
//                               return ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor:
//                                       isCredit
//                                           ? Colors.green[100]
//                                           : Colors.red[100],
//                                   child: Icon(
//                                     isCredit
//                                         ? Icons.arrow_downward
//                                         : Icons.arrow_upward,
//                                     color: isCredit ? Colors.green : Colors.red,
//                                   ),
//                                 ),
//                                 title: Text(txn['description']),
//                                 subtitle: Text(txn['date']),
//                                 trailing: Text(
//                                   "${isCredit ? '+' : '-'} Ksh ${txn['amount']}",
//                                   style: TextStyle(
//                                     color: isCredit ? Colors.green : Colors.red,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }
// }

// // // ignore: file_names
// // import 'package:flutter/material.dart';

// // class WalletScreen extends StatefulWidget {
// //   const WalletScreen({super.key});

// //   @override
// //   _WalletScreenState createState() => _WalletScreenState();
// // }

// // class _WalletScreenState extends State<WalletScreen> {
// //   double walletBalance = 5000.00; // Example balance

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         title: const Text('My Wallet'),
// //         centerTitle: true,
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         foregroundColor: Colors.black,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               'Wallet Balance',
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 10),
// //             Container(
// //               padding: const EdgeInsets.all(16.0),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(10),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black12,
// //                     blurRadius: 5,
// //                     spreadRadius: 2,
// //                   ),
// //                 ],
// //               ),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Text(
// //                     'Ksh ${walletBalance.toStringAsFixed(2)}',
// //                     style: const TextStyle(
// //                       fontSize: 20,
// //                       fontWeight: FontWeight.bold,
// //                       color: Colors.green,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.refresh, color: Colors.blue),
// //                     onPressed: () {
// //                       // TODO: Implement refresh wallet balance logic
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: () {
// //                 // TODO: Implement add money logic
// //               },
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.lightBlueAccent,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text('Add Money'),
// //             ),
// //             const SizedBox(height: 10),
// //             ElevatedButton(
// //               onPressed: () {
// //                 // TODO: Implement withdraw money logic
// //               },
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.orangeAccent,
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text('Withdraw Money'),
// //             ),
// //             const SizedBox(height: 20),
// //             const Text(
// //               'Transaction History',
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             Expanded(
// //               child: ListView(
// //                 children: const [
// //                   ListTile(
// //                     leading: Icon(Icons.arrow_downward, color: Colors.green),
// //                     title: Text('Received Ksh 2,000'),
// //                     subtitle: Text('March 30, 2025'),
// //                     trailing: Text(
// //                       '+ Ksh 2,000',
// //                       style: TextStyle(color: Colors.green),
// //                     ),
// //                   ),
// //                   ListTile(
// //                     leading: Icon(Icons.arrow_upward, color: Colors.red),
// //                     title: Text('Paid for ride'),
// //                     subtitle: Text('March 28, 2025'),
// //                     trailing: Text(
// //                       '- Ksh 500',
// //                       style: TextStyle(color: Colors.red),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
