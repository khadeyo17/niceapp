import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

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
  bool isLoadingRecentRide=false;
  String? fullname;
 bool isLoading = true;
  List<Map<String, dynamic>> commonPlaces = [];
  bool isPlacesLoading = true;
  RideHistory? recentRide;
  String? currentLocation;
 bool isLocationLoading = true;

 final transportServices = [
  {
    'name': 'Taxi',
    'image': 'assets/imgs/taxi.png',
    'route': '/services/transport/ride-booking',
  },
  {
    'name': 'Machinery',
    'image': 'assets/imgs/machineryx.png',
    'route': '/services/transport/machinery',
  },
  {
    'name': 'Clean Water',
    'image': 'assets/imgs/cleanwater.png',
    'route': '/services/transport/water-bower',
  },
  {
    'name': 'Exhauster',
    'image': 'assets/imgs/exhausterx.png',
    'route': '/services/transport/honey-sucker',
  },
];

@override
void initState() {
  super.initState();

  _startAutoScroll();
  getCurrentLocation();
  fetchUserProfile();
  _fetchRecentRide();
}
//Rides? recentRide;
//bool isRecentRideLoading = false;

Future<void> _fetchRecentRide() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  if (mounted) {
    setState(() => isLoadingRecentRide = true);
  }

  try {
    final firebaseId = user.uid;

    final response = await http.get(
      Uri.parse(
        '${baseUrl}/passengerrides/passenger/newhistory/$firebaseId',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        recentRide = RideHistory.fromPassengerJson(
  Map<String, dynamic>.from(data),
);
      });
    } else if (response.statusCode == 404) {
      if (!mounted) return;

      setState(() {
        recentRide = null;
      });
    } else {
      debugPrint(
        'Latest ride API error: ${response.statusCode} ${response.body}',
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Error fetching latest ride: $e');
    debugPrintStack(stackTrace: stackTrace);
  } finally {
    if (mounted) {
      setState(() => isLoadingRecentRide = false);
    }
  }
}


void _openRecentRide() {
  if (recentRide == null) return;

  final ride = recentRide!;

  final status = (ride.status ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_-]'), '');

  switch (status) {
    case 'completed':
    case 'cancelled':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RideHistoryScreen(),
        ),
      );
      break;

    case 'requested':
    case 'pending':
    case 'driverassigned':
    case 'ontheway':
    case 'inprogress':
    case 'scheduled':
    default:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideInProgressLiveScreen(
            rideId: ride.id.toString(),
            pickup: LatLng(
              ride.pickupLatitude,
              ride.pickupLongitude,
            ),
            destination: LatLng(
              ride.destinationLatitude,
              ride.destinationLongitude,
            ),

          ),
        ),
      );
      break;
  }
}


  Future<void> fetchUserProfile() async {
    try {

    final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("User not logged in");

      final idToken = await user.getIdToken();

      final profileRes = await http.get(
        Uri.parse('$baseUrl/passengerauth/profile'),
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
      );

      if (profileRes.statusCode == 200) {
        final data = json.decode(profileRes.body);
        fullname = data['fullname'] ?? "";

      } else {
        throw Exception("Failed to load profile: ${profileRes.body}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
Future<void> getCurrentLocation() async {
  try {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!mounted) return;

    if (!serviceEnabled) {
      setState(() {
        currentLocation = 'Location services disabled';
        isLocationLoading = false;
      });
      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (!mounted) return;
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        currentLocation = 'Location permission denied';
        isLocationLoading = false;
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocation = 'Location permission denied';
        isLocationLoading = false;
      });
      return;
    }

    final Position position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    debugPrint(
      'Current coordinates: '
      '${position.latitude}, ${position.longitude}',
    );

    final List<Placemark> placemarks =
        await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;

      String location = '';

      if (place.subLocality != null &&
          place.subLocality!.trim().isNotEmpty) {
        location = place.subLocality!;
      } else if (place.locality != null &&
          place.locality!.trim().isNotEmpty) {
        location = place.locality!;
      }

      if (place.locality != null &&
          place.locality!.trim().isNotEmpty &&
          !location.contains(place.locality!)) {
        location = '$location, ${place.locality}';
      }

      if (!mounted) return;

      setState(() {
        currentLocation =
            location.isNotEmpty
                ? location
                : 'Current location';

        isLocationLoading = false;
      });
    } else {
      if (!mounted) return;

      setState(() {
        currentLocation = 'Current location';
        isLocationLoading = false;
      });
    }
  } catch (e) {
    debugPrint('Location error: $e');

    if (!mounted) return;

    setState(() {
      currentLocation = 'Unable to get location';
      isLocationLoading = false;
    });
  }
}

  String getUserName() {
  //final user = FirebaseAuth.instance.currentUser;

  if (fullname == null) {
    return 'User';
  }

  if (fullname != null && fullname!.trim().isNotEmpty) {
    return fullname!.trim().split(' ').first;
  }

  return 'User';
}
String getUserInitials() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return 'U';
  }

  final displayName = user.displayName?.trim();

  if (displayName != null && displayName.isNotEmpty) {
    final parts = displayName.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  // Fallback to email
  final email = user.email?.trim();

  if (email != null && email.isNotEmpty) {
    return email[0].toUpperCase();
  }

  return 'U';
}
  Future<void> fetchRecentRide() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  setState(() => isLoadingRecentRide = true);

  try {
    final response = await http
        .get(Uri.parse('$baseUrl/passengerrides/passenger/history/${user.uid}'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final rides = data
            .map((json) => RideHistory.fromPassengerJson(json))
            .toList();

        rides.sort((a, b) {
          final aDate = a.dropoffTime ?? DateTime(2000);
          final bDate = b.dropoffTime ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        setState(() {
          recentRide = rides.first;
        });
      }
    }
  } catch (e) {
    debugPrint("Recent ride error: $e");
  } finally {
    setState(() => isLoadingRecentRide = false);
  }
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
  

  //google
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

  void _navigateToPlanAhead() {
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

  context.push('/plan-ahead');
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
    // final transportServices = [
    //   {
    //     'name': 'Cab',
    //     'image': "assets/imgs/Sedan2.png",
    //     'color': Colors.orange,
    //     'route': '/services/transport/ride-booking',
    //   },
    //   {
    //     'name': 'Exhauster',
    //     'image': "assets/imgs/Exhauster.png",
    //     'color': Colors.teal,
    //     'route': '/services/transport/honey-sucker',
    //   },
    //   {
    //     'name': 'Clean Water',
    //     'image': "assets/imgs/waterlorry1.png",
    //     'color': Colors.lightBlueAccent,
    //     'route': '/services/transport/water-bower',
    //   },
    //   {
    //     'name': 'Heavy Machinery',
    //     'image': "assets/imgs/Machinery2.png",
    //     'color': Colors.indigo,
    //     'route': '/services/transport/machinery',
    //   },
    // ];

    

    // return Scaffold(
    //   backgroundColor: Colors.white,
    //   appBar: AppBar(
    //     title: const Text('Amini', style: TextStyle(color: Colors.black)),
    //     backgroundColor: Colors.white,
    //     elevation: 0,
    //     foregroundColor: Colors.black,
    //   ),
    //   body:
    //       isPlacesLoading
    //           ? const Center(
    //             child: CircularProgressIndicator(
    //               color: Colors.blue, // optional: make it blue
    //             ),
    //           )
    //           : SingleChildScrollView(
    //             padding: const EdgeInsets.all(16),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 _buildSearchRow(),
    //                 if (commonPlaces.isNotEmpty) _buildCommonPlaces(),
    //                 const SizedBox(height: 24),
    //                 const Text(
    //                   'Services',
    //                   style: TextStyle(
    //                     fontWeight: FontWeight.bold,
    //                     fontSize: 16,
    //                   ),
    //                 ),
    //                 const SizedBox(height: 12),
    //                 _buildServicesGrid(transportServices),
    //                 const SizedBox(height: 50),
    //                 _buildWelcomeCard(),
    //               ],
    //             ),
    //           ),
    // );
  
  return Scaffold(
  backgroundColor: Colors.white,
  body: SafeArea(
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: Column(
            children: [
              // =================================================
              // SECTION 1
              // =================================================
              Container(
                width: double.infinity,
                height: 486,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                      0.0,
                      0.6058,
                      0.8269,
                      0.8846,
                      0.9663,
                    ],
                    colors: [
                      Color(0xFF2685DD),
                      Color(0xFFB6C33E),
                      Color.fromRGBO(233, 217, 6, 0.35),
                      Color.fromRGBO(233, 217, 6, 0.275),
                      Color.fromRGBO(233, 217, 6, 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.only(
                  bottom: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHomeHeader(),

                    const SizedBox(height: 12),

                    _buildLocation(),

                    const SizedBox(height: 16),

                    _buildWhereTo(),

                    const SizedBox(height: 16),

                    _buildServicesGrid(),
                    const SizedBox(height: 1),
                  ],
                ),
              ),

              // =================================================
              // SECTION 2
              // =================================================
              // Expanded(
              //   child: Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.only(
              //       left: 20,
              //       right: 20,
              //       top: 20,
              //     ),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       children: [
              //         _buildPlanAhead(),

              //         const SizedBox(height: 16),

              //         const Align(
              //           alignment: Alignment.centerLeft,
              //           child: Text(
              //             'Recent activity',
              //             style: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.w600,
              //               color: Colors.black,
              //             ),
              //           ),
              //         ),

              //         const SizedBox(height: 16),

              //         _buildRecentRide(),
              //       ],
              //     ),
              //   ),
              // ),

              Expanded(
  child: SingleChildScrollView(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPlanAhead(),

          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildRecentRide(),
        ],
      ),
    ),
  ),
),
            ],
          ),
        ),

        // =================================================
        // FIXED BOTTOM NAVIGATION
        // =================================================
       // _buildBottomNavigation(),
      ],
    ),
  ),
);
  
  }

// Widget _buildServicesGridd() {
//   final services = [
//     {
//       'title': 'Taxi',
//       'icon': Icons.local_taxi,
//     },
//     {
//       'title': 'Machinery',
//       'icon': Icons.construction,
//     },
//     {
//       'title': 'Clean Water',
//       'icon': Icons.water_drop,
//     },
//     {
//       'title': 'Exhauster',
//       'icon': Icons.local_shipping,
//     },
//   ];

//   return Container(
//     width: 350,
//     height: 247,
//     margin: const EdgeInsets.symmetric(horizontal: 20),
//     child: GridView.builder(
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: services.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 18,
//         mainAxisSpacing: 16,
//         childAspectRatio: 1.0,
//       ),
//       itemBuilder: (context, index) {
//         final service = services[index];

//         return 
//         (
//           title: service['title'] as String,
//           icon: service['icon'] as IconData,
//         );
//       },
//     ),
//   );
// } 



// Widget _buildServicesGrid() {
//   return SizedBox(
//     width: 350,
//     height: 247,
//     child: GridView.builder(
//       physics: const NeverScrollableScrollPhysics(),
//       padding: EdgeInsets.zero,
//       itemCount: transportServices.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 18,
//         mainAxisSpacing: 16,
//         childAspectRatio: 156 / 124,
//       ),
//       itemBuilder: (context, index) {
//         final service = transportServices[index];

//         return GestureDetector(
//           onTap: () {
//             context.push(service['route'] as String);
//           },
//           child: SizedBox(
//             width: 156,
//             height: 124,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // IMAGE CONTAINER
//                 Container(
//                   width: 156,
//                   height: 82,
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: const Color(0xFFE9D906),
//                       width: 2,
//                     ),
//                   ),
//                   child: Image.asset(
//                     service['image'] as String,
//                     fit: BoxFit.contain,
//                   ),
//                 ),

//                 const SizedBox(height: 6),

//                 // NAME
//                 Container(
//                   height: 26,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 3,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: const Color(0xFFE9D906),
//                       width: 2,
//                     ),
//                   ),
//                   child: Text(
//                     service['name'] as String,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }
Widget _buildServicesGrid() {
  return SizedBox(
    width: 350,
    height: 247,
    child: GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transportServices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 16,
        mainAxisExtent: 124,
      ),
      itemBuilder: (context, index) {
        final service = transportServices[index];

        return GestureDetector(
          onTap: () {
            context.push(service['route'] as String);
          },
          child: SizedBox(
            width: 156,
            height: 124,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 156,
                  height: 82,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE9D906),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    service['image'] as String,
                    fit: BoxFit.contain,
                  ),
                ),

                // =================================================
                // NAME - CUTTING ACROSS BOTTOM BORDER
                // =================================================
                Positioned(
                  top: 70,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE9D906),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      service['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildServiceCardx({
  required String title,
  required IconData icon,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Handle service selection
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.black,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildWhereTo() {
  return Container(
    width: 350,
    height: 58,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _navigateToWhereTo();
        // Navigate to your destination/search screen
      },
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 22,
            color: Colors.black,
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Where to?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 15,
            color: Colors.grey,
          ),
        ],
      ),
    ),
  );
}

Widget _buildLocation() {
  return Center(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          width: 269,
          height: 36,
          padding: const EdgeInsets.only(
            top: 8,
            right: 16,
            bottom: 8,
            left: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 17,
                color: Colors.white,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  isLocationLoading
                      ? 'Getting your location...'
                      : currentLocation ?? 'Current location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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

Widget _buildHomeHeader() {
  return Container(
    width: double.infinity,
    height: 64,
    padding: const EdgeInsets.only(
      left: 20,
      right: 20,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting
        Text(
          'Hi, $fullname',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // User initials
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            getUserName(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

// Widget _buildPlanAhead() {
//   return Center(
//     child: Container(
//       width: 350,
//       height: 78,
//       padding: const EdgeInsets.only(
//         top: 15,
//         right: 20,
//         bottom: 15,
//         left: 20,
//       ),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [
//             Color(0xFF015ACE),
//             Color(0xFF2685DD),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [

//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: const Color(0xFFE9D906),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.calendar_month_rounded,
//               color: Colors.white,
//               size: 28,
//             ),
//           ),

//           const SizedBox(width: 14),
//           const Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Plan Ahead',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Schedule any service in seconds',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(width: 10),

//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(
//               Icons.arrow_forward_ios_rounded,
//               color: Colors.white,
//               size: 16,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

Widget _buildPlanAhead() {
  return Center(
    child: GestureDetector(
      onTap:_navigateToPlanAhead,// _navigateToScheduleRide,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 350,
        height: 78,
        padding: const EdgeInsets.only(
          top: 15,
          right: 20,
          bottom: 15,
          left: 20,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF015ACE),
              Color(0xFF2685DD),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Calendar icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE9D906),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Ahead',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Schedule any service in seconds',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Arrow
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
 
// Widget _buildRecentRide() {
//   if (recentRide == null) {
//     return Container(
//       width: double.infinity,
//       height: 74,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: const Color(0xFFE1E6ED),
//         ),
//       ),
//       child: const Row(
//         children: [
//           Icon(
//             Icons.history,
//             size: 22,
//             color: Colors.grey,
//           ),
//           SizedBox(width: 12),
//           Text(
//             'No recent activity',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   final ride = recentRide!;

//   // return Container(
//   //   width: double.infinity,
//   //   height: 74,
//   //   padding: const EdgeInsets.all(16),
//   //   decoration: BoxDecoration(
//   //     color: Colors.white,
//   //     borderRadius: BorderRadius.circular(16),
//   //     border: Border.all(
//   //       color: const Color(0xFFE1E6ED),
//   //       width: 1,
//   //     ),
//   //   ),
//   //   child: Row(
//   //     mainAxisAlignment:
//   //         MainAxisAlignment.spaceBetween,
//   //     children: [
//   //       Row(
//   //         children: [
//   //           Container(
//   //             width: 42,
//   //             height: 42,
//   //             decoration: BoxDecoration(
//   //               color: const Color(0xFFF1F5F9),
//   //               borderRadius:
//   //                   BorderRadius.circular(12),
//   //             ),
//   //             child: const Icon(
//   //               Icons.local_taxi,
//   //               color: Colors.black,
//   //             ),
//   //           ),

//   //           const SizedBox(width: 12),

//   //           Column(
//   //             mainAxisAlignment:
//   //                 MainAxisAlignment.center,
//   //             crossAxisAlignment:
//   //                 CrossAxisAlignment.start,
//   //             children: [
//   //               Text(
//   //                 ride.pickupLocation ?? 'Pickup',
//   //                 maxLines: 1,
//   //                 overflow:
//   //                     TextOverflow.ellipsis,
//   //                 style: const TextStyle(
//   //                   fontSize: 13,
//   //                   fontWeight:
//   //                       FontWeight.w600,
//   //                 ),
//   //               ),

//   //               const SizedBox(height: 3),

//   //               Text(
//   //                 ride.destination ??
//   //                     'Destination',
//   //                 maxLines: 1,
//   //                 overflow:
//   //                     TextOverflow.ellipsis,
//   //                 style: const TextStyle(
//   //                   fontSize: 11,
//   //                   color: Colors.grey,
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ],
//   //       ),

//   //       Column(
//   //         mainAxisAlignment:
//   //             MainAxisAlignment.center,
//   //         crossAxisAlignment:
//   //             CrossAxisAlignment.end,
//   //         children: [
//   //           Text(
//   //             ride.status ?? '',
//   //             style: const TextStyle(
//   //               fontSize: 11,
//   //               fontWeight:
//   //                   FontWeight.w600,
//   //             ),
//   //           ),

//   //           const SizedBox(height: 3),

//   //           const Icon(
//   //             Icons.chevron_right,
//   //             color: Colors.grey,
//   //           ),
//   //         ],
//   //       ),
//   //     ],
//   //   ),
//   // );

//   return Material(
//   color: Colors.transparent,
//   child: InkWell(
//     borderRadius: BorderRadius.circular(16),
//     onTap: () => _openRecentRide(),
//     child: Container(
//       width: double.infinity,
//       constraints: const BoxConstraints(minHeight: 74),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: const Color(0xFFE1E6ED),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF1F5F9),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.local_taxi,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   ride.pickupLocation ?? 'Pickup',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   ride.destination ?? 'Destination',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 ride.status ?? '',
//                 style: const TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               const Icon(
//                 Icons.chevron_right,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ],
//       ),
//     ),
//   ),
// );
// }
 Widget _buildRecentRide() {
  if (isLoadingRecentRide) {
    return Container(
      width: double.infinity,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF015ACE),
        ),
      ),
    );
  }

  if (recentRide == null) {
    return Container(
      width: double.infinity,
      height: 74,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: const Row(
        children: [
          Icon(Icons.history, size: 22, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            'No recent activity',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  final ride = recentRide!;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openRecentRide,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE1E6ED),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_taxi,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.pickupLocation.isNotEmpty
                        ? ride.pickupLocation
                        : 'Pickup',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ride.destination.isNotEmpty
                        ? ride.destination
                        : 'Destination',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ride.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
 
 Widget _buildBottomNavigation() {
  return Container(
    width: double.infinity,
    height: 81,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(
          color: Color(0xFFE1E6ED),
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBottomNavItem(
          icon: Icons.home_rounded,
          label: 'Home',
          selected: true,
          onTap: () {},
        ),

        _buildBottomNavItem(
          icon: Icons.directions_car_rounded,
          label: 'Rides',
          selected: false,
          onTap: () {
            // Navigate to rides
          },
        ),

        _buildBottomNavItem(
          icon: Icons.person_rounded,
          label: 'Account',
          selected: false,
          onTap: () {
            // Navigate to account
          },
        ),
      ],
    ),
  );
}

Widget _buildBottomNavItem({
  required IconData icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF2685DD).withOpacity(0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF2685DD),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2685DD),
            ),
          ),
        ],
      ),
    ),
  );
}
 
 
 
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

  // Widget _buildLocation() {
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: 20),
//     padding: const EdgeInsets.symmetric(
//       horizontal: 16,
//       vertical: 8,
//     ),
//     decoration: BoxDecoration(
//       color: Colors.white.withOpacity(0.95),
//       borderRadius: BorderRadius.circular(9999),
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(
//           Icons.location_on,
//           size: 17,
//           color: Color(0xFF2685DD),
//         ),

//         const SizedBox(width: 8),

//         Flexible(
//           child: Text(
//             currentLocation ?? 'Westlands, Nairobi',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.black,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
  
  
  // Widget _buildServicesGrid(List<Map<String, dynamic>> services) {
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 4,
  //       crossAxisSpacing: 16,
  //       mainAxisSpacing: 16,
  //       childAspectRatio: 0.75,
  //     ),
  //     itemCount: services.length,
  //     itemBuilder: (context, index) {
  //       final service = services[index];
  //       return _buildServiceCard(
  //         context,
  //         title: service['name'],
  //         image: service['image'],
  //         color: service['color'],
  //         route: service['route'],
  //       );
  //     },
  //   );
  // }

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
  //       decoration: BoxDecoration(
  //         color: Colors.grey.shade100,
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           SizedBox(width: 35, height: 35, child: Image.asset(image)),
  //           const SizedBox(height: 6),

  //           /// 🔥 THIS FIXES "Clean Water" ISSUE COMPLETELY
  //           Expanded(
  //             child: FittedBox(
  //               fit: BoxFit.scaleDown,
  //               child: Text(
  //                 title,
  //                 textAlign: TextAlign.center,
  //                 maxLines: 2,
  //                 style: const TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
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
  //mbox
//   Future<List<Map<String, dynamic>>?> loadNearbyPlaces() async {
//   try {
//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.medium,
//     );

//     final url = Uri.parse(
//       "https://api.mapbox.com/search/searchbox/v1/category/"
//       "poi"
//       "?proximity=${position.longitude},${position.latitude}"
//       "&limit=3"
//       "&access_token=$mapboxAccessToken",
//     );

//     final response = await http
//         .get(url)
//         .timeout(const Duration(seconds: 5));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);

//       if (data["features"] != null) {
//         final features = data["features"] as List;

//         return features.map((place) {
//           final coordinates = place["geometry"]["coordinates"];

//           return {
//             "name": place["properties"]?["name"] ?? "Unknown Place",
//             "address": place["properties"]?["full_address"] ?? "",
//             "lat": coordinates[1],
//             "lng": coordinates[0],
//             "icon": Icons.place,
//           };
//         }).toList();
//       }
//     }
//   } catch (e) {
//     debugPrint("Mapbox nearby places error: $e");
//   }

//   return null;
// }

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