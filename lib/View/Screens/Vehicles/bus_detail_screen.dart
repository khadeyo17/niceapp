import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Vehicles/paymentscreendetail.dart';

class BusDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bus;
  final DateTime travelDate;

  const BusDetailsScreen({
    super.key,
    required this.bus,
    required this.travelDate,
  });

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  String? selectedSeat;
  List<dynamic> seatLayout = [];
  bool isLoading = true;
  double? normalFare;
  double? businessFare;
  double? vipFare;
  double selectedFare = 0.0;

  @override
  void initState() {
    super.initState();
    fetchSeatData();
  }

  Future<void> fetchSeatData() async {
    final busId = widget.bus['id'];
    final date = widget.travelDate.toIso8601String();
    final response = await http.get(
      Uri.parse('$baseUrl/passengerrides/$busId/seats?travelDate=$date'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        seatLayout = List<Map<String, dynamic>>.from(data['layout']);
        normalFare = (data['normalFare'] as num?)?.toDouble();
        businessFare = (data['businessFare'] as num?)?.toDouble();
        vipFare = (data['vipFare'] as num?)?.toDouble();
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load seat data: ${response.body}")),
      );
    }
  }

  // Future<void> completeBooking(String? token) async {
  //   final bookingResponse = await http.post(
  //     Uri.parse('$baseUrl/passengerrides/bus/book'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({
  //       "busId": widget.bus["id"],
  //       "seatNumber": widget.bus["seatNumber"],
  //       "travelDate": widget.travelDate.toIso8601String(),
  //       "firebaseIdToken": token,
  //     }),
  //   );

  //   if (bookingResponse.statusCode == 200) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder:
  //             (_) => PaymentScreen(
  //               busId: widget.bus['id'].toString(),
  //               seatNumber: selectedSeat!,
  //               travelDate: widget.travelDate,
  //               amount: selectedFare,
  //             ),
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Booking failed: ${bookingResponse.body}")),
  //     );
  //   }

  //   setState(() => isProcessing = false);
  // }

  @override
  Widget build(BuildContext context) {
    final totalSeats = widget.bus['totalSeats'] ?? seatLayout.length;
    final availableSeats = widget.bus['availableSeats'] ?? 0;

    final hasVip = seatLayout.any((seat) => seat['isVip'] == true);
    final hasBusiness = seatLayout.any((seat) => seat['isBusiness'] == true);
    final hasNormal = seatLayout.any(
      (seat) => seat['isVip'] != true && seat['isBusiness'] != true,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.bus['company'] ?? 'Bus Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // children: [
          //   // Text("Normal Fare: KES ${widget.bus['fare']}"),
          //   // Text("Business Class: KES ${widget.bus['fare']}"),
          //   // Text("Vip Fare: KES ${widget.bus['fare']}"),
          //   if (normalFare != null)
          //     Text("Normal Fare: KES ${normalFare!.toStringAsFixed(0)}"),
          //   if (businessFare != null)
          //     Text(
          //       "Business Class Fare: KES ${businessFare!.toStringAsFixed(0)}",
          //     ),
          //   if (vipFare != null)
          //     Text("VIP Fare: KES ${vipFare!.toStringAsFixed(0)}"),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (normalFare != null)
              Text(
                "Normal Fare: KES ${normalFare!.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (businessFare != null)
              Text(
                "Business Class Fare: KES ${businessFare!.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (vipFare != null)
              Text(
                "VIP Fare: KES ${vipFare!.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

            Text(
              "Seats: $availableSeats / $totalSeats Available",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                        itemCount: seatLayout.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemBuilder: (_, index) {
                          final seat = seatLayout[index];
                          final seatId = seat['seatNumber'];
                          final isBooked = seat['isBooked'] ?? false;
                          final isSelected = selectedSeat == seatId;
                          final isVip = seat['isVip'] ?? false;
                          final isBusiness = seat['isBusiness'] ?? false;

                          Color seatColor;
                          if (isBooked) {
                            seatColor = Colors.grey;
                          } else if (isSelected) {
                            seatColor = Colors.blue;
                          } else if (isVip) {
                            seatColor = Colors.red;
                          } else if (isBusiness) {
                            seatColor = Colors.orange;
                          } else {
                            seatColor = Colors.green;
                          }

                          return GestureDetector(
                            onTap:
                                isBooked
                                    ? null
                                    : () {
                                      setState(() {
                                        selectedSeat = seatId;
                                      });
                                    },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: seatColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                seatId,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 12),
            if (hasVip || hasBusiness || hasNormal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (hasVip)
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.red),
                        const SizedBox(width: 4),
                        const Text("VIP Seat"),
                      ],
                    ),
                  if (hasBusiness)
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.orange),
                        const SizedBox(width: 4),
                        const Text("Business Class"),
                      ],
                    ),
                  if (hasNormal)
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text("Normal Seat"),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              // onPressed:
              //     selectedSeat == null
              //         ? null
              //         : () {
              //           // final selectedSeatData = seatLayout.firstWhere(
              //           //   (s) => s['seatNumber'] == selectedSeat,
              //           //   orElse: () => null,
              //           // );
              //           final selectedSeatData = seatLayout.firstWhere(
              //             (s) => s['seatNumber'] == selectedSeat,
              //             orElse:
              //                 () =>
              //                     <
              //                       String,
              //                       dynamic
              //                     >{}, // Return an empty map instead of null
              //           );
              //           double selectedFare; // =
              //           if (selectedSeatData.containsKey('fare') &&
              //               selectedSeatData['fare'] != null) {
              //             selectedFare = selectedSeatData['fare'].toDouble();
              //           } else if (selectedSeatData['isVip'] == true) {
              //             selectedFare = vipFare ?? 0.0;
              //           } else if (selectedSeatData['isBusiness'] == true) {
              //             selectedFare = businessFare ?? 0.0;
              //           } else {
              //             selectedFare = normalFare ?? 0.0;
              //           } // selectedSeatData.containsKey('fare')
              //           //     ? (selectedSeatData['fare']?.toDouble() ??
              //           //         normalFare ??
              //           //         0.0)
              //           //     : (normalFare ?? 0.0);
              //           // final double selectedFare =
              //           //     selectedSeatData?['fare']?.toDouble() ??
              //           //     normalFare ??
              //           //     0.0;

              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder:
              //                   (_) => PaymentScreen(
              //                     busId: widget.bus['id'].toString(),
              //                     seatNumber: selectedSeat!,
              //                     travelDate: widget.travelDate,
              //                     amount: selectedFare,
              //                   ),
              //             ),
              //           );
              //         },
              onPressed:
                  selectedSeat == null
                      ? null
                      : () async {
                        final selectedSeatData = seatLayout.firstWhere(
                          (s) => s['seatNumber'] == selectedSeat,
                          orElse: () => <String, dynamic>{},
                        );

                        double selectedFare;
                        if (selectedSeatData.containsKey('fare') &&
                            selectedSeatData['fare'] != null) {
                          selectedFare = selectedSeatData['fare'].toDouble();
                        } else if (selectedSeatData['isVip'] == true) {
                          selectedFare = vipFare ?? 0.0;
                        } else if (selectedSeatData['isBusiness'] == true) {
                          selectedFare = businessFare ?? 0.0;
                        } else {
                          selectedFare = normalFare ?? 0.0;
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        final token = await user?.getIdToken();

                        if (token == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("You must be logged in"),
                            ),
                          );
                          return;
                        }

                        //   final bookingResponse = await http.post(
                        //     Uri.parse('$baseUrl/passengerrides/bus/book'),
                        //     headers: {'Content-Type': 'application/json'},
                        //     body: json.encode({
                        //       "busId": widget.bus["id"],
                        //       "seatNumber": selectedSeat,
                        //       "travelDate": widget.travelDate.toIso8601String(),
                        //       "firebaseIdToken": token,
                        //     }),
                        //   );

                        //   if (bookingResponse.statusCode == 200) {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder:
                        //             (_) => PaymentScreen(
                        //               busId: widget.bus['id'].toString(),
                        //               seatNumber: selectedSeat!,
                        //               travelDate: widget.travelDate,
                        //               amount: selectedFare,
                        //               rideId: widget.r,
                        //             ),
                        //       ),
                        //     );
                        //   } else {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(
                        //         content: Text(
                        //           "Booking failed: ${bookingResponse.body}",
                        //         ),
                        //       ),
                        //     );
                        //   }
                        // },

                        final bookingResponse = await http.post(
                          Uri.parse('$baseUrl/passengerrides/bus/book'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            "busId": widget.bus["id"],
                            "seatNumber": selectedSeat,
                            "travelDate": widget.travelDate.toIso8601String(),
                            "firebaseIdToken": token,
                          }),
                        );

                        if (bookingResponse.statusCode == 200) {
                          final responseData = jsonDecode(bookingResponse.body);
                          final int rideId = responseData['rideId'];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => PaymentScreen(
                                    busId: widget.bus['id'].toString(),
                                    seatNumber: selectedSeat!,
                                    travelDate: widget.travelDate,
                                    amount: selectedFare,
                                    rideId:
                                        rideId, // ✅ pass the rideId received from backend
                                  ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Booking failed: ${bookingResponse.body}",
                              ),
                            ),
                          );
                        }
                      },

              icon: const Icon(Icons.payment),
              label: const Text('Book Selected Seat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700], // Button background
                foregroundColor: Colors.white, // Text & icon color
                //minimumSize: const Size.fromHeight(50),
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            //             ElevatedButton.icon(
            //               onPressed:
            //                   // selectedSeat == null
            //                   //     ? null
            //                   //     : () {
            //                   //       Navigator.push(
            //                   //         context,
            //                   //         MaterialPageRoute(
            //                   //           builder:
            //                   //               (_) => PaymentScreen(
            //                   //                 busId: widget.bus['id'].toString(),
            //                   //                 seatNumber: selectedSeat!,
            //                   //                 travelDate: widget.travelDate,
            //                   //                 amount: widget.bus['fare']?.toDouble() ?? 0.0,
            //                   //               ),
            //                   //         ),
            //                   //       );
            //                   //     },
            //                   final selectedSeatData = seatLayout.firstWhere(
            //   (s) => s['seatNumber'] == selectedSeat,
            //   orElse: () => null,
            // );

            // final double selectedFare = selectedSeatData?['fare']?.toDouble() ?? normalFare ?? 0.0;

            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => PaymentScreen(
            //       busId: widget.bus['id'].toString(),
            //       seatNumber: selectedSeat!,
            //       travelDate: widget.travelDate,
            //       amount: selectedFare,
            //     ),
            //   ),
            // );
            //   icon: const Icon(Icons.payment),
            //   label: const Text('Book Selected Seat'),
            //   style: ElevatedButton.styleFrom(
            //     minimumSize: const Size.fromHeight(50),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Vehicles/paymentscreendetail.dart';

// class BusDetailsScreen extends StatefulWidget {
//   final Map<String, dynamic> bus;
//   final DateTime travelDate;

//   const BusDetailsScreen({
//     super.key,
//     required this.bus,
//     required this.travelDate,
//   });

//   @override
//   State<BusDetailsScreen> createState() => _BusDetailsScreenState();
// }

// class _BusDetailsScreenState extends State<BusDetailsScreen> {
//   Map<String, dynamic>? selectedSeat;

//   List<dynamic> seatLayout = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchSeatLayout();
//   }

//   Future<void> fetchSeatLayout() async {
//     final busId = widget.bus['id'];
//     final date = widget.travelDate.toIso8601String();

//     final response = await http.get(
//       Uri.parse('$baseUrl/passengerrides/$busId/seats?travelDate=$date'),
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       setState(() {
//         seatLayout = List<Map<String, dynamic>>.from(data['layout']);
//         isLoading = false;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to load seats: ${response.body}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final availableSeats = widget.bus['availableSeats'] ?? 0;
//     final totalSeats = widget.bus['totalSeats'] ?? seatLayout.length;

//     return Scaffold(
//       appBar: AppBar(title: Text(widget.bus['company'] ?? 'Bus Details')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text("Seats: $availableSeats / $totalSeats Available"),
//             const SizedBox(height: 16),
//             Expanded(
//               child:
//                   isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : GridView.builder(
//                         itemCount: seatLayout.length,
//                         gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 4,
//                               mainAxisSpacing: 8,
//                               crossAxisSpacing: 8,
//                             ),
//                         itemBuilder: (_, index) {
//                           final seat = seatLayout[index];
//                           final seatNumber = seat['seatNumber'];
//                           final isBooked = seat['isBooked'] ?? false;
//                           final isVip = seat['isVip'] ?? false;
//                           final fare = (seat['fare'] ?? 0).toDouble();
//                           final isSelected =
//                               selectedSeat?['seatNumber'] == seatNumber;

//                           Color bgColor;
//                           if (isBooked) {
//                             bgColor = Colors.grey;
//                           } else if (isSelected) {
//                             bgColor = Colors.blue;
//                           } else {
//                             bgColor = isVip ? Colors.amber : Colors.green;
//                           }

//                           return GestureDetector(
//                             onTap:
//                                 isBooked
//                                     ? null
//                                     : () {
//                                       setState(() {
//                                         selectedSeat = seat;
//                                       });
//                                     },
//                             child: Container(
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                 color: bgColor,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     seatNumber,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   Text(
//                                     'KES ${fare.toStringAsFixed(0)}',
//                                     style: const TextStyle(
//                                       color: Colors.white70,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//             ),
//             if (selectedSeat != null) ...[
//               const SizedBox(height: 10),
//               Text(
//                 "Selected Seat: ${selectedSeat!['seatNumber']} (KES ${selectedSeat!['fare'].toStringAsFixed(0)})",
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 10),
//             ],
//             ElevatedButton.icon(
//               onPressed:
//                   selectedSeat == null
//                       ? null
//                       : () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (_) => PaymentScreen(
//                                   busId: widget.bus['id'].toString(),
//                                   seatNumber: selectedSeat!['seatNumber'],
//                                   travelDate: widget.travelDate,
//                                   amount:
//                                       (selectedSeat!['fare'] ?? 0).toDouble(),
//                                 ),
//                           ),
//                         );
//                       },
//               icon: const Icon(Icons.payment),
//               label: const Text('Book Selected Seat'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size.fromHeight(50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
