// ignore: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<void> fetchWalletData() async {
    setState(() => isLoading = true);
    try {
      final balanceRes = await http.get(
        Uri.parse("https://api.example.com/wallet/balance"),
      );
      final txnRes = await http.get(
        Uri.parse("https://api.example.com/wallet/transactions"),
      );

      if (balanceRes.statusCode == 200 && txnRes.statusCode == 200) {
        final balanceData = jsonDecode(balanceRes.body);
        final txnData = jsonDecode(txnRes.body);

        setState(() {
          walletBalance = balanceData['balance'] ?? 0.0;
          transactions = txnData['transactions'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet data: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> addMoney() async {
    // Example: Add Ksh 1000
    final res = await http.post(
      Uri.parse("https://api.example.com/wallet/add-money"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"amount": 1000}),
    );

    if (res.statusCode == 200) {
      fetchWalletData(); // refresh
    }
  }

  Future<void> withdrawMoney() async {
    // Example: Withdraw Ksh 500
    final res = await http.post(
      Uri.parse("https://api.example.com/wallet/withdraw"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"amount": 500}),
    );

    if (res.statusCode == 200) {
      fetchWalletData(); // refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
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

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: addMoney,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle),
                            label: const Text("Add Money"),
                          ),
                          ElevatedButton.icon(
                            onPressed: withdrawMoney,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.remove_circle),
                            label: const Text("Withdraw"),
                          ),
                        ],
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
                            child: Text(
                              "No transactions yet.",
                              style: TextStyle(color: Colors.black54),
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
                                title: Text(txn['description']),
                                subtitle: Text(txn['date']),
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
// import 'package:flutter/material.dart';

// class WalletScreen extends StatefulWidget {
//   const WalletScreen({super.key});

//   @override
//   _WalletScreenState createState() => _WalletScreenState();
// }

// class _WalletScreenState extends State<WalletScreen> {
//   double walletBalance = 5000.00; // Example balance

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('My Wallet'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Wallet Balance',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Container(
//               padding: const EdgeInsets.all(16.0),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 5,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Ksh ${walletBalance.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.refresh, color: Colors.blue),
//                     onPressed: () {
//                       // TODO: Implement refresh wallet balance logic
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Implement add money logic
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.lightBlueAccent,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Add Money'),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Implement withdraw money logic
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orangeAccent,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Withdraw Money'),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Transaction History',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Expanded(
//               child: ListView(
//                 children: const [
//                   ListTile(
//                     leading: Icon(Icons.arrow_downward, color: Colors.green),
//                     title: Text('Received Ksh 2,000'),
//                     subtitle: Text('March 30, 2025'),
//                     trailing: Text(
//                       '+ Ksh 2,000',
//                       style: TextStyle(color: Colors.green),
//                     ),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.arrow_upward, color: Colors.red),
//                     title: Text('Paid for ride'),
//                     subtitle: Text('March 28, 2025'),
//                     trailing: Text(
//                       '- Ksh 500',
//                       style: TextStyle(color: Colors.red),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
