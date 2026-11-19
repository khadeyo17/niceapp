import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/machinery.dart';
import 'package:niceapp/View/Screens/Other_Screens/water_bower_screen.dart';


class ScheduleRideScreen extends StatefulWidget {
  final VehicleCategory category;
  final LatLng? pickupLocation;
  final LatLng? dropLocation;

  const ScheduleRideScreen({super.key,required this.category, this.pickupLocation, this.dropLocation});

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

  String get serviceName {
  switch (widget.category) {
    case VehicleCategory.passenger:
      return 'Ride';

    case VehicleCategory.waterBowser:
      return 'Water Delivery';

    case VehicleCategory.exhauster:
      return 'Exhauster Service';

    case VehicleCategory.machinery:
      return 'Machinery Service';

    default:
      return 'Service';
  }
}

String get scheduleTitle {
  switch (widget.category) {
    case VehicleCategory.passenger:
      return 'Plan your ride';

    case VehicleCategory.waterBowser:
      return 'Schedule water delivery';

    case VehicleCategory.exhauster:
      return 'Schedule exhauster service';

    case VehicleCategory.machinery:
      return 'Schedule machinery';

    default:
      return 'Plan your service';
  }
}

String get scheduleDescription {
  switch (widget.category) {
    case VehicleCategory.passenger:
      return 'Book ahead and have your ride ready when you need it.';

    case VehicleCategory.waterBowser:
      return 'Schedule your water delivery and have clean water delivered when you need it.';

    case VehicleCategory.exhauster:
      return 'Book your exhauster service in advance and have your waste collection handled at your preferred time.';

    case VehicleCategory.machinery:
      return 'Reserve the machinery you need ahead of time and plan your project with ease.';

    default:
      return 'Schedule your service at a convenient date and time.';
  }
}

String get pickupSectionTitle {
  switch (widget.category) {
    case VehicleCategory.passenger:
      return 'Pickup details';

    case VehicleCategory.waterBowser:
      return 'Delivery details';

    case VehicleCategory.exhauster:
      return 'Service details';

    case VehicleCategory.machinery:
      return 'Booking details';

    default:
      return 'Schedule details';
  }
}

String get pickupSectionDescription {
  switch (widget.category) {
    case VehicleCategory.passenger:
      return 'Choose when you would like to be picked up.';

    case VehicleCategory.waterBowser:
      return 'Choose when you would like your water delivered.';

    case VehicleCategory.exhauster:
      return 'Choose when you need your exhauster service.';

    case VehicleCategory.machinery:
      return 'Choose when you need the machinery delivered or made available.';

    default:
      return 'Choose your preferred service date and time.';
  }
}

String get scheduleButtonText {
  switch (widget.category) {
    case VehicleCategory.passenger:
      return 'Confirm Ride Schedule';

    case VehicleCategory.waterBowser:
      return 'Schedule Water Delivery';

    case VehicleCategory.exhauster:
      return 'Schedule Exhauster';

    case VehicleCategory.machinery:
      return 'Schedule Machinery';

    default:
      return 'Confirm Schedule';
  }
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

// Future<void> _scheduleRide() async {
//   if (_selectedDate == null || _selectedTime == null) return;

//   final scheduledDateTime = DateTime(
//     _selectedDate!.year,
//     _selectedDate!.month,
//     _selectedDate!.day,
//     _selectedTime!.hour,
//     _selectedTime!.minute,
//   );

//   // Current time rounded down to the nearest minute
//   final now = DateTime.now();
//   final currentMinute = DateTime(
//     now.year,
//     now.month,
//     now.day,
//     now.hour,
//     now.minute,
//   );

//   // Minimum allowed scheduling time
//   final minimumScheduleTime = currentMinute.add(
//     const Duration(minutes: 30),
//   );

//   debugPrint("Current time: $currentMinute");
//   debugPrint("Minimum allowed: $minimumScheduleTime");
//   debugPrint("Selected time: $scheduledDateTime");

//   if (scheduledDateTime.isBefore(minimumScheduleTime)) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           "Please select a time at least 30 minutes from now.",
//         ),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }

//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(
//       builder: (_) => HomeScreen(
//         pickup: widget.pickupLocation ?? currentLocation,
//         destination: widget.dropLocation,
//         category: VehicleCategory.passenger,
//         isScheduled: true,
//         scheduledDate: scheduledDateTime,
//       ),
//     ),
//   );
// }

Future<void> _scheduleRide() async {
  if (_selectedDate == null || _selectedTime == null) return;

  final scheduledDateTime = DateTime(
    _selectedDate!.year,
    _selectedDate!.month,
    _selectedDate!.day,
    _selectedTime!.hour,
    _selectedTime!.minute,
  );

  final now = DateTime.now();

  final currentMinute = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  );

  final minimumScheduleTime = currentMinute.add(
    const Duration(minutes: 30),
  );

  debugPrint('Current time: $currentMinute');
  debugPrint('Minimum allowed: $minimumScheduleTime');
  debugPrint('Selected time: $scheduledDateTime');

  if (scheduledDateTime.isBefore(minimumScheduleTime)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please select a time at least 30 minutes from now.',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (!mounted) return;

  switch (widget.category) {
    case VehicleCategory.passenger:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            pickup: widget.pickupLocation ?? currentLocation,
            destination: widget.dropLocation,
            category: VehicleCategory.passenger,
            isScheduled: true,
            scheduledDate: scheduledDateTime,
          ),
        ),
      );
      break;

    case VehicleCategory.waterBowser:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaterBowerScreen(
            pickup: widget.pickupLocation ?? currentLocation,
            destination: widget.dropLocation,
            category: VehicleCategory.waterBowser,
            isScheduled: true,
            scheduledDate: scheduledDateTime,
          ),
        ),
      );
      break;

    case VehicleCategory.exhauster:
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HoneySuckerScreen(
            pickup: widget.pickupLocation ?? currentLocation,
            destination: widget.dropLocation,
            category: VehicleCategory.exhauster,
            isScheduled: true,
            scheduledDate: scheduledDateTime,
          ),
        ),
      );
      break;

    case VehicleCategory.machinery:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MachineryScreen(
            pickup: widget.pickupLocation ?? currentLocation,
            destination: widget.dropLocation,
            category: VehicleCategory.machinery,
            isScheduled: true,
            scheduledDate: scheduledDateTime,
          ),
        ),
      );
      break;

    default:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scheduling is not supported for this service.',
          ),
        ),
      );
      break;
  }
}

  @override
Widget build(BuildContext context) {
  final dateText =
      _selectedDate != null
          ? DateFormat('EEE, dd MMM yyyy').format(_selectedDate!)
          : "Select pickup date";

  final timeText =
      _selectedTime != null
          ? _selectedTime!.format(context)
          : "Select pickup time";

  DateTime? scheduledDateTime;

  if (_selectedDate != null && _selectedTime != null) {
    scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),

    appBar: AppBar(
      title: Text(
  'Schedule $serviceName',
  style: GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  ),
),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================================================
            // PREMIUM HEADER
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF015ACE),
                    Color(0xFF003F99),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF015ACE).withOpacity(0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [

                  // Decorative yellow circle
                  Positioned(
                    right: -25,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0D000).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Decorative small circle
                  Positioned(
                    right: 35,
                    bottom: -30,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // Illustration
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 48,
                              color: Colors.white,
                            ),

                            Positioned(
                              right: 10,
                              bottom: 12,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0D000),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Header text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              scheduleTitle,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                             scheduleDescription,// "Book ahead and have your ride ready when you need it.",
                              style: GoogleFonts.nunitoSans(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white.withOpacity(0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================================================
            // SECTION TITLE
            // =========================================================
            Text(
              pickupSectionTitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 5),
Text(
  pickupSectionDescription,
  style: GoogleFonts.nunitoSans(
    fontSize: 14,
    color: Colors.black54,
  ),
),

            const SizedBox(height: 16),

            // =========================================================
            // DATE CARD
            // =========================================================
            _buildPremiumSelectorCard(
              icon: Icons.calendar_today_rounded,
              iconBackground: const Color(0xFFE8F1FF),
              iconColor: const Color(0xFF015ACE),
              accentColor: const Color(0xFF015ACE),
              //title: "Pickup Date",
              value: dateText,
              title: 'Preferred Date',
subtitle: _selectedDate == null
    ? 'When do you need this service?'
    : 'Your selected service date',
              onTap: () => _pickDate(context),
            ),

            const SizedBox(height: 14),

            // =========================================================
            // TIME CARD
            // =========================================================
            _buildPremiumSelectorCard(
              icon: Icons.access_time_rounded,
              iconBackground: const Color(0xFFFFF8D6),
              iconColor: const Color(0xFFD4B600),
              accentColor: const Color(0xFFF0D000),
              //title: "Pickup Time",
              value: timeText,
              title: 'Preferred Date',
subtitle: _selectedDate == null
    ? 'When do you need this service?'
    : 'Your selected service date',
              onTap: () => _pickTime(context),
            ),

            const SizedBox(height: 22),

            // =========================================================
            // SUMMARY
            // =========================================================
            if (scheduledDateTime != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [

                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0D000),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                          'Your $serviceName is scheduled for',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            DateFormat(
                              'EEE, dd MMM • h:mm a',
                            ).format(scheduledDateTime),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // =========================================================
            // CONFIRM BUTTON
            // =========================================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _scheduleRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF015ACE),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_send_rounded,
                      size: 21,
                    ),

                    const SizedBox(width: 10),

                    Text(
                      //"Confirm Schedule",
                      scheduleButtonText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Small reassurance
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "You can review your ride before confirming",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget _buildPremiumSelectorCard({
  required IconData icon,
  required Color iconBackground,
  required Color iconColor,
  required Color accentColor,
  required String title,
  required String value,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [

          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 15),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color:
                        value.startsWith("Select")
                            ? Colors.black38
                            : Colors.black,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          // Arrow
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: iconColor,
              size: 22,
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
