import 'dart:async';
import 'package:flutter/material.dart';
import 'package:niceapp/View/Screens/Cargo/driver_assignment_screen.dart';

class RequestConfirmedScreen extends StatefulWidget {
  final String? destinationAddress;
  final DateTime? requestedAt;
  final bool isDriverAssigned; // initial state
  final VoidCallback? onCancel;

  const RequestConfirmedScreen({
    super.key,
    this.destinationAddress,
    this.requestedAt,
    this.isDriverAssigned = false,
    this.onCancel,
  });

  @override
  State<RequestConfirmedScreen> createState() => _RequestConfirmedScreenState();
}

class _RequestConfirmedScreenState extends State<RequestConfirmedScreen> {
  bool _driverAssigned = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _driverAssigned = widget.isDriverAssigned;
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      bool assigned =
          await checkDriverAssignment(); // Replace with real API call
      if (assigned) {
        setState(() {
          _driverAssigned = true;
        });
        _pollingTimer?.cancel();
        _navigateToDriverScreen();
      }
    });
  }

  Future<bool> checkDriverAssignment() async {
    // 🔁 Simulate checking backend for driver assignment
    // Replace this with real HTTP call.
    await Future.delayed(const Duration(seconds: 1));
    return false; // ✅ Change to `true` to simulate a driver being assigned
  }

  void _navigateToDriverScreen() {
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder:
    //         (_) =>
    //             const DriverAssignmentScreen(), // 🔁 Replace with your screen
    //   ),
    // );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        widget.requestedAt != null
            ? "${widget.requestedAt!.hour.toString().padLeft(2, '0')}:${widget.requestedAt!.minute.toString().padLeft(2, '0')}"
            : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Confirmed'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text(
                    'Your exhauster request has been confirmed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (widget.destinationAddress != null)
                    Text(
                      'Destination: ${widget.destinationAddress}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  if (formattedTime.isNotEmpty)
                    Text(
                      'Requested at: $formattedTime',
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 30),
                  if (!_driverAssigned)
                    ElevatedButton.icon(
                      onPressed: () {
                        _pollingTimer?.cancel();
                        widget.onCancel?.call();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel Request"),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.home),
                    label: const Text("Back to Home"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//   State<RequestConfirmedScreen> createState() => _RequestConfirmedScreenState();
// }

// class _RequestConfirmedScreenState extends State<RequestConfirmedScreen> {
//   bool isCancelled = false;
//   bool driverAssigned = false; // Simulate: change to true to disable cancel

//   void cancelRequest() {
//     setState(() {
//       isCancelled = true;
//     });

//     // TODO: Make an API call here to cancel the request in backend

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Your request has been cancelled.'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final formattedTime =
//         widget.requestedAt != null
//             ? "${widget.requestedAt!.hour.toString().padLeft(2, '0')}:${widget.requestedAt!.minute.toString().padLeft(2, '0')}"
//             : '';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Request Confirmed'),
//         centerTitle: true,
//         backgroundColor: Colors.green.shade700,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Card(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             elevation: 8,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     isCancelled ? Icons.cancel_outlined : Icons.check_circle,
//                     size: 80,
//                     color: isCancelled ? Colors.red : Colors.green,
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     isCancelled
//                         ? 'Your request has been cancelled.'
//                         : 'Your exhauster request has been confirmed!',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   if (widget.destinationAddress != null)
//                     Text(
//                       'Destination: ${widget.destinationAddress}',
//                       style: const TextStyle(fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                   if (formattedTime.isNotEmpty)
//                     Text(
//                       'Requested at: $formattedTime',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   const SizedBox(height: 30),
//                   if (!driverAssigned && !isCancelled)
//                     ElevatedButton.icon(
//                       onPressed: cancelRequest,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 32,
//                           vertical: 16,
//                         ),
//                       ),
//                       icon: const Icon(Icons.cancel),
//                       label: const Text("Cancel Request"),
//                     ),
//                   const SizedBox(height: 16),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.popUntil(context, (route) => route.isFirst);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green.shade700,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 32,
//                         vertical: 16,
//                       ),
//                     ),
//                     icon: const Icon(Icons.home),
//                     label: const Text("Back to Home"),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
