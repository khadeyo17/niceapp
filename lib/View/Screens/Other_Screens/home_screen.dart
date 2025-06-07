// // // home_screen.dart
// // import 'package:flutter/material.dart';
// // import 'wallet_screen.dart';
// // import 'payments_screen.dart';
// // import 'logistics_screen.dart';
// // import 'honey_sucker_screen.dart';
// // import 'bus_booking_screen.dart';
// // import 'movers_screen.dart';
// // import 'ride_booking_screen.dart';
// // import 'ride_history_screen.dart';

// // class HomeScreen extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Home')),
// //       body: GridView.count(
// //         crossAxisCount: 3, // Updated to 3 icons per row
// //         padding: EdgeInsets.all(16),
// //         crossAxisSpacing: 10,
// //         mainAxisSpacing: 10,
// //         children: [
// //           _buildHomeTile(context, Icons.car_rental, 'Order Ride', RideBookingScreen()),
// //           _buildHomeTile(context, Icons.car_rental, 'My Rides', RideHistoryScreen()),
// //           _buildHomeTile(context, Icons.account_balance_wallet, 'Wallet', WalletScreen()),
// //           _buildHomeTile(context, Icons.payment, 'Payments', PaymentsScreen()),
// //           _buildHomeTile(context, Icons.local_shipping, 'Logistics', LogisticsScreen()),
// //           _buildHomeTile(context, Icons.clean_hands, 'Honey Sucker', HoneySuckerScreen()),
// //           _buildHomeTile(context, Icons.directions_bus, 'Bus Booking', BusBookingScreen()),
// //           _buildHomeTile(context, Icons.move_to_inbox, 'Movers', MoversScreen()),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildHomeTile(BuildContext context, IconData icon, String title, Widget screen) {
// //     return GestureDetector(
// //       onTap: () => Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (context) => screen),
// //       ),
// //       child: Card(
// //         elevation: 4,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(icon, size: 40, color: Colors.blue), // Reduced icon size
// //             SizedBox(height: 8),
// //             Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // home_screen.dart
// // import 'package:flutter/material.dart';
// // import 'wallet_screen.dart';
// // import 'payments_screen.dart';
// // import 'logistics_screen.dart';
// // import 'honey_sucker_screen.dart';
// // import 'bus_booking_screen.dart';
// // import 'movers_screen.dart';
// // import 'ride_booking_screen.dart';
// // import 'ride_history_screen.dart';

// // class HomeScreen extends StatelessWidget {
// //   final VoidCallback toggleTheme;
  
// //   HomeScreen({required this.toggleTheme});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Home'),
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.brightness_6),
// //             onPressed: toggleTheme,
// //           ),
// //         ],
// //       ),
// //       body: GridView.count(
// //         crossAxisCount: 3,
// //         padding: EdgeInsets.all(16),
// //         crossAxisSpacing: 10,
// //         mainAxisSpacing: 10,
// //         children: [
// //           _buildHomeTile(context, Icons.car_rental, 'Order Ride', RideBookingScreen()),
// //           _buildHomeTile(context, Icons.car_rental, 'My Rides', RideHistoryScreen()),
// //           _buildHomeTile(context, Icons.account_balance_wallet, 'Wallet', WalletScreen()),
// //           _buildHomeTile(context, Icons.payment, 'Payments', PaymentsScreen()),
// //           _buildHomeTile(context, Icons.local_shipping, 'Logistics', LogisticsScreen()),
// //           _buildHomeTile(context, Icons.clean_hands, 'Honey Sucker', HoneySuckerScreen()),
// //           _buildHomeTile(context, Icons.directions_bus, 'Bus Booking', BusBookingScreen()),
// //           _buildHomeTile(context, Icons.move_to_inbox, 'Movers', MoversScreen()),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildHomeTile(BuildContext context, IconData icon, String title, Widget screen) {
// //     return GestureDetector(
// //       onTap: () => Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (context) => screen),
// //       ),
// //       child: Card(
// //         elevation: 4,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(icon, size: 40, color: Colors.blue),
// //             SizedBox(height: 8),
// //             Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// // home_screen.dart
// // import 'package:flutter/material.dart';
// // import 'wallet_screen.dart';
// // import 'payments_screen.dart';
// // import 'logistics_screen.dart';
// // import 'honey_sucker_screen.dart';
// // import 'bus_booking_screen.dart';
// // import 'movers_screen.dart';
// // import 'ride_booking_screen.dart';
// // import 'ride_history_screen.dart';
// // import 'account_screen.dart';
// // import 'transport_screen.dart';
// // import 'services_screen.dart';

// // class HomeScreen extends StatefulWidget {
// //   final VoidCallback toggleTheme;

// //   HomeScreen({required this.toggleTheme});

// //   @override
// //   _HomeScreenState createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen> {
// //   int _selectedIndex = 0;

// //   static List<Widget> _screens = <Widget>[
// //     HomeContent(),
// //     AccountScreen(),
// //     TransportScreen(),
// //     ServicesScreen(),
// //   ];

// //   void _onItemTapped(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Vicsacs'),
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.brightness_6),
// //             onPressed: widget.toggleTheme,
// //           ),
// //         ],
// //       ),
// //       body: _screens[_selectedIndex],
// //       bottomNavigationBar: BottomNavigationBar(
// //         items: const <BottomNavigationBarItem>[
// //           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
// //           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
// //           BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Transport'),
// //           BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
// //         ],
// //         currentIndex: _selectedIndex,
// //         selectedItemColor: Colors.blue,
// //         onTap: _onItemTapped,
// //       ),
// //     );
// //   }
// // }

// // class HomeContent extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return GridView.count(
// //       crossAxisCount: 3,
// //       padding: EdgeInsets.all(16),
// //       crossAxisSpacing: 10,
// //       mainAxisSpacing: 10,
// //       children: [
// //         _buildHomeTile(context, Icons.car_rental, 'Order Ride', RideBookingScreen()),
// //         _buildHomeTile(context, Icons.car_rental, 'My Rides', RideHistoryScreen()),
// //         _buildHomeTile(context, Icons.account_balance_wallet, 'Wallet', WalletScreen()),
// //         _buildHomeTile(context, Icons.payment, 'Payments', PaymentsScreen()),
// //         _buildHomeTile(context, Icons.local_shipping, 'Logistics', LogisticsScreen()),
// //         _buildHomeTile(context, Icons.clean_hands, 'Honey Sucker', HoneySuckerScreen()),
// //         _buildHomeTile(context, Icons.directions_bus, 'Bus Booking', BusBookingScreen()),
// //         _buildHomeTile(context, Icons.move_to_inbox, 'Movers', MoversScreen()),
// //       ],
// //     );
// //   }

// //   Widget _buildHomeTile(BuildContext context, IconData icon, String title, Widget screen) {
// //     return GestureDetector(
// //       onTap: () => Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (context) => screen),
// //       ),
// //       child: Card(
// //         elevation: 4,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(icon, size: 40, color: Colors.blue),
// //             SizedBox(height: 8),
// //             Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// // home_screen.dart
// import 'package:flutter/material.dart';
// import 'wallet_screen.dart';
// import 'payments_screen.dart';
// import 'logistics_screen.dart';
// import 'honey_sucker_screen.dart';
// import 'bus_booking_screen.dart';
// import 'movers_screen.dart';
// import 'ride_booking_screen.dart';
// import 'ride_history_screen.dart';
// import 'account_screen.dart';
// import 'transport_screen.dart';
// import 'services_screen.dart';

// class HomeScreen extends StatefulWidget {
// final VoidCallback toggleTheme;

//   HomeScreen({required this.toggleTheme});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   static List<Widget> _screens = <Widget>[
//     HomeContent(),
//     AccountScreen(),
//     TransportScreen(),
//     ServicesScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Vicsacs'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.brightness_6),
//             onPressed: widget.toggleTheme,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(child: _screens[_selectedIndex]),
//           Container(
//             padding: EdgeInsets.all(10),
//             color: Colors.grey[200],
//             child: Image.asset(
//               'assets/images/ad1.jpeg',
//              // 'assets/images/ad2.jpeg',
//              // 'assets/images/ad3.jpeg',
//               height: 80,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
//           BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Transport'),
//           BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.blue,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }

// class HomeContent extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GridView.count(
//       crossAxisCount: 3,
//       padding: EdgeInsets.all(16),
//       crossAxisSpacing: 10,
//       mainAxisSpacing: 10,
//       children: [
//         _buildHomeTile(context, Icons.car_rental, 'Order Ride', RideBookingScreen()),
//         _buildHomeTile(context, Icons.car_rental, 'My Rides', RideHistoryScreen()),
//         _buildHomeTile(context, Icons.account_balance_wallet, 'Wallet', WalletScreen()),
//         _buildHomeTile(context, Icons.payment, 'Payments', PaymentsScreen()),
//         _buildHomeTile(context, Icons.local_shipping, 'Logistics', LogisticsScreen()),
//         _buildHomeTile(context, Icons.clean_hands, 'Honey Sucker', HoneySuckerScreen()),
//         _buildHomeTile(context, Icons.directions_bus, 'Bus Booking', BusBookingScreen()),
//         _buildHomeTile(context, Icons.move_to_inbox, 'Movers', MoversScreen()),
//       ],
//     );
//   }

// //   Widget _buildHomeTile(BuildContext context, IconData icon, String title, Widget screen) {
// //     return GestureDetector(
// //       onTap: () => Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (context) => screen),
// //       ),
// //       child: Card(
// //         elevation: 4,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(icon, size: 40, color: Colors.blue.withOpacity(0.5)),
// //             SizedBox(height: 8),
// //             Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//   Widget _buildHomeTile(BuildContext context, IconData icon, String title, Widget screen) {
//   return GestureDetector(
//     onTap: () => Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => screen),
//     ),
//     child: Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 40, color: Colors.blue.withOpacity(0.5)), // Adjust transparency
//           SizedBox(height: 8),
//           Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     ),
//   );
// }}