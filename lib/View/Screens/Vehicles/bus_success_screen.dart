import 'package:flutter/material.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String seatNumber;
  final DateTime travelDate;
  final double amount;

  const BookingSuccessScreen({
    super.key,
    required this.seatNumber,
    required this.travelDate,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Make sure any previous loading dialogs are closed when this screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white10,
      appBar: AppBar(
        title: const Text("Booking Confirmed"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Success!",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Your booking has been confirmed.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event_seat),
                      title: const Text("Seat Number"),
                      subtitle: Text(seatNumber),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text("Travel Date"),
                      subtitle: Text(
                        travelDate.toLocal().toString().split(' ')[0],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text("Paid Amount"),
                      subtitle: Text("KES ${amount.toStringAsFixed(2)}"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransportServicesScreen(),
                  ),
                );
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(
                //     builder: (_) => const TransportServicesScreen(),
                //   ),
                //   (route) => false,
                // );
              },
              icon: const Icon(Icons.home),
              label: const Text("Return to Home"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart';

// class BookingSuccessScreen extends StatelessWidget {
//   final String seatNumber;
//   final DateTime travelDate;
//   final double amount;

//   const BookingSuccessScreen({
//     super.key,
//     required this.seatNumber,
//     required this.travelDate,
//     required this.amount,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green[50],
//       appBar: AppBar(
//         title: const Text("Booking Confirmed"),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.check_circle, size: 100, color: Colors.green),
//             const SizedBox(height: 20),
//             const Text(
//               "Success!",
//               style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "Your booking has been confirmed.",
//               style: TextStyle(fontSize: 16, color: Colors.grey[800]),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     ListTile(
//                       leading: const Icon(Icons.event_seat),
//                       title: const Text("Seat Number"),
//                       subtitle: Text(seatNumber),
//                     ),
//                     ListTile(
//                       leading: const Icon(Icons.calendar_today),
//                       title: const Text("Travel Date"),
//                       subtitle: Text(
//                         travelDate.toLocal().toString().split(' ')[0],
//                       ),
//                     ),
//                     ListTile(
//                       leading: const Icon(Icons.attach_money),
//                       title: const Text("Paid Amount"),
//                       subtitle: Text("KES ${amount.toStringAsFixed(2)}"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.of(
//                   context,
//                   rootNavigator: true,
//                 ).pop(); // Close dialog

//                 Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const TransportServicesScreen(),
//                   ),
//                   (route) => false,
//                 );
//               },
//               icon: const Icon(Icons.home),
//               label: const Text("Return to Home"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size.fromHeight(50),
//               ),
//             ),

//             // ElevatedButton.icon(
//             //   onPressed: () {
//             //     if (mounted) {
//             //       Navigator.of(
//             //         context,
//             //         rootNavigator: true,
//             //       ).pop(); // Close dialog
//             //       Navigator.pushAndRemoveUntil(
//             //         context,
//             //         MaterialPageRoute(
//             //           builder: (_) => const TransportServicesScreen(),
//             //         ),
//             //         (route) => false,
//             //       );
//             //     }
//             //   },
//             //   icon: const Icon(Icons.home),
//             //   label: const Text("Return to Home"),
//             //   style: ElevatedButton.styleFrom(
//             //     backgroundColor: Colors.green,
//             //     foregroundColor: Colors.white,
//             //     minimumSize: const Size.fromHeight(50),
//             //   ),
//             // ),

//             //             ElevatedButton.icon(
//             //               onPressed:
//             //                   () => if (mounted) {
//             //   Navigator.of(context, rootNavigator: true).pop(); // Close dialog
//             //   Navigator.pushAndRemoveUntil(
//             //     context,
//             //     MaterialPageRoute(builder: (_) => const TransportServicesScreen()),
//             //     (route) => false,
//             //   );
//             // }
//             //               icon: const Icon(Icons.home),
//             //               label: const Text("Return to Home"),
//             //               style: ElevatedButton.styleFrom(
//             //                 backgroundColor: Colors.green,
//             //                 foregroundColor: Colors.white,
//             //                 minimumSize: const Size.fromHeight(50),
//             //               ),
//             //             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
