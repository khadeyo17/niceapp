import 'dart:async';
import 'package:flutter/material.dart';

class FindingDriverScreen extends StatefulWidget {
  final Future<void> Function() onCancel;
  final Stream<bool> driverLinkedStream;

  const FindingDriverScreen({
    super.key,
    required this.onCancel,
    required this.driverLinkedStream,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Listen for driver linkage
    widget.driverLinkedStream.listen((isLinked) {
      if (isLinked) {
        _stopProgress();
        _closeScreen();
      }
    });

    // Start progress
    _startProgressTimer();
  }

  // void _startProgressTimer() {
  //   const totalDuration = 60; // seconds
  //   const interval = 0.1; // seconds per tick
  //   final increment = interval / totalDuration;

  //   _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
  //     timer,
  //   ) {
  //     setState(() {
  //       _progress += increment;
  //       if (_progress >= 1.0) {
  //         _progress = 1.0;
  //         _stopProgress();
  //         // _showNoDriverDialog();
  //       }
  //     });
  //   });
  // }
  void _startProgressTimer() {
    const totalDuration = 60; // seconds
    const interval = 0.1; // seconds per tick
    final increment = interval / totalDuration;

    _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
      timer,
    ) {
      setState(() {
        _progress += increment;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _stopProgress();

          // Instead of showing dialog, show SnackBar + exit
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No available driver, please try again later."),
                duration: Duration(seconds: 2),
              ),
            );

            // Delay slightly so user sees the message
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      });
    });
  }

  void _stopProgress() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleCancel() async {
    // Stop timer
    _stopProgress();

    // Call any cancel logic
    await widget.onCancel();

    // Return to previous screen
    Navigator.pop(context);
  }

  void _closeScreen() {
    Navigator.pop(context);
  }

  void _showNoDriverDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text("No Available Driver"),
            content: const Text(
              "Sorry, we couldn't find a driver nearby. Please try again later.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // First close the dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  // Then close the FindingDriverScreen safely
                  Future.microtask(() {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _stopProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // prevent back
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top loader
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: _progress,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Finding you a driver...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Please wait while we connect you with the nearest driver.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // Bottom cancel button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _handleCancel,
                      child: const Text(
                        "Cancel Ride",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
}
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
