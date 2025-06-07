// // ignore: file_names
// import 'package:flutter/material.dart';

// class PaymentScreen extends StatefulWidget {
//   const PaymentScreen({super.key});

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   final TextEditingController amountController = TextEditingController();
//   final TextEditingController transactionIdController = TextEditingController();
//   String selectedPaymentMethod = 'M-Pesa';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       appBar: AppBar(
//         title: const Text('Payments'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Make a Payment',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             TextFormField(
//               controller: amountController,
//               decoration: const InputDecoration(labelText: 'Amount (Ksh)'),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 10),
//             const Text('Select Payment Method:'),
//             DropdownButtonFormField<String>(
//               value: selectedPaymentMethod,
//               items:
//                   [
//                         'M-Pesa',
//                         'Airtel Money',
//                         'Credit/Debit Card',
//                         'Bank Transfer',
//                       ]
//                       .map(
//                         (method) => DropdownMenuItem(
//                           value: method,
//                           child: Text(method),
//                         ),
//                       )
//                       .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedPaymentMethod = value!;
//                 });
//               },
//             ),
//             if (selectedPaymentMethod == 'M-Pesa' ||
//                 selectedPaymentMethod == 'Airtel Money')
//               TextFormField(
//                 controller: transactionIdController,
//                 decoration: const InputDecoration(labelText: 'Transaction ID'),
//               ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Implement payment logic
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.lightBlueAccent,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Confirm Payment'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  String selectedPaymentMethod = 'M-Pesa';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15), // translucent blue panel
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make a Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Ksh)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items:
                      [
                            'M-Pesa',
                            'Airtel Money',
                            'Credit/Debit Card',
                            'Bank Transfer',
                          ]
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                ),
                if (selectedPaymentMethod == 'M-Pesa' ||
                    selectedPaymentMethod == 'Airtel Money') ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: transactionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement payment logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
