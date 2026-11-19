import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';
import 'package:niceapp/main.dart';

class RideStatusBanner extends ConsumerStatefulWidget {
  final String userId;
  const RideStatusBanner({super.key, required this.userId});

  @override
  ConsumerState<RideStatusBanner> createState() => _RideStatusBannerState();
}

class _RideStatusBannerState extends ConsumerState<RideStatusBanner>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _heightAnimation;

  double _bottom = 20;
  double _left = 16;
  final double _bannerWidth = 300;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnimation = Tween<double>(
      begin: 70,
      end: 150,
    ).animate(_animationController);
  }

  // void _navigateToLiveRide({
  //   required String rideId,
  //   required String driverId,
  //   required LatLng pickup,
  //   required LatLng destination,
  // }) {
  //   // Optionally collapse banner
  //   setState(() {
  //     _isExpanded = false;
  //     _animationController.reverse();
  //   });

  //   navigatorKey.currentState?.push(
  //     MaterialPageRoute(
  //       builder:
  //           (_) => RideInProgressLiveScreen(
  //             rideId: rideId,
  //             driverId: driverId,
  //             pickup: pickup,
  //             destination: destination,
  //           ),
  //       settings: const RouteSettings(name: '/rideInProgress'),
  //     ),
  //   );
  // }

  // void _navigateToRideScreen(RideInfo rideInfo) {
  //   // Hide banner before navigating
  //   setState(() {
  //     _isExpanded = false;
  //     _animationController.reverse();
  //   });

  //   if (rideInfo.status == RideStatus.assigned) {
  //     navigatorKey.currentState?.push(
  //       MaterialPageRoute(
  //         // builder:
  //         //     (_) => DriverConfirmationScreen(
  //         //       rideId: rideInfo.rideId,
  //         //       pickup: LatLng(rideInfo.pickup.latitude,rideInfo.pickup.longitude),
  //         //       //pickupLng: rideInfo.pickup.longitude,
  //         //       destination: LatLng(rideInfo.destination.latitude,rideInfo.destination.longitude),
  //         //       : rideInfo.destination.longitude,
  //         //       rider: rideInfo.riderName,
  //         //       mobile: rideInfo.mobile,
  //         //     ),

  //         final url = '$baseUrl/passengerrides/myrides/$realRideId';
  //           final response = await http.get(Uri.parse(url));

  //           if (response.statusCode == 200) {
  //             final rideData = jsonDecode(response.body);

  //             if (rideData['driver'] != null) {
  //               final driverData = rideData['driver'];

  //               _driverLinkedController.add(true);

  //               await Future.delayed(const Duration(milliseconds: 200));

  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder:
  //                       (_) => DriverConfirmationScreen(
  //                         rideId: realRideId,
  //                         pickup: widget.pickup,
  //                         driverId: driverData['firebaseId'],
  //                         Phone: driverData['phoneNumber'],
  //                         regnumber: driverData['registrationNumber'],
  //                         vehicleMake: driverData['vehicleMake'],
  //                         vehicleModel: driverData['vehicleModel'],
  //                         colour: driverData['vehicleColour'],
  //                         drivername: driverData['firstName'],
  //                       ),
  //                 ),
  //               );
  //               return;
  //             }
  //           }
  //         }
  //         settings: const RouteSettings(name: '/assignedRide'),
  //       ),
  //     );
  //   } else if (rideInfo.status == RideStatus.inProgress) {
  //     navigatorKey.currentState?.push(
  //       MaterialPageRoute(
  //         builder:
  //             (_) => RideInProgressLiveScreen(
  //               rideId: rideInfo.rideId,
  //               pickup: LatLng(
  //                 rideInfo.pickup.latitude,
  //                 rideInfo.pickup.longitude,
  //               ),
  //               destination: LatLng(
  //                 rideInfo.destination.latitude,
  //                 rideInfo.destination.longitude,
  //               ), // rideInfo.pickup.longitude,
  //             ),
  //         settings: const RouteSettings(name: '/rideInProgress'),
  //       ),
  //     );
  //   }
  // }
  void _navigateToLiveRide(RideInfo rideInfo) async {
    // Hide banner before navigating
    setState(() {
      _isExpanded = false;
      _animationController.reverse();
    });

    if (rideInfo.status == RideStatus.assigned) {
      try {
        final realRideId = rideInfo.rideId;
        final url = '$baseUrl/passengerrides/myrides/$realRideId';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final rideData = jsonDecode(response.body);

          if (rideData['driver'] != null) {
            final driverData = rideData['driver'];

            //    _driverLinkedController.add(true);

            await Future.delayed(const Duration(milliseconds: 200));

            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder:
                    (_) => DriverConfirmationScreen(
                      rideId: realRideId,
                      pickup: LatLng(
                        rideInfo.pickup.latitude,
                        rideInfo.pickup.longitude,
                      ),
                      driverId: driverData['firebaseId'],
                      Phone: driverData['phoneNumber'],
                      regnumber: driverData['registrationNumber'],
                      vehicleMake: driverData['vehicleMake'],
                      vehicleModel: driverData['vehicleModel'],
                      colour: driverData['vehicleColour'],
                      drivername: driverData['firstName'],
                    ),
                settings: const RouteSettings(name: '/assignedRide/:rideId'),
              ),
            );
            return;
          }
        } else {
          debugPrint("❌ Failed to fetch ride: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("❌ Error fetching ride: $e");
      }
    } else if (rideInfo.status == RideStatus.inProgress) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (_) => RideInProgressLiveScreen(
                rideId: rideInfo.rideId,
                pickup: LatLng(
                  rideInfo.pickup.latitude,
                  rideInfo.pickup.longitude,
                ),
                destination: LatLng(
                  rideInfo.destination.latitude,
                  rideInfo.destination.longitude,
                ),
              ),
          settings: const RouteSettings(name: '/rideInProgress'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideInfoAsync = ref.watch(rideStatusStreamProvider(widget.userId));

    return rideInfoAsync.when(
      data: (rideInfo) {
        if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
          return const SizedBox.shrink();
        }

        // Hide banner on live ride screen
        final isLiveRideScreen =
            ModalRoute.of(context)?.settings.name == '/rideInProgress';
        if (isLiveRideScreen) return const SizedBox.shrink();

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Positioned(
          bottom: _bottom,
          left: _left,
          child: GestureDetector(
            onTap: () => _navigateToLiveRide(rideInfo),
            onPanUpdate: (details) {
              setState(() {
                _left += details.delta.dx;
                _bottom -= details.delta.dy;

                // Horizontal clamp
                if (_left < 0) _left = 0;
                if (_left > screenWidth - _bannerWidth) {
                  _left = screenWidth - _bannerWidth;
                }

                // Vertical clamp
                final maxBottom = screenHeight - _heightAnimation.value - 20;
                if (_bottom < 0) _bottom = 0;
                if (_bottom > maxBottom) _bottom = maxBottom;
              });
            },
            child: AnimatedBuilder(
              animation: _heightAnimation,
              builder: (context, child) {
                return Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black87,
                  child: Container(
                    width: _bannerWidth,
                    height: _heightAnimation.value,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_taxi,
                          color: Colors.yellow,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "You have an active ride",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Status: ${rideInfo.status.name}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              if (_isExpanded) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "Tap to view ride details",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';
// import 'package:niceapp/main.dart';

// class RideStatusBanner extends ConsumerStatefulWidget {
//   final String userId;
//   const RideStatusBanner({super.key, required this.userId});

//   @override
//   ConsumerState<RideStatusBanner> createState() => _RideStatusBannerState();
// }

// class _RideStatusBannerState extends ConsumerState<RideStatusBanner>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   late final AnimationController _animationController;
//   late final Animation<double> _heightAnimation;

//   // Draggable position
//   double _bottom = 20;
//   double _left = 16;

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 250),
//     );

//     _heightAnimation = Tween<double>(
//       begin: 70,
//       end: 150,
//     ).animate(_animationController);
//   }

//   void _toggleBanner() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _animationController.forward();
//       } else {
//         _animationController.reverse();
//       }
//     });
//   }

//   void _navigateToLiveRide(String rideId) {
//     // Hide banner before navigating
//     setState(() {
//       _isExpanded = false;
//       _animationController.reverse();
//     });

//     navigatorKey.currentState?.push(
//       MaterialPageRoute(
//         builder: (_) => RideInProgressLiveScreen(rideId: rideId),
//         settings: const RouteSettings(name: '/rideInProgress'),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final rideInfoAsync = ref.watch(rideStatusStreamProvider(widget.userId));

//     return rideInfoAsync.when(
//       data: (rideInfo) {
//         if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
//           return const SizedBox.shrink();
//         }

//         // Hide banner on live ride screen
//         final isLiveRideScreen =
//             ModalRoute.of(context)?.settings.name == '/rideInProgress';
//         if (isLiveRideScreen) return const SizedBox.shrink();

//         final screenWidth = MediaQuery.of(context).size.width;
//         final screenHeight = MediaQuery.of(context).size.height;

//         return Positioned(
//           bottom: _bottom,
//           left: _left,
//           child: GestureDetector(
//             onTap: () => _navigateToLiveRide(rideInfo.rideId),
//             onPanUpdate: (details) {
//               setState(() {
//                 _left += details.delta.dx;
//                 _bottom -= details.delta.dy; // dragging up increases bottom

//                 // Clamp horizontal
//                 if (_left < 0) _left = 0;
//                 if (_left > screenWidth - 300) _left = screenWidth - 300;

//                 // Clamp vertical from bottom
//                 if (_bottom < 0) _bottom = 0;
//                 if (_bottom > screenHeight - _heightAnimation.value - 20) {
//                   _bottom = screenHeight - _heightAnimation.value - 20;
//                 }
//               });
//             },
//             child: AnimatedBuilder(
//               animation: _heightAnimation,
//               builder: (context, child) {
//                 return Material(
//                   elevation: 8,
//                   borderRadius: BorderRadius.circular(16),
//                   color: Colors.black87,
//                   child: Container(
//                     width: 300,
//                     height: _heightAnimation.value,
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.local_taxi,
//                           color: Colors.yellow,
//                           size: 32,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "You have an active ride",
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 "Status: ${rideInfo.status.name}",
//                                 style: const TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                               if (_isExpanded) ...[
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   "Tap to view ride details",
//                                   style: TextStyle(
//                                     color: Colors.white.withOpacity(0.85),
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),
//                         Icon(
//                           _isExpanded
//                               ? Icons.keyboard_arrow_down
//                               : Icons.keyboard_arrow_up,
//                           color: Colors.white70,
//                           size: 24,
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//       loading: () => const SizedBox.shrink(),
//       error: (_, __) => const SizedBox.shrink(),
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
// }
// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';
// // import 'package:niceapp/main.dart';

// // class RideStatusBanner extends ConsumerStatefulWidget {
// //   final String userId;
// //   const RideStatusBanner({super.key, required this.userId});

// //   @override
// //   ConsumerState<RideStatusBanner> createState() => _RideStatusBannerState();
// // }

// // class _RideStatusBannerState extends ConsumerState<RideStatusBanner>
// //     with SingleTickerProviderStateMixin {
// //   bool _isExpanded = false;
// //   late final AnimationController _animationController;
// //   late final Animation<double> _heightAnimation;

// //   // Draggable position
// //   double _top = 20;
// //   double _left = 16;

// //   @override
// //   void initState() {
// //     super.initState();

// //     _animationController = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 250),
// //     );

// //     _heightAnimation = Tween<double>(
// //       begin: 70,
// //       end: 150,
// //     ).animate(_animationController);
// //   }

// //   void _toggleBanner() {
// //     setState(() {
// //       _isExpanded = !_isExpanded;
// //       if (_isExpanded) {
// //         _animationController.forward();
// //       } else {
// //         _animationController.reverse();
// //       }
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final rideInfoAsync = ref.watch(rideStatusStreamProvider(widget.userId));

// //     return rideInfoAsync.when(
// //       data: (rideInfo) {
// //         if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
// //           return const SizedBox.shrink();
// //         }

// //         // Hide on live ride screen
// //         final isLiveRideScreen =
// //             ModalRoute.of(context)?.settings.name == '/rideInProgress';
// //         if (isLiveRideScreen) return const SizedBox.shrink();

// //         final screenWidth = MediaQuery.of(context).size.width;
// //         final screenHeight = MediaQuery.of(context).size.height;

// //         return Positioned(
// //           bottom: _bottom,
// //           left: _left,
// //           child: GestureDetector(
// //             onTap: () {
// //               navigatorKey.currentState?.push(
// //                 MaterialPageRoute(
// //                   builder:
// //                       (_) => RideInProgressLiveScreen(rideId: rideInfo.rideId),
// //                 ),
// //               );
// //             },
// //             // onTap: () {
// //             //   if (_isExpanded) {
// //             //     navigatorKey.currentState?.push(
// //             //       MaterialPageRoute(
// //             //         builder:
// //             //             (_) =>
// //             //                 RideInProgressLiveScreen(rideId: rideInfo.rideId),
// //             //       ),
// //             //     );
// //             //   } else {
// //             //     _toggleBanner();
// //             //   }
// //          //   },

// //             onPanUpdate: (details) {
// //               setState(() {
// //                 _left += details.delta.dx;
// //                 _top += details.delta.dy;

// //                 // Clamp within screen bounds
// //                 if (_left < 0) _left = 0;
// //                 if (_left > screenWidth - 300)
// //                   _left = screenWidth - 300; // banner width approx

// //                 if (_top < 0) _top = 0;
// //                 if (_top > screenHeight - _heightAnimation.value - 20) {
// //                   _top = screenHeight - _heightAnimation.value - 20;
// //                 }
// //               });
// //             },
// //             child: AnimatedBuilder(
// //               animation: _heightAnimation,
// //               builder: (context, child) {
// //                 return Material(
// //                   elevation: 8,
// //                   borderRadius: BorderRadius.circular(16),
// //                   color: Colors.black87,
// //                   child: Container(
// //                     width: 300,
// //                     height: _heightAnimation.value,
// //                     padding: const EdgeInsets.symmetric(horizontal: 16),
// //                     child: Row(
// //                       children: [
// //                         const Icon(
// //                           Icons.local_taxi,
// //                           color: Colors.yellow,
// //                           size: 32,
// //                         ),
// //                         const SizedBox(width: 12),
// //                         Expanded(
// //                           child: Column(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 "You have an active ride",
// //                                 style: const TextStyle(
// //                                   color: Colors.white,
// //                                   fontSize: 16,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 4),
// //                               Text(
// //                                 "Status: ${rideInfo.status.name}",
// //                                 style: const TextStyle(
// //                                   color: Colors.white70,
// //                                   fontSize: 13,
// //                                 ),
// //                               ),
// //                               if (_isExpanded) ...[
// //                                 const SizedBox(height: 8),
// //                                 Text(
// //                                   "Tap to view ride details",
// //                                   style: TextStyle(
// //                                     color: Colors.white.withOpacity(0.85),
// //                                     fontSize: 12,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ],
// //                           ),
// //                         ),
// //                         Icon(
// //                           _isExpanded
// //                               ? Icons.keyboard_arrow_down
// //                               : Icons.keyboard_arrow_up,
// //                           color: Colors.white70,
// //                           size: 24,
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         );
// //       },
// //       loading: () => const SizedBox.shrink(),
// //       error: (_, __) => const SizedBox.shrink(),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _animationController.dispose();
// //     super.dispose();
// //   }
// // }
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';
// // // import 'package:niceapp/main.dart';

// // // class RideStatusBanner extends ConsumerStatefulWidget {
// // //   final String userId;
// // //   const RideStatusBanner({super.key, required this.userId});

// // //   @override
// // //   ConsumerState<RideStatusBanner> createState() => _RideStatusBannerState();
// // // }

// // // class _RideStatusBannerState extends ConsumerState<RideStatusBanner>
// // //     with SingleTickerProviderStateMixin {
// // //   bool _isExpanded = false;
// // //   late final AnimationController _animationController;
// // //   late final Animation<double> _heightAnimation;

// // //   // Draggable position
// // //   double _bottom = 20;
// // //   double _left = 16;
// // //   double _right = 16;
// // //   double _top = 20;

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     _animationController = AnimationController(
// // //       vsync: this,
// // //       duration: const Duration(milliseconds: 250),
// // //     );

// // //     _heightAnimation = Tween<double>(
// // //       begin: 70,
// // //       end: 150,
// // //     ).animate(_animationController);
// // //   }

// // //   void _toggleBanner() {
// // //     setState(() {
// // //       _isExpanded = !_isExpanded;
// // //       if (_isExpanded) {
// // //         _animationController.forward();
// // //       } else {
// // //         _animationController.reverse();
// // //       }
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final rideInfoAsync = ref.watch(rideStatusStreamProvider(widget.userId));

// // //     return rideInfoAsync.when(
// // //       data: (rideInfo) {
// // //         if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
// // //           return const SizedBox.shrink();
// // //         }

// // //         final isLiveRideScreen =
// // //             ModalRoute.of(context)?.settings.name == '/rideInProgress';
// // //         if (isLiveRideScreen) return const SizedBox.shrink();

// // //         return Positioned(
// // //           bottom: _bottom,
// // //           left: _left,
// // //           right: _right,
// // //           child: GestureDetector(
// // //             onTap: () {
// // //               if (_isExpanded) {
// // //                 navigatorKey.currentState?.push(
// // //                   MaterialPageRoute(
// // //                     builder:
// // //                         (_) =>
// // //                             RideInProgressLiveScreen(rideId: rideInfo.rideId),
// // //                   ),
// // //                 );
// // //               } else {
// // //                 _toggleBanner();
// // //               }
// // //             },
// // //             onVerticalDragUpdate: (details) {
// // //               setState(() {
// // //                 _top += details.delta.dy;

// // //                 final screenHeight = MediaQuery.of(context).size.height;
// // //                 final bannerHeight = 80.0; // or your banner's height

// // //                 if (_top < 0) _top = 0;
// // //                 if (_top > screenHeight - bannerHeight)
// // //                   _top = screenHeight - bannerHeight;
// // //               });
// // //             },

// // //             onHorizontalDragUpdate: (details) {
// // //               setState(() {
// // //                 _left += details.delta.dx;
// // //                 // Keep banner within screen bounds
// // //                 if (_left < 0) _left = 0;
// // //                 if (_left +
// // //                         MediaQuery.of(context).size.width -
// // //                         32 > // 32 = left + right padding
// // //                     MediaQuery.of(context).size.width) {
// // //                   _left =
// // //                       MediaQuery.of(context).size.width -
// // //                       (MediaQuery.of(context).size.width - 32);
// // //                 }
// // //               });
// // //             },

// // //             child: AnimatedBuilder(
// // //               animation: _heightAnimation,
// // //               builder: (context, child) {
// // //                 return Material(
// // //                   elevation: 8,
// // //                   borderRadius: BorderRadius.circular(16),
// // //                   color: Colors.black87,
// // //                   child: Container(
// // //                     height: _heightAnimation.value,
// // //                     padding: const EdgeInsets.symmetric(horizontal: 16),
// // //                     child: Row(
// // //                       children: [
// // //                         const Icon(
// // //                           Icons.local_taxi,
// // //                           color: Colors.yellow,
// // //                           size: 32,
// // //                         ),
// // //                         const SizedBox(width: 12),
// // //                         Expanded(
// // //                           child: Column(
// // //                             mainAxisAlignment: MainAxisAlignment.center,
// // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // //                             children: [
// // //                               Text(
// // //                                 "You have an active ride",
// // //                                 style: const TextStyle(
// // //                                   color: Colors.white,
// // //                                   fontSize: 16,
// // //                                   fontWeight: FontWeight.bold,
// // //                                 ),
// // //                               ),
// // //                               const SizedBox(height: 4),
// // //                               Text(
// // //                                 "Status: ${rideInfo.status.name}",
// // //                                 style: const TextStyle(
// // //                                   color: Colors.white70,
// // //                                   fontSize: 13,
// // //                                 ),
// // //                               ),
// // //                               if (_isExpanded) ...[
// // //                                 const SizedBox(height: 8),
// // //                                 Text(
// // //                                   "Tap to view ride details",
// // //                                   style: TextStyle(
// // //                                     color: Colors.white.withOpacity(0.85),
// // //                                     fontSize: 12,
// // //                                   ),
// // //                                 ),
// // //                               ],
// // //                             ],
// // //                           ),
// // //                         ),
// // //                         Icon(
// // //                           _isExpanded
// // //                               ? Icons.keyboard_arrow_down
// // //                               : Icons.keyboard_arrow_up,
// // //                           color: Colors.white70,
// // //                           size: 24,
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //       loading: () => const SizedBox.shrink(),
// // //       error: (_, __) => const SizedBox.shrink(),
// // //     );
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _animationController.dispose();
// // //     super.dispose();
// // //   }
// // // }

// // //             // onVerticalDragUpdate: (details) {
// // //             //   setState(() {
// // //             //     _bottom -= details.delta.dy;
// // //             //     if (!_isExpanded && details.delta.dy < -5) _toggleBanner();
// // //             //     if (_isExpanded && details.delta.dy > 5) _toggleBanner();
// // //             //   });
// // //             // },
// // //             // onHorizontalDragUpdate: (details) {
// // //             //   setState(() {
// // //             //     _left += details.delta.dx;
// // //             //     _right -= details.delta.dx;
// // //             //     // Keep it within screen bounds
// // //             //     if (_left < 0) _left = 0;
// // //             //     if (_right < 0) _right = 0;
// // //             //   });
// // //             // },
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';
// // // // import 'package:niceapp/main.dart';

// // // // class RideStatusBanner extends ConsumerStatefulWidget {
// // // //   final String userId;
// // // //   const RideStatusBanner({super.key, required this.userId});

// // // //   @override
// // // //   ConsumerState<RideStatusBanner> createState() => _RideStatusBannerState();
// // // // }

// // // // class _RideStatusBannerState extends ConsumerState<RideStatusBanner>
// // // //     with SingleTickerProviderStateMixin {
// // // //   bool _isExpanded = false;
// // // //   late final AnimationController _animationController;
// // // //   late final Animation<double> _heightAnimation;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();

// // // //     _animationController = AnimationController(
// // // //       vsync: this,
// // // //       duration: const Duration(milliseconds: 250),
// // // //     );

// // // //     _heightAnimation = Tween<double>(
// // // //       begin: 70,
// // // //       end: 150,
// // // //     ).animate(_animationController);
// // // //   }

// // // //   void _toggleBanner() {
// // // //     setState(() {
// // // //       _isExpanded = !_isExpanded;
// // // //       if (_isExpanded) {
// // // //         _animationController.forward();
// // // //       } else {
// // // //         _animationController.reverse();
// // // //       }
// // // //     });
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final rideInfoAsync = ref.watch(rideStatusStreamProvider(widget.userId));

// // // //     return rideInfoAsync.when(
// // // //       data: (rideInfo) {
// // // //         if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
// // // //           return const SizedBox.shrink();
// // // //         }

// // // //         // Hide banner if we are already on live ride screen
// // // //         final isLiveRideScreen =
// // // //             ModalRoute.of(context)?.settings.name == '/rideInProgress';
// // // //         if (isLiveRideScreen) return const SizedBox.shrink();

// // // //         return Positioned(
// // // //           bottom: 20,
// // // //           left: 16,
// // // //           right: 16,
// // // //           child: GestureDetector(
// // // //             onTap: () {
// // // //               if (_isExpanded) {
// // // //                 // Go to Live Ride Screen
// // // //                 navigatorKey.currentState?.push(
// // // //                   MaterialPageRoute(
// // // //                     builder:
// // // //                         (_) =>
// // // //                             RideInProgressLiveScreen(rideId: rideInfo.rideId),
// // // //                   ),
// // // //                 );
// // // //               } else {
// // // //                 _toggleBanner();
// // // //               }
// // // //             },
// // // //             onVerticalDragUpdate: (details) {
// // // //               if (!_isExpanded && details.delta.dy < -5) {
// // // //                 _toggleBanner();
// // // //               } else if (_isExpanded && details.delta.dy > 5) {
// // // //                 _toggleBanner();
// // // //               }
// // // //             },
// // // //             child: AnimatedBuilder(
// // // //               animation: _heightAnimation,
// // // //               builder: (context, child) {
// // // //                 return Material(
// // // //                   elevation: 8,
// // // //                   borderRadius: BorderRadius.circular(16),
// // // //                   color: Colors.black87,
// // // //                   child: Container(
// // // //                     height: _heightAnimation.value,
// // // //                     padding: const EdgeInsets.symmetric(horizontal: 16),
// // // //                     child: Row(
// // // //                       children: [
// // // //                         const Icon(
// // // //                           Icons.local_taxi,
// // // //                           color: Colors.yellow,
// // // //                           size: 32,
// // // //                         ),
// // // //                         const SizedBox(width: 12),
// // // //                         Expanded(
// // // //                           child: Column(
// // // //                             mainAxisAlignment: MainAxisAlignment.center,
// // // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // // //                             children: [
// // // //                               Text(
// // // //                                 "You have an active ride",
// // // //                                 style: const TextStyle(
// // // //                                   color: Colors.white,
// // // //                                   fontSize: 16,
// // // //                                   fontWeight: FontWeight.bold,
// // // //                                 ),
// // // //                               ),
// // // //                               const SizedBox(height: 4),
// // // //                               Text(
// // // //                                 "Status: ${rideInfo.status.name}",
// // // //                                 style: const TextStyle(
// // // //                                   color: Colors.white70,
// // // //                                   fontSize: 13,
// // // //                                 ),
// // // //                               ),
// // // //                               if (_isExpanded) ...[
// // // //                                 const SizedBox(height: 8),
// // // //                                 Text(
// // // //                                   "Tap to view ride details",
// // // //                                   style: TextStyle(
// // // //                                     color: Colors.white.withOpacity(0.85),
// // // //                                     fontSize: 12,
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //                         Icon(
// // // //                           _isExpanded
// // // //                               ? Icons.keyboard_arrow_down
// // // //                               : Icons.keyboard_arrow_up,
// // // //                           color: Colors.white70,
// // // //                           size: 24,
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 );
// // // //               },
// // // //             ),
// // // //           ),
// // // //         );
// // // //       },
// // // //       loading: () => const SizedBox.shrink(),
// // // //       error: (_, __) => const SizedBox.shrink(),
// // // //     );
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _animationController.dispose();
// // // //     super.dispose();
// // // //   }
// // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // // // import 'package:go_router/go_router.dart';
// // // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// // // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';
// // // // // import 'package:niceapp/main.dart';

// // // // // class RideStatusBanner extends ConsumerWidget {
// // // // //   final String userId;

// // // // //   const RideStatusBanner({super.key, required this.userId});

// // // // //   @override
// // // // //   Widget build(BuildContext context, WidgetRef ref) {
// // // // //     final rideInfoAsync = ref.watch(rideStatusStreamProvider(userId));

// // // // //     return rideInfoAsync.when(
// // // // //       data: (rideInfo) {
// // // // //         if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
// // // // //           return const SizedBox.shrink();
// // // // //         }

// // // // //         return Positioned(
// // // // //           top: 40,
// // // // //           left: 20,
// // // // //           right: 20,
// // // // //           child: Material(
// // // // //             elevation: 6,
// // // // //             borderRadius: BorderRadius.circular(12),
// // // // //             color: Colors.black87,
// // // // //             child: ListTile(
// // // // //               leading: const Icon(Icons.local_taxi, color: Colors.yellow),
// // // // //               title: const Text(
// // // // //                 "You have an active ride",
// // // // //                 style: TextStyle(color: Colors.white),
// // // // //               ),
// // // // //               subtitle: Text(
// // // // //                 "Status: ${rideInfo.status.name}",
// // // // //                 style: const TextStyle(color: Colors.white70),
// // // // //               ),
// // // // //               onTap: () {
// // // // //                 navigatorKey.currentState?.push(
// // // // //                   MaterialPageRoute(
// // // // //                     builder:
// // // // //                         (_) =>
// // // // //                             RideInProgressLiveScreen(rideId: rideInfo.rideId),
// // // // //                   ),
// // // // //                 );
// // // // //                 // // Use GoRouter safely, ensuring context is under MaterialApp.router
// // // // //                 // final router = GoRouter.maybeOf(context);
// // // // //                 // if (router != null) {
// // // // //                 //   router.push('/rideInProgress', extra: rideInfo.rideId);
// // // // //                 // } else {
// // // // //                 //   debugPrint("🚨 GoRouter not found in context!");
// // // // //                 // }
// // // // //               },
// // // // //             ),
// // // // //           ),
// // // // //         );
// // // // //       },
// // // // //       loading: () => const SizedBox.shrink(),
// // // // //       error: (_, __) => const SizedBox.shrink(),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // class GlobalRideBanner {
// // // // // //   static final GlobalRideBanner _instance = GlobalRideBanner._internal();
// // // // // //   factory GlobalRideBanner() => _instance;
// // // // // //   GlobalRideBanner._internal();

// // // // // //   OverlayEntry? _entry;

// // // // // //   void show(BuildContext context, String rideId, String status) {
// // // // // //     // Remove existing banner
// // // // // //     _entry?.remove();

// // // // // //     _entry = OverlayEntry(
// // // // // //       builder:
// // // // // //           (_) => Positioned(
// // // // // //             top: 40,
// // // // // //             left: 20,
// // // // // //             right: 20,
// // // // // //             child: Material(
// // // // // //               elevation: 6,
// // // // // //               borderRadius: BorderRadius.circular(12),
// // // // // //               color: Colors.black87,
// // // // // //               child: ListTile(
// // // // // //                 leading: const Icon(Icons.local_taxi, color: Colors.yellow),
// // // // // //                 title: const Text(
// // // // // //                   "You have an active ride",
// // // // // //                   style: TextStyle(color: Colors.white),
// // // // // //                 ),
// // // // // //                 subtitle: Text(
// // // // // //                   "Status: $status",
// // // // // //                   style: const TextStyle(color: Colors.white70),
// // // // // //                 ),
// // // // // //                 onTap: () {
// // // // // //                   navigatorKey.currentState?.push(
// // // // // //                     MaterialPageRoute(
// // // // // //                       builder: (_) => RideInProgressLiveScreen(rideId: rideId),
// // // // // //                     ),
// // // // // //                   );
// // // // // //                 },
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //     );

// // // // // //     Overlay.of(context).insert(_entry!);
// // // // // //   }

// // // // // //   void hide() {
// // // // // //     _entry?.remove();
// // // // // //     _entry = null;
// // // // // //   }
// // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// // // // // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';

// // // // // // // class RideStatusBanner extends ConsumerWidget {
// // // // // // //   final String userId;
// // // // // // //   //final GlobalKey<NavigatorState> navigatorKey;
// // // // // // //   const RideStatusBanner({
// // // // // // //     super.key,
// // // // // // //     required this.userId,
// // // // // // //     // required this.navigatorKey,
// // // // // // //   });

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context, WidgetRef ref) {
// // // // // // //     final rideInfoAsync = ref.watch(rideStatusStreamProvider(userId));

// // // // // // //     return rideInfoAsync.when(
// // // // // // //       data: (rideInfo) {
// // // // // // //         if (rideInfo.status == RideStatus.none || rideInfo.rideId.isEmpty) {
// // // // // // //           return const SizedBox.shrink();
// // // // // // //         }

// // // // // // //         return Positioned(
// // // // // // //           top: 40,
// // // // // // //           left: 20,
// // // // // // //           right: 20,
// // // // // // //           child: Material(
// // // // // // //             elevation: 6,
// // // // // // //             borderRadius: BorderRadius.circular(12),
// // // // // // //             color: Colors.black87,
// // // // // // //             child: ListTile(
// // // // // // //               leading: const Icon(Icons.local_taxi, color: Colors.yellow),
// // // // // // //               title: const Text(
// // // // // // //                 "You have an active ride",
// // // // // // //                 style: TextStyle(color: Colors.white),
// // // // // // //               ),
// // // // // // //               subtitle: Text(
// // // // // // //                 "Status: ${rideInfo.status.name}",
// // // // // // //                 style: TextStyle(color: Colors.white70),
// // // // // // //               ),

// // // // // // //               // onTap: () {
// // // // // // //               //   Navigator.push(
// // // // // // //               //     context,
// // // // // // //               //     MaterialPageRoute(
// // // // // // //               //       builder:
// // // // // // //               //           (_) =>
// // // // // // //               //               RideInProgressLiveScreen(rideId: rideInfo.rideId),
// // // // // // //               //     ),
// // // // // // //               //   );
// // // // // // //               // },
// // // // // // //               onTap: () {
// // // // // // //                 // Ensure it uses root navigator
// // // // // // //                 // navigatorKey.currentState?.push(
// // // // // // //                 //   MaterialPageRoute(
// // // // // // //                 //     builder:
// // // // // // //                 //         (_) =>
// // // // // // //                 //             RideInProgressLiveScreen(rideId: rideInfo.rideId),
// // // // // // //                 //   ),
// // // // // // //                 // );
// // // // // // //                 GoRouter.of(
// // // // // // //                   context,
// // // // // // //                 ).push('/rideInProgress', extra: rideInfo.rideId);
// // // // // // //               },
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       },
// // // // // // //       loading: () => const SizedBox.shrink(),
// // // // // // //       error: (_, __) => const SizedBox.shrink(),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // // // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
// // // // // // // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_provider.dart';

// // // // // // // class RideStatusBanner extends ConsumerWidget {
// // // // // // //   final String userId;
// // // // // // //   const RideStatusBanner({super.key, required this.userId});

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context, WidgetRef ref) {
// // // // // // //     final rideStatusAsync = ref.watch(rideStatusStreamProvider(userId));

// // // // // // //     return rideStatusAsync.when(
// // // // // // //       data: (status) {
// // // // // // //         if (status == RideStatus.none) return const SizedBox.shrink();

// // // // // // //         return Positioned(
// // // // // // //           top: 40,
// // // // // // //           left: 20,
// // // // // // //           right: 20,
// // // // // // //           child: Material(
// // // // // // //             elevation: 6,
// // // // // // //             borderRadius: BorderRadius.circular(12),
// // // // // // //             color: Colors.black87,
// // // // // // //             child: ListTile(
// // // // // // //               leading: const Icon(Icons.local_taxi, color: Colors.yellow),
// // // // // // //               title: const Text(
// // // // // // //                 "You have an active ride",
// // // // // // //                 style: TextStyle(color: Colors.white),
// // // // // // //               ),
// // // // // // //               subtitle: Text(
// // // // // // //                 "Status: ${status.name}",
// // // // // // //                 style: const TextStyle(color: Colors.white70),
// // // // // // //               ),
// // // // // // //               onTap: () {
// // // // // // //                 Navigator.push(
// // // // // // //                   context,
// // // // // // //                   MaterialPageRoute(
// // // // // // //                     builder:
// // // // // // //                         (_) => RideInProgressLiveScreen(
// // // // // // //                            rideId: widget.rideId!,
// // // // // // //                         ),
// // // // // // //                   ),
// // // // // // //                 );
// // // // // // //               },
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         );
// // // // // // //       },
// // // // // // //       loading: () => const SizedBox.shrink(),
// // // // // // //       error: (_, __) => const SizedBox.shrink(),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }
