import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double walletBalance = 0.0;
  bool isLoading = true;
  List transactions = [];

  @override
  void initState() {
    super.initState();
    fetchWalletData();
  }

  // Future<void> fetchPaymentModes() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     final idToken = await user?.getIdToken();

  //     final response = await http.get(
  //       Uri.parse('$baseUrl/payments/modes'),
  //       headers: {"Content-Type": "application/json"},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       // Parse as list of maps
  //       paymentModesData = List<Map<String, dynamic>>.from(
  //         data['paymentModes'] ?? [],
  //       );

  //       setState(() {
  //         if (paymentModesData.isNotEmpty) {
  //           selectedPaymentMode = paymentModesData[0]['name'];
  //           selectedPaymentModeId = paymentModesData[0]['id'];
  //         }
  //       });
  //     } else {
  //       print('Failed to fetch payment modes: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error fetching payment modes: $e');
  //   }
  // }

  Future<void> fetchWalletData() async {
    setState(() => isLoading = true);
    try {
      final balanceRes = await http.get(Uri.parse("$baseUrl/wallet/balance"));
      final txnRes = await http.get(Uri.parse("$baseUrl/wallet/transactions"));

      if (balanceRes.statusCode == 200 && txnRes.statusCode == 200) {
        final balanceData = jsonDecode(balanceRes.body);
        final txnData = jsonDecode(txnRes.body);

        setState(() {
          walletBalance = balanceData['balance'] ?? 0.0;
          transactions = txnData['transactions'] ?? [];
        });
      } else {
        debugPrint("Failed to load wallet data");
      }
    } catch (e) {
      debugPrint("Error fetching wallet data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

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

  Future<void> addMoney() async {
    double? selectedAmount;
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    List<Map<String, dynamic>> paymentModesData = [];
    String? selectedPaymentMode;
    int? selectedPaymentModeId;

    // Fetch payment modes from backend
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/payments/modes'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        paymentModesData = List<Map<String, dynamic>>.from(
          data['paymentModes'] ?? [],
        );
        if (paymentModesData.isNotEmpty) {
          selectedPaymentMode = paymentModesData[0]['name'];
          selectedPaymentModeId = paymentModesData[0]['id'];
          // If mobile money, autopopulate phone
          if (selectedPaymentMode!.toLowerCase().contains('mpesa') ||
              selectedPaymentMode!.toLowerCase().contains('airtel')) {
            phoneController.text = user?.phoneNumber ?? '';
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch payment modes: $e');
    }

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    "Add Money",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Select an amount or enter custom"),
                        const SizedBox(height: 12),

                        // Preset amounts
                        Wrap(
                          spacing: 10,
                          children:
                              [100, 500, 1000, 2000].map((amount) {
                                final isSelected = selectedAmount == amount;
                                return ChoiceChip(
                                  label: Text("Ksh $amount"),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(
                                      () => selectedAmount = amount.toDouble(),
                                    );
                                    amountController.text = amount.toString();
                                  },
                                  selectedColor: Colors.blueAccent,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 12),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Custom Amount",
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (val) => selectedAmount = double.tryParse(val),
                        ),
                        const SizedBox(height: 12),

                        // Payment Mode Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedPaymentMode,
                          items:
                              paymentModesData
                                  .map(
                                    (mode) => DropdownMenuItem<String>(
                                      value: mode['name'],
                                      child: Text(mode['name']),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedPaymentMode = val;
                              // Auto-fill phone if mobile money
                              if (val!.toLowerCase().contains('mpesa') ||
                                  val.toLowerCase().contains('airtel')) {
                                phoneController.text =
                                    FirebaseAuth
                                        .instance
                                        .currentUser
                                        ?.phoneNumber ??
                                    '';
                              } else {
                                phoneController.clear();
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: "Payment Method",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Phone input for mobile money
                        if (selectedPaymentMode != null &&
                            (selectedPaymentMode!.toLowerCase().contains(
                                  'mpesa',
                                ) ||
                                selectedPaymentMode!.toLowerCase().contains(
                                  'airtel',
                                )))
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Phone Number",
                              border: OutlineInputBorder(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedAmount == null || selectedAmount! <= 0)
                          return;
                        final user = FirebaseAuth.instance.currentUser;
                        final idToken = await user?.getIdToken();

                        final body = {
                          "amount": selectedAmount,
                          "paymentModeId": selectedPaymentModeId,
                          if (phoneController.text.isNotEmpty)
                            "phone": phoneController.text,
                        };

                        final res = await http.post(
                          Uri.parse("$baseUrl/wallet/add-money"),
                          headers: {
                            "Content-Type": "application/json",
                            "Authorization": "Bearer $idToken",
                          },
                          body: jsonEncode(body),
                        );

                        if (res.statusCode == 200) {
                          Navigator.pop(context);
                          fetchWalletData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Ksh ${selectedAmount!.toStringAsFixed(0)} added successfully",
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to add money"),
                            ),
                          );
                        }
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchWalletData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wallet Balance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Wallet Balance",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Ksh ${walletBalance.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                onPressed: fetchWalletData,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Add Money Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: addMoney,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle),
                          label: const Text(
                            "Add Money",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        "Transaction History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      transactions.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                "No transactions yet.",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder:
                                (_, __) => Divider(color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              final txn = transactions[index];
                              final isCredit = txn['type'] == 'credit';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isCredit
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isCredit ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(txn['description'] ?? ""),
                                subtitle: Text(txn['date'] ?? ""),
                                trailing: Text(
                                  "${isCredit ? '+' : '-'} Ksh ${txn['amount']}",
                                  style: TextStyle(
                                    color: isCredit ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
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
