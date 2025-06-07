// import 'package:flutter/material.dart';
// import 'payments_screen.dart';
// import 'wallet_screen.dart';

// class FinancialServicesScreen extends StatelessWidget {
//   const FinancialServicesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Financial Services')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             ListTile(
//               title: const Text('Payments'),
//               leading: const Icon(Icons.payment, color: Colors.blue),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => PaymentsScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               title: const Text('Wallet'),
//               leading: const Icon(
//                 Icons.account_balance_wallet,
//                 color: Colors.green,
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => WalletScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'payments_screen.dart';
// import 'wallet_screen.dart';

// class FinancialServicesScreen extends StatelessWidget {
//   const FinancialServicesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Financial Services'),
//         backgroundColor: Colors.white,
//         elevation: 2,
//         iconTheme: const IconThemeData(color: Colors.black),
//         titleTextStyle: const TextStyle(
//           color: Colors.black,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.blue.shade50,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildServiceTile(
//               context,
//               title: 'Payments',
//               icon: Icons.payment,
//               color: Colors.blue,
//               screen: PaymentScreen(),
//             ),
//             const SizedBox(height: 12),
//             _buildServiceTile(
//               context,
//               title: 'Wallet',
//               icon: Icons.account_balance_wallet,
//               color: Colors.green,
//               screen: WalletScreen(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Reusable ListTile widget with modern design
//   Widget _buildServiceTile(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required Color color,
//     required Widget screen,
//   }) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 12,
//           horizontal: 16,
//         ),
//         leading: Icon(icon, color: color, size: 30),
//         title: Text(
//           title,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//         ),
//         trailing: const Icon(
//           Icons.arrow_forward_ios,
//           size: 18,
//           color: Colors.grey,
//         ),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => screen),
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'payments_screen.dart';
import 'wallet_screen.dart';

class FinancialServicesScreen extends StatelessWidget {
  const FinancialServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Payments',
        'icon': Icons.payment,
        'color': Colors.blue.withOpacity(0.8),
        'screen': const PaymentScreen(),
      },
      {
        'title': 'Wallet',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green.withOpacity(0.8),
        'screen': const WalletScreen(),
      },
      // You can add more financial services here to fill 3 rows if needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Services'),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15), // translucent panel
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 items per row
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1, // square tiles
            ),
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceTile(
                context,
                title: service['title'],
                icon: service['icon'],
                color: service['color'],
                screen: service['screen'],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 40,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: color.withOpacity(0.5),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
