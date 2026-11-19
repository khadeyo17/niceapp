import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/machinery.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_detail_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/scedule_how_it_works_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/water_bower_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';


class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<RideHistory> allRides = [];
  List<RideHistory> pastRides = [];
  List<RideHistory> upcomingRides = [];
  bool isLoading = true;
  LatLng? currentLocation;
  TabController? _tabController;
  DateTime selectedMonth = DateTime.now();
  List<RideHistory>? _cachedRides;
  bool isMonthFilterApplied = false;
  bool _hasActiveRide = false;

  final ValueNotifier<LatLng?> currentLocationNotifier = ValueNotifier(null);

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 2, vsync: this);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     fetchRideHistory();
  //     _getCurrentLocation();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController!.addListener(() {
      setState(() {}); // 🔥 forces UI refresh when tab changes
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchRideHistory();
      _getCurrentLocation();
    });
  }

  

  Future<void> _getCurrentLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref(
      'passengers/${user.uid}/location',
    );
    ref.onValue.listen((event) {
      final location = event.snapshot.value as Map?;
      if (location != null) {
        final latLng = LatLng(location['latitude'], location['longitude']);
        currentLocationNotifier.value = latLng; // update notifier
        setState(() => currentLocation = latLng);
      }
    });
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

  Future<void> fetchRideHistory() async {
    if (_cachedRides != null) {
      setState(() {
        allRides = _cachedRides!;
        isLoading = false;
      });
      filterRides();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/passengerrides/passenger/history/${user.uid}'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final rides =
            data.map((json) => RideHistory.fromPassengerJson(json)).toList();

        _cachedRides = rides; // cache rides
        setState(() => allRides = rides);
        filterRides();
      }
    } catch (e) {
      debugPrint("Ride fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
void _clearMonthFilter() {
  setState(() {
    isMonthFilterApplied = false;
  });
}


  // void filterRides() {
  //   final now = DateTime.now();
  //   setState(() {
  //     pastRides =
  //         allRides
  //             .where((r) => r.status == "Completed" || r.status == "Cancelled")
  //             .toList();
  //     upcomingRides =
  //         allRides
  //             .where(
  //               (r) => r.scheduledDate != null && r.scheduledDate!.isAfter(now),
  //             )
  //             .toList();
  //   });
  // }

  void filterRides() {
  final now = DateTime.now();

  setState(() {
    // PAST: Completed and Cancelled rides
    pastRides = allRides.where((r) {
      final status = r.status.trim().toLowerCase();

      return status == 'completed' ||
          status == 'cancelled';
    }).toList();

    // UPCOMING: Scheduled rides and future active rides
    upcomingRides = allRides.where((r) {
      final status = r.status.trim().toLowerCase();

      // Never include completed or cancelled rides
      if (status == 'completed' || status == 'cancelled') {
        return false;
      }

      // Scheduled rides
      if (status == 'scheduled') {
        return true;
      }

      // Other rides with a future scheduled date
      return r.scheduledDate != null &&
          r.scheduledDate!.isAfter(now);
    }).toList();
  });

  debugPrint('========== FILTERED RIDES ==========');
  debugPrint('All rides: ${allRides.length}');
  debugPrint('Past rides: ${pastRides.length}');
  debugPrint('Upcoming rides: ${upcomingRides.length}');

  for (final ride in upcomingRides) {
    debugPrint(
      'Upcoming: ID=${ride.id}, '
      'Status=${ride.status}, '
      'Scheduled=${ride.scheduledDate}',
    );
  }

  debugPrint('====================================');
}

  void _selectMonth(BuildContext context) async {
  final picked = await showMonthPicker(
    context: context,
    initialDate: selectedMonth,
    firstDate: DateTime(DateTime.now().year - 2),
    lastDate: DateTime(DateTime.now().year + 1),
  );

  if (picked != null) {
    setState(() {
      selectedMonth = picked;
      isMonthFilterApplied = true;
    });
  }
}
  // List<RideHistory> _getFilteredRides(List<RideHistory> rides) {
  //   return rides.where((r) {
  //     final date = r.dropoffTime ?? r.scheduledDate;
  //     if (date == null) return false;
  //     return date.year == selectedMonth.year &&
  //         date.month == selectedMonth.month;
  //   }).toList();
  // }

 List<RideHistory> _getFilteredRides(
  List<RideHistory> rides, {
  required bool past,
}) {
  return rides.where((r) {
    final status = r.status.trim().toLowerCase();

    // =====================================================
    // PAST RIDES
    // =====================================================
    if (past) {
      // Only completed/cancelled rides
      if (status != 'completed' && status != 'cancelled') {
        return false;
      }

      // If no month filter is selected,
      // SHOW ALL PAST RIDES
      if (!isMonthFilterApplied) {
        return true;
      }

      // When month filter is active,
      // use actual dropoff date first
      final date = r.dropoffTime ?? r.scheduledDate;

      if (date == null) {
        return false;
      }

      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }

    // =====================================================
    // UPCOMING RIDES
    // =====================================================

    // Completed/cancelled rides aren't upcoming
    if (status == 'completed' || status == 'cancelled') {
      return false;
    }

    final date = r.scheduledDate;

    if (date == null) {
      return false;
    }

    // Must actually be in the future
    if (!date.isAfter(DateTime.now())) {
      return false;
    }

    // If no month filter is selected,
    // SHOW ALL UPCOMING RIDES
    if (!isMonthFilterApplied) {
      return true;
    }

    // Month filter selected
    return date.year == selectedMonth.year &&
        date.month == selectedMonth.month;
  }).toList();
}

  Widget _buildRideList(List<RideHistory> rides) {
    if (rides.isEmpty) {
      return const Center(
        child: Text(
          "No rides found",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        return ValueListenableBuilder<LatLng?>(
          valueListenable: currentLocationNotifier,
          builder: (_, location, __) {
            return UberStyleRideTile(
              ride: rides[index],
              currentLocation: location,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

  final filteredPastRides = _getFilteredRides(
    pastRides,
    past: true,
  );

  final filteredUpcomingRides = _getFilteredRides(
    upcomingRides,
    past: false,
  );
    
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title:  Text(
         
         
          "Your Trips",

          
          //style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          style: GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
        ),

          
        
        centerTitle: true,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelStyle:  
          
           GoogleFonts.spaceGrotesk(

            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
        actions: [
  // Show selected month only when filter is active
  if (isMonthFilterApplied)
    Center(
      child: Text(
        DateFormat('MMM yyyy').format(selectedMonth),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
        ),
      ),
    ),

  // Month filter button
  IconButton(
    icon: Icon(
      Icons.date_range,
      color: isMonthFilterApplied
          ? const Color(0xFF015ACE)
          : Colors.black54,
    ),
    tooltip: 'Filter by month',
    onPressed: () => _selectMonth(context),
  ),

  // Clear month filter
  if (isMonthFilterApplied)
    IconButton(
      icon: const Icon(Icons.close),
      tooltip: 'Clear date filter',
      onPressed: _clearMonthFilter,
    ),
],
      ),
      floatingActionButton:
          _tabController!.index == 0
              ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF015ACE),
                onPressed: _navigateToPlanAhead,
                // () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder:
                //           (_) => const WhereToScreen(
                //             category: VehicleCategory.passenger,
                //             IsScheduled: true,
                //           ),
                //     ),
                //   );
                // },
               // icon: const Icon(Icons.schedule),
                label:  Text(
                  "Plan ahead",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
              : null,

//               body: TabBarView(
//   controller: _tabController,
//   children: [
//     // PAST
//     isLoading
//         ? const Center(
//             child: CircularProgressIndicator(
//               color: Color(0xFF015ACE),
//             ),
//           )
//         : _buildRideList(
//             _getFilteredRides(pastRides),
//           ),

//     // UPCOMING
//     isLoading
//         ? const Center(
//             child: CircularProgressIndicator(
//               color: Color(0xFF015ACE),
//             ),
//           )
//         : _getFilteredRides(upcomingRides).isEmpty
//             ? _buildUpcomingEmptyState(context)
//             : _buildRideList(
//                 _getFilteredRides(upcomingRides),
//               ),
//   ],
// ),

body: TabBarView(
  controller: _tabController,
  children: [

   

    // UPCOMING
    isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF015ACE),
            ),
          )
        : filteredUpcomingRides.isEmpty
            ? _buildUpcomingEmptyState(context)
            : _buildRideList(filteredUpcomingRides),

        // PAST
         
      isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF015ACE),
            ),
          )
        : filteredPastRides.isEmpty
            ? _buildPastEmptyState(context)
            : _buildRideList(filteredPastRides),
  ],
),

      // body: TabBarView(
      //   controller: _tabController,
      //   children: [
      //     isLoading
      //         ? const Center(
      //           child: CircularProgressIndicator(color:  Color(0xFF015ACE)),
      //         )
      //         : _buildRideList(_getFilteredRides(pastRides)),
      //     isLoading
      //         ? const Center(
      //           child: CircularProgressIndicator(color:  Color(0xFF015ACE),),
      //         )
      //         : _buildRideList(_getFilteredRides(upcomingRides)),
      //   ],
      // ),
    );
  }
}

Widget _buildPastEmptyState(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_rounded,
            size: 70,
            color: Color(0xFF015ACE),
          ),

          const SizedBox(height: 20),

          Text(
            "No past rides",
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Your completed and cancelled rides will appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildUpcomingEmptyState(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF015ACE).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 38,
              color: Color(0xFF015ACE),
            ),
          ),

          const SizedBox(height: 18),

           Text(
            "No upcoming trips",
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

           Text(
            "You don't have any scheduled trips yet. "
            "Schedule a ride and we'll have it ready for you.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              height: 1.5,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 18),

          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HowItWorksScreen(),
                ),
              );
            },
            child:  Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF015ACE),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Learn how it works",
                    style: GoogleFonts.spaceGrotesk(
                      color: Color(0xFF015ACE),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF015ACE),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
class UberStyleRideTile extends ConsumerWidget {
  final RideHistory ride;
  final VehicleCategory? category;
  final LatLng? currentLocation;

  const UberStyleRideTile({
    super.key,
    required this.ride,
    this.category,
    required this.currentLocation,
  });
void _rebookRide(
  BuildContext context,
  RideHistory ride,
) {
  if (currentLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location not ready"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final destination = LatLng(
    ride.destinationLatitude,
    ride.destinationLongitude,
  );

  final selectedCategory =
      category ?? _getVehicleCategory(ride);

  debugPrint(
    "REBOOK CATEGORY: $selectedCategory",
  );

  late Widget destinationScreen;

  switch (selectedCategory) {
    case VehicleCategory.passenger:
      destinationScreen = HomeScreen(
        pickup: currentLocation!,
        destination: destination,
        category: VehicleCategory.passenger,
      );
      break;

    case VehicleCategory.waterBowser:
      destinationScreen = WaterBowerScreen(
        category: VehicleCategory.waterBowser,
        destination: destination,
      );
      break;

    case VehicleCategory.exhauster:
      destinationScreen = HoneySuckerScreen(
        category: VehicleCategory.exhauster,
        destination: destination,
      );
      break;

    case VehicleCategory.machinery:
      destinationScreen = MachineryScreen(
        category: VehicleCategory.machinery,
        destination: destination,
      );
      break;

    default:
      destinationScreen = HomeScreen(
        pickup: currentLocation!,
        destination: destination,
        category: VehicleCategory.passenger,
      );
      break;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => destinationScreen,
    ),
  );
}
  
  VehicleCategory _getVehicleCategory(RideHistory ride) {
  final value = ride.vehicleCategory
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll('-', '')
      .replaceAll(' ', '');

  debugPrint("Ride subCategory: ${ride.vehicleCategory}");
  debugPrint("Normalized category: $value");

  switch (value) {
    case 'ridebooking':
    case 'passenger':
    case 'ride':
      return VehicleCategory.passenger;

    case 'waterbowser':
      return VehicleCategory.waterBowser;

    case 'exhauster':
    case 'honeysucker':
      return VehicleCategory.exhauster;

    case 'machinery':
    case 'machine':
      return VehicleCategory.machinery;

    default:
      debugPrint(
        "UNKNOWN RIDE CATEGORY: ${ride.subCategory}",
      );

      return VehicleCategory.passenger;
  }
}
  
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsset =
        ride.vehicleType == "bike"
            ? "assets/imgs/bike.png"
            : "assets/imgs/aminicar.jpeg";

    final isCancelled = ride.status?.toLowerCase() == "cancelled";

    final date = ride.dropoffTime ?? ride.scheduledDate;

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🚗 VEHICLE IMAGE + CANCEL OVERLAY
                // Stack(
                //   children: [
                //     ClipRRect(
                //       borderRadius: BorderRadius.circular(10),
                //       child: Opacity(
                //         opacity: isCancelled ? 1 : 1, // fade if cancelled
                //         child: Image.asset(
                //           imageAsset,
                //           height: 48,
                //           width: 48,
                //           fit: BoxFit.cover,
                //         ),
                //       ),
                //     ),

                //     /// ❌ CROSS IF CANCELLED
                //     if (isCancelled)
                //       Positioned.fill(
                //         child: Container(
                //           decoration: BoxDecoration(
                //             borderRadius: BorderRadius.circular(10),
                //           ),
                //           child: const Center(
                //             child: Icon(
                //               Icons.close,
                //               color: Colors.red,
                //               size: 48,
                //               weight: 900,
                //             ),
                //           ),
                //         ),
                //       ),
                //   ],
                // ),
                /// VEHICLE ICON + STATUS BELOW
// Column(
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     ClipRRect(
//       borderRadius: BorderRadius.circular(10),
//       child: Image.asset(
//         imageAsset,
//         height: 48,
//         width: 48,
//         fit: BoxFit.cover,
//       ),
//     ),
//     const SizedBox(height: 5),
//     Text(
//       isCancelled ? 'Cancelled' : 'Completed',
//       style: TextStyle(
//         fontFamily: 'Nunito Sans',
//         fontSize: 10,
//         fontWeight: FontWeight.w700,
//         color: isCancelled
//             ? Colors.grey.shade600
//             : const Color(0xFF0E9E8C),
//       ),
//     ),
//   ],
// ),
// const SizedBox(width: 10),

                //const SizedBox(width: 10),

                Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    /// VEHICLE CATEGORY
    

    const SizedBox(height: 5),

    /// VEHICLE IMAGE
    ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        imageAsset,
        height: 48,
        width: 48,
        fit: BoxFit.cover,
      ),
    ),

    const SizedBox(height: 5),

    /// RIDE STATUS
    Text(
      isCancelled ? 'Cancelled' : 'Completed',
      style: TextStyle(
        fontFamily: 'Nunito Sans',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isCancelled
            ? Colors.red
            : Colors.grey[900],
      ),
    ),
  ],
),
const SizedBox(width: 10),

                /// 📍 DETAILS
                Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
      ride.vehicleCategory ?? '',
      style: const TextStyle(
        fontFamily: 'Nunito Sans',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF015ACE),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
      
     Text(
  (ride.destination ?? "Unknown destination").isEmpty
      ? "Unknown destination"
      : (ride.destination ?? "Unknown destination")[0].toUpperCase() +
          (ride.destination ?? "Unknown destination")
              .substring(1)
              .toLowerCase(),
  style: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),

      const SizedBox(height: 3),

      Text(
        ride.contactName ?? "",
        style: TextStyle(
          fontSize: 12,
          color: Colors.black.withOpacity(0.7),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      const SizedBox(height: 3),

      Text(
        "KES ${ride.fare.toStringAsFixed(0)}",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),

      const SizedBox(height: 4),

      if (date != null)
        Text(
          DateFormat('dd MMM yyyy, HH:mm').format(date),
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
    ],
  ),
),

                Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    const SizedBox(height: 4),

    /// 🔁 REBOOK
    InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _rebookRide(context, ride),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[500],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              "Rebook",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
)
              ],
            ),
          ),
        ),
        Divider(
          height: 1, // 🔥 removes vertical spacing
          thickness: 1,
          indent: 20,
          endIndent: 20,
          color: Colors.grey.withOpacity(0.4),
        ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 20),
        //   child: Divider(thickness: 1, color: Colors.grey.withOpacity(0.4)),
        // ),
      ],
    );
  }
}

// class UberStyleRideTile extends ConsumerWidget {
//   final RideHistory ride;
//   final LatLng? currentLocation;

//   const UberStyleRideTile({
//     super.key,
//     required this.ride,
//     required this.currentLocation,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final imageAsset =
//         ride.vehicleType == "bike"
//             ? "assets/imgs/bike.png"
//             : "assets/imgs/aminicar.jpeg";

//     Color statusColor;
//     switch (ride.status?.toLowerCase()) {
//       case 'completed':
//         statusColor = Colors.green;
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         break;
//       default:
//         statusColor = Colors.blue;
//     }

//     final date = ride.dropoffTime ?? ride.scheduledDate;

//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
//         );
//       },
//       child: Card(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//         color: Colors.white,
//         elevation: 0, // ❗ no shadow
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(14),
//           side: BorderSide(
//             color: Colors.grey.withOpacity(0.8), // ✅ black border
//             width: 1,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// 🚗 VEHICLE IMAGE
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.asset(
//                   imageAsset,
//                   height: 55,
//                   width: 55,
//                   fit: BoxFit.cover,
//                 ),
//               ),

//               const SizedBox(width: 14),

//               /// 📍 RIDE DETAILS
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     /// DESTINATION
//                     Text(
//                       ride.destination ?? "Unknown destination",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),

//                     const SizedBox(height: 6),

//                     /// DRIVER / COMPANY
//                     Text(
//                       ride.contactName ?? "",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black.withOpacity(0.7),
//                       ),
//                     ),

//                     const SizedBox(height: 4),

//                     /// FARE
//                     Text(
//                       "KES ${ride.fare.toStringAsFixed(0)}",
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),

//                     const SizedBox(height: 6),

//                     /// DATE
//                     if (date != null)
//                       Text(
//                         DateFormat('dd MMM yyyy, HH:mm').format(date),
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.black.withOpacity(0.5),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               /// 👉 RIGHT SIDE (STATUS + REBOOK)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   /// STATUS BADGE
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[400],
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: statusColor),
//                     ),
//                     child: Text(
//                       ride.status ?? "Unknown",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   /// 🔁 REBOOK BUTTON (MODERN)
//                   InkWell(
//                     borderRadius: BorderRadius.circular(20),
//                     onTap: () {
//                       if (currentLocation == null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text("Location not ready"),
//                             backgroundColor: Colors.red,
//                           ),
//                         );
//                         return;
//                       }

//                       final destination = LatLng(
//                         ride.destinationLatitude,
//                         ride.destinationLongitude,
//                       );

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => HomeScreen(
//                                 pickup: currentLocation!,
//                                 destination: destination,
//                                 stops: ref.read(stopsProvider),
//                                 category: VehicleCategory.passenger,
//                               ),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.blue, //.withOpacity(0.08),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.white),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Icon(Icons.refresh, size: 16, color: Colors.white),
//                           SizedBox(width: 4),
//                           Text(
//                             "Rebook",
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class UberStyleRideTile extends ConsumerWidget {
//   final RideHistory ride;
//   final LatLng? currentLocation;

//   const UberStyleRideTile({
//     super.key,
//     required this.ride,
//     required this.currentLocation,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final imageAsset =
//         ride.vehicleType == "bike"
//             ? "assets/imgs/bike.png"
//             : "assets/imgs/aminicar.jpeg";

//     Color statusColor;
//     switch (ride.status?.toLowerCase()) {
//       case 'completed':
//         statusColor = Colors.green;
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         break;
//       default:
//         statusColor = Colors.blue;
//     }

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
//         );
//       },
//       child: Card(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         elevation: 3,
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.asset(
//                   imageAsset,
//                   height: 50,
//                   width: 50,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "${ride.destination}",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       "Driver/Company: ${ride.contactName}",
//                       style: const TextStyle(fontSize: 14, color: Colors.black),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "Fare: KES ${ride.fare.toStringAsFixed(0)}",
//                       style: const TextStyle(fontSize: 14, color: Colors.black),
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: statusColor),
//                     ),
//                     child: Text(
//                       ride.status ?? "Unknown",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: statusColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     ride.dropoffTime != null
//                         ? DateFormat('dd MMM').format(ride.dropoffTime!)
//                         : ride.scheduledDate != null
//                         ? DateFormat('dd MMM').format(ride.scheduledDate!)
//                         : 'N/A',
//                     style: const TextStyle(fontSize: 12, color: Colors.black45),
//                   ),
//                   TextButton.icon(
//                     onPressed: () {
//                       if (currentLocation == null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text(
//                               "Current location not available yet.",
//                             ),
//                             backgroundColor: Colors.red,
//                           ),
//                         );
//                         return;
//                       }
//                       final destination = LatLng(
//                         ride.destinationLatitude,
//                         ride.destinationLongitude,
//                       );
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (_) => HomeScreen(
//                                 pickup: currentLocation!,
//                                 destination: destination,
//                                 stops: ref.read(stopsProvider),
//                                 category: VehicleCategory.passenger,
//                               ),
//                         ),
//                       );
//                     },
//                     icon: Icon(
//                       Icons.repeat,
//                       color: Colors.blue.shade700,
//                       size: 18,
//                     ),
//                     label: Text(
//                       "Rebook",
//                       style: TextStyle(
//                         color: Colors.blue.shade700,
//                         fontSize: 13,
//                       ),
//                     ),
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.zero,
//                       minimumSize: const Size(50, 30),
//                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class UberStyleRideTile extends ConsumerWidget {
//   final RideHistory ride;
//   final LatLng? currentLocation;

//   const UberStyleRideTile({
//     super.key,
//     required this.ride,
//     required this.currentLocation,
//   });

//   VehicleCategory _mapCategory(String? type) {
//     switch (type?.toLowerCase()) {
//       case "exhauster":
//         return VehicleCategory.exhauster;
//       case "cargo":
//         return VehicleCategory.cargo;
//       case "waterbowser":
//         return VehicleCategory.waterBowser;
//       default:
//         return VehicleCategory.passenger;
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final imageAsset =
//         ride.vehicleType == "bike"
//             ? "assets/imgs/bike.png"
//             : "assets/imgs/aminicar.jpeg";

//     final date = ride.dropoffTime ?? ride.scheduledDate;

//     Color statusColor;
//     switch (ride.status?.toLowerCase()) {
//       case 'completed':
//         statusColor = Colors.green;
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         break;
//       default:
//         statusColor = Colors.blue;
//     }

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.grey.shade200), // ✅ BORDER ADDED
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.03),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.asset(
//                 imageAsset,
//                 height: 55,
//                 width: 55,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(width: 14),

//             /// 🔥 DETAILS
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     ride.destination ?? "Unknown destination",
//                     style: const TextStyle(
//                       fontSize: 17, // 🔥 improved
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 6),

//                   Text(
//                     ride.contactName ?? "",
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
//                   ),

//                   const SizedBox(height: 4),

//                   Text(
//                     "KES ${ride.fare.toStringAsFixed(0)}",
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),

//                   const SizedBox(height: 6),

//                   /// ✅ EXACT DATE
//                   if (date != null)
//                     Text(
//                       DateFormat('dd MMM yyyy, HH:mm').format(date),
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             /// 🔥 RIGHT SIDE
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 /// STATUS CHIP
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: statusColor.withOpacity(0.08),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: statusColor.withOpacity(0.4)),
//                   ),
//                   child: Text(
//                     ride.status ?? "Unknown",
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: statusColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 /// 🔥 MODERN REBOOK (ICON ONLY / CLEAN)
//                 InkWell(
//                   borderRadius: BorderRadius.circular(20),
//                   onTap: () {
//                     if (currentLocation == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Location not ready"),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                       return;
//                     }

//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder:
//                             (_) => WhereToScreen(
//                               category: _mapCategory(
//                                 ride.vehicleType,
//                               ), // ✅ dynamic
//                               IsScheduled: false, // ✅ blank new ride
//                             ),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.refresh,
//                       size: 18,
//                       color: Colors.grey.shade800,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:month_picker_dialog/month_picker_dialog.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
// import 'package:niceapp/View/Screens/Other_Screens/ride_detail_screen.dart';
// import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

// class RideHistoryScreen extends StatefulWidget {
//   const RideHistoryScreen({super.key});

//   @override
//   State<RideHistoryScreen> createState() => _RideHistoryScreenState();
// }

// class _RideHistoryScreenState extends State<RideHistoryScreen>
//     with SingleTickerProviderStateMixin {
//   List<RideHistory> allRides = [];
//   List<RideHistory> pastRides = [];
//   List<RideHistory> upcomingRides = [];

//   LatLng? currentLocation;
//   TabController? _tabController;
//   DateTime selectedMonth = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     //_tabController = TabController(length: 2, vsync: this);

//     _tabController = TabController(length: 2, vsync: this);
//     _tabController!.addListener(() {
//       setState(() {});
//     });
//     fetchRideHistory();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final ref = FirebaseDatabase.instance.ref(
//       'passengers/${user.uid}/location',
//     );
//     ref.onValue.listen((event) {
//       final location = event.snapshot.value as Map?;
//       if (location != null) {
//         final lat = location['latitude'];
//         final lng = location['longitude'];
//         setState(() {
//           currentLocation = LatLng(lat, lng);
//         });
//       }
//     });
//   }

//   Future<void> fetchRideHistory() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final response = await http.get(
//       Uri.parse('$baseUrl/passengerrides/passenger/history/${user.uid}'),
//     );

//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(response.body);
//       allRides =
//           data.map((json) => RideHistory.fromPassengerJson(json)).toList();
//       filterRides();
//     } else {
//       print("Failed to load ride history");
//     }
//   }

//   void filterRides() {
//     final now = DateTime.now();
//     final futureLimit = now.add(const Duration(days: 60));

//     setState(() {
//       pastRides =
//           allRides
//               .where(
//                 (r) => //r.status != null,
//                     r.status == "Completed" ||
//                     r.status ==
//                         "Cancelled", //dropoffTime != null && r.dropoffTime!.isBefore(now),
//               )
//               .toList();
//       upcomingRides =
//           allRides
//               .where(
//                 (r) =>
//                     r.scheduledDate != null &&
//                     r.scheduledDate!.isAfter(now), // &&
//                 //r.scheduledDate!.isBefore(futureLimit),
//               )
//               .toList();
//     });
//   }

//   void _selectMonth(BuildContext context) async {
//     final picked = await showMonthPicker(
//       context: context,
//       initialDate: selectedMonth,
//       firstDate: DateTime(DateTime.now().year - 2),
//       lastDate: DateTime(DateTime.now().year + 1),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedMonth = picked;
//       });
//     }
//   }
//   // void _selectMonth(BuildContext context) async {
//   //   final now = DateTime.now();
//   //   final picked = await showDatePicker(
//   //     context: context,
//   //     initialDate: selectedMonth,
//   //     firstDate: DateTime(now.year - 2),
//   //     lastDate: DateTime(now.year + 1),
//   //     helpText: 'Select Month',
//   //   );

//   //   if (picked != null) {
//   //     setState(() => selectedMonth = picked);
//   //   }
//   // }

//   // List<RideHistory> _getFilteredRides(List<RideHistory> rides) {
//   //   return rides
//   //       .where(
//   //         (r) => r.id > 0,
//   //         // &&              r.dropoffTime!.year == selectedMonth.year &&
//   //         // r.dropoffTime!.month == selectedMonth.month,
//   //       )
//   //       .toList();
//   // }

//   Widget _buildRideList(List<RideHistory> rides, bool isUpcoming) {
//     if (rides.isEmpty) {
//       return const Center(child: Text("No rides found"));
//     }

//     return ListView.builder(
//       itemCount: rides.length,
//       itemBuilder: (context, index) {
//         final ride = rides[index];
//         return UberStyleRideTile(ride: ride, currentLocation: currentLocation);
//       },
//     );
//   }

//   List<RideHistory> _getFilteredRides(List<RideHistory> rides) {
//     return rides.where((r) {
//       final date = r.dropoffTime ?? r.scheduledDate;
//       if (date == null) return false;

//       return date.year == selectedMonth.year &&
//           date.month == selectedMonth.month;
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final isUpcomingTab = _tabController!.index == 1;
//     // final ridesToShow =
//     //     isUpcomingTab
//     //         ? _getFilteredRides(upcomingRides)
//     //         : _getFilteredRides(pastRides);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Your Trips"),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,

//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [Tab(text: 'Past'), Tab(text: 'Upcoming')],
//           onTap: (_) => setState(() {}),
//         ),
//         actions: [
//           Center(
//             child: Text(
//               DateFormat('MMM yyyy').format(selectedMonth),
//               style: const TextStyle(color: Colors.black54, fontSize: 14),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.date_range),
//             onPressed: () => _selectMonth(context),
//           ),
//         ],

//         // actions: [
//         //   const SizedBox(width: 10),
//         //   Text(
//         //     DateFormat('MMM yyyy').format(selectedMonth),
//         //     style: const TextStyle(fontSize: 14, color: Colors.black54),
//         //   ),
//         // ],
//       ),
//       floatingActionButton:
//           _tabController!.index == 1
//               ? FloatingActionButton.extended(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (_) => const WhereToScreen(
//                             category: VehicleCategory.passenger,
//                             IsScheduled: true,
//                           ),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.schedule),
//                 label: const Text("Schedule Ride"),
//               )
//               : null,

//       // floatingActionButton:
//       //     isUpcomingTab
//       //         ? FloatingActionButton.extended(
//       //           onPressed: () {
//       //             Navigator.push(
//       //               context,
//       //               MaterialPageRoute(
//       //                 builder:
//       //                     (_) => const WhereToScreen(
//       //                       category: VehicleCategory.passenger,
//       //                       IsScheduled: true,
//       //                     ), //ScheduleRideScreen(),
//       //               ),
//       //             );
//       //           },
//       //           icon: const Icon(Icons.schedule),
//       //           label: const Text("Schedule Ride"),
//       //         )
//       //         : null,
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildRideList(_getFilteredRides(pastRides), false),
//           _buildRideList(_getFilteredRides(upcomingRides), true),
//         ],
//       ),
//       // body:
//       //     ridesToShow.isEmpty
//       //         ? const Center(child: Text("No rides found"))
//       //         : ListView.builder(
//       //           itemCount: ridesToShow.length,
//       //           itemBuilder: (context, index) {
//       //             final ride = ridesToShow[index];
//       //             return UberStyleRideTile(
//       //               ride: ride,
//       //               currentLocation: currentLocation,
//       //             );
//       //           },
//       //         ),
//     );
//   }
// }

// class UberStyleRideTile extends ConsumerWidget {
//   final RideHistory ride;
//   final LatLng? currentLocation;

//   const UberStyleRideTile({
//     super.key,
//     required this.ride,
//     required this.currentLocation,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final imageAsset =
//         ride.vehicleType == "bike"
//             ? "assets/imgs/bike.png"
//             : "assets/imgs/aminicar.jpeg";

//     // Define status color
//     Color statusColor;
//     String statusLabel = ride.status ?? "Unknown";

//     switch (ride.status?.toLowerCase()) {
//       case 'completed':
//         statusColor = Colors.green;
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         break;
//       default:
//         statusColor = Colors.blue;
//     }

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
//         );
//       },
//       child: Card(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.asset(
//                       imageAsset,
//                       height: 40,
//                       width: 40,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "${ride.pickupLocation} → ${ride.destination}",
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "Driver/Company: ${ride.contactName}",
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.black54,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           "Fare: KES ${ride.fare.toStringAsFixed(0)}",
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.black54,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           border: Border.all(color: statusColor),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           statusLabel,
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: statusColor,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         ride.dropoffTime != null
//                             ? DateFormat('dd MMM').format(ride.dropoffTime!)
//                             : ride.scheduledDate != null
//                             ? DateFormat('dd MMM').format(ride.scheduledDate!)
//                             : 'N/A',
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: Colors.black45,
//                         ),
//                       ),
//                       TextButton.icon(
//                         onPressed: () {
//                           if (currentLocation == null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                   "Current location not available yet.",
//                                 ),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                             return;
//                           }

//                           final destination = LatLng(
//                             ride.destinationLatitude,
//                             ride.destinationLongitude,
//                           );

//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (_) => HomeScreen(
//                                     pickup: currentLocation!,
//                                     destination: destination,
//                                     stops: ref.read(stopsProvider),
//                                     category: VehicleCategory.passenger,
//                                   ),
//                             ),
//                           );
//                         },
//                         icon: Icon(
//                           Icons.repeat,
//                           color: Colors.blue.shade700,
//                           size: 18,
//                         ),
//                         label: Text(
//                           "Rebook",
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontSize: 12,
//                           ),
//                         ),
//                         style: TextButton.styleFrom(
//                           padding: EdgeInsets.zero,
//                           minimumSize: const Size(50, 30),
//                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final imageAsset =
//         ride.vehicleType == "bike"
//             ? "assets/imgs/bike.png"
//             : "assets/imgs/aminicar.jpeg";

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
//         );
//       },
//       child: Card(
//         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 1.5,
//         color: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.asset(
//                       imageAsset,
//                       height: 35,
//                       width: 35,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "${ride.pickupLocation} → ${ride.destination}",
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           "Driver: ${ride.contactName}",
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),
//                         Text(
//                           "Fare: KES ${ride.fare.toStringAsFixed(0)}",
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         ride.dropoffTime != null
//                             ? DateFormat('dd MMM').format(ride.dropoffTime!)
//                             : 'N/A',
//                         style: const TextStyle(
//                           color: Colors.black54,
//                           fontSize: 11,
//                         ),
//                       ),
//                       TextButton.icon(
//                         onPressed: () {
//                           if (currentLocation == null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                   "Current location not available yet. Please wait.",
//                                 ),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                             return;
//                           }

//                           final destination = LatLng(
//                             ride.destinationLatitude,
//                             ride.destinationLongitude,
//                           );

//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (_) => HomeScreen(
//                                     pickup: currentLocation!,
//                                     destination: destination,
//                                     stops: ref.read(stopsProvider),
//                                     category: VehicleCategory.passenger,
//                                   ),
//                             ),
//                           );
//                         },
//                         icon: Icon(
//                           Icons.repeat,
//                           color: Colors.blue.shade700,
//                           size: 18,
//                         ),
//                         label: Text(
//                           "Rebook",
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontSize: 12,
//                           ),
//                         ),
//                         style: TextButton.styleFrom(
//                           padding: EdgeInsets.zero,
//                           minimumSize: const Size(50, 30),
//                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
