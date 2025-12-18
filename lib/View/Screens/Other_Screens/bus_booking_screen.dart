import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Vehicles/bus_detail_screen.dart';

class BusSearchRequest {
  final String from;
  final String to;
  final DateTime travelDate;

  BusSearchRequest({
    required this.from,
    required this.to,
    required this.travelDate,
  });

  Map<String, dynamic> toJson() => {
    "from": from,
    "to": to,
    "travelDate": travelDate.toIso8601String(),
  };
}

class BusBookingScreen extends StatefulWidget {
  const BusBookingScreen({super.key, required VehicleCategory category});

  @override
  _BusBookingScreenState createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  final TextEditingController travelDateController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();

  String? selectedFrom;
  String? selectedTo;
  String? selectedBusId;
  DateTime? selectedDate;
  bool isReturnTrip = false;
  DateTime? returnDate;

  List<String> locations = [];
  List<Map<String, dynamic>> availableBuses = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rides/routes'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonBody = json.decode(response.body);
        setState(() {
          locations = List<String>.from(jsonBody);
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
    }
  }

  Future<void> searchBuses() async {
    if (selectedFrom == null || selectedTo == null || selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final request = BusSearchRequest(
      from: selectedFrom!,
      to: selectedTo!,
      travelDate: selectedDate!,
    );

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rides/buses/search"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          setState(
            () => availableBuses = List<Map<String, dynamic>>.from(decoded),
          );
        }

        if (availableBuses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No buses found for the selected route."),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to fetch buses")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error searching buses: $e")));
    }
  }

  Future<void> submitBooking() async {
    if (selectedBusId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a bus')));
      return;
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl/rides/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'busId': selectedBusId,
        'travelDate': selectedDate?.toIso8601String(),
        'firebaseIdToken': token,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit booking')));
    }
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String? value, {
    Color iconColor = Colors.blueGrey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value ?? '', overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Booking'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🚌 Banner
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/imgs/bus_banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// FROM card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedFrom,
                            hint: const Text("Select departure location"),
                            items:
                                locations
                                    .map(
                                      (loc) => DropdownMenuItem(
                                        value: loc,
                                        child: Text(loc),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() => selectedFrom = val),
                            decoration: const InputDecoration.collapsed(
                              hintText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// TO card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedTo,
                            hint: const Text("Select destination"),
                            items:
                                locations
                                    .map(
                                      (loc) => DropdownMenuItem(
                                        value: loc,
                                        child: Text(loc),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() => selectedTo = val),
                            decoration: const InputDecoration.collapsed(
                              hintText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// DATE card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          travelDateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                : 'Select travel date',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /// RETURN TRIP switch
                SwitchListTile(
                  title: const Text(
                    "Return Trip?",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  value: isReturnTrip,
                  activeColor: Colors.redAccent,
                  onChanged:
                      (v) => setState(() {
                        isReturnTrip = v;
                        if (!v) returnDate = null;
                      }),
                ),

                if (isReturnTrip)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            returnDate = picked;
                            returnDateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked);
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              returnDate != null
                                  ? DateFormat('yyyy-MM-dd').format(returnDate!)
                                  : 'Select return date',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                /// SEARCH BUTTON
                ElevatedButton.icon(
                  onPressed: searchBuses,
                  icon: const Icon(Icons.search),
                  label: const Text(
                    "Search Buses",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          /// 🚌 Bus Results
          if (availableBuses.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.25,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Available Buses",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: availableBuses.length,
                          itemBuilder: (context, index) {
                            final bus = availableBuses[index];
                            final imageUrl =
                                (bus['imageUrl'] != null &&
                                        bus['imageUrl'].toString().isNotEmpty)
                                    ? (bus['imageUrl'].toString().startsWith(
                                          'http',
                                        )
                                        ? bus['imageUrl']
                                        : "$ImageUrl${bus['imageUrl']}")
                                    : null;
                            return InkWell(
                              onTap: () async {
                                final busId = bus['id'];
                                final response = await http.get(
                                  Uri.parse(
                                    '$baseUrl/rides/$busId/seats?travelDate=${selectedDate!.toIso8601String()}',
                                  ),
                                );
                                if (response.statusCode == 200) {
                                  final seatData = Map<String, dynamic>.from(
                                    jsonDecode(response.body),
                                  );
                                  final fullBus = {...bus, ...seatData};
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => BusDetailsScreen(
                                            bus: fullBus,
                                            travelDate: selectedDate!,
                                          ),
                                    ),
                                  );
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child:
                                                imageUrl != null
                                                    ? Image.network(
                                                      imageUrl,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : const Icon(
                                                      Icons.directions_bus,
                                                      size: 80,
                                                      color: Colors.redAccent,
                                                    ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              bus['company'] ?? 'Bus Operator',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _infoRow(
                                        Icons.event_seat,
                                        "Seats: ",
                                        "${bus['availableSeats'] ?? 'N/A'}",
                                      ),
                                      _infoRow(
                                        Icons.departure_board,
                                        "Depart: ",
                                        bus['departureTime'],
                                      ),
                                      _infoRow(
                                        Icons.access_time,
                                        "Arrival: ",
                                        bus['arrivalTime'],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
// import 'package:niceapp/View/Screens/Vehicles/bus_detail_screen.dart';

// class BusSearchRequest {
//   final String from;
//   final String to;
//   final DateTime travelDate;

//   BusSearchRequest({
//     required this.from,
//     required this.to,
//     required this.travelDate,
//   });

//   Map<String, dynamic> toJson() => {
//     "from": from,
//     "to": to,
//     "travelDate": travelDate.toIso8601String(),
//   };
// }

// class BusBookingScreen extends StatefulWidget {
//   const BusBookingScreen({super.key, required VehicleCategory category});

//   @override
//   _BusBookingScreenState createState() => _BusBookingScreenState();
// }

// class _BusBookingScreenState extends State<BusBookingScreen> {
//   final TextEditingController travelDateController = TextEditingController();

//   String? selectedFrom;
//   String? selectedTo;
//   String? selectedBusId;
//   DateTime? selectedDate;

//   bool isReturnTrip = false;
//   DateTime? returnDate;
//   final TextEditingController returnDateController = TextEditingController();

//   List<String> locations = [];
//   List<Map<String, dynamic>> availableBuses = [];
//   double? fare;

//   @override
//   void initState() {
//     super.initState();
//     fetchLocations();
//   }

//   Future<void> fetchLocations() async {
//     final response = await http.get(Uri.parse('$baseUrl/rides/routes'));

//     if (response.statusCode == 200) {
//       final List<dynamic> jsonBody = json.decode(response.body);
//       setState(() {
//         locations = List<String>.from(jsonBody);
//       });
//       print("Loaded locations: $locations");
//     } else {
//       print('Failed to load locations: ${response.statusCode}');
//     }
//   }

//   Future<void> searchBuses() async {
//     if (selectedFrom == null || selectedTo == null || selectedDate == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
//       return;
//     }

//     final request = BusSearchRequest(
//       from: selectedFrom!,
//       to: selectedTo!,
//       travelDate: selectedDate!,
//     );

//     try {
//       final response = await http.post(
//         Uri.parse("$baseUrl/rides/buses/search"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(request.toJson()),
//       );

//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);

//         if (decoded is List) {
//           setState(() {
//             availableBuses = List<Map<String, dynamic>>.from(decoded);
//           });
//         }
//         if (availableBuses.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("No buses found for the selected route."),
//               duration: Duration(seconds: 3),
//             ),
//           );
//         }

//         // else {
//         //   print("Unexpected format: $decoded");
//         //   ScaffoldMessenger.of(context).showSnackBar(
//         //     const SnackBar(content: Text("Invalid server response")),
//         //   );
//         // }
//       } else {
//         print("Error ${response.statusCode}: ${response.body}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No buses found for selected route.")),
//         );
//       }
//     } catch (e) {
//       print("Exception: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error searching buses: $e")));
//     }
//   }

//   Future<void> submitBooking() async {
//     if (selectedBusId == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select a bus')));
//       return;
//     }

//     final token = await FirebaseAuth.instance.currentUser?.getIdToken();
//     final response = await http.post(
//       Uri.parse('$baseUrl/rides/bookings'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'busId': selectedBusId,
//         'travelDate': selectedDate?.toIso8601String(),
//         'firebaseIdToken': token,
//       }),
//     );
//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Booking submitted successfully')),
//       );
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Failed to submit booking')));
//     }
//   }

//   Widget _infoRow(
//     IconData icon,
//     String label,
//     String? value, {
//     Color iconColor = Colors.blueGrey,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: iconColor),
//           const SizedBox(width: 4),
//           Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//           Flexible(child: Text(value ?? '', overflow: TextOverflow.ellipsis)),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final textColor = isDark ? Colors.white : Colors.black;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       //backgroundColor: isDark ? Colors.grey[900] : Colors.white,
//       appBar: AppBar(
//         title: const Text('Matatu Booking'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 DropdownButtonFormField<String>(
//                   value: locations.contains(selectedFrom) ? selectedFrom : null,
//                   hint: const Text("From"),
//                   items:
//                       locations.map((location) {
//                         return DropdownMenuItem(
//                           value: location,
//                           child: Text(location),
//                         );
//                       }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedFrom = value;
//                     });
//                   },
//                   decoration: const InputDecoration(
//                     labelText: 'Departure',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 DropdownButtonFormField<String>(
//                   value: locations.contains(selectedTo) ? selectedTo : null,
//                   hint: const Text("To"),
//                   items:
//                       locations.map((location) {
//                         return DropdownMenuItem(
//                           value: location,
//                           child: Text(location),
//                         );
//                       }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedTo = value;
//                     });
//                   },
//                   decoration: const InputDecoration(
//                     labelText: 'Destination',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextFormField(
//                   controller: travelDateController,
//                   decoration: const InputDecoration(
//                     labelText: 'Travel Date',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.datetime,
//                   onTap: () async {
//                     FocusScope.of(context).requestFocus(FocusNode());
//                     final pickedDate = await showDatePicker(
//                       context: context,
//                       firstDate: DateTime.now(),
//                       lastDate: DateTime(2100),
//                       initialDate: DateTime.now(),
//                     );
//                     if (pickedDate != null) {
//                       setState(() {
//                         selectedDate = pickedDate;
//                         travelDateController.text = DateFormat(
//                           'yyyy-MM-dd',
//                         ).format(pickedDate);
//                       });
//                     }
//                   },
//                 ),
//                 const SizedBox(height: 20),

//                 SwitchListTile.adaptive(
//                   title: const Text("Return Trip?"),
//                   value: isReturnTrip,
//                   onChanged: (value) {
//                     setState(() {
//                       isReturnTrip = value;
//                       if (!value) {
//                         returnDate = null;
//                         returnDateController.clear();
//                       }
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 10),
//                 // 👇 Add this if the user selects return trip
//                 if (isReturnTrip) ...[
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: returnDateController,
//                     readOnly: true,
//                     decoration: const InputDecoration(
//                       labelText: 'Return Date',
//                       border: OutlineInputBorder(),
//                     ),
//                     onTap: () async {
//                       FocusScope.of(context).unfocus();
//                       final picked = await showDatePicker(
//                         context: context,
//                         firstDate:
//                             selectedDate != null
//                                 ? selectedDate!.add(const Duration(days: 1))
//                                 : DateTime.now().add(const Duration(days: 1)),
//                         lastDate: DateTime(2100),
//                         initialDate:
//                             selectedDate != null
//                                 ? selectedDate!.add(const Duration(days: 1))
//                                 : DateTime.now().add(const Duration(days: 1)),
//                       );
//                       if (picked != null) {
//                         setState(() {
//                           returnDate = picked;
//                           returnDateController.text = DateFormat(
//                             'yyyy-MM-dd',
//                           ).format(picked);
//                         });
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//                 ElevatedButton.icon(
//                   onPressed: searchBuses,
//                   icon: const Icon(Icons.search),
//                   label: const Text('Search Buses'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[700],
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size.fromHeight(50),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//               ],
//             ),
//           ),
//           if (availableBuses.isNotEmpty)
//             DraggableScrollableSheet(
//               initialChildSize: 0.4,
//               minChildSize: 0.25,
//               maxChildSize: 0.8,
//               builder: (context, scrollController) {
//                 return Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(20),
//                     ),
//                     boxShadow: [BoxShadow(color: Colors.black, blurRadius: 10)],
//                   ),
//                   child: Column(
//                     children: [
//                       const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 10),
//                         child: Text(
//                           "Available Buses",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: ListView.builder(
//                           controller: scrollController,
//                           itemCount: availableBuses.length,
//                           itemBuilder: (context, index) {
//                             final bus = availableBuses[index];
//                             final imageUrl =
//                                 (bus['imageUrl'] != null &&
//                                         bus['imageUrl'].toString().isNotEmpty)
//                                     ? (bus['imageUrl'].toString().startsWith(
//                                           'http',
//                                         )
//                                         ? bus['imageUrl']
//                                         : "$ImageUrl${bus['imageUrl']}")
//                                     : null;
//                             return InkWell(
//                               onTap: () async {
//                                 final busId = bus['id'];
//                                 final response = await http.get(
//                                   Uri.parse(
//                                     '$baseUrl/rides/$busId/seats?travelDate=${selectedDate!.toIso8601String()}',
//                                   ),
//                                 );
//                                 if (response.statusCode == 200) {
//                                   final seatData = Map<String, dynamic>.from(
//                                     jsonDecode(response.body),
//                                   );
//                                   final fullBus = {...bus, ...seatData};
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder:
//                                           (_) => BusDetailsScreen(
//                                             bus: fullBus,
//                                             travelDate: selectedDate!,
//                                           ),
//                                     ),
//                                   );
//                                 }
//                               },
//                               splashColor: Colors.blue.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(12),
//                               child: Card(
//                                 elevation: 4,
//                                 margin: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 8,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),

//                                 child: Padding(
//                                   padding: const EdgeInsets.all(12),
//                                   child: Column(
//                                     children: [
//                                       Row(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           // Top Left: Bus Image
//                                           ClipRRect(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                             child:
//                                                 imageUrl != null
//                                                     ? Image.network(
//                                                       imageUrl,
//                                                       width: 80,
//                                                       height: 80,
//                                                       fit: BoxFit.cover,
//                                                     )
//                                                     : const Icon(
//                                                       Icons.directions_bus,
//                                                       size: 80,
//                                                     ),
//                                           ),
//                                           const SizedBox(width: 12),

//                                           // Top Right: Company name
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Align(
//                                                   alignment: Alignment.topRight,
//                                                   child: Text(
//                                                     bus['company'] ??
//                                                         'Bus Operator',
//                                                     style: const TextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 12),

//                                       Row(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           // Bottom Left: Seat and Time Info (wider)
//                                           Expanded(
//                                             flex: 3,
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 _infoRow(
//                                                   Icons.event_seat,
//                                                   "Seats  : ",
//                                                   "${bus['availableSeats'] ?? 'N/A'}",
//                                                 ),
//                                                 _infoRow(
//                                                   Icons.departure_board,
//                                                   "Depart : ",
//                                                   bus['departureTime'],
//                                                 ),
//                                                 _infoRow(
//                                                   Icons.access_time,
//                                                   "Arrival: ",
//                                                   bus['arrivalTime'],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),

//                                           const SizedBox(
//                                             width: 8,
//                                           ), // optional spacing between columns
//                                           // Bottom Right: Fares (narrower)
//                                           Expanded(
//                                             flex: 2,
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.end,
//                                               children: [
//                                                 if (bus['normalFare'] != null)
//                                                   _infoRow(
//                                                     Icons.event_seat,
//                                                     "Normal: ",
//                                                     "KES ${bus['normalFare']}",
//                                                     iconColor: Colors.green,
//                                                   ),
//                                                 if (bus['businessFare'] != null)
//                                                   _infoRow(
//                                                     Icons.event_seat,
//                                                     "Business: ",
//                                                     "KES ${bus['businessFare']}",
//                                                     iconColor: Colors.orange,
//                                                   ),
//                                                 if (bus['vipFare'] != null)
//                                                   _infoRow(
//                                                     Icons.event_seat,
//                                                     "VIP: ",
//                                                     "KES ${bus['vipFare']}",
//                                                     iconColor: Colors.red,
//                                                   ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }
// }
