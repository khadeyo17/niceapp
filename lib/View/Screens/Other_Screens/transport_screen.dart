// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // class TransportServicesScreen extends StatelessWidget {
// //   const TransportServicesScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Transport Services')),
// //       body: ListView(
// //         padding: const EdgeInsets.all(16.0),
// //         children: [
// //           _buildServiceTile(context, 'Bus Booking', '/busBooking'),
// //           _buildServiceTile(context, 'Honey Sucker', '/honeySucker'),
// //           _buildServiceTile(context, 'Movers', '/movers'),
// //           _buildServiceTile(context, 'Cargo Transport', '/cargoTransport'),
// //           _buildServiceTile(context, 'Car Hire', '/carHire'),
// //           _buildServiceTile(context, 'Ambulance', '/ambulance'),
// //           _buildServiceTile(context, 'Water Bowser', '/waterBowser'),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildServiceTile(BuildContext context, String title, String route) {
// //     return Card(
// //       child: ListTile(
// //         title: Text(title),
// //         // child: Icon(Icons.payment, size: 100, color: Colors.green),
// //         trailing: const Icon(Icons.arrow_forward_ios),
// //         onTap: () => context.push(route),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class TransportServicesScreen extends StatelessWidget {
//   const TransportServicesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> services = [
//       {
//         'name': 'Bus Booking',
//         'icon': Icons.directions_bus,
//         'route': '/services/transport/bus-booking',
//       },
//       {
//         'name': 'Honey Sucker',
//         'icon': Icons.water_damage,
//         'route': '/services/transport/honey-sucker',
//       },
//       {
//         'name': 'Movers',
//         'icon': Icons.local_shipping,
//         'route': '/services/transport/movers',
//       },
//       {
//         'name': 'Cargo Transport',
//         'icon': Icons.local_mall,
//         'route': '/services/transport/cargo',
//       },
//       {
//         'name': 'Car Hire',
//         'icon': Icons.car_rental,
//         'route': '/services/transport/car-hire',
//       },
//       {
//         'name': 'Ambulance',
//         'icon': Icons.health_and_safety,
//         'route': '/services/transport/ambulance',
//       },
//       {
//         'name': 'Water Bowser',
//         'icon': Icons.water,
//         'route': '/services/transport/water-bower',
//       },
//       {
//         'name': 'Breakdown',
//         'icon': Icons.car_repair,
//         'route': '/services/transport/breakdown',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(title: const Text('Transport Services')),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//           return Card(
//             elevation: 3,
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             child: ListTile(
//               leading: Icon(service['icon'], color: Colors.redAccent),
//               title: Text(service['name']),
//               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//               onTap: () {
//                 GoRouter.of(context).go(service['route']);
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class TransportServicesScreen extends StatelessWidget {
//   const TransportServicesScreen({super.key});
//   //RideBookingScreen
//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> services = [
//       {
//         'name': 'Ride Booking',
//         'icon': Icons.card_travel,
//         'color': Colors.blue,
//         'route': '/services/transport/ride-ooking',
//       },
//       {
//         'name': 'Bus Booking',
//         'icon': Icons.directions_bus,
//         'color': Colors.blue,
//         'route': '/services/transport/bus-booking',
//       },
//       {
//         'name': 'Honey Sucker',
//         'icon': Icons.water_damage,
//         'color': Colors.teal,
//         'route': '/services/transport/honey-sucker',
//       },
//       {
//         'name': 'Movers',
//         'icon': Icons.local_shipping,
//         'color': Colors.orange,
//         'route': '/services/transport/movers',
//       },
//       {
//         'name': 'Cargo Transport',
//         'icon': Icons.local_mall,
//         'color': Colors.purple,
//         'route': '/services/transport/cargo',
//       },
//       {
//         'name': 'Car Hire',
//         'icon': Icons.car_rental,
//         'color': Colors.green,
//         'route': '/services/transport/car-hire',
//       },
//       {
//         'name': 'Ambulance',
//         'icon': Icons.health_and_safety,
//         'color': Colors.red,
//         'route': '/services/transport/ambulance',
//       },
//       {
//         'name': 'Water Bowser',
//         'icon': Icons.water,
//         'color': Colors.blueAccent,
//         'route': '/services/transport/water-bower',
//       },
//       {
//         'name': 'Breakdown',
//         'icon': Icons.car_repair,
//         'color': Colors.brown,
//         'route': '/services/transport/breakdown',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Transport Services'),
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
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//           return _buildServiceTile(
//             context,
//             title: service['name'],
//             icon: service['icon'],
//             color: service['color'],
//             route: service['route'],
//           );
//         },
//       ),
//     );
//   }

//   /// Reusable Service Tile with card design
//   Widget _buildServiceTile(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required Color color,
//     required String route,
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
//         onTap: () => GoRouter.of(context).go(route),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class TransportServicesScreen extends StatelessWidget {
//   const TransportServicesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> services = [
//       {
//         'name': 'Ride Booking',
//         'icon': Icons.card_travel,
//         'route': '/services/transport/ride-booking',
//       },
//       {
//         'name': 'Bus Booking',
//         'icon': Icons.directions_bus,
//         'route': '/services/transport/bus-booking',
//       },
//       {
//         'name': 'Honey Sucker',
//         'icon': Icons.water_damage,
//         'route': '/services/transport/honey-sucker',
//       },
//       {
//         'name': 'Movers',
//         'icon': Icons.local_shipping,
//         'route': '/services/transport/movers',
//       },
//       {
//         'name': 'Cargo Transport',
//         'icon': Icons.local_mall,
//         'route': '/services/transport/cargo',
//       },
//       {
//         'name': 'Car Hire',
//         'icon': Icons.car_rental,
//         'route': '/services/transport/car-hire',
//       },
//       {
//         'name': 'Ambulance',
//         'icon': Icons.health_and_safety,
//         'route': '/services/transport/ambulance',
//       },
//       {
//         'name': 'Water Bowser',
//         'icon': Icons.water,
//         'route': '/services/transport/water-bower',
//       },
//       {
//         'name': 'Breakdown',
//         'icon': Icons.car_repair,
//         'route': '/services/transport/breakdown',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Transport Services'),
//         backgroundColor: Colors.blue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         titleTextStyle: const TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.blue,
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12.0),
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//           return _buildServiceTile(
//             context,
//             title: service['name'],
//             icon: service['icon'],
//             route: service['route'],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildServiceTile(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required String route,
//   }) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//         leading: Icon(icon, color: Colors.yellow[700], size: 28),
//         title: Text(
//           title,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//         trailing: const Icon(
//           Icons.arrow_forward_ios,
//           size: 16,
//           color: Colors.grey,
//         ),
//         onTap: () => GoRouter.of(context).go(route),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class TransportServicesScreen extends StatelessWidget {
//   const TransportServicesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> services = [
//       {
//         'name': 'Ride Booking',
//         'icon': Icons.card_travel,
//         'route': '/services/transport/ride-booking',
//       },
//       {
//         'name': 'Bus Booking',
//         'icon': Icons.directions_bus,
//         'route': '/services/transport/bus-booking',
//       },
//       {
//         'name': 'Honey Sucker',
//         'icon': Icons.water_damage,
//         'route': '/services/transport/honey-sucker',
//       },
//       {
//         'name': 'Movers',
//         'icon': Icons.local_shipping,
//         'route': '/services/transport/movers',
//       },
//       {
//         'name': 'Cargo Transport',
//         'icon': Icons.local_mall,
//         'route': '/services/transport/cargo',
//       },
//       {
//         'name': 'Car Hire',
//         'icon': Icons.car_rental,
//         'route': '/services/transport/car-hire',
//       },
//       {
//         'name': 'Ambulance',
//         'icon': Icons.health_and_safety,
//         'route': '/services/transport/ambulance',
//       },
//       {
//         'name': 'Water Bowser',
//         'icon': Icons.water,
//         'route': '/services/transport/water-bower',
//       },
//       {
//         'name': 'Breakdown',
//         'icon': Icons.car_repair,
//         'route': '/services/transport/breakdown',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Transport Services'),
//         backgroundColor: Colors.blue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         titleTextStyle: const TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: GridView.count(
//           crossAxisCount: 3,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           children:
//               services.map((service) {
//                 return _buildServiceCard(
//                   context,
//                   title: service['name'],
//                   icon: service['icon'],
//                   route: service['route'],
//                 );
//               }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required String route,
//   }) {
//     return InkWell(
//       onTap: () => GoRouter.of(context).go(route),
//       child: Card(
//         color: Colors.blue,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: Colors.yellow, size: 30),
//               const SizedBox(height: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Screens/Other_Screens/payments_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';

class TransportServicesScreen extends StatelessWidget {
  const TransportServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transport = [
      {
        'name': 'Ride Booking',
        'icon': Icons.directions_car,
        'color': Colors.orange,
        'route': '/services/transport/ride-booking',
      },
      {
        'name': 'Bus Booking',
        'icon': Icons.directions_bus,
        'color': Colors.blue,
        'route': '/services/transport/bus-booking',
      },
      {
        'name': 'Honey Sucker',
        'icon': Icons.water_drop,
        'color': Colors.teal,
        'route': '/services/transport/honey-sucker',
      },
      {
        'name': 'Movers',
        'icon': Icons.local_shipping,
        'color': Colors.deepPurple,
        'route': '/services/transport/movers',
      },
      {
        'name': 'Cargo Transport',
        'icon': Icons.local_mall,
        'color': Colors.green,
        'route': '/services/transport/cargo',
      },
      {
        'name': 'Car Hire',
        'icon': Icons.car_rental,
        'color': Colors.amber,
        'route': '/services/transport/car-hire',
      },
      {
        'name': 'Ambulance',
        'icon': Icons.medical_services,
        'color': Colors.red,
        'route': '/services/transport/ambulance',
      },
      {
        'name': 'Water Bowser',
        'icon': Icons.water,
        'color': Colors.lightBlueAccent,
        'route': '/services/transport/water-bower',
      },
      {
        'name': 'Breakdown',
        'icon': Icons.build,
        'color': Colors.brown,
        'route': '/services/transport/breakdown',
      },
      {
        'name': 'Mechanical',
        'icon': Icons.construction,
        'color': Colors.indigo,
        'route': '/services/transport/mechanical',
      },
      {
        'name': 'School Transport',
        'icon': Icons.school,
        'color': Colors.pinkAccent,
        'route': '/services/transport/school-transport',
      },
    ];

    final List<Map<String, dynamic>> payments = [
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amini Services'),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transport Section Header
            const Text(
              'Transport Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Transport Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children:
                  transport.map((service) {
                    return _buildServiceCard(
                      context,
                      title: service['name'],
                      icon: service['icon'],
                      color: service['color'],
                      route: service['route'],
                    );
                  }).toList(),
            ),

            const SizedBox(height: 32),

            // Payments Section Header
            const Text(
              'Payment Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Payments Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children:
                  payments.map((service) {
                    return _buildPaymentCard(
                      context,
                      title: service['title'],
                      icon: service['icon'],
                      color: service['color'],
                      screen: service['screen'],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => GoRouter.of(context).go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Amini Services'),
//         backgroundColor: Colors.blue,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         titleTextStyle: const TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Container(
//           margin: const EdgeInsets.all(16),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.blue.withOpacity(
//               0.15,
//             ), // translucent panel background
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.blue.withOpacity(0.2),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 3,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             children:
//                 transport.map((service) {
//                   return _buildServiceCard(
//                     context,
//                     title: service['name'],
//                     icon: service['icon'],
//                     color: service['color'],
//                     route: service['route'],
//                   );
//                 }).toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required Color color,
//     required String route,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(12),
//       onTap: () => GoRouter.of(context).go(route),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 36),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }
