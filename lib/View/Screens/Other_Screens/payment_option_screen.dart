import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Screens/Other_Screens/payments_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';

class PaymentServicesScreen extends StatefulWidget {
  const PaymentServicesScreen({super.key});
  // class TransportServicesScreen extends StatelessWidget {
  //   const TransportServicesScreen({super.key});

  @override
  State<PaymentServicesScreen> createState() => _PaymentServicesScreenState();
}

class _PaymentServicesScreenState extends State<PaymentServicesScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= 5) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconAssets = {
      // //"Ride Booking": "assets/imgs/Sedan2.png",
      // "Bus Booking": "assets/imgs/Bus.jpeg",
      // //"Honey Sucker": "assets/imgs/Exhauster.png",
      // "Movers": "assets/imgs/MoversBus.jpeg",
      // "Cargo Transport": "assets/imgs/CargoBus2.jpeg",
      // "Car Hire": "assets/imgs/Carhirere.jpeg",
      // "Ambulance": "assets/imgs/Ambulance2.png",
      // // "Water Bowser": "assets/imgs/waterlorry1.png",
      // "Breakdown Services": "assets/imgs/Breakdown.jpeg",
      // "Mechanical Services": "assets/imgs/Garage.png",
      // //"Machinery": "assets/imgs/Machinery2.png",
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
    // final List<Map<String, dynamic>> transport = [
    //   // {
    //   //   'name': 'Taxi/Cab',
    //   //   'image': iconAssets['Ride Booking'],
    //   //   'color': Colors.orange,
    //   //   'route': '/services/transport/ride-booking',
    //   // },
    //   {
    //     'name': 'Bus/Matatu Booking',
    //     'image': iconAssets['Bus Booking'],
    //     'color': Colors.blue,
    //     'route': '/services/transport/bus-booking',
    //   },
    //   // {
    //   //   'name': 'Exhauster',
    //   //   'image': iconAssets['Honey Sucker'],
    //   //   'color': Colors.teal,
    //   //   'route': '/services/transport/honey-sucker',
    //   // },
    //   {
    //     'name': 'Movers',
    //     'image': iconAssets['Movers'],
    //     'color': Colors.deepPurple,
    //     'route': '/services/transport/movers',
    //   },
    //   {
    //     'name': 'Cargo Transport',
    //     'image': iconAssets['Cargo Transport'],
    //     'color': Colors.green,
    //     'route': '/services/transport/cargo',
    //   },
    //   {
    //     'name': 'Car Hire',
    //     'image': iconAssets['Car Hire'],
    //     'color': Colors.amber,
    //     'route': '/services/transport/car-hire',
    //   },
    //   {
    //     'name': 'Ambulance',
    //     'image': iconAssets['Ambulance'],
    //     'color': Colors.red,
    //     'route': '/services/transport/ambulance',
    //   },
    //   // {
    //   //   'name': 'Water Bowser',
    //   //   'image': iconAssets['Water Bowser'],
    //   //   'color': Colors.lightBlueAccent,
    //   //   'route': '/services/transport/water-bower',
    //   // },
    //   {
    //     'name': 'Breakdown Services',
    //     'image': iconAssets['Breakdown Services'],
    //     'color': Colors.brown,
    //     'route': '/services/transport/breakdown',
    //   },
    //   {
    //     'name': 'Mechanical Services',
    //     'image': iconAssets['Mechanical Services'],
    //     'color': Colors.indigo,
    //     'route': '/services/transport/mechanical',
    //   },
    //   // {
    //   //   'name': 'Machinery',
    //   //   'image': iconAssets['Machinery'],
    //   //   'color': Colors.indigo,
    //   //   'route': '/services/transport/machinery',
    //   // },
    // ];

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
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.all(16),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       // Transport Section Header
      //       const Text(
      //         'Transport Services',
      //         style: TextStyle(
      //           fontSize: 16,
      //           fontWeight: FontWeight.bold,
      //           color: Colors.black,
      //         ),
      //       ),
      //       const SizedBox(height: 12),
      //       GridView.count(
      //         shrinkWrap: true,
      //         physics: const NeverScrollableScrollPhysics(),
      //         crossAxisCount: 3, // two per row so each card is bigger
      //         crossAxisSpacing: 16,
      //         mainAxisSpacing: 16,
      //         childAspectRatio: 0.95, // <— less than 1.0 makes them taller
      //         children:
      //             transport.map((service) {
      //               return _buildServiceCard(
      //                 context,
      //                 title: service['name'],
      //                 image: service['image'],
      //                 color: service['color'],
      //                 route: service['route'],
      //               );
      //             }).toList(),
      //       ),

      //       const SizedBox(height: 32),

      //       // Payments Section Header
      //       const Text(
      //         'Payment Services',
      //         style: TextStyle(
      //           fontSize: 16,
      //           fontWeight: FontWeight.bold,
      //           color: Colors.black,
      //         ),
      //       ),
      //       const SizedBox(height: 12),

      //       // Payments Grid
      //       GridView.count(
      //         shrinkWrap: true,
      //         physics: const NeverScrollableScrollPhysics(),
      //         crossAxisCount: 3,
      //         crossAxisSpacing: 16,
      //         mainAxisSpacing: 16,
      //         childAspectRatio: 0.95, // even taller for payment cards
      //         children:
      //             payments.map((service) {
      //               return _buildPaymentCard(
      //                 context,
      //                 title: service['title'],
      //                 image: service['image'],
      //                 color: service['color'],
      //                 screen: service['screen'],
      //               );
      //             }).toList(),
      //       ),
      //     ],
      //   ),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👇 Advert Section
            // const Text(
            //   'Adverts',
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.black,
            //   ),
            // ),
            const SizedBox(height: 12),

            // SizedBox(
            //   height: 140, // fixed height for advert cards
            //   child: SingleChildScrollView(
            //     scrollDirection: Axis.horizontal,
            //     child: Row(
            //       children: List.generate(5, (index) {
            //         return Container(
            //           width: 220,
            //           margin: const EdgeInsets.only(right: 12),
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(16),
            //             color: Colors.white,
            //             boxShadow: [
            //               BoxShadow(
            //                 color: Colors.black12,
            //                 blurRadius: 6,
            //                 offset: Offset(0, 3),
            //               ),
            //             ],
            //             image: DecorationImage(
            //               image: AssetImage(
            //                 "assets/imgs/ad${index + 1}.png",
            //               ), // 👈 your advert images
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //         );
            //       }),
            //     ),
            //   ),
            // ),

            // // Auto-moving Adverts Section working
            // SizedBox(
            //   height: 160,
            //   child: PageView.builder(
            //     controller: _pageController,
            //     itemCount: 5,
            //     itemBuilder: (context, index) {
            //       return Container(
            //         margin: const EdgeInsets.only(right: 0),
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(16),
            //           boxShadow: const [
            //             BoxShadow(
            //               color: Colors.black12,
            //               blurRadius: 6,
            //               offset: Offset(0, 3),
            //             ),
            //           ],
            //           image: DecorationImage(
            //             image: AssetImage("assets/imgs/ad${index + 1}.png"),
            //             fit: BoxFit.cover,
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),

            // SizedBox(
            //   height: 160, // height for advert cards
            //   child: PageView.builder(
            //     controller: PageController(
            //       viewportFraction: 1,
            //     ), // 👈 makes it full width
            //     itemCount: 5,
            //     itemBuilder: (context, index) {
            //       return Container(
            //         margin: const EdgeInsets.only(
            //           right: 0,
            //         ), // no gap needed now
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(16),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.black12,
            //               blurRadius: 6,
            //               offset: Offset(0, 3),
            //             ),
            //           ],
            //           image: DecorationImage(
            //             image: AssetImage("assets/imgs/ad${index + 1}.png"),
            //             fit: BoxFit.cover, // 👈 makes image cover full space
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
            const SizedBox(height: 24),

            // 👇 Transport Section Header
            // const Text(
            //   'Transport Services',
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.black,
            //   ),
            // ),
            // const SizedBox(height: 12),

            // GridView.count(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   crossAxisCount: 3,
            //   crossAxisSpacing: 16,
            //   mainAxisSpacing: 16,
            //   childAspectRatio: 0.95,
            //   children:
            //       transport.map((service) {
            //         return _buildServiceCard(
            //           context,
            //           title: service['name'],
            //           image: service['image'],
            //           color: service['color'],
            //           route: service['route'],
            //         );
            //       }).toList(),
            // ),

            // const SizedBox(height: 32),

            // 👇 Payments Section Header
            const Text(
              'Payment Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
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

            // Positioned(
            //   right: 16,
            //   bottom: 100,
            //   child: ValueListenableBuilder<List<FloatingTask>>(
            //     valueListenable: taskManager, // global notifier
            //     builder: (context, tasks, _) {
            //       return Column(
            //         crossAxisAlignment: CrossAxisAlignment.end,
            //         children:
            //             tasks.map((task) {
            //               return GestureDetector(
            //                 onTap: task.onTap,
            //                 child: Container(
            //                   margin: const EdgeInsets.only(bottom: 8),
            //                   child: Chip(
            //                     avatar: Icon(task.icon, color: Colors.white),
            //                     label: Text(
            //                       task.title,
            //                       style: const TextStyle(color: Colors.white),
            //                     ),
            //                     backgroundColor: Colors.blueAccent,
            //                   ),
            //                 ),
            //               );
            //             }).toList(),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String image,
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => GoRouter.of(context).go(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12, // reduced font size
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // prevents overflow
              maxLines: 2, // wrap into 2 lines if needed
            ),
          ],
        ),
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
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12, // smaller font
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
