// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class MainLayout extends StatelessWidget {
//   final Widget child;
//   const MainLayout({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: child, // This ensures the current screen is displayed
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _getSelectedIndex(context),
//         onTap: (index) {
//           switch (index) {
//             case 0:
//               GoRouter.of(context).go('/home');
//               break;
//             case 1:
//               GoRouter.of(context).go('/services');
//               break;
//             case 2:
//               GoRouter.of(context).go('/rideHistory');
//               break;
//             case 3:
//               GoRouter.of(context).go('/profile');
//               break;
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Services',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'rideHistory',
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//     );
//   }

//   int _getSelectedIndex(BuildContext context) {
//     final String location = GoRouterState.of(context).location;
//     if (location.startsWith('/home')) return 0;
//     if (location.startsWith('/services')) return 1;
//     if (location.startsWith('/rideHistory')) return 2;
//     if (location.startsWith('/profile')) return 3;
//     return 0;
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: child, // This ensures the current screen is displayed
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Prevents blurring effect
        selectedItemColor: Colors.grey, // Highlight selected item
        unselectedItemColor: Colors.black,
        currentIndex: _getSelectedIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              GoRouter.of(context).go('/home');
              break;

            // case 1:
            //   GoRouter.of(context).go('/otherservices');
            //   break;

            // case 2:
            //   GoRouter.of(
            //     context,
            //   ).go('/paymentservices'); // Updated from 'rideHistory'
            //   break;
            case 1:
              GoRouter.of(context).go('/events'); // Updated from 'rideHistory'
              break;
            case 2:
              GoRouter.of(context).go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30, color: Colors.black),

            label: 'Home',
          ),

          // BottomNavigationBarItem(
          //   icon: Icon(Icons.dashboard, size: 30, color: Colors.black),
          //   label: 'Services',
          // ),

          // BottomNavigationBarItem(
          //   icon: Icon(Icons.payments, size: 30, color: Colors.grey),
          //   // activeIcon: Icon(Icons.payments, size: 30),
          //   label: 'Payments',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event, size: 30, color: Colors.black),
            label: 'Events',
          ), // Corrected Icon
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30, color: Colors.black),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).location;
    if (location.startsWith('/home')) return 0;
    // if (location.startsWith('/otherservices')) return 1;
    //if (location.startsWith('/paymentservices')) return 1;
    if (location.startsWith('/events')) return 1; // Fixed navigation mapping
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
}
