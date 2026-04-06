import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';

class FindingDriverScreen extends StatefulWidget {
  final Future<void> Function() onCancel;
  final Stream<bool> driverLinkedStream;
  final String? rideId;
  final String? driverId;
  final LatLng? pickup;
  final LatLng? destination;

  const FindingDriverScreen({
    required this.onCancel,
    required this.driverLinkedStream,
    this.rideId,
    this.driverId,
    this.pickup,
    this.destination,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _timer;

  late AnimationController _carRotationController;

  Map<String, String> _getDynamicMessage() {
    if (_progress < 0.5) {
      return {
        "title": "Searching for drivers near you...",
        "subtitle": "We’re checking nearby drivers. Please hold on 🚗",
      };
    } else if (_progress < 0.7) {
      return {
        "title": "Still looking, expanding search...",
        "subtitle": "Hang tight! We're reaching more drivers in your area.",
      };
    } else if (_progress < 1) {
      return {
        "title": "Almost there...",
        "subtitle": "We’re very close to finding your driver. Stay ready!",
      };
    } else {
      return {
        "title": "No drivers available",
        "subtitle": "Please try again in a moment.",
      };
    }
  }

  @override
  void initState() {
    super.initState();
    // if (widget.rideId != null)
    _carRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    widget.driverLinkedStream.listen((isLinked) {
      if (isLinked) {
        _stopProgress();
        _closeScreen();
      }
    });

    _startProgressTimer();
  }

  void _startProgressTimer() {
    const totalDuration = 60;
    const interval = 0.1;
    final increment = interval / totalDuration;

    _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
      timer,
    ) {
      setState(() {
        _progress += increment;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _stopProgress();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No available driver, please try again later."),
                duration: Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      });
    });
  }

  // Future<String> getFirebaseIdToken() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     throw Exception("User not logged in");
  //   }
  //   return await user.getIdToken().toString();
  // }

  // void _incrementProgress(double amount) {
  //   if (!mounted) return;
  //   setState(() {
  //     _progress += amount;
  //     if (_progress > 0.99) _progress = 0.99;
  //   });
  // }

  // void _startProgressTimer() {
  //   const intervalSeconds = 2;

  //   _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
  //     if (widget.rideId == null) return;

  //     try {
  //       final response = await http.get(
  //         Uri.parse('$baseUrl/rides/ridestatus/${widget.rideId}/status'),
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'firebaseIdToken': await getFirebaseIdToken(),
  //         },
  //       );

  //       if (!mounted) return;

  //       if (response.statusCode == 200) {
  //         final data = jsonDecode(response.body);
  //         final status = data['status'];
  //         final driverUid = data['driverUid'];

  //         if (driverUid != null && status == 'DriverAssigned') {
  //           _stopProgress();
  //           _goToLiveRide();
  //         } else {
  //           _incrementProgress(0.05); // update progress smoothly
  //         }
  //       } else if (response.statusCode == 404) {
  //         _incrementProgress(0.05);
  //       } else {
  //         debugPrint('Ride status API error: ${response.body}');
  //         _incrementProgress(0.01); // small fallback increment
  //       }

  //       // If progress reaches 1 → stop
  //       if (_progress >= 1.0) {
  //         _stopProgress();
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text("No available driver, please try again later."),
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //         Future.delayed(const Duration(seconds: 2), () {
  //           if (mounted) Navigator.pop(context);
  //         });
  //       }
  //     } catch (e) {
  //       debugPrint('Error fetching ride status: $e');
  //       _incrementProgress(0.01);
  //     }
  //   });
  // }

  void _stopProgress() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleCancel() async {
    _stopProgress();
    await widget.onCancel();
    Navigator.pop(context);
  }

  void _closeScreen() {
    Navigator.pop(context);
  }

  void _goToLiveRide() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => RideInProgressLiveScreen(
              rideId: widget.rideId.toString(),
              driverId: widget.driverId,
              pickup: widget.pickup,
              destination: widget.destination,
              //baseFare: 100, // optional (or pass dynamically)
              //perKmFare: 50, // optional
            ),
      ),
    );
  }

  @override
  void dispose() {
    _stopProgress();
    _carRotationController.dispose();
    super.dispose();
  }

  Widget _buildCircularProgressWithCar() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress
          CircularProgressIndicator(
            value: _progress,
            strokeWidth: 10,
            color: Colors.blue,
            backgroundColor: Colors.grey.shade300,
          ),
          // Rotating car
          AnimatedBuilder(
            animation: _carRotationController,
            builder: (context, child) {
              final angle = 2 * pi * _carRotationController.value;
              final radius = 80.0;
              final x = radius * cos(angle);
              final y = radius * sin(angle);
              return Transform.translate(
                offset: Offset(x, y),
                child: Transform.rotate(
                  angle: angle,
                  child: const Icon(
                    Icons.directions_car,
                    size: 36,
                    color: Colors.blue,
                  ),
                ),
              );
            },
          ),
          // Main center icon
          const Icon(Icons.local_taxi, size: 50, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildLinearProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 8,
        backgroundColor: Colors.grey.shade300,
        color: Colors.blue,
      ),
    );
  }

  // Widget _buildBottomCarSection() {
  //   return Column(
  //     children: [
  //       Image.asset(
  //         "assets/imgs/carwhite.png",
  //         width: 180,
  //         height: 100,
  //         fit: BoxFit.contain,
  //         errorBuilder: (context, error, stackTrace) {
  //           return const Icon(
  //             Icons.directions_car,
  //             size: 80,
  //             color: Colors.grey,
  //           );
  //         },
  //       ),
  //       const SizedBox(height: 16),
  //       const Text(
  //         "Amini is searching for drivers near you...",
  //         style: TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //       const SizedBox(height: 8),
  //       const Text(
  //         "Don't worry! We’ll find the nearest driver soon. Sit tight 🚗",
  //         style: TextStyle(fontSize: 14, color: Colors.black54),
  //         textAlign: TextAlign.center,
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBottomCarSection() {
    final message = _getDynamicMessage();

    return Column(
      children: [
        Image.asset(
          "assets/imgs/Sedan2.png",
          width: 180,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.directions_car,
              size: 80,
              color: Colors.grey,
            );
          },
        ),
        const SizedBox(height: 16),

        // 🔥 Dynamic Title
        Text(
          message["title"]!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // 🔥 Dynamic Subtitle
        Text(
          message["subtitle"]!,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircularProgressWithCar(),
              _buildLinearProgress(),
              const SizedBox(height: 40),
              _buildBottomCarSection(),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.black26,
                      elevation: 6,
                    ),
                    child: const Text(
                      "Cancel Ride",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';

// class FindingDriverScreen extends StatefulWidget {
//   final Future<void> Function() onCancel;
//   final Stream<bool> driverLinkedStream;

//   const FindingDriverScreen({
//     super.key,
//     required this.onCancel,
//     required this.driverLinkedStream,
//   });

//   @override
//   State<FindingDriverScreen> createState() => _FindingDriverScreenState();
// }

// class _FindingDriverScreenState extends State<FindingDriverScreen>
//     with TickerProviderStateMixin {
//   double _progress = 0.0;
//   Timer? _timer;

//   late AnimationController _mainCarController;
//   late List<AnimationController> _bgCarControllers;

//   final int bgCarCount = 4;

//   @override
//   void initState() {
//     super.initState();

//     // Main floating car
//     _mainCarController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);

//     // Background moving cars
//     _bgCarControllers = List.generate(bgCarCount, (index) {
//       final controller = AnimationController(
//         vsync: this,
//         duration: Duration(seconds: 5 + index * 2),
//       );
//       controller.repeat();
//       return controller;
//     });

//     // Listen for driver linkage
//     widget.driverLinkedStream.listen((isLinked) {
//       if (isLinked) {
//         _stopProgress();
//         _closeScreen();
//       }
//     });

//     _startProgressTimer();
//   }

//   void _startProgressTimer() {
//     const totalDuration = 60; // seconds
//     const interval = 0.1;
//     final increment = interval / totalDuration;

//     _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
//       timer,
//     ) {
//       setState(() {
//         _progress += increment;
//         if (_progress >= 1.0) {
//           _progress = 1.0;
//           _stopProgress();
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("No available driver, please try again later."),
//                 duration: Duration(seconds: 2),
//               ),
//             );
//             Future.delayed(const Duration(seconds: 2), () {
//               if (mounted) Navigator.pop(context);
//             });
//           }
//         }
//       });
//     });
//   }

//   void _stopProgress() {
//     _timer?.cancel();
//     _timer = null;
//   }

//   Future<void> _handleCancel() async {
//     _stopProgress();
//     await widget.onCancel();
//     Navigator.pop(context);
//   }

//   void _closeScreen() {
//     Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     _stopProgress();
//     _mainCarController.dispose();
//     for (var controller in _bgCarControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   Widget _buildBackgroundCars(Size size) {
//     return Stack(
//       children: List.generate(bgCarCount, (index) {
//         final controller = _bgCarControllers[index];
//         final topPosition = 100.0 + index * 70;
//         final color = Colors.primaries[index % Colors.primaries.length]
//             .withOpacity(0.5);

//         return AnimatedBuilder(
//           animation: controller,
//           builder: (context, child) {
//             final leftPos =
//                 (size.width + 50) * controller.value - 50; // loop across screen
//             return Positioned(
//               top: topPosition,
//               left: leftPos % (size.width + 100) - 50,
//               child: Transform.rotate(
//                 angle: 0,
//                 child: Container(
//                   width: 60,
//                   height: 35,
//                   decoration: BoxDecoration(
//                     color: color,
//                     borderRadius: BorderRadius.circular(8),
//                     boxShadow: [
//                       BoxShadow(
//                         color: color.withOpacity(0.7),
//                         blurRadius: 6,
//                         offset: const Offset(2, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       }),
//     );
//   }

//   Widget _buildFloatingMainCar() {
//     return AnimatedBuilder(
//       animation: _mainCarController,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, -10 + 20 * _mainCarController.value),
//           child: child,
//         );
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Glow circle
//           Container(
//             width: 160,
//             height: 160,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [
//                   Colors.amberAccent.withOpacity(0.6),
//                   Colors.transparent,
//                 ],
//                 stops: const [0.0, 1.0],
//               ),
//             ),
//           ),
//           // Circular progress
//           SizedBox(
//             width: 150,
//             height: 150,
//             child: CircularProgressIndicator(
//               value: _progress,
//               strokeWidth: 8,
//               color: Colors.amberAccent,
//               backgroundColor: Colors.white24,
//             ),
//           ),
//           // Main car
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.amberAccent,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.amberAccent,
//                   blurRadius: 8,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//             child: const Icon(
//               Icons.directions_car,
//               size: 40,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Scaffold(
//         body: Stack(
//           children: [
//             // Vibrant gradient background
//             Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Color(0xFFf7971e),
//                     Color(0xFFFFD200),
//                     Color(0xFF00c6ff),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//             ),

//             // Background cars
//             _buildBackgroundCars(size),

//             SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Main floating car
//                     Column(
//                       children: [
//                         const SizedBox(height: 60),
//                         _buildFloatingMainCar(),
//                         const SizedBox(height: 40),
//                         const Text(
//                           "Finding your driver...",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           "Hang tight! We're connecting you to the nearest driver.",
//                           style: TextStyle(color: Colors.white70, fontSize: 16),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),

//                     // Cancel Button
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 40),
//                       child: SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             shadowColor: Colors.black45,
//                             elevation: 8,
//                             backgroundColor: Colors.redAccent,
//                           ),
//                           onPressed: _handleCancel,
//                           child: const Text(
//                             "Cancel Ride",
//                             style: TextStyle(fontSize: 18, color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:flutter/material.dart';

// class FindingDriverScreen extends StatefulWidget {
//   final Future<void> Function() onCancel;
//   final Stream<bool> driverLinkedStream;

//   const FindingDriverScreen({
//     super.key,
//     required this.onCancel,
//     required this.driverLinkedStream,
//   });

//   @override
//   State<FindingDriverScreen> createState() => _FindingDriverScreenState();
// }

// class _FindingDriverScreenState extends State<FindingDriverScreen> {
//   double _progress = 0.0;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();

//     // Listen for driver linkage
//     widget.driverLinkedStream.listen((isLinked) {
//       if (isLinked) {
//         _stopProgress();
//         _closeScreen();
//       }
//     });

//     // Start progress
//     _startProgressTimer();
//   }

//   // void _startProgressTimer() {
//   //   const totalDuration = 60; // seconds
//   //   const interval = 0.1; // seconds per tick
//   //   final increment = interval / totalDuration;

//   //   _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
//   //     timer,
//   //   ) {
//   //     setState(() {
//   //       _progress += increment;
//   //       if (_progress >= 1.0) {
//   //         _progress = 1.0;
//   //         _stopProgress();
//   //         // _showNoDriverDialog();
//   //       }
//   //     });
//   //   });
//   // }
//   void _startProgressTimer() {
//     const totalDuration = 60; // seconds
//     const interval = 0.1; // seconds per tick
//     final increment = interval / totalDuration;

//     _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
//       timer,
//     ) {
//       setState(() {
//         _progress += increment;
//         if (_progress >= 1.0) {
//           _progress = 1.0;
//           _stopProgress();

//           // Instead of showing dialog, show SnackBar + exit
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("No available driver, please try again later."),
//                 duration: Duration(seconds: 2),
//               ),
//             );

//             // Delay slightly so user sees the message
//             Future.delayed(const Duration(seconds: 2), () {
//               if (mounted) Navigator.pop(context);
//             });
//           }
//         }
//       });
//     });
//   }

//   void _stopProgress() {
//     _timer?.cancel();
//     _timer = null;
//   }

//   Future<void> _handleCancel() async {
//     // Stop timer
//     _stopProgress();

//     // Call any cancel logic
//     await widget.onCancel();

//     // Return to previous screen
//     Navigator.pop(context);
//   }

//   void _closeScreen() {
//     Navigator.pop(context);
//   }

//   void _showNoDriverDialog() {
//     if (!mounted) return;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (_) => AlertDialog(
//             title: const Text("No Available Driver"),
//             content: const Text(
//               "Sorry, we couldn't find a driver nearby. Please try again later.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   // First close the dialog
//                   Navigator.of(context, rootNavigator: true).pop();

//                   // Then close the FindingDriverScreen safely
//                   Future.microtask(() {
//                     if (mounted) {
//                       Navigator.of(context).pop();
//                     }
//                   });
//                 },
//                 child: const Text("OK"),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   void dispose() {
//     _stopProgress();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => false, // prevent back
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Top loader
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 100),
//                     Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 20),
//                       child: LinearProgressIndicator(
//                         minHeight: 10,
//                         value: _progress,
//                         color: Colors.white,
//                         backgroundColor: Colors.white24,
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//                     const Text(
//                       "Finding you a driver...",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 26,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       "Please wait while we connect you with the nearest driver.",
//                       style: TextStyle(color: Colors.white70, fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),

//                 // Bottom cancel button
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 40),
//                   child: SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.redAccent,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       onPressed: _handleCancel,
//                       child: const Text(
//                         "Cancel Ride",
//                         style: TextStyle(fontSize: 18, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }




// import 'dart:async';
// import 'package:flutter/material.dart';

// class FindingDriverScreen extends StatefulWidget {
//   final Future<void> Function() onCancel;
//   final Stream<bool> driverLinkedStream;

//   const FindingDriverScreen({
//     super.key,
//     required this.onCancel,
//     required this.driverLinkedStream,
//   });

//   @override
//   State<FindingDriverScreen> createState() => _FindingDriverScreenState();
// }

// class _FindingDriverScreenState extends State<FindingDriverScreen> {
//   bool _isLocked = true; // Prevents exit
//   double _progress = 0.0; // Progress value for LinearProgressIndicator
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();

//     // Listen for driver linkage
//     widget.driverLinkedStream.listen((isLinked) {
//       if (isLinked && mounted) {
//         _stopProgress();
//         _closeScreen();
//       }
//     });

//     // Start filling progress over 60 seconds
//     _startProgressTimer();
//   }

//   void _startProgressTimer() {
//     const totalDuration = 60; // seconds
//     const interval = 0.1; // seconds per tick
//     final increment = interval / totalDuration;

//     _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
//       timer,
//     ) {
//       if (!mounted) return;

//       setState(() {
//         _progress += increment;
//         if (_progress >= 1.0) {
//           _progress = 1.0;
//           _stopProgress();
//           _showNoDriverDialog();
//         }
//       });
//     });
//   }

//   void _stopProgress() {
//     _timer?.cancel();
//     _timer = null;
//   }

//   Future<void> _handleCancel() async {
//     await widget.onCancel();
//     if (!mounted) return;
//     _stopProgress();
//     setState(() => _isLocked = false);
//     _closeScreen();
//   }

//   void _closeScreen() {
//     if (!mounted) return;
//     Navigator.pop(context);
//   }

//   void _showNoDriverDialog() {
//     if (!mounted) return;

//     // Schedule after current frame to ensure widget is mounted
//     Future.microtask(() {
//       if (!mounted) return;
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder:
//             (_) => AlertDialog(
//               title: const Text("No Available Driver"),
//               content: const Text(
//                 "Sorry, we couldn't find a driver nearby. Please try again later.",
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     if (!mounted) return;
//                     Navigator.pop(context); // close dialog
//                     _closeScreen();
//                   },
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _stopProgress();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => !_isLocked,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: SafeArea(
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Top loader
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 100),

//                         // Horizontal progress bar filling over 60s
//                         Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 20),
//                           child: LinearProgressIndicator(
//                             minHeight: 10,
//                             value: _progress,
//                             color: Colors.white,
//                             backgroundColor: Colors.white24,
//                           ),
//                         ),

//                         const SizedBox(height: 40),
//                         const Text(
//                           "Finding you a driver...",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           "Please wait while we connect you with the nearest driver.",
//                           style: TextStyle(color: Colors.white70, fontSize: 16),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),

//                     // Bottom cancel button
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 40),
//                       child: SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.redAccent,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           onPressed: _handleCancel,
//                           child: const Text(
//                             "Cancel Ride",
//                             style: TextStyle(fontSize: 18, color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Block taps on nav (Home, Events, Profile)
//               if (_isLocked)
//                 IgnorePointer(
//                   ignoring: false,
//                   child: Container(color: Colors.transparent),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// // import 'dart:async';
// // import 'package:flutter/material.dart';

// // class FindingDriverScreen extends StatefulWidget {
// //   final Future<void> Function() onCancel;
// //   final Stream<bool> driverLinkedStream;

// //   const FindingDriverScreen({
// //     super.key,
// //     required this.onCancel,
// //     required this.driverLinkedStream,
// //   });

// //   @override
// //   State<FindingDriverScreen> createState() => _FindingDriverScreenState();
// // }

// // class _FindingDriverScreenState extends State<FindingDriverScreen> {
// //   bool _isLocked = true; // Prevents exit
// //   double _progress = 0.0; // 0 to 1 for LinearProgressIndicator
// //   Timer? _timer;

// //   @override
// //   void initState() {
// //     super.initState();

// //     // Listen for driver linkage
// //     widget.driverLinkedStream.listen((isLinked) {
// //       if (isLinked && mounted) {
// //         _stopTimer();
// //         _navigateBack();
// //       }
// //     });

// //     // Start incremental progress
// //     _startProgressTimer();
// //   }

// //   void _startProgressTimer() {
// //     const totalDuration = 60; // seconds
// //     const interval = 0.1; // seconds per tick
// //     final increment = interval / totalDuration;

// //     _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
// //       timer,
// //     ) {
// //       if (!mounted) return;

// //       setState(() {
// //         _progress += increment;
// //         if (_progress >= 1.0) {
// //           _progress = 1.0;
// //           _stopTimer();
// //           _showNoDriverDialog();
// //         }
// //       });
// //     });
// //   }

// //   void _stopTimer() {
// //     _timer?.cancel();
// //     _timer = null;
// //   }

// //   Future<void> _handleCancel() async {
// //     await widget.onCancel();
// //     if (mounted) {
// //       _stopTimer();
// //       setState(() {
// //         _isLocked = false;
// //       });
// //       _navigateBack();
// //     }
// //   }

// //   void _navigateBack() {
// //     if (!mounted) return;
// //     setState(() => _isLocked = false);
// //     Navigator.pop(context);
// //   }

// //   void _showNoDriverDialog() {
// //     if (!mounted) return;
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder:
// //           (_) => AlertDialog(
// //             title: const Text("No Available Driver"),
// //             content: const Text(
// //               "Sorry, we couldn't find a driver nearby. Please try again later.",
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () {
// //                   Navigator.pop(context); // close dialog
// //                   _navigateBack(); // close screen
// //                 },
// //                 child: const Text("OK"),
// //               ),
// //             ],
// //           ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _stopTimer();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return WillPopScope(
// //       onWillPop: () async => !_isLocked,
// //       child: Scaffold(
// //         backgroundColor: Colors.black,
// //         body: SafeArea(
// //           child: Stack(
// //             children: [
// //               Padding(
// //                 padding: const EdgeInsets.all(24.0),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     // Top loader
// //                     Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         const SizedBox(height: 100),

// //                         // Linear progress bar
// //                         Container(
// //                           margin: const EdgeInsets.symmetric(horizontal: 20),
// //                           child: LinearProgressIndicator(
// //                             minHeight: 10,
// //                             value: _progress,
// //                             color: Colors.white,
// //                             backgroundColor: Colors.white24,
// //                           ),
// //                         ),

// //                         const SizedBox(height: 40),
// //                         const Text(
// //                           "Finding you a driver...",
// //                           style: TextStyle(
// //                             color: Colors.white,
// //                             fontSize: 26,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                           textAlign: TextAlign.center,
// //                         ),
// //                         const SizedBox(height: 16),
// //                         const Text(
// //                           "Please wait while we connect you with the nearest driver.",
// //                           style: TextStyle(color: Colors.white70, fontSize: 16),
// //                           textAlign: TextAlign.center,
// //                         ),
// //                       ],
// //                     ),

// //                     // Bottom cancel button
// //                     Padding(
// //                       padding: const EdgeInsets.only(bottom: 40),
// //                       child: SizedBox(
// //                         width: double.infinity,
// //                         child: ElevatedButton(
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: Colors.redAccent,
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(30),
// //                             ),
// //                           ),
// //                           onPressed: _handleCancel,
// //                           child: const Text(
// //                             "Cancel Ride",
// //                             style: TextStyle(fontSize: 18, color: Colors.white),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),

// //               // Block taps on nav (Home, Events, Profile)
// //               if (_isLocked)
// //                 IgnorePointer(
// //                   ignoring: false,
// //                   child: Container(color: Colors.transparent),
// //                 ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// // // import 'package:flutter/material.dart';

// // // class FindingDriverScreen extends StatefulWidget {
// // //   final Future<void> Function() onCancel;
// // //   final Stream<bool> driverLinkedStream;

// // //   const FindingDriverScreen({
// // //     super.key,
// // //     required this.onCancel,
// // //     required this.driverLinkedStream,
// // //   });

// // //   @override
// // //   State<FindingDriverScreen> createState() => _FindingDriverScreenState();
// // // }

// // // class _FindingDriverScreenState extends State<FindingDriverScreen> {
// // //   bool _isLocked = true; // Prevents exit

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     // 🔑 Listen for driver linkage
// // //     widget.driverLinkedStream.listen((isLinked) {
// // //       if (isLinked && mounted) {
// // //         setState(() {
// // //           _isLocked = false; // unlock navigation
// // //         });
// // //         Navigator.pop(context); // close screen automatically
// // //       }
// // //     });
// // //   }

// // //   Future<void> _handleCancel() async {
// // //     await widget.onCancel();
// // //     if (mounted) {
// // //       setState(() {
// // //         _isLocked = false; // unlock navigation
// // //       });
// // //       Navigator.pop(context); // Close screen manually
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return WillPopScope(
// // //       onWillPop: () async => !_isLocked,
// // //       child: Scaffold(
// // //         backgroundColor: Colors.black,
// // //         body: SafeArea(
// // //           child: Stack(
// // //             children: [
// // //               Padding(
// // //                 padding: const EdgeInsets.all(24.0),
// // //                 child: Column(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: [
// // //                     // Top loader
// // //                     Column(
// // //                       mainAxisAlignment: MainAxisAlignment.center,
// // //                       children: [
// // //                         const SizedBox(height: 100),

// // //                         // 🔄 Replaced with horizontal stick
// // //                         Container(
// // //                           margin: const EdgeInsets.symmetric(horizontal: 20),
// // //                           child: const LinearProgressIndicator(
// // //                             minHeight: 10,
// // //                             color: Colors.white,
// // //                             backgroundColor: Colors.white24,
// // //                           ),
// // //                         ),

// // //                         const SizedBox(height: 40),
// // //                         const Text(
// // //                           "Finding you a driver...",
// // //                           style: TextStyle(
// // //                             color: Colors.white,
// // //                             fontSize: 26,
// // //                             fontWeight: FontWeight.bold,
// // //                           ),
// // //                           textAlign: TextAlign.center,
// // //                         ),
// // //                         const SizedBox(height: 16),
// // //                         const Text(
// // //                           "Please wait while we connect you with the nearest driver.",
// // //                           style: TextStyle(color: Colors.white70, fontSize: 16),
// // //                           textAlign: TextAlign.center,
// // //                         ),
// // //                       ],
// // //                     ),

// // //                     // Bottom cancel button
// // //                     Padding(
// // //                       padding: const EdgeInsets.only(bottom: 40),
// // //                       child: SizedBox(
// // //                         width: double.infinity,
// // //                         child: ElevatedButton(
// // //                           style: ElevatedButton.styleFrom(
// // //                             backgroundColor: Colors.redAccent,
// // //                             padding: const EdgeInsets.symmetric(vertical: 16),
// // //                             shape: RoundedRectangleBorder(
// // //                               borderRadius: BorderRadius.circular(30),
// // //                             ),
// // //                           ),
// // //                           onPressed: _handleCancel,
// // //                           child: const Text(
// // //                             "Cancel Ride",
// // //                             style: TextStyle(fontSize: 18, color: Colors.white),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),

// // //               // Block taps on nav (Home, Events, Profile)
// // //               if (_isLocked)
// // //                 IgnorePointer(
// // //                   ignoring: false,
// // //                   child: Container(color: Colors.transparent),
// // //                 ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // // // import 'package:flutter/material.dart';

// // // // class FindingDriverScreen extends StatefulWidget {
// // // //   final Future<void> Function() onCancel;
// // // //   final Stream<bool> driverLinkedStream;
// // // //   // 🔑 A stream that emits true when driver is linked

// // // //   const FindingDriverScreen({
// // // //     super.key,
// // // //     required this.onCancel,
// // // //     required this.driverLinkedStream,
// // // //   });

// // // //   @override
// // // //   State<FindingDriverScreen> createState() => _FindingDriverScreenState();
// // // // }

// // // // class _FindingDriverScreenState extends State<FindingDriverScreen> {
// // // //   bool _isLocked = true; // Prevents exit

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();

// // // //     // 🔑 Listen for driver linkage
// // // //     widget.driverLinkedStream.listen((isLinked) {
// // // //       if (isLinked && mounted) {
// // // //         setState(() {
// // // //           _isLocked = false; // unlock navigation
// // // //         });
// // // //         Navigator.pop(context); // close screen automatically
// // // //       }
// // // //     });
// // // //   }

// // // //   Future<void> _handleCancel() async {
// // // //     await widget.onCancel();
// // // //     if (mounted) {
// // // //       setState(() {
// // // //         _isLocked = false; // unlock navigation
// // // //       });
// // // //       Navigator.pop(context); // Close screen manually
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return WillPopScope(
// // // //       // Prevent back button
// // // //       onWillPop: () async => !_isLocked,
// // // //       child: Scaffold(
// // // //         backgroundColor: Colors.black,
// // // //         body: SafeArea(
// // // //           child: Stack(
// // // //             children: [
// // // //               Padding(
// // // //                 padding: const EdgeInsets.all(24.0),
// // // //                 child: Column(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                   children: [
// // // //                     // Top loader
// // // //                     Column(
// // // //                       mainAxisAlignment: MainAxisAlignment.center,
// // // //                       children: [
// // // //                         const SizedBox(height: 100),
// // // //                         const SizedBox(
// // // //                           height: 120,
// // // //                           width: 120,
// // // //                           child: CircularProgressIndicator(
// // // //                             color: Colors.white,
// // // //                             strokeWidth: 6,
// // // //                           ),
// // // //                         ),
// // // //                         const SizedBox(height: 40),
// // // //                         const Text(
// // // //                           "Finding you a driver...",
// // // //                           style: TextStyle(
// // // //                             color: Colors.white,
// // // //                             fontSize: 26,
// // // //                             fontWeight: FontWeight.bold,
// // // //                           ),
// // // //                           textAlign: TextAlign.center,
// // // //                         ),
// // // //                         const SizedBox(height: 16),
// // // //                         const Text(
// // // //                           "Please wait while we connect you with the nearest driver.",
// // // //                           style: TextStyle(color: Colors.white70, fontSize: 16),
// // // //                           textAlign: TextAlign.center,
// // // //                         ),
// // // //                       ],
// // // //                     ),

// // // //                     // Bottom cancel button
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.only(bottom: 40),
// // // //                       child: SizedBox(
// // // //                         width: double.infinity,
// // // //                         child: ElevatedButton(
// // // //                           style: ElevatedButton.styleFrom(
// // // //                             backgroundColor: Colors.redAccent,
// // // //                             padding: const EdgeInsets.symmetric(vertical: 16),
// // // //                             shape: RoundedRectangleBorder(
// // // //                               borderRadius: BorderRadius.circular(30),
// // // //                             ),
// // // //                           ),
// // // //                           onPressed: _handleCancel,
// // // //                           child: const Text(
// // // //                             "Cancel Ride",
// // // //                             style: TextStyle(fontSize: 18, color: Colors.white),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),

// // // //               // Block taps on nav (Home, Events, Profile)
// // // //               if (_isLocked)
// // // //                 IgnorePointer(
// // // //                   ignoring: false,
// // // //                   child: Container(color: Colors.transparent),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // // // import 'package:flutter/material.dart';

// // // // // class FindingDriverScreen extends StatelessWidget {
// // // // //   final Future<void> Function() onCancel;

// // // // //   const FindingDriverScreen({super.key, required this.onCancel});

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return WillPopScope(
// // // // //       // Prevents back button dismissal
// // // // //       onWillPop: () async => false,
// // // // //       child: Scaffold(
// // // // //         backgroundColor: Colors.black,
// // // // //         body: SafeArea(
// // // // //           child: Padding(
// // // // //             padding: const EdgeInsets.all(24.0),
// // // // //             child: Column(
// // // // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //               children: [
// // // // //                 // Top section with loading
// // // // //                 Column(
// // // // //                   mainAxisAlignment: MainAxisAlignment.center,
// // // // //                   children: [
// // // // //                     const SizedBox(height: 100),
// // // // //                     const SizedBox(
// // // // //                       height: 120,
// // // // //                       width: 120,
// // // // //                       child: CircularProgressIndicator(
// // // // //                         color: Colors.white,
// // // // //                         strokeWidth: 6,
// // // // //                       ),
// // // // //                     ),
// // // // //                     const SizedBox(height: 40),
// // // // //                     const Text(
// // // // //                       "Finding you a driver...",
// // // // //                       style: TextStyle(
// // // // //                         color: Colors.white,
// // // // //                         fontSize: 26,
// // // // //                         fontWeight: FontWeight.bold,
// // // // //                       ),
// // // // //                       textAlign: TextAlign.center,
// // // // //                     ),
// // // // //                     const SizedBox(height: 16),
// // // // //                     const Text(
// // // // //                       "Please wait while we connect you with the nearest driver.",
// // // // //                       style: TextStyle(color: Colors.white70, fontSize: 16),
// // // // //                       textAlign: TextAlign.center,
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),

// // // // //                 // Bottom cancel button styled like Uber
// // // // //                 Padding(
// // // // //                   padding: const EdgeInsets.only(bottom: 40),
// // // // //                   child: SizedBox(
// // // // //                     width: double.infinity,
// // // // //                     child: ElevatedButton(
// // // // //                       style: ElevatedButton.styleFrom(
// // // // //                         backgroundColor: Colors.redAccent,
// // // // //                         padding: const EdgeInsets.symmetric(vertical: 16),
// // // // //                         shape: RoundedRectangleBorder(
// // // // //                           borderRadius: BorderRadius.circular(30),
// // // // //                         ),
// // // // //                       ),
// // // // //                       onPressed: () async {
// // // // //                         await onCancel();
// // // // //                         if (context.mounted) {
// // // // //                           Navigator.pop(context); // close screen
// // // // //                         }
// // // // //                       },
// // // // //                       child: const Text(
// // // // //                         "Cancel Ride",
// // // // //                         style: TextStyle(fontSize: 18, color: Colors.white),
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // // // import 'package:flutter/material.dart';

// // // // // // class FindingDriverScreen extends StatelessWidget {
// // // // // //   final Future<void> Function() onCancel;

// // // // // //   const FindingDriverScreen({super.key, required this.onCancel});

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       backgroundColor: Colors.black,
// // // // // //       body: SafeArea(
// // // // // //         child: Center(
// // // // // //           child: Padding(
// // // // // //             padding: const EdgeInsets.all(24.0),
// // // // // //             child: Column(
// // // // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // // // //               children: [
// // // // // //                 const CircularProgressIndicator(
// // // // // //                   color: Colors.blueAccent,
// // // // // //                   strokeWidth: 5,
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 30),
// // // // // //                 const Text(
// // // // // //                   "Finding you a driver...",
// // // // // //                   style: TextStyle(
// // // // // //                     color: Colors.white,
// // // // // //                     fontSize: 24,
// // // // // //                     fontWeight: FontWeight.bold,
// // // // // //                   ),
// // // // // //                   textAlign: TextAlign.center,
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 15),
// // // // // //                 const Text(
// // // // // //                   "Please wait while we assign a driver nearby.",
// // // // // //                   style: TextStyle(color: Colors.white70, fontSize: 16),
// // // // // //                   textAlign: TextAlign.center,
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 40),
// // // // // //                 ElevatedButton(
// // // // // //                   style: ElevatedButton.styleFrom(
// // // // // //                     backgroundColor: Colors.redAccent,
// // // // // //                     padding: const EdgeInsets.symmetric(
// // // // // //                       vertical: 14,
// // // // // //                       horizontal: 40,
// // // // // //                     ),
// // // // // //                     shape: RoundedRectangleBorder(
// // // // // //                       borderRadius: BorderRadius.circular(30),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   onPressed: () async {
// // // // // //                     await onCancel();
// // // // // //                     if (context.mounted) {
// // // // // //                       Navigator.pop(context);
// // // // // //                     }
// // // // // //                   },
// // // // // //                   child: const Text(
// // // // // //                     "Cancel Ride",
// // // // // //                     style: TextStyle(fontSize: 18, color: Colors.white),
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }
