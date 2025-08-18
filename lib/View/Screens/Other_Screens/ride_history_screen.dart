import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_detail_screen.dart';
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

  LatLng? currentLocation;
  TabController? _tabController;
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      setState(() {});
    });
    fetchRideHistory();
    _getCurrentLocation();
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
        setState(() {
          currentLocation = LatLng(location['latitude'], location['longitude']);
        });
      }
    });
  }

  Future<void> fetchRideHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/rides/passenger/history/${user.uid}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      allRides =
          data.map((json) => RideHistory.fromPassengerJson(json)).toList();
      filterRides();
    }
  }

  void filterRides() {
    final now = DateTime.now();
    setState(() {
      pastRides =
          allRides
              .where((r) => r.status == "Completed" || r.status == "Cancelled")
              .toList();
      upcomingRides =
          allRides
              .where(
                (r) => r.scheduledDate != null && r.scheduledDate!.isAfter(now),
              )
              .toList();
    });
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
      });
    }
  }

  List<RideHistory> _getFilteredRides(List<RideHistory> rides) {
    return rides.where((r) {
      final date = r.dropoffTime ?? r.scheduledDate;
      if (date == null) return false;
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
        return UberStyleRideTile(
          ride: rides[index],
          currentLocation: currentLocation,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Your Trips",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [Tab(text: 'Past'), Tab(text: 'Upcoming')],
        ),
        actions: [
          Center(
            child: Text(
              DateFormat('MMM yyyy').format(selectedMonth),
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      floatingActionButton:
          _tabController!.index == 1
              ? FloatingActionButton.extended(
                backgroundColor: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => const WhereToScreen(
                            category: VehicleCategory.passenger,
                            IsScheduled: true,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.schedule),
                label: const Text(
                  "Schedule Ride",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
              : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRideList(_getFilteredRides(pastRides)),
          _buildRideList(_getFilteredRides(upcomingRides)),
        ],
      ),
    );
  }
}

class UberStyleRideTile extends ConsumerWidget {
  final RideHistory ride;
  final LatLng? currentLocation;

  const UberStyleRideTile({
    super.key,
    required this.ride,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsset =
        ride.vehicleType == "bike"
            ? "assets/imgs/bike.png"
            : "assets/imgs/aminicar.jpeg";

    Color statusColor;
    switch (ride.status?.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RideDetailsScreen(ride: ride)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageAsset,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${ride.pickupLocation} → ${ride.destination}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Driver/Company: ${ride.contactName}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Fare: KES ${ride.fare.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      ride.status ?? "Unknown",
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ride.dropoffTime != null
                        ? DateFormat('dd MMM').format(ride.dropoffTime!)
                        : ride.scheduledDate != null
                        ? DateFormat('dd MMM').format(ride.scheduledDate!)
                        : 'N/A',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (currentLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Current location not available yet.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final destination = LatLng(
                        ride.destinationLatitude,
                        ride.destinationLongitude,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => HomeScreen(
                                pickup: currentLocation!,
                                destination: destination,
                                stops: ref.read(stopsProvider),
                                category: VehicleCategory.passenger,
                              ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.repeat,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    label: Text(
                      "Rebook",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
//       Uri.parse('$baseUrl/rides/passenger/history/${user.uid}'),
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
