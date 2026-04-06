import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive/hive.dart';

class TransportServicesScreen extends StatefulWidget {
  const TransportServicesScreen({super.key});

  @override
  State<TransportServicesScreen> createState() =>
      _TransportServicesScreenState();
}

class _TransportServicesScreenState extends State<TransportServicesScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentPage = 0;
  Timer? _timer;
  bool _hasActiveRide = false;

  List<Map<String, dynamic>> commonPlaces = [];
  bool isPlacesLoading = true;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();

    // 🔥 Run async tasks concurrently
    Future.wait([_loadCachedOrFetchPlaces()]);
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 5;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadCachedOrFetchPlaces() async {
    final box = Hive.box('cacheBox');

    // 🔹 Load cached places first
    final cachedPlaces = box.get('commonPlaces');
    if (cachedPlaces != null) {
      setState(() {
        commonPlaces = List<Map<String, dynamic>>.from(cachedPlaces);
        isPlacesLoading = false; // show immediately
      });
    }

    // 🔹 Fetch fresh data in background
    final freshPlaces = await loadNearbyPlaces();
    if (freshPlaces != null) {
      setState(() {
        commonPlaces = freshPlaces;
        isPlacesLoading = false;
      });

      // Cache the new places for next time
      await box.put('commonPlaces', freshPlaces);
    }
  }
  // Future<void> loadNearbyPlaces() async {
  //   try {
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     final url =
  //         "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
  //         "?location=${position.latitude},${position.longitude}"
  //         "&radius=3000"
  //         "&type=point_of_interest"
  //         "&key=$mapKey";

  //     final response = await http
  //         .get(Uri.parse(url))
  //         .timeout(const Duration(seconds: 5));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final results = data["results"] as List;

  //       setState(() {
  //         commonPlaces =
  //             results.take(2).map((place) {
  //               return {
  //                 "name": place["name"] ?? "Unknown Place",
  //                 "address": place["vicinity"] ?? "",
  //                 "lat": place["geometry"]["location"]["lat"],
  //                 "lng": place["geometry"]["location"]["lng"],
  //                 "icon": Icons.place,
  //               };
  //             }).toList();
  //         isPlacesLoading = false;
  //       });
  //     } else {
  //       setState(() => isPlacesLoading = false);
  //     }
  //   } catch (e) {
  //     debugPrint("Error loading places: $e");
  //     setState(() => isPlacesLoading = false);
  //   }
  // }
  Future<List<Map<String, dynamic>>?> loadNearbyPlaces() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${position.latitude},${position.longitude}"
          "&radius=3000"
          "&type=point_of_interest"
          "&key=$mapKey";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data["results"] as List;

        return results.take(3).map((place) {
          return {
            "name": place["name"] ?? "Unknown Place",
            "address": place["vicinity"] ?? "",
            "lat": place["geometry"]["location"]["lat"],
            "lng": place["geometry"]["location"]["lng"],
            "icon": Icons.place,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error loading places: $e");
    }
    return null;
  }

  void _navigateToWhereTo() {
    if (_hasActiveRide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already have an active ride. Complete or cancel it first.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const WhereToScreen(category: VehicleCategory.passenger),
      ),
    );
  }

  void _navigateToScheduleRide() {
    if (_hasActiveRide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already have an active ride. Complete or cancel it first.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const WhereToScreen(
              category: VehicleCategory.passenger,
              IsScheduled: true, // 🔥 THIS IS THE FIX
            ),
      ),
    );
  }

  void _navigateToRecentPlace(Map<String, dynamic> place) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => HomeScreen(
              pickup: LatLng(position.latitude, position.longitude),
              destination: LatLng(place["lat"], place["lng"]),
              stops: [],
              category: VehicleCategory.passenger,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transportServices = [
      {
        'name': 'Cab',
        'image': "assets/imgs/Sedan2.png",
        'color': Colors.orange,
        'route': '/services/transport/ride-booking',
      },
      {
        'name': 'Exhauster',
        'image': "assets/imgs/Exhauster.png",
        'color': Colors.teal,
        'route': '/services/transport/honey-sucker',
      },
      {
        'name': 'Clean Water',
        'image': "assets/imgs/waterlorry1.png",
        'color': Colors.lightBlueAccent,
        'route': '/services/transport/water-bower',
      },
      {
        'name': 'Heavy Machinery',
        'image': "assets/imgs/Machinery2.png",
        'color': Colors.indigo,
        'route': '/services/transport/machinery',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Amini', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body:
          isPlacesLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue, // optional: make it blue
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchRow(),
                    if (commonPlaces.isNotEmpty) _buildCommonPlaces(),
                    const SizedBox(height: 24),
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildServicesGrid(transportServices),
                    const SizedBox(height: 50),
                    _buildWelcomeCard(),
                  ],
                ),
              ),
    );
  }

  // Widget _buildSkeleton() {
  //   return Shimmer.fromColors(
  //     baseColor: Colors.grey.shade300,
  //     highlightColor: Colors.grey.shade100,
  //     child: Column(
  //       children: [
  //         Container(height: 50, color: Colors.white),
  //         const SizedBox(height: 20),
  //         Container(height: 60, color: Colors.white),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _navigateToWhereTo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _navigateToScheduleRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Schedule",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonPlaces() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: commonPlaces.length,
      itemBuilder: (context, index) {
        final place = commonPlaces[index];
        return GestureDetector(
          onTap: () => _navigateToRecentPlace(place),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(place["icon"], color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        place["address"],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesGrid(List<Map<String, dynamic>> services) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          context,
          title: service['name'],
          image: service['image'],
          color: service['color'],
          route: service['route'],
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return GestureDetector(
      onTap: _navigateToWhereTo,
      child: Container(
        height: 150,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(18),
          // gradient: const LinearGradient(
          //   colors: [Color(0xFFFFA726), Color(0xFFFFD54F)],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome to Amini",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Flexible(
                    child: Text(
                      "Move smarter, travel faster, and access all services in one tap.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Book a ride",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              height: 90,
              child: Image.asset("assets/imgs/Sedan2.png", fit: BoxFit.contain),
            ),
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
      onTap: () {
        if (title == "Cab") {
          _navigateToWhereTo();
        } else {
          GoRouter.of(context).go(route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 35, height: 35, child: Image.asset(image)),
            const SizedBox(height: 6),

            /// 🔥 THIS FIXES "Clean Water" ISSUE COMPLETELY
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  // Widget _buildServiceCard(
  //   BuildContext context, {
  //   required String title,
  //   required String image,
  //   required Color color,
  //   required String route,
  // }) {
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(12),
  //     onTap: () {
  //       if (title == "Cab") {
  //         _navigateToWhereTo();
  //       } else {
  //         GoRouter.of(context).go(route);
  //       }
  //     },
  //     child: Container(
  //       constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
  //       decoration: BoxDecoration(
  //         color: Colors.grey.shade100,
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           SizedBox(width: 40, height: 40, child: Image.asset(image)),
  //           const SizedBox(height: 8),
  //           Flexible(
  //             child: Text(
  //               title,
  //               style: const TextStyle(
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w500,
  //                 color: Colors.black87,
  //               ),
  //               textAlign: TextAlign.center,
  //               maxLines: 2,
  //               overflow: TextOverflow.ellipsis,
  //               softWrap: true,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
//}



  // Widget _buildServiceCardx(
  //   BuildContext context, {
  //   required String title,
  //   required String image,
  //   required Color color,
  //   required String route,
  // }) {
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(12),
  //     onTap: () => GoRouter.of(context).go(route),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(color: Colors.grey, width: 1.5),

  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black12,
  //             blurRadius: 4,
  //             offset: Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             width: 55,
  //             height: 55,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: color.withOpacity(0.2),
  //             ),
  //             padding: const EdgeInsets.all(8),
  //             child: Image.asset(image, fit: BoxFit.contain),
  //           ),
  //           const SizedBox(height: 6),
  //           Text(
  //             title,
  //             style: const TextStyle(
  //               fontSize: 12, // reduced font size
  //               fontWeight: FontWeight.w500,
  //               color: Colors.black87,
  //             ),
  //             textAlign: TextAlign.center,
  //             overflow: TextOverflow.ellipsis, // prevents overflow
  //             maxLines: 2, // wrap into 2 lines if needed
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildPaymentCard(
  //   BuildContext context, {
  //   required String title,
  //   required String image,
  //   required Color color,
  //   required Widget screen,
  // }) {
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(12),
  //     onTap:
  //         () => Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => screen),
  //         ),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black12,
  //             blurRadius: 4,
  //             offset: Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             width: 55,
  //             height: 55,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: color.withOpacity(0.2),
  //             ),
  //             padding: const EdgeInsets.all(8),
  //             child: Image.asset(image, fit: BoxFit.contain),
  //           ),
  //           const SizedBox(height: 6),
  //           Text(
  //             title,
  //             style: const TextStyle(
  //               fontSize: 12, // smaller font
  //               fontWeight: FontWeight.w500,
  //               color: Colors.black87,
  //             ),
  //             textAlign: TextAlign.center,
  //             overflow: TextOverflow.ellipsis,
  //             maxLines: 2,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildPaymentCard(
  //   BuildContext context, {
  //   required String title,
  //   required String image,
  //   required Color color,
  //   required Widget screen,
  // }) {
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(16),
  //     onTap:
  //         () => Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => screen),
  //         ),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black12,
  //             blurRadius: 6,
  //             offset: Offset(0, 3),
  //           ),
  //         ],
  //       ),
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             width: 70,
  //             height: 70,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: color.withOpacity(0.2),
  //             ),
  //             padding: const EdgeInsets.all(12),
  //             child: Image.asset(image, fit: BoxFit.contain),
  //           ),
  //           const SizedBox(height: 12),
  //           Text(
  //             title,
  //             style: const TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.black87,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildPaymentCard(
  //   BuildContext context, {
  //   required String title,
  //   required String image,
  //   required Color color,
  //   required Widget screen,
  // }) {
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(12),
  //     //onTap: () => GoRouter.of(context).go(route),
  //     onTap:
  //         () => Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => screen),
  //         ),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Container(
  //           width: 60,
  //           height: 60,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: color.withOpacity(0.2),
  //           ),
  //           padding: const EdgeInsets.all(8),
  //           child: Image.asset(image, fit: BoxFit.contain),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           title,
  //           style: const TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.black87,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
//}

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

            // Auto-moving Adverts Section

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
    // ];    // final List<Map<String, dynamic>> payments = [
    //   {
    //     'title': 'Payments',
    //     'image': iconAssets['Payments'],
    //     'color': Colors.blue.withOpacity(0.8),
    //     'screen': const PaymentHistoryScreen(),
    //   },
    //   {
    //     'title': 'Wallet',
    //     'image': iconAssets['Wallet'],
    //     'color': Colors.green.withOpacity(0.8),
    //     'screen': const WalletScreen(),
    //   },
    // ];
     // {
      //   'name': 'Movers',
      //   'image': iconAssets['Movers'],
      //   'color': Colors.deepPurple,
      //   'route': '/services/transport/movers',
      // },
      // {
      //   'name': 'Cargo Transport',
      //   'image': iconAssets['Cargo Transport'],
      //   'color': Colors.green,
      //   'route': '/services/transport/cargo',
      // },
      // {
      //   'name': 'Car Hire',
      //   'image': iconAssets['Car Hire'],
      //   'color': Colors.amber,
      //   'route': '/services/transport/car-hire',
      // },
      // {
      //   'name': 'Ambulance',
      //   'image': iconAssets['Ambulance'],
      //   'color': Colors.red,
      //   'route': '/services/transport/ambulance',
      // }, // {
      //   'name': 'Breakdown Services',
      //   'image': iconAssets['Breakdown Services'],
      //   'color': Colors.brown,
      //   'route': '/services/transport/breakdown',
      // },
      // {
      //   'name': 'Mechanical Services',
      //   'image': iconAssets['Mechanical Services'],
      //   'color': Colors.indigo,
      //   'route': '/services/transport/mechanical',
      // },
            // 👇 Payments Section Header
            // const Text(
            //   'Payment Services',
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
            //       payments.map((service) {
            //         return _buildPaymentCard(
            //           context,
            //           title: service['title'],
            //           image: service['image'],
            //           color: service['color'],
            //           screen: service['screen'],
            //         );
            //       }).toList(),
            // ),

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
            // ),  // // backgroundColor: Colors.blue,
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
      // ),      // "Movers": "assets/imgs/MoversBus.jpeg",
      // "Cargo Transport": "assets/imgs/CargoBus2.jpeg",
      // "Car Hire": "assets/imgs/Carhirere.jpeg",
      // "Ambulance": "assets/imgs/Ambulance2.png",      //"Breakdown Services": "assets/imgs/Breakdown.jpeg",
      // "Mechanical Services": "assets/imgs/Garage.png",
            // "Payments": "assets/imgs/Payment.jpg",
      // "Wallet": "assets/imgs/Wallet.png",
            // "Bus Booking": "assets/imgs/Bus.jpeg",

            // Positioned(
            //   bottom: 20,
            //   left: 10,
            //   right: 10,
            //   child: GestureDetector(
            //     onTap: _navigateToWhereTo,
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 14,
            //       ),
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.circular(12),
            //         border: Border.all(color: Colors.grey, width: 1.5),
            //         boxShadow: const [
            //           BoxShadow(color: Colors.black26, blurRadius: 4),
            //         ],
            //       ),
            //       child: const Row(
            //         children: [
            //           Icon(Icons.search, color: Colors.grey),
            //           SizedBox(width: 10),
            //           Text(
            //             'Where to?',
            //             style: TextStyle(
            //               fontSize: 24,
            //               fontWeight: FontWeight.bold,
            //               color: Colors.redAccent,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

             // if (recentRides.isNotEmpty) ...[
            //   const SizedBox(height: 5),

            //   // const Text(
            //   //   "",
            //   //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //   // ),
            //   const SizedBox(height: 10),

            //   ListView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemCount: recentRides.length,
            //     itemBuilder: (context, index) {
            //       final ride = recentRides[index];

            //       return GestureDetector(
            //         onTap: () => _openRecentRide(ride),
            //         child: Container(
            //           margin: const EdgeInsets.only(bottom: 8),
            //           padding: const EdgeInsets.symmetric(
            //             horizontal: 10,
            //             vertical: 12,
            //           ),
            //           decoration: BoxDecoration(
            //             color: Colors.grey.shade100,
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           child: Row(
            //             children: [
            //               const Icon(Icons.history, color: Colors.black54),
            //               const SizedBox(width: 12),

            //               Expanded(
            //                 child: Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Text(
            //                       ride.destination ?? "Recent Destination",
            //                       style: const TextStyle(
            //                         fontWeight: FontWeight.bold,
            //                       ),
            //                     ),

            //                     Text(
            //                       ride.destination ?? "",
            //                       overflow: TextOverflow.ellipsis,
            //                       style: const TextStyle(
            //                         fontSize: 12,
            //                         color: Colors.black54,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ],