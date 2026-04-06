import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';

// class ScheduleRideScreen extends StatefulWidget {
//   final LatLng? pickupLocation;
//   final LatLng? dropLocation;

//   const ScheduleRideScreen({super.key, this.pickupLocation, this.dropLocation});

//   @override
//   State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
// }

// class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedTime;
//   LatLng? currentLocation;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();

//     // Autofill with current time + 30 minutes
//     final now = DateTime.now().add(const Duration(minutes: 1));
//     _selectedDate = DateTime(now.year, now.month, now.day);
//     _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
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

//   Future<void> _pickDate(BuildContext context) async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? now,
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 60)), // 60-day max
//     );

//     if (picked != null) {
//       setState(() => _selectedDate = picked);
//     }
//   }

//   Future<void> _pickTime(BuildContext context) async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime ?? TimeOfDay.now(),
//     );

//     if (picked != null) {
//       setState(() => _selectedTime = picked);
//     }
//   }

//   Future<void> _scheduleRide() async {
//     if (_selectedDate == null || _selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select both date and time')),
//       );
//       return;
//     }

//     final scheduledDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedTime!.hour,
//       _selectedTime!.minute,
//     );

//     final now = DateTime.now().add(const Duration(minutes: 1));
//     final roundedNow = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       now.hour,
//       now.minute,
//     );

//     if (scheduledDateTime.isBefore(roundedNow)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Pickup time must be at least 31 minutes from now.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Scheduled ride for ${DateFormat.yMMMd().add_jm().format(scheduledDateTime)}',
//         ),
//       ),
//     );

//     await Future.delayed(const Duration(seconds: 2));

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => HomeScreen(
//               pickup: widget.pickupLocation ?? currentLocation,
//               destination: widget.dropLocation,
//               category: VehicleCategory.passenger,
//               isScheduled: true,
//               scheduledDate: scheduledDateTime,
//             ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateText =
//         _selectedDate != null
//             ? DateFormat.yMMMMd().format(_selectedDate!)
//             : 'Pick a date';

//     final timeText =
//         _selectedTime != null ? _selectedTime!.format(context) : 'Pick a time';

//     final buttonStyle = ElevatedButton.styleFrom(
//       backgroundColor: Colors.grey[700],
//       foregroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Schedule a Ride'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Schedule your ride',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 30),
//             ListTile(
//               leading: const Icon(Icons.calendar_today, color: Colors.blue),
//               title: Text(dateText),
//               trailing: ElevatedButton(
//                 onPressed: () => _pickDate(context),
//                 style: buttonStyle,
//                 child: const Text("Select"),
//               ),
//             ),
//             const SizedBox(height: 12),
//             ListTile(
//               leading: const Icon(Icons.access_time, color: Colors.green),
//               title: Text(timeText),
//               trailing: ElevatedButton(
//                 onPressed: () => _pickTime(context),
//                 style: buttonStyle,
//                 child: const Text("Select"),
//               ),
//             ),
//             const Spacer(),
//             ElevatedButton.icon(
//               onPressed: _scheduleRide,
//               icon: const Icon(Icons.schedule),
//               label: const Text('Confirm and Continue'),
//               style: buttonStyle.copyWith(
//                 minimumSize: MaterialStateProperty.all(
//                   const Size(double.infinity, 50),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class ScheduleRideScreen extends StatefulWidget {
  final LatLng? pickupLocation;
  final LatLng? dropLocation;

  const ScheduleRideScreen({super.key, this.pickupLocation, this.dropLocation});

  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? currentLocation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    final now = DateTime.now().add(const Duration(minutes: 30));
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  Future<void> _getCurrentLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseDatabase.instance
        .ref('passengers/${user.uid}/location')
        .onValue
        .listen((event) {
          final location = event.snapshot.value as Map?;
          if (location != null) {
            setState(() {
              currentLocation = LatLng(
                location['latitude'],
                location['longitude'],
              );
            });
          }
        });
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _scheduleRide() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final now = DateTime.now().add(const Duration(minutes: 30));

    if (scheduledDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select at least 30 mins from now"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => HomeScreen(
              pickup: widget.pickupLocation ?? currentLocation,
              destination: widget.dropLocation,
              category: VehicleCategory.passenger,
              isScheduled: true,
              scheduledDate: scheduledDateTime,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        _selectedDate != null
            ? DateFormat('EEE, dd MMM yyyy').format(_selectedDate!)
            : "Select Date";

    final timeText =
        _selectedTime != null ? _selectedTime!.format(context) : "Select Time";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Schedule Ride"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      /// 🔥 BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// DATE CARD
            _buildSelectorCard(
              icon: Icons.calendar_today,
              title: "Pickup Date",
              value: dateText,
              onTap: () => _pickDate(context),
            ),

            const SizedBox(height: 14),

            /// TIME CARD
            _buildSelectorCard(
              icon: Icons.access_time,
              title: "Pickup Time",
              value: timeText,
              onTap: () => _pickTime(context),
            ),

            const Spacer(),

            /// SUMMARY
            if (_selectedDate != null && _selectedTime != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  "Scheduled for ${DateFormat.yMMMd().add_jm().format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute))}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// 🔥 BLACK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _scheduleRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm Schedule",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 MODERN SELECTOR CARD
  Widget _buildSelectorCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';

// class ScheduleRideScreen extends StatefulWidget {
//   final LatLng? pickupLocation;
//   final LatLng? dropLocation;

//   const ScheduleRideScreen({super.key, this.pickupLocation, this.dropLocation});

//   @override
//   State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
// }

// class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedTime;
//   LatLng? currentLocation;

//   @override
//   void initState() {
//     super.initState();
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

//   Future<void> _pickDate(BuildContext context) async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 30)),
//     );

//     if (picked != null) {
//       setState(() => _selectedDate = picked);
//     }
//   }

//   Future<void> _pickTime(BuildContext context) async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );

//     if (picked != null) {
//       setState(() => _selectedTime = picked);
//     }
//   }

//   Future<void> _scheduleRide() async {
//     if (_selectedDate == null || _selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select both date and time')),
//       );
//       return;
//     }

//     final scheduledDateTime = DateTime(
//       _selectedDate!.year,
//       _selectedDate!.month,
//       _selectedDate!.day,
//       _selectedTime!.hour,
//       _selectedTime!.minute,
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Scheduled ride for ${DateFormat.yMMMd().add_jm().format(scheduledDateTime)}',
//         ),
//       ),
//     );

//     await Future.delayed(const Duration(seconds: 1));

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => HomeScreen(
//               pickup: widget.pickupLocation ?? currentLocation,
//               destination: widget.dropLocation,
//               category: VehicleCategory.passenger,
//               isScheduled: true,
//               scheduledDate: scheduledDateTime,
//             ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateText =
//         _selectedDate != null
//             ? DateFormat.yMMMMd().format(_selectedDate!)
//             : 'Pick a date';

//     final timeText =
//         _selectedTime != null ? _selectedTime!.format(context) : 'Pick a time';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Schedule a Ride'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Schedule your ride',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 30),
//             ListTile(
//               leading: const Icon(Icons.calendar_today, color: Colors.blue),
//               title: Text(dateText),
//               trailing: ElevatedButton(
//                 onPressed: () => _pickDate(context),
//                 child: const Text("Select"),
//               ),
//             ),
//             const SizedBox(height: 12),
//             ListTile(
//               leading: const Icon(Icons.access_time, color: Colors.green),
//               title: Text(timeText),
//               trailing: ElevatedButton(
//                 onPressed: () => _pickTime(context),
//                 child: const Text("Select"),
//               ),
//             ),
//             const Spacer(),
//             ElevatedButton.icon(
//               onPressed: _scheduleRide,
//               icon: const Icon(Icons.schedule),
//               label: const Text('Confirm and Continue'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 50),
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:latlong2/latlong.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
// // import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';

// // class ScheduleRideScreen extends StatefulWidget {
// //   final LatLng? pickupLocation;
// //   final LatLng? dropLocation;
// //   const ScheduleRideScreen({super.key,this.dropLocation,this.pickupLocation});

// //   @override
// //   State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
// // }

// // class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
// //   DateTime? _selectedDate;
// //   TimeOfDay? _selectedTime;
// //   LatLng? currentLocation;
// //   final _formKey = GlobalKey<FormState>();

// //   Future<void> _pickDate(BuildContext context) async {
// //     final now = DateTime.now();
// //     final date = await showDatePicker(
// //       context: context,
// //       initialDate: now,
// //       firstDate: now,
// //       lastDate: now.add(Duration(days: 30)),
// //     );

// //     if (date != null) {
// //       setState(() => _selectedDate = date);
// //     }
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     _getCurrentLocation();
// //   }

// //   Future<void> _pickTime(BuildContext context) async {
// //     final time = await showTimePicker(
// //       context: context,
// //       initialTime: TimeOfDay.now(),
// //     );

// //     if (time != null) {
// //       setState(() => _selectedTime = time);
// //     }
// //   }

// //   Future<void> _getCurrentLocation() async {
// //     final user = FirebaseAuth.instance.currentUser;
// //     if (user == null) return;

// //     final ref = FirebaseDatabase.instance.ref(
// //       'passengers/${user.uid}/location',
// //     );
// //     ref.onValue.listen((event) {
// //       final location = event.snapshot.value as Map?;
// //       if (location != null) {
// //         final lat = location['latitude'];
// //         final lng = location['longitude'];
// //         setState(() {
// //           currentLocation = LatLng(lat, lng);
// //         });
// //       }
// //     });
// //   }

// //   Future<void> _scheduleRide() async {
// //     if (_selectedDate == null || _selectedTime == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Please select both date and time')),
// //       );
// //       return;
// //     }

// //     final scheduledDateTime = DateTime(
// //       _selectedDate!.year,
// //       _selectedDate!.month,
// //       _selectedDate!.day,
// //       _selectedTime!.hour,
// //       _selectedTime!.minute,
// //     );

// //     // TODO: Send this to Firebase or your backend
// //     print('Scheduled for: $scheduledDateTime');

// //     // Show confirmation
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(
// //           'Ride scheduled for ${DateFormat.yMMMd().add_jm().format(scheduledDateTime)}',
// //         ),
// //       ),
// //     );

// //     // Optional delay
// //     await Future.delayed(Duration(seconds: 1));

// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder:
// //             (_) => HomeScreen(
// //               pickup: pickupLocation,
// //               destination: dropLocation,
// //               //stops: ref.read(stopsProvider),
// //               category: VehicleCategory.passenger,
// //             ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final selectedDate =
// //         _selectedDate != null
// //             ? DateFormat.yMMMd().format(_selectedDate!)
// //             : 'Select Date';

// //     final selectedTime =
// //         _selectedTime != null ? _selectedTime!.format(context) : 'Select Time';

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Schedule a Ride'),
// //         backgroundColor: Colors.redAccent,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             children: [
// //               Text(
// //                 'Choose your preferred ride time',
// //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
// //               ),
// //               const SizedBox(height: 30),
// //               ListTile(
// //                 leading: Icon(Icons.calendar_today, color: Colors.blueAccent),
// //                 title: Text(selectedDate),
// //                 trailing: ElevatedButton(
// //                   onPressed: () => _pickDate(context),
// //                   child: Text('Pick Date'),
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //               ListTile(
// //                 leading: Icon(Icons.access_time, color: Colors.green),
// //                 title: Text(selectedTime),
// //                 trailing: ElevatedButton(
// //                   onPressed: () => _pickTime(context),
// //                   child: Text('Pick Time'),
// //                 ),
// //               ),
// //               const SizedBox(height: 40),
// //               ElevatedButton.icon(
// //                 onPressed: _scheduleRide,
// //                 icon: Icon(Icons.check),
// //                 label: Text('Schedule Ride'),
// //                 style: ElevatedButton.styleFrom(
// //                   minimumSize: Size(double.infinity, 50),
// //                   backgroundColor: Colors.redAccent,
// //                   textStyle: TextStyle(fontSize: 18),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
