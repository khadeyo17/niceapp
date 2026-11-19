import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/reverse_geocoding_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_in_progress_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';





// class _CircularFillPainter extends CustomPainter {
//   final double progress;

//   _CircularFillPainter({
//     required this.progress,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(
//       size.width / 2,
//       size.height / 2,
//     );

//     final radius = size.width / 2;

//     final paint = Paint()
//       ..color = const Color(0xFFF0D000).withOpacity(0.2055)
//       ..style = PaintingStyle.fill;

//     // Start from the top (-90 degrees)
//     const startAngle = -pi / 2;

//     // Fill progressively around the circle
//     final sweepAngle = 2 * pi * progress;

//     canvas.drawArc(
//       Rect.fromCircle(
//         center: center,
//         radius: radius,
//       ),
//       startAngle,
//       sweepAngle,
//       true,
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(
//     covariant _CircularFillPainter oldDelegate,
//   ) {
//     return oldDelegate.progress != progress;
//   }
// }

class _CircularFillPainter extends CustomPainter {
  final double progress;

  _CircularFillPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 7;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // Background track.
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE8F0FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc.
    final progressPaint = Paint()
      ..color = const Color(0xFFF0D000)//(0xFF015ACE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularFillPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class FindingDriverScreen extends StatefulWidget {
  final Future<void> Function() onCancel;
  final Stream<bool> driverLinkedStream;
  final String? rideId;
  final String? driverId;
  final LatLng? pickup;
  final LatLng? destination;
  final VehicleCategory category;


  const FindingDriverScreen({
    required this.onCancel,
    required this.driverLinkedStream,
    required this.category,
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
  Timer? _messageTimer;
int _searchMessageIndex = 0;
bool _finishingSearch = false;

bool _noDriversAvailable = false;
bool _rideCancelled = false;

final Map<String, DateTime> _lastDriverAttempt = {};

static const Duration _refreshSearchInterval =
    Duration(seconds: 5);
//Timer? _searchProgressTimer;

static const int _searchDurationSeconds = 60;
DateTime? _searchStartedAt;
bool _searchReady = false;
Completer<String>? _activeRequestCompleter;

  late AnimationController _carRotationController;
late AnimationController _panelController;
  late Animation<Offset> _panelOffset;
  LatLng _initialFallback = const LatLng(-1.286389, 36.817223);
  //final StreamController<bool> _driverLinkedController =
   //   StreamController<bool>.broadcast();
StreamSubscription<DatabaseEvent>? _rideSub;
final DatabaseReference _database =
    FirebaseDatabase.instance.ref();

//StreamSubscription<DatabaseEvent>? _rideSub;
//StreamSubscription<DatabaseEvent>? _driverLinkedSub;
StreamSubscription<bool>? _driverLinkedSub;
StreamSubscription<DatabaseEvent>? _requestSub;

static const List<Map<String, String>> categoryImages = [
  {

    'name': 'Passenger',
    'image': 'assets/imgs/taxi.png',
    'route': '/services/transport/ride-booking',
    'dispalyname':'Taxi'
  },
  {
    'name': 'Machinery',
    'image': 'assets/imgs/machineryx.png',
    'route': '/services/transport/machinery',
    'dispalyname':'Machinery'
  },
  {
    'name': 'WaterBowser',
    'image': 'assets/imgs/cleanwater.png',
    'route': '/services/transport/water-bower',
    'dispalyname':'Water Bowser'
  },
  {
    'name': 'Exhauster',
    'image': 'assets/imgs/exhausterx.png',
    'route': '/services/transport/honey-sucker',
     'dispalyname':'Exhauster'
  },
];
Map<String, String> get _selectedCategory {
  return categoryImages.firstWhere(
    (item) =>
        item['name']!.toLowerCase() ==
        widget.category.name.toLowerCase(),
    orElse: () => categoryImages.first,
  );
}

String get _categoryName => _selectedCategory['name']!;
String get _categoryDisplayName => _selectedCategory['dispalyname']!;

String get _categoryImage => _selectedCategory['image']!;
bool _searching = false;
bool _rideAccepted = false;
String? _activeDriverId;

static const double _searchRadiusKm = 10.0;
static const int _requestTimeoutSeconds = 15;


  GoogleMapController? _mapController;
  //List<Map<String, dynamic>> _commonPlaces = [];
  bool isPlacesLoading = false;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> routePoints = [];
  double distanceInKm = 0;
  int durationInMinutes = 0;
  String? newRideId;
  int PassengerCount=0;
  String? PaymentMethod;

  String? pickupAddress;
  String? destinationAddress;

LatLng? _pickupLocation;


bool get _isDestinationOnlyService {
  final category = _categoryName.trim().toLowerCase();

  return category == 'waterbowser' ||
      category == 'exhauster' ||
      category == 'machinery';
}


  // Map<String, String> _getDynamicMessage() {
  //   if (_progress < 0.5) {
  //     return {
  //       "title": "Searching for drivers near you...",
  //       "subtitle": "We’re checking nearby drivers. Please hold on 🚗",
  //     };
  //   } else if (_progress < 0.7) {
  //     return {
  //       "title": "Still looking, expanding search...",
  //       "subtitle": "Hang tight! We're reaching more drivers in your area.",
  //     };
  //   } else if (_progress < 1) {
  //     return {
  //       "title": "Almost there...",
  //       "subtitle": "We’re very close to finding your driver. Stay ready!",
  //     };
  //   } 
  //   else {
  //     return {
  //       "title": "No drivers available",
  //       "subtitle": "Please try again in a moment.",
  //     };
  //   }
  // }

  Map<String, String> _getDynamicMessage() {
  if (_rideAccepted) {
    return {
      'title': 'You’re Connected!',
      'subtitle': 'Your provider has accepted your request.',
    };
  }

  if (_noDriversAvailable) {
    return {
      'title': 'No Providers Available',
      'subtitle':
          'Unfortunately, we could not find an available $_categoryDisplayName. Please try again shortly.',
    };
  }

  if (_rideCancelled) {
    return {
      'title': 'Request Cancelled',
      'subtitle': 'Your request has been cancelled successfully.',
    };
  }

  final stage = _progress < 0.33
      ? 0
      : _progress < 0.70
          ? 1
          : 2;

  switch (_categoryDisplayName.toLowerCase()) {
    case 'taxi':
      return [
        {
          'title': 'Finding Your Taxi',
          'subtitle': 'Searching for available taxi drivers near you.',
        },
        {
          'title': 'Checking Driver Availability',
          'subtitle': 'Finding a driver who can pick you up.',
        },
        {
          'title': 'Connecting You',
          'subtitle': 'We are giving nearby drivers time to accept your ride.',
        },
      ][stage];

    case 'machinery':
      return [
        {
          'title': 'Finding Available Machinery',
          'subtitle': 'Searching for machinery and operators near you.',
        },
        {
          'title': 'Checking Equipment Availability',
          'subtitle': 'Matching your request with available equipment.',
        },
        {
          'title': 'Connecting You',
          'subtitle': 'We are contacting suitable machinery providers.',
        },
      ][stage];

    case 'water bowser':
      return [
        {
          'title': 'Finding a Water Bowser',
          'subtitle': 'Searching for water delivery vehicles near you.',
        },
        {
          'title': 'Checking Water Availability',
          'subtitle': 'Checking nearby water delivery providers.',
        },
        {
          'title': 'Connecting You',
          'subtitle': 'We are contacting available water bowser providers.',
        },
      ][stage];

    case 'exhauster':
      return [
        {
          'title': 'Finding an Exhauster',
          'subtitle': 'Searching for available exhauster services near you.',
        },
        {
          'title': 'Checking Service Availability',
          'subtitle': 'Looking for available exhauster operators.',
        },
        {
          'title': 'Connecting You',
          'subtitle': 'We are contacting nearby exhauster providers.',
        },
      ][stage];

    default:
      return [
        {
          'title': 'Finding Your Service',
          'subtitle': 'Searching for available providers near you.',
        },
        {
          'title': 'Checking Availability',
          'subtitle': 'Checking available providers in your area.',
        },
        {
          'title': 'Connecting You',
          'subtitle': 'We are contacting available providers.',
        },
      ][stage];
  }
}

  // @override
  // void initState() {
  //   super.initState();
  //   // if (widget.rideId != null)

  //   // Slide panel animation
  //   _panelController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 400),
  //   );
  //   _panelOffset = Tween<Offset>(
  //     begin: const Offset(0, 1),
  //     end: Offset.zero,
  //   ).animate(
  //     CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
  //   );


  //   _carRotationController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(seconds: 4),
  //   )..repeat();

  //   widget.driverLinkedStream.listen((isLinked) {
  //     if (isLinked) {
  //       _stopProgress();
  //       _closeScreen();
  //     }
  //   });

  //   _startProgressTimer();
  // }

// @override
// void initState() {
//   super.initState();

//   _panelController = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 400),
//   );

//   _panelOffset = Tween<Offset>(
//     begin: const Offset(0, 1),
//     end: Offset.zero,
//   ).animate(
//     CurvedAnimation(
//       parent: _panelController,
//       curve: Curves.easeOutCubic,
//     ),
//   );

//   _carRotationController = AnimationController(
//     vsync: this,
//     duration: const Duration(seconds: 4),
//   )..repeat();
// _messageTimer = Timer.periodic(
//   const Duration(seconds: 5),
//   (_) {
//     if (!mounted || _rideAccepted || _noDriversAvailable || _rideCancelled) {
//       return;
//     }

//     setState(() {
//       _searchMessageIndex++;
//     });
//   },
// );
//   _driverLinkedSub = widget.driverLinkedStream.listen((isLinked) {
//     if (isLinked && mounted && !_rideAccepted) {
//       _rideAccepted = true;
//       _stopProgress();
//       _goToLiveRide();
//     }
//   });

//   if (widget.pickup != null && widget.destination != null) {
//     _setupMarkers();
//     _fetchAddressesAndRoute();
//     _startRideMatching();
//   } 
//   else {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Pickup and destination are required.'),
//           ),
//         );
//       }
//     });
//   }
// }

// @override
// void initState() {
//   super.initState();

//   // Use the supplied pickup when available.
//   _pickupLocation = widget.pickup;

//   _panelController = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 400),
//   );

//   _panelOffset = Tween<Offset>(
//     begin: const Offset(0, 1),
//     end: Offset.zero,
//   ).animate(
//     CurvedAnimation(
//       parent: _panelController,
//       curve: Curves.easeOutCubic,
//     ),
//   );

//   _carRotationController = AnimationController(
//     vsync: this,
//     duration: const Duration(seconds: 4),
//   )..repeat();

//   // Rotate search messages every five seconds.
//   _messageTimer = Timer.periodic(
//     const Duration(seconds: 5),
//     (_) {
//       if (!mounted ||
//           _rideAccepted ||
//           _noDriversAvailable ||
//           _rideCancelled) {
//         return;
//       }

//       setState(() {
//         _searchMessageIndex =
//             (_searchMessageIndex + 1) % 3;
//       });
//     },
//   );

//   // Listen for driver assignment.
//   _driverLinkedSub = widget.driverLinkedStream.listen(
//     (isLinked) {
//       if (isLinked && mounted && !_rideAccepted) {
//         _rideAccepted = true;
//         _noDriversAvailable = false;

//         _stopProgress();

//         final completer = _activeRequestCompleter;
//         if (completer != null && !completer.isCompleted) {
//           completer.complete('accepted');
//         }

//         setState(() {});
//         _goToLiveRide();
//       }
//     },
//     onError: (error) {
//       debugPrint('Driver linked stream error: $error');
//     },
//   );

//   // Initialize pickup, destination, route and driver matching.
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     _initializeRideSearch();
//   });
// }


@override
void initState() {
  super.initState();

  _pickupLocation = widget.pickup;

  _panelController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  _panelOffset = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    ),
  );

  _carRotationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  // Start the circular and linear progress immediately.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    _startProgressTimer();
    _initializeRideSearch();
  });

  // Rotate search messages every five seconds.
  _messageTimer = Timer.periodic(
    const Duration(seconds: 5),
    (_) {
      if (!mounted ||
          _rideAccepted ||
          _noDriversAvailable ||
          _rideCancelled) {
        return;
      }

      setState(() {
        _searchMessageIndex =
            (_searchMessageIndex + 1) % 3;
      });
    },
  );

  // Listen for driver assignment.
  _driverLinkedSub = widget.driverLinkedStream.listen(
    (isLinked) {
      if (isLinked && mounted && !_rideAccepted) {
        _rideAccepted = true;
        _noDriversAvailable = false;

        _stopProgress();

        final completer = _activeRequestCompleter;

        if (completer != null && !completer.isCompleted) {
          completer.complete('accepted');
        }

        setState(() {});
        _goToLiveRide();
      }
    },
    onError: (error) {
      debugPrint('Driver linked stream error: $error');
    },
  );
}



double _distanceKm(LatLng a, LatLng b) {
  const earthRadius = 6371.0;

  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLng = (b.longitude - a.longitude) * pi / 180;

  final lat1 = a.latitude * pi / 180;
  final lat2 = b.latitude * pi / 180;

  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) *
          cos(lat2) *
          sin(dLng / 2) *
          sin(dLng / 2);

  return earthRadius *
      2 *
      atan2(sqrt(h), sqrt(1 - h));
}

Future<void> _initializeRideSearch() async {
  try {
    if (!mounted) return;

    // Destination is compulsory for every service.
    if (widget.destination == null) {
      throw Exception(
        'Please select your destination to continue.',
      );
    }

    // Destination-only services can automatically use
    // the passenger's current location as their pickup.
    if (_pickupLocation == null) {
      if (!_isDestinationOnlyService) {
        throw Exception(
          'Please select your pickup location.',
        );
      }

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please enable your location services to continue.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission is required to find your pickup location.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Enable it in your phone settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      _pickupLocation = LatLng(
        position.latitude,
        position.longitude,
      );
    }

    if (_pickupLocation == null) {
      throw Exception(
        'Unable to determine your pickup location.',
      );
    }

    if (!mounted) return;

    setState(() {});

    // Initialize map and addresses after pickup is available.
    _setupMarkers();

    await _fetchAddressesAndRoute();

    if (!mounted) return;

    
    
    _searchReady = true;
    await _startRideMatching();
  } catch (e) {
    debugPrint('Ride initialization error: $e');

    if (!mounted) return;
_stopProgress();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        
      ),
    );
  }
}


Future<List<Map<String, dynamic>>> _findNearbyDrivers() async {
  final pickup =_pickupLocation;// widget.pickup;

  if (pickup == null) return [];

  final snapshot = await _database.child('drivers').get();

  if (!snapshot.exists || snapshot.value is! Map) {
    return [];
  }

  final drivers = <Map<String, dynamic>>[];

  final data = Map<dynamic, dynamic>.from(
    snapshot.value as Map,
  );

  data.forEach((key, value) {
    if (value is! Map) return;

    final driver = Map<String, dynamic>.from(value);
    final driverId = key.toString();

    final isOnline = driver['isOnline'] == true;
    final isAvailable = driver['isAvailable'] == true;

    if (!isOnline || !isAvailable) return;

    if (driver['currentRideId'] != null &&
        driver['currentRideId'].toString().isNotEmpty) {
      return;
    }

    final latitude = double.tryParse(
      '${driver['latitude'] ?? ''}',
    );

    final longitude = double.tryParse(
      '${driver['longitude'] ?? ''}',
    );

    if (latitude == null || longitude == null) return;

    final distance = _distanceKm(
      pickup,
      LatLng(latitude, longitude),
    );

    if (distance <= _searchRadiusKm) {
      drivers.add({
        'driverId': driverId,
        'distanceKm': distance,
        'vehicleType': driver['vehicleType'],
      });
    }
  });

  drivers.sort(
    (a, b) => (a['distanceKm'] as double)
        .compareTo(b['distanceKm'] as double),
  );

  return drivers;
}



Future<void> _startRideMatching() async {
  if (_searching || _rideAccepted) return;

  _searching = true;
  _noDriversAvailable = false;
  _rideCancelled = false;
  _finishingSearch = false;
//   //_progress = 0.0;
//   if (_timer == null) {
//   _progress = 0.0;
//   _startProgressTimer();
// }
  _activeDriverId = null;
  _lastDriverAttempt.clear();

  if (mounted) {
    setState(() {});
  }

  try {
    newRideId = widget.rideId ??
        _database.child('rides').push().key;

    if (newRideId == null) {
      throw Exception('Could not create a ride ID.');
    }

    final rideRef = _database.child('rides/$newRideId');
    final passengerId = FirebaseAuth.instance.currentUser?.uid;

    // Validate pickup and destination.
    if (_pickupLocation == null || widget.destination == null) {
      throw Exception('Pickup and destination are required.');
    }

    final existingRide = await rideRef.get();

    if (!mounted) return;

    if (!existingRide.exists) {
      if (passengerId == null) {
        throw Exception('Passenger is not authenticated.');
      }

      await rideRef.set({
        'rideId': newRideId,
        'passengerId': passengerId,
        'status': 'searching',

        // Store the category name rather than the enum/object.
        'category': _categoryName,

        // 'pickup': {
        //   'latitude': widget.pickup!.latitude,
        //   'longitude': widget.pickup!.longitude,
        //   'address': pickupAddress ?? '',
        // },
        'pickup': {
  'latitude': _pickupLocation!.latitude,
  'longitude': _pickupLocation!.longitude,
  'address': pickupAddress ?? '',
},
        'destination': {
          'latitude': widget.destination!.latitude,
          'longitude': widget.destination!.longitude,
          'address': destinationAddress ?? '',
        },
        'createdAt': ServerValue.timestamp,
      });
    }

    // Listen for authoritative ride updates.
    await _rideSub?.cancel();

    _rideSub = rideRef.onValue.listen((event) {
      if (!mounted || !event.snapshot.exists) return;

      final value = event.snapshot.value;
      if (value is! Map) return;

      final ride = Map<dynamic, dynamic>.from(value);

      final status =
          '${ride['status'] ?? ''}'.trim().toLowerCase();

      // DRIVER ACCEPTED
      if (status == 'accepted' ||
          status == 'driver_assigned') {
        final acceptedDriverId =
            ride['driverId']?.toString();

        if (acceptedDriverId != null &&
            acceptedDriverId.isNotEmpty &&
            !_rideAccepted) {
          _rideAccepted = true;
          _noDriversAvailable = false;
          _rideCancelled = false;
          _activeDriverId = acceptedDriverId;

          _stopProgress();

          final completer = _activeRequestCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete('accepted');
          }

          setState(() {});

          _goToLiveRide();
        }
      }

      // BACKEND CONFIRMED NO AVAILABLE DRIVERS
      else if (status == 'no_available_driver' ||
          status == 'no_available_drivers' ||
          status == 'no_driver_available') {
        if (!_noDriversAvailable && !_rideAccepted) {
          _noDriversAvailable = true;
          _searching = false;

          _stopProgress();

          final completer = _activeRequestCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete('expired');
          }

          _requestSub?.cancel();
          _requestSub = null;

          setState(() {});
        }
      }

      // RIDE CANCELLED
      else if (status == 'cancelled') {
        _rideCancelled = true;
        _searching = false;

        _stopProgress();

        final completer = _activeRequestCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete('cancelled');
        }

        _requestSub?.cancel();
        _requestSub = null;

        setState(() {});
      }
    });

    // Start the 90-second progress timer.
    // This controls both the circular and linear indicators.
    //_startProgressTimer();

    // CONTINUOUS DRIVER MATCHING
    while (mounted &&
        !_rideAccepted &&
        !_noDriversAvailable &&
        !_rideCancelled) {
      try {
        final drivers = await _findNearbyDrivers();

        if (!mounted ||
            _rideAccepted ||
            _noDriversAvailable ||
            _rideCancelled) {
          break;
        }

        final now = DateTime.now();

        // Allow drivers to be retried after 30 seconds.
        _lastDriverAttempt.removeWhere(
          (driverId, lastAttempt) =>
              now.difference(lastAttempt).inSeconds >= 30,
        );

        final eligibleDrivers = drivers.where((driver) {
          final driverId = driver['driverId'].toString();

          return !_lastDriverAttempt.containsKey(driverId);
        }).toList();

        for (final driver in eligibleDrivers) {
          if (!mounted ||
              _rideAccepted ||
              _noDriversAvailable ||
              _rideCancelled) {
            break;
          }

          final driverId = driver['driverId'].toString();

          _activeDriverId = driverId;
          _lastDriverAttempt[driverId] = DateTime.now();

          final requestRef = _database.child(
            'rideRequests/$driverId/$newRideId',
          );

          final distanceValue = driver['distanceKm'];

          final distanceKm = distanceValue is num
              ? distanceValue.toDouble()
              : 0.0;

          // Send request and wait for the driver's response.
          await _sendRequestAndWait(
            requestRef: requestRef,
            driverId: driverId,
            distanceKm: distanceKm,
          );

          if (!mounted ||
              _rideAccepted ||
              _noDriversAvailable ||
              _rideCancelled) {
            break;
          }
        }
      } catch (e) {
        debugPrint('Driver search error: $e');
      }

      if (!mounted ||
          _rideAccepted ||
          _noDriversAvailable ||
          _rideCancelled) {
        break;
      }

      // Refresh nearby drivers.
      await Future<void>.delayed(
        _refreshSearchInterval,
      );
    }
  } catch (e) {
    debugPrint('Ride matching initialization error: $e');

    _stopProgress();

    if (mounted && !_rideAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  } finally {
    _searching = false;

    if (mounted) {
      setState(() {});
    }
  }
}



Future<String> _sendRequestAndWait({
  required DatabaseReference requestRef,
  required String driverId,
  required double distanceKm,
}) async {
  // Do not send another request if the ride has already ended.
  if (!mounted ||
      _rideAccepted ||
      _noDriversAvailable ||
      _rideCancelled) {
    return 'cancelled';
  }

  final completer = Completer<String>();

  // Register this completer so the 90-second global timer
  // can interrupt the current driver's pending request.
  _activeRequestCompleter = completer;

  StreamSubscription<DatabaseEvent>? requestSubscription;

  try {
    // Cancel any previous request listener.
    await _requestSub?.cancel();
    _requestSub = null;

    if (!mounted ||
        _rideAccepted ||
        _noDriversAvailable ||
        _rideCancelled) {
      return 'cancelled';
    }

    final passengerId =
        FirebaseAuth.instance.currentUser?.uid;

    if (passengerId == null) {
      throw Exception('Passenger is not authenticated.');
    }

    // Send request to the selected driver.
    await requestRef.set({
      'rideId': newRideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'status': 'pending',
      'distanceToPickupKm': distanceKm,
      // 'pickup': {
      //   'latitude': widget.pickup!.latitude,
      //   'longitude': widget.pickup!.longitude,
      //   'address': pickupAddress ?? '',
      // },
      'pickup': {
  'latitude': _pickupLocation!.latitude,
  'longitude': _pickupLocation!.longitude,
  'address': pickupAddress ?? '',
},
      'destination': {
        'latitude': widget.destination!.latitude,
        'longitude': widget.destination!.longitude,
        'address': destinationAddress ?? '',
      },
      'createdAt': ServerValue.timestamp,
    });

    if (!mounted ||
        _rideAccepted ||
        _noDriversAvailable ||
        _rideCancelled) {
      return 'cancelled';
    }

    // Listen for the driver's response.
    requestSubscription = requestRef.onValue.listen(
      (event) {
        if (!mounted ||
            !event.snapshot.exists ||
            completer.isCompleted) {
          return;
        }

        final value = event.snapshot.value;

        if (value is! Map) return;

        final request =
            Map<dynamic, dynamic>.from(value);

        final status =
            '${request['status'] ?? ''}'
                .trim()
                .toLowerCase();

        debugPrint(
          'Driver $driverId request status: $status',
        );

        switch (status) {
          case 'accepted':
            if (!_rideAccepted) {
              _rideAccepted = true;
              _noDriversAvailable = false;
              _rideCancelled = false;
              _activeDriverId = driverId;

              _stopProgress();

              if (mounted) {
                setState(() {});
              }
            }

            if (!completer.isCompleted) {
              completer.complete('accepted');
            }
            break;

          case 'declined':
          case 'rejected':
          case 'cancelled':
          case 'expired':
            if (!completer.isCompleted) {
              completer.complete(status);
            }
            break;
        }
      },
      onError: (error) {
        debugPrint(
          'Driver request listener error: $error',
        );

        if (!completer.isCompleted) {
          completer.complete('error');
        }
      },
    );

    // Keep a reference for global cancellation.
    _requestSub = requestSubscription;

    // Wait for the driver or the individual request timeout.
    final response = await completer.future.timeout(
      const Duration(seconds: _requestTimeoutSeconds),
      onTimeout: () => 'expired',
    );

    debugPrint(
      'Driver $driverId final response: $response',
    );

    return response;
  } catch (e) {
    debugPrint(
      'Error sending request to driver $driverId: $e',
    );

    return 'error';
  } finally {
    // Cancel only this method's listener.
    await requestSubscription?.cancel();

    // Clear the shared listener only if it is still ours.
    if (identical(_requestSub, requestSubscription)) {
      _requestSub = null;
    }

    // Do not clear a newer request's completer.
    if (identical(_activeRequestCompleter, completer)) {
      _activeRequestCompleter = null;
    }
  }
}



  // void _startProgressTimer() {
  //   const totalDuration = 60;
  //   const interval = 0.1;
  //   final increment = interval / totalDuration;

  //   _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).toInt()), (
  //     timer,
  //   ) {
  //     setState(() {
  //       _progress += increment;
  //       if (_progress >= 1.0) {
  //         _progress = 1.0;
  //         _stopProgress();

  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text("No available driver, please try again later."),
  //               duration: Duration(seconds: 2),
  //             ),
  //           );
  //           Future.delayed(const Duration(seconds: 2), () {
  //             if (mounted) Navigator.pop(context);
  //           });
  //         }
  //       }
  //     });
  //   });
  // }

void _startProgressTimer() {
  _stopProgress();

  _progress = 0.0;

  final startedAt = DateTime.now();

  _timer = Timer.periodic(
    const Duration(milliseconds: 100),
    (timer) {
      if (!mounted ||
          _rideAccepted ||
          _noDriversAvailable ||
          _rideCancelled) {
        timer.cancel();
        _timer = null;
        return;
      }

      final elapsed =
          DateTime.now().difference(startedAt).inMilliseconds;

      final newProgress =
          (elapsed / (_searchDurationSeconds * 1000))
              .clamp(0.0, 1.0);

      setState(() {
        _progress = newProgress;
      });

      if (_progress >= 1.0) {
        timer.cancel();
        _timer = null;
       if(_searchReady){
        _finishNoDriversAvailable();
        }
      }
    },
  );
}

void _stopProgress() {
  _timer?.cancel();
  _timer = null;
}


// Future<void> _finishNoDriversAvailable() async {
//   if (!mounted || _rideAccepted || _noDriversAvailable ||
//       _rideCancelled) {
//     return;
//   }

//   // Stop the matching process immediately.
//   _noDriversAvailable = true;
//   _searching = false;

//   _stopProgress();

//   // Release any request currently waiting for a driver response.
//   if (_activeRequestCompleter != null &&
//       !_activeRequestCompleter!.isCompleted) {
//     _activeRequestCompleter!.complete('expired');
//   }

//   await _requestSub?.cancel();
//   _requestSub = null;

//   // Mark the ride as unavailable only if it has not already
//   // been accepted or cancelled by another process.
//   if (newRideId != null) {
//     try {
//       final rideRef = _database.child('rides/$newRideId');

//       await rideRef.runTransaction((currentData) {
//         if (currentData == null || currentData is! Map) {
//           return Transaction.abort();
//         }

//         final ride = Map<dynamic, dynamic>.from(currentData);
//         final status = '${ride['status'] ?? ''}'.toLowerCase();

//         if (status == 'accepted' ||
//             status == 'driver_assigned' ||
//             status == 'cancelled') {
//           return Transaction.abort();
//         }

//         ride['status'] = 'no_available_drivers';
//         ride['updatedAt'] = ServerValue.timestamp;

//         return Transaction.success(ride);
//       });
//     } catch (e) {
//       debugPrint('Could not update unavailable ride status: $e');
//     }
//   }

//   if (!mounted) return;

//   setState(() {
//     _progress = 1.0;
//   });

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       behavior: SnackBarBehavior.floating,
//       backgroundColor: const Color(0xFF172B4D),
//       duration: const Duration(seconds: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       content: Text(
//         'No available $_categoryName found. Please try again shortly.',
//         style: GoogleFonts.nunitoSans(
//           color: Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     ),
//   );
// }


Future<void> _finishNoDriversAvailable() async {
  if (!mounted ||
      _rideAccepted ||
      _noDriversAvailable ||
      _rideCancelled ||
      _finishingSearch) {
    return;
  }

  _finishingSearch = true;
  _searching = false;

  _stopProgress();

  // Release any driver request currently waiting for a response.
  final completer = _activeRequestCompleter;

  if (completer != null && !completer.isCompleted) {
    completer.complete('expired');
  }

  await _requestSub?.cancel();
  _requestSub = null;

  bool markedUnavailable = false;

  try {
    if (newRideId != null) {
      final rideRef = _database.child('rides/$newRideId');

      final result = await rideRef.runTransaction(
        (currentData) {
          if (currentData == null || currentData is! Map) {
            return Transaction.abort();
          }

          final ride =
              Map<dynamic, dynamic>.from(currentData);

          final status =
              '${ride['status'] ?? ''}'.trim().toLowerCase();

          // Never overwrite an accepted or cancelled ride.
          if (status == 'accepted' ||
              status == 'driver_assigned' ||
              status == 'cancelled' ||
              status == 'no_available_driver' ||
              status == 'no_available_drivers' ||
              status == 'no_driver_available') {
            return Transaction.abort();
          }

          ride['status'] = 'no_available_drivers';
          ride['updatedAt'] = ServerValue.timestamp;

          return Transaction.success(ride);
        },
      );

      markedUnavailable = result.committed;

      // If the transaction did not commit, check the latest
      // backend status in case a driver accepted at the same time.
      if (!markedUnavailable) {
        final snapshot = await rideRef.get();

        if (snapshot.value is Map) {
          final ride = Map<dynamic, dynamic>.from(
            snapshot.value as Map,
          );

          final status =
              '${ride['status'] ?? ''}'.trim().toLowerCase();

          if (status == 'accepted' ||
              status == 'driver_assigned') {
            final driverId = ride['driverId']?.toString();

            if (driverId != null && driverId.isNotEmpty) {
              _rideAccepted = true;
              _activeDriverId = driverId;
              _noDriversAvailable = false;

              if (mounted) {
                setState(() {});
                _goToLiveRide();
              }

              return;
            }
          }

          if (status == 'cancelled') {
            _rideCancelled = true;
            _noDriversAvailable = false;

            if (mounted) {
              setState(() {});
            }

            return;
          }

          // Backend has already declared no availability.
          if (status == 'no_available_driver' ||
              status == 'no_available_drivers' ||
              status == 'no_driver_available') {
            markedUnavailable = true;
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Could not update ride search status: $e');
  }

  if (!mounted) return;

  if (markedUnavailable) {
    setState(() {
      _noDriversAvailable = true;
      _searching = false;
      _progress = 1.0;
    });

   ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'We couldn’t find an available driver nearby just now. Please try again in a moment.',
            style: TextStyle(
              fontFamily: 'Nunito Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: const Color(0xFF015ACE),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    duration: const Duration(seconds: 4),
    elevation: 4,
  ),
);
  } else {
    // Avoid showing "No drivers available" if the backend
    // could not confirm that status.
    setState(() {
      _searching = false;
    });
  }
}

  
  // void _stopProgress() {
  //   _timer?.cancel();
  //   _timer = null;
  // }
  
// void _startSearchProgress() {
//   _searchProgressTimer?.cancel();

//   _progress = 0;
//   _searchStartedAt = DateTime.now();

//   _searchProgressTimer = Timer.periodic(
//     const Duration(milliseconds: 100),
//     (timer) {
//       if (!mounted ||
//           _rideAccepted ||
//           _noDriversAvailable ||
//           _rideCancelled) {
//         timer.cancel();
//         return;
//       }

//       final elapsed = DateTime.now()
//           .difference(_searchStartedAt!)
//           .inMilliseconds;

//       final progress = (elapsed /
//               (_searchDurationSeconds * 1000))
//           .clamp(0.0, 1.0);

//       setState(() {
//         _progress = progress;
//       });

//       if (progress >= 1.0) {
//         timer.cancel();
//         _searchProgressTimer = null;
//         _finishNoDriversAvailable();
//       }
//     },
//   );
// }
  void _setupMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation!,

        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination!,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

//google
  Future<void> _fetchAddressesAndRoute() async {
    // Fetch human-readable names for pickup & destination
    final pickupName = await ReverseGeocodingService.getNameFromLatLng(
      _pickupLocation!,
    );
    final destinationName = await ReverseGeocodingService.getNameFromLatLng(
      widget.destination!,
    );

    if (!mounted) return;

    setState(() {
      pickupAddress = pickupName;
      destinationAddress = destinationName;
    });

    await _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final origin = '${widget.pickup?.latitude},${widget.pickup?.longitude}';
    final destination =
        '${widget.destination?.latitude},${widget.destination?.longitude}';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$mapKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final overviewPolyline = route['overview_polyline']['points'];
        final points = _decodePolyline(overviewPolyline);

        setState(() {
          routePoints = points;
          distanceInKm = leg['distance']['value'] / 1000;
          durationInMinutes = (leg['duration']['value'] / 60).round();
          polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF015ACE),
              width: 5,
              points: routePoints,
            ),
          };
        });

        // Move camera to bounds
        if (_mapController != null) {
          _moveCameraToBounds(widget.pickup, widget.destination);
        }
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
void _moveCameraToBounds(LatLng? pos1, LatLng? pos2) {
  if (pos1 == null || pos2 == null || _mapController == null) {
    return;
  }

  final southWest = LatLng(
    min(pos1.latitude, pos2.latitude),
    min(pos1.longitude, pos2.longitude),
  );

  final northEast = LatLng(
    max(pos1.latitude, pos2.latitude),
    max(pos1.longitude, pos2.longitude),
  );

  final bounds = LatLngBounds(
    southwest: southWest,
    northeast: northEast,
  );

  _mapController!.animateCamera(
    CameraUpdate.newLatLngBounds(
      bounds,
      50,
    ),
  );
}

  Future<void> _handleCancel() async {
    _stopProgress();
    await widget.onCancel();
    Navigator.pop(context);
  }

  void _closeScreen() {
    Navigator.pop(context);
  }


  

  // void _goToLiveRide() {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (_) => RideInProgressLiveScreen(
  //             rideId: widget.rideId.toString(),
  //             driverId: widget.driverId,
  //             pickup: widget.pickup,
  //             destination: widget.destination,
  //             //baseFare: 100, // optional (or pass dynamically)
  //             //perKmFare: 50, // optional
  //           ),
  //     ),
  //   );
  // }

  void _goToLiveRide() {
  if (!mounted) return;

  final resolvedRideId = newRideId ?? widget.rideId;
  final resolvedDriverId = _activeDriverId ?? widget.driverId;

  if (resolvedRideId == null || resolvedDriverId == null) {
    return;
  }

  _stopProgress();

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => RideInProgressLiveScreen(
        rideId: resolvedRideId,
        driverId: resolvedDriverId,
        pickup: _pickupLocation!,
        destination: widget.destination,
      ),
    ),
  );
}

  // @override
  // void dispose() {
  //   _stopProgress();
  //   _carRotationController.dispose();
  //   super.dispose();
  // }

//   @override
// void dispose() {
//   _stopProgress();

//   _rideSub?.cancel();
//   _requestSub?.cancel();
//   _driverLinkedSub?.cancel();
//   _carRotationController.dispose();
//   _messageTimer?.cancel();
//   _panelController.dispose();
//   super.dispose();
// }

@override
void dispose() {
  _messageTimer?.cancel();
  _messageTimer = null;

  _stopProgress();

  final completer = _activeRequestCompleter;

  if (completer != null && !completer.isCompleted) {
    completer.complete('cancelled');
  }

  _rideSub?.cancel();
  _requestSub?.cancel();
  _driverLinkedSub?.cancel();

  _carRotationController.dispose();
  _panelController.dispose();

  super.dispose();
}

// Widget _buildCircularProgressWithCar() {
//   final message = _getDynamicMessage();

//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       SizedBox(
//         width: 150,
//         height: 150,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [

//             AnimatedBuilder(
//   animation: _carRotationController,
//   builder: (context, child) {
//     return CustomPaint(
//       size: const Size(90, 90),
//       painter: _CircularFillPainter(
//         progress: _carRotationController.value,
//       ),
//     );
//   },
// ),
//             Container(
//               width: 56,
//               height: 56,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Color(0xFF015ACE),
//               ),
//               alignment: Alignment.center,
//               child: const Icon(
//                 Icons.directions_car,
//                 size: 26,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),


//       Text(
//         message["title"]!,
//         style: const TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.black87,
//         ),
//         textAlign: TextAlign.center,
//       ),

//       const SizedBox(height: 8),
//       Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Text(
//           message["subtitle"]!,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Colors.black54,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     ],
//   );
// }
Widget _buildCircularProgressWithCar() {
  final message = _getDynamicMessage();

  final isSearching = !_rideAccepted &&
      !_noDriversAvailable &&
      !_rideCancelled;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _carRotationController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(150, 150),
                  painter: _CircularFillPainter(
                    progress: _progress,
                  ),
                );
              },
            ),

            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF015ACE),
              ),
              child: Icon(
                _rideAccepted
                    ? Icons.check_rounded
                    : _noDriversAvailable
                        ? Icons.search_off_rounded
                        : _rideCancelled
                            ? Icons.close_rounded
                            : Icons.directions_car_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(message['title']),
          children: [
            Text(
              message['title']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                message['subtitle']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 22),

      // Matching linear progress.
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 7,
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: const Color(0xFFE8F0FC),
            valueColor: AlwaysStoppedAnimation<Color>(
              _noDriversAvailable
                  ? const Color(0xFF7B8BA5)
                  : const Color(0xFFF0D000),//(0xFF015ACE),
            ),
          ),
        ),
      ),

      const SizedBox(height: 9),

      Text(
        isSearching
            ? '${(_progress * 100).round()}% • Finding your provider'
            : _noDriversAvailable
                ? 'Search completed'
                : _rideAccepted
                    ? 'Request accepted'
                    : 'Request cancelled',
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
        ),
      ),
    ],
  );
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
  target: _pickupLocation ?? widget.destination ?? _initialFallback,
  zoom: 12,
),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCameraToBounds(widget.pickup, widget.destination);
              Future.delayed(const Duration(milliseconds: 300), () {
                _panelController.forward();
              });
            },
          ),
         
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _panelOffset,
              builder: (context, child) {
                return AnimatedSlide(
                  offset: _panelOffset.value,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: child,
                );
              },
              child: _buildBottomPanel(),
            ),
          ),
        ],
      ),
    );
   }

//    Widget _buildBottomPanel() {
//   return Container(
//     width: double.infinity,
//     padding: const EdgeInsets.fromLTRB(
//       20,
//       16,
//       20,
//       20,
//     ),
//     decoration: const BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.vertical(
//         top: Radius.circular(24),
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black12,
//           blurRadius: 15,
//           offset: Offset(0, -4),
//         ),
//       ],
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Center(
//           child: Container(
//             width: 45,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),

//         // Selected category and vehicle.
//         _buildCategoryCard(),

//         const SizedBox(height: 20),

//         // Continuous searching animation and category message.
//         _buildCircularProgressWithCar(),

//         const SizedBox(height: 20),

//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _handleCancel,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF015ACE),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(
//                 vertical: 16,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               elevation: 4,
//             ),
//             child: Text(
//               'Cancel Ride',
//               style: GoogleFonts.nunitoSans(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

Widget _buildBottomPanel() {
  return SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle.
            Container(
              width: 45,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Selected category and vehicle image.
            _buildCategoryCard(),

            const SizedBox(height: 24),

            // Animated search indicator and changing messages.
            _buildCircularProgressWithCar(),

            const SizedBox(height: 24),

            // Cancel button.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF015ACE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Cancel Ride',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  
//    Widget _buildBottomPanel() {
//    return Container(
//     width: double.infinity,
//     padding: const EdgeInsets.fromLTRB(
//       20,
//       16,
//       20,
//       20,
//     ),
//     decoration: const BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.vertical(
//         top: Radius.circular(24),
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black12,
//           blurRadius: 15,
//           offset: Offset(0, -4),
//         ),
//       ],
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [


//         Center(
//           child: Container(
//             width: 45,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),

//         _buildCircularProgressWithCar(),


//         const SizedBox(height: 15),

//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _handleCancel,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF015ACE),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(
//                 vertical: 16,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               elevation: 4,
//             ),
//             child: Text(
//               "Cancel Ride",
//               style: GoogleFonts.nunitoSans(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );

  
// }
Widget _buildCategoryCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFE0EAFA),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _categoryDisplayName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF015ACE),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your selected service',
                style: GoogleFonts.nunitoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Finding an available $_categoryDisplayName near you',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Image.asset(
          _categoryImage,
          width: 105,
          height: 65,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.directions_car,
            size: 42,
            color: Color(0xFF015ACE),
          ),
        ),
      ],
    ),
  );
} 
  // @override
  // Widget build(BuildContext context) {
  //   return WillPopScope(
  //     onWillPop: () async => false,
  //     child: Scaffold(
  //       backgroundColor: Colors.white,
  //       body: SafeArea(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             _buildCircularProgressWithCar(),
  //             _buildLinearProgress(),
  //             const SizedBox(height: 40),
  //             _buildBottomCarSection(),
  //             const SizedBox(height: 40),
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 0),
  //               child: SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   onPressed: _handleCancel,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.blue,
  //                     padding: const EdgeInsets.symmetric(vertical: 16),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(30),
  //                     ),
  //                     shadowColor: Colors.black26,
  //                     elevation: 6,
  //                   ),
  //                   child: const Text(
  //                     "Cancel Ride",
  //                     style: TextStyle(fontSize: 18, color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 40),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
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




// Future<void> _startRideMatching() async {
//   if (_searching || _rideAccepted) return;

//   _searching = true;
//   _startProgressTimer();

//   try {
//     // Reuse the existing ride ID or create one.
//     newRideId = widget.rideId ??
//         _database.child('rides').push().key;

//     if (newRideId == null) {
//       throw Exception('Could not create a ride ID.');
//     }

//     final rideRef = _database.child('rides/$newRideId');
//     final passengerId = FirebaseAuth.instance.currentUser?.uid;

//     // Create the ride record only if this is a new ride.
//     final existingRide = await rideRef.get();

//     if (!existingRide.exists) {
//       if (passengerId == null) {
//         throw Exception('Passenger is not authenticated.');
//       }

//       await rideRef.set({
//         'rideId': newRideId,
//         'passengerId': passengerId,
//         'status': 'searching',
//         'pickup': {
//           'latitude': widget.pickup!.latitude,
//           'longitude': widget.pickup!.longitude,
//           'address': pickupAddress ?? '',
//         },
//         'destination': {
//           'latitude': widget.destination!.latitude,
//           'longitude': widget.destination!.longitude,
//           'address': destinationAddress ?? '',
//         },
//         'createdAt': ServerValue.timestamp,
//       });
//     }

//     // Listen for acceptance or cancellation.
//     _rideSub?.cancel();

//     _rideSub = rideRef.onValue.listen((event) {
//       if (!mounted || !event.snapshot.exists) return;

//       final value = event.snapshot.value;

//       if (value is! Map) return;

//       final ride = Map<dynamic, dynamic>.from(value);
//       final status = '${ride['status'] ?? ''}'.toLowerCase();

//       if (status == 'accepted' || status == 'driver_assigned') {
//         final acceptedDriverId = ride['driverId']?.toString();

//         if (acceptedDriverId != null &&
//             acceptedDriverId.isNotEmpty &&
//             !_rideAccepted) {
//           _rideAccepted = true;
//           _activeDriverId = acceptedDriverId;
//           _stopProgress();

//           if (mounted) {
//             _goToLiveRide();
//           }
//         }
//       } else if (status == 'cancelled' && mounted) {
//         _stopProgress();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('This ride was cancelled.')),
//         );
//       }
//     });

//     final drivers = await _findNearbyDrivers();

//     if (drivers.isEmpty) {
//       throw Exception('No available drivers found nearby.');
//     }

//     for (final driver in drivers) {
//       if (!mounted || _rideAccepted) return;

//       // Avoid waiting indefinitely for the entire driver list.
//       if (_progress >= 1.0) break;

//       final driverId = driver['driverId'] as String;
//       _activeDriverId = driverId;

//       final requestRef = _database.child(
//         'rideRequests/$driverId/$newRideId',
//       );

//       final response = await _sendRequestAndWait(
//         requestRef: requestRef,
//         driverId: driverId,
//         distanceKm: driver['distanceKm'] as double,
//       );

//       if (_rideAccepted || !mounted) return;

//       if (response == 'accepted') {
//         // The ride listener handles navigation after the
//         // authoritative ride record identifies the driver.
//         await Future<void>.delayed(
//           const Duration(milliseconds: 500),
//         );

//         if (_rideAccepted) return;
//       }
//     }

//     if (!_rideAccepted && mounted) {
//       throw Exception('No driver accepted your ride. Please try again.');
//     }
//   } catch (e) {
//     if (mounted && !_rideAccepted) {
//       _stopProgress();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             e.toString().replaceFirst('Exception: ', ''),
//           ),
//         ),
//       );

//       await Future<void>.delayed(
//         const Duration(seconds: 2),
//       );

//       if (mounted) Navigator.of(context).pop();
//     }
//   } finally {
//     _searching = false;
//   }
// }