import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Screens/Other_Screens/payments_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';

class TransportServicesScreen extends StatelessWidget {
  const TransportServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iconAssets = {
      "Ride Booking": "assets/imgs/Sedan2.png",
      "Bus Booking": "assets/imgs/Bus.jpeg",
      "Honey Sucker": "assets/imgs/Exhauster.png",
      "Movers": "assets/imgs/MoversBus.jpeg",
      "Cargo Transport": "assets/imgs/CargoBus2.jpeg",
      "Car Hire": "assets/imgs/Carhirere.jpeg",
      "Ambulance": "assets/imgs/Ambulance2.png",
      "Water Bowser": "assets/imgs/waterlorry1.png",
      "Breakdown Services": "assets/imgs/Breakdown.jpeg",
      "Mechanical Services": "assets/imgs/Garage.png",
      "Payments": "assets/imgs/Payment.jpg",
      "Wallet": "assets/imgs/Wallet.png",
    };
    // final List<Map<String, dynamic>> transport = [
    //   {
    //     'name': 'Ride Booking',
    //     'icon': "assets/imgs/Sedan2.png",
    //     'color': Colors.orange,
    //     'route': '/services/transport/ride-booking',
    //   },
    //   {
    //     'name': 'Bus Booking',
    //     'icon': Icons.directions_bus,
    //     'color': Colors.blue,
    //     'route': '/services/transport/bus-booking',
    //   },
    //   {
    //     'name': 'Honey Sucker',
    //     'icon': Icons.water_drop,
    //     'color': Colors.teal,
    //     'route': '/services/transport/honey-sucker',
    //   },
    //   {
    //     'name': 'Movers',
    //     'icon': Icons.local_shipping,
    //     'color': Colors.deepPurple,
    //     'route': '/services/transport/movers',
    //   },
    //   {
    //     'name': 'Cargo Transport',
    //     'icon': Icons.local_mall,
    //     'color': Colors.green,
    //     'route': '/services/transport/cargo',
    //   },
    //   {
    //     'name': 'Car Hire',
    //     'icon': Icons.car_rental,
    //     'color': Colors.amber,
    //     'route': '/services/transport/car-hire',
    //   },
    //   {
    //     'name': 'Ambulance',
    //     'icon': Icons.medical_services,
    //     'color': Colors.red,
    //     'route': '/services/transport/ambulance',
    //   },
    //   {
    //     'name': 'Water Bowser',
    //     'icon': Icons.water,
    //     'color': Colors.lightBlueAccent,
    //     'route': '/services/transport/water-bower',
    //   },
    //   {
    //     'name': 'Breakdown Services',
    //     'icon': Icons.build,
    //     'color': Colors.brown,
    //     'route': '/services/transport/breakdown',
    //   },
    //   {
    //     'name': 'Mechanical Services',
    //     'icon': Icons.construction,
    //     'color': Colors.indigo,
    //     'route': '/services/transport/mechanical',
    //   },
    //   // {
    //   //   'name': 'School Transport',
    //   //   'icon': Icons.school,
    //   //   'color': Colors.pinkAccent,
    //   //   'route': '/services/transport/school-transport',
    //   // },
    // ];
    final List<Map<String, dynamic>> transport = [
      {
        'name': 'Taxi/Cab',
        'image': iconAssets['Ride Booking'],
        'color': Colors.orange,
        'route': '/services/transport/ride-booking',
      },
      {
        'name': 'Bus/Matatu Booking',
        'image': iconAssets['Bus Booking'],
        'color': Colors.blue,
        'route': '/services/transport/bus-booking',
      },
      {
        'name': 'Exhauster',
        'image': iconAssets['Honey Sucker'],
        'color': Colors.teal,
        'route': '/services/transport/honey-sucker',
      },
      {
        'name': 'Movers',
        'image': iconAssets['Movers'],
        'color': Colors.deepPurple,
        'route': '/services/transport/movers',
      },
      {
        'name': 'Cargo Transport',
        'image': iconAssets['Cargo Transport'],
        'color': Colors.green,
        'route': '/services/transport/cargo',
      },
      {
        'name': 'Car Hire',
        'image': iconAssets['Car Hire'],
        'color': Colors.amber,
        'route': '/services/transport/car-hire',
      },
      {
        'name': 'Ambulance',
        'image': iconAssets['Ambulance'],
        'color': Colors.red,
        'route': '/services/transport/ambulance',
      },
      {
        'name': 'Water Bowser',
        'image': iconAssets['Water Bowser'],
        'color': Colors.lightBlueAccent,
        'route': '/services/transport/water-bower',
      },
      {
        'name': 'Breakdown Services',
        'image': iconAssets['Breakdown Services'],
        'color': Colors.brown,
        'route': '/services/transport/breakdown',
      },
      {
        'name': 'Mechanical Services',
        'image': iconAssets['Mechanical Services'],
        'color': Colors.indigo,
        'route': '/services/transport/mechanical',
      },
    ];

    final List<Map<String, dynamic>> payments = [
      {
        'title': 'Payments',
        'image': iconAssets['Payments'],
        'color': Colors.blue.withOpacity(0.8),
        'screen': const PaymentHistoryScreen(),
      },
      {
        'title': 'Wallet',
        'image': iconAssets['Wallet'],
        'color': Colors.green.withOpacity(0.8),
        'screen': const WalletScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Amini Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        // title: const Text('Amini Services'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      // // backgroundColor: Colors.blue,
      // // elevation: 0,
      // // iconTheme: const IconThemeData(color: Colors.white),
      // // titleTextStyle: const TextStyle(
      // //   color: Colors.white,
      //   fontSize: 20,
      //   fontWeight: FontWeight.bold,
      // ),
      //  ),
      // backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transport Section Header
            const Text(
              'Transport Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                      image: service['image'],
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                      image: service['image'],
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
    required String image, // image path (e.g., "assets/imgs/Sedan2.png")
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => GoRouter.of(context).go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(image, fit: BoxFit.contain),
          ),
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
    required String image,
    required Color color,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      //onTap: () => GoRouter.of(context).go(route),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(image, fit: BoxFit.contain),
          ),
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

  // return InkWell(
  //   borderRadius: BorderRadius.circular(12),
  //   onTap:
  //       () => Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (_) => screen),
  //       ),
  //   child: Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(icon, color: color, size: 48),
  //       const SizedBox(height: 12),
  //       Text(
  //         title,
  //         style: const TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w700,
  //           color: Colors.black87,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //     ],
  //   ),
  // );
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
