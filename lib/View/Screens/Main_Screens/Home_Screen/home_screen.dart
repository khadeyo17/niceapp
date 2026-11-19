import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/Services/location_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/confirm_ride_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';
import 'package:niceapp/View/Screens/Other_Screens/visa_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_estimate_model.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart';
import 'package:niceapp/View/Screens/Vehicles/fare_service.dart' as FareService;
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_service.dart';
import 'package:niceapp/View/Screens/Vehicles/vehicle_subcategory.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // as gmaps;

class HomeScreen extends ConsumerStatefulWidget {
  final LatLng? pickup;
  final LatLng? destination;
  final List<Map<String, dynamic>>? stops;
  final VehicleCategory category;
  final DateTime? scheduledDate;
  final bool? isScheduled;

  const HomeScreen({
    super.key,
    this.pickup,
    this.destination,
    this.stops,
    required this.category,
    this.scheduledDate,
    this.isScheduled,
    //this.stops
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //final vehicleCategories = ["Sedan", "SUV", "Van", "Bike"];
  Set<Marker> _markers = {};
  List<VehicleSubCategory> vehicleCategories = [];
  List<FareEstimate?> fareEstimates = [];
  bool isLoadingCategories = true;
  int selectedIndex = -1;
  LatLng? currentLocation;
  String? pickupAddress;
  String? destinationAddress;
  //LatLng? pickup;
  List<LatLng> routePoints = [];
  double? routeDistance;
  double durationInMinutes = 0;
  bool isSwiped = false;
  LatLng _initialFallback = const LatLng(-1.286389, 36.817223);
  //GoogleMapController? mapController;
  //late ScrollController _scrollController;
  GoogleMapController? _mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  double _mapOffsetY = 0;
  String? selectedPayment="Cash";
  double appBalance = 0.0;
  bool isWalletLoading = true;

  final double maxUpOffset = -150; // adjust as needed
  late ScrollController _scrollController = ScrollController();
  List<bool> driverAvailability = [];
  bool isMonthFilterApplied = false;
  final LocationService _locationService = LocationService();
  // final formatCurrency = NumberFormat.simpleCurrency(
  //   locale: Localizations.localeOf(context).toString(),
  // );

  List<Map<String, dynamic>> stops = [];

  @override
  void initState() {
    super.initState();
    //_getCurrentLocation();
    //_setCurrentLocation();
     _loadWalletBalance();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      canStartRide(userId).then((allowed) {
        if (!allowed) {
          _listenToActiveRide(userId);
        }
      });
    }
    ////working
    // if (widget.destination != null) {
    //   fetchVehicleSubCategoriesByType(widget.category.index).then((
    //     categories,
    //   ) async {
    //     setState(() {
    //       vehicleCategories = categories;
    //       fareEstimates = List<FareEstimate?>.filled(categories.length, null);
    //       isLoadingCategories = false;

    //       if (categories.isNotEmpty) {
    //         selectedIndex = 0;
    //         ref.read(selectedCategoryProvider.notifier).state = categories[0];
    //       }
    //     });
    //     if (widget.pickup != null && widget.destination != null) {
    //       await _fetchRoute();
    //       //for (int i = 0; i < categories.length; i++) {
    //       // final category = categories[i];
    //       // try {
    //       //   final estimate = await FareService.getFareEstimate(
    //       //     categoryId: category.id,
    //       //     pickupLat: widget.pickup!.latitude,
    //       //     pickupLng: widget.pickup!.longitude,
    //       //     destLat: widget.destination!.latitude,
    //       //     destLng: widget.destination!.longitude,
    //       //     distanceKm: ,
    //       //     countryCode: "KE",
    //       //   );
    //       //   print('Received estimate for ${category.name}: $estimate');
    //       //   setState(() {
    //       //     fareEstimates[i] = estimate;
    //       //   });
    //       // } catch (e) {
    //       //   print('Failed to load fare for category ${category.name}: $e');
    //       // }
    //       // }
    //     }
    //   });
    //   _setupMarkers();
    //_fetchRoute();

    if (widget.stops != null) {
      stops = widget.stops ?? [];
    }

    if (widget.destination != null) {
      fetchVehicleSubCategoriesByType(widget.category.index).then((
        categories,
      ) async {
        // Extract availability info directly from backend
        List<bool> availabilityList =
            categories.map((category) => category.isAvailable).toList();

        setState(() {
          vehicleCategories = categories;
          fareEstimates = List<FareEstimate?>.filled(categories.length, null);
          isLoadingCategories = false;
          driverAvailability = availabilityList;

          if (categories.isNotEmpty) {
            selectedIndex = 0;
            ref.read(selectedCategoryProvider.notifier).state = categories[0];
          }
        });

        if (widget.pickup != null && widget.destination != null) {
          await _fetchRoute();
        }
      });

      _setupMarkers();
    }

    // _scrollController = ScrollController();

    // Add scroll listener to update map camera when the sheet scrolls

    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      // Map moves up as offset grows, but clamp so it never moves beyond maxUpOffset
      final newMapOffset = (-offset).clamp(maxUpOffset, 0).toDouble();

      setState(() {
        _mapOffsetY = newMapOffset;
      });
    });

    
    // canStartRide();
    // _scrollController.addListener(() {
    //   if (widget.pickup != null && widget.destination != null) {
    //     _moveCameraToBounds(context, widget.pickup!, widget.destination!);
    //   } else if (widget.pickup != null) {
    //     _mapController?.animateCamera(
    //       CameraUpdate.newLatLngZoom(widget.pickup!, 14),
    //     );
    //   }
    // });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Optional post-frame logic
    // });
  }
void _showFareUnavailable() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -----------------------------------------
              // Icon
              // -----------------------------------------
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 32,
                  color: Color(0xFFF0D000),
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------
              // Title
              // -----------------------------------------
              Text(
                'Fare Unavailable',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              // -----------------------------------------
              // Description
              // -----------------------------------------
              Text(
                'We couldn’t calculate a fare for this trip. '
                'Please check your pickup and destination, '
                'then try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // -----------------------------------------
              // Button
              // -----------------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015ACE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



void _showStillInsufficientAMiNiBalance(
  double fare,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 30,
                  color: Color(0xFFF0D000),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Wallet Balance Still Low',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your wallet balance is still below the '
                'fare required for this ride.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Available: KES ${appBalance.toStringAsFixed(2)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Required: KES ${fare.toStringAsFixed(2)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015ACE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Use Cash',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



 Future<void> _loadWalletBalance() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('Wallet: Firebase user is null.');

      if (!mounted) return;

      setState(() {
        appBalance = 0.0;
        isWalletLoading = false;
      });

      return;
    }

    debugPrint('Wallet User ID: ${user.uid}');

    // Get Firebase authentication token
    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      debugPrint('Wallet: Firebase token is null or empty.');

      if (!mounted) return;

      setState(() {
        appBalance = 0.0;
        isWalletLoading = false;
      });

      return;
    }

    debugPrint('Wallet: Firebase token obtained.');

    // New API returns wallet balance + latest 5 transactions
    final url = Uri.parse(
      '${'$baseUrl'}/wallet/transactions',
    );

    debugPrint('Wallet Transactions URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint(
      'Wallet API Status: ${response.statusCode}',
    );

    debugPrint(
      'Wallet API Response: ${response.body}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // New API property is walletBalance
      final balanceValue = data['walletBalance'];

      final double balance;

      if (balanceValue is num) {
        balance = balanceValue.toDouble();
      } else {
        balance =
            double.tryParse(
              balanceValue?.toString() ?? '0',
            ) ??
            0.0;
      }

      debugPrint(
        'AMiNi Balance: KES ${balance.toStringAsFixed(2)}',
      );

      if (!mounted) return;

      setState(() {
        appBalance = balance;
        isWalletLoading = false;
      });
    } else {
      debugPrint(
        'Wallet API failed with status '
        '${response.statusCode}: ${response.body}',
      );

      if (!mounted) return;

      setState(() {
        appBalance = 0.0;
        isWalletLoading = false;
      });
    }
  } catch (e, stackTrace) {
    debugPrint(
      'Wallet balance error: $e',
    );

    debugPrint(
      stackTrace.toString(),
    );

    if (!mounted) return;

    setState(() {
      appBalance = 0.0;
      isWalletLoading = false;
    });
  }
}



Future<bool?> _showInsufficientAMiNiBalance(
  double fare,
) async {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -----------------------------------------
              // Wallet Icon
              // -----------------------------------------
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 32,
                  color: Color(0xFFF0D000),
                ),
              ),

              const SizedBox(height: 18),

              // -----------------------------------------
              // Title
              // -----------------------------------------
              Text(
                'Insufficient AMiNi Balance',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              // -----------------------------------------
              // Description
              // -----------------------------------------
              Text(
                'Your AMiNi wallet does not have enough '
                'funds to pay for this ride.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------------------
              // Balance information
              // -----------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _walletAmountRow(
                      label: 'Available balance',
                      amount:
                          'KES ${appBalance.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 10),

                    _walletAmountRow(
                      label: 'Ride fare',
                      amount:
                          'KES ${fare.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 10),

                    Divider(
                      color: Colors.grey.shade300,
                      height: 1,
                    ),

                    const SizedBox(height: 10),

                    _walletAmountRow(
                      label: 'Amount needed',
                      amount:
                          'KES ${(fare - appBalance).toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------------------
              // Add Funds
              // -----------------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Add Funds',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015ACE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // -----------------------------------------
              // Cancel
              // -----------------------------------------
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text(
                    'Use Cash Instead',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


 
  Future<bool> checkDriverAvailability(int categoryId) async {
    final uri = Uri.parse(
      '$baseUrl/drivers/availability?categoryId=$categoryId',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] ?? false;
    } else {
      return false;
    }
  }

  bool _isRideScreenOpen = false;

  // void _listenToActiveRide(String userId) {
  //   final ridesRef = FirebaseDatabase.instance.ref("rides");

  //   ridesRef.orderByChild("riderId").equalTo(userId).onValue.listen((event) {
  //     if (!event.snapshot.exists) return;

  //     final rides = Map<String, dynamic>.from(
  //       event.snapshot.value as Map<dynamic, dynamic>,
  //     );

  //     // Find all active rides
  //     final activeRides =
  //         rides.entries.where((entry) {
  //           final status = entry.value['status']?.toString();
  //           return status == 'assigned' || status == 'in-progress';
  //         }).toList();

  //     if (activeRides.isEmpty) {
  //       // 🚪 No active rides → close if screen open
  //       if (_isRideScreenOpen) {
  //         Navigator.of(context).pop();
  //         _isRideScreenOpen = false;
  //       }
  //       return;
  //     }

  //     // 🚀 Always take the last active ride
  //     final activeRide = activeRides.last;
  //     final rideData = Map<String, dynamic>.from(activeRide.value);
  //     final rideId = rideData['rideId'] ?? activeRide.key;

  //     if (!_isRideScreenOpen) {
  //       _isRideScreenOpen = true;

  //       Navigator.of(context)
  //           .push(
  //             MaterialPageRoute(
  //               builder: (_) => RideInProgressLiveScreen(rideId: rideId),
  //             ),
  //           )
  //           .then((_) {
  //             // Reset when screen is popped
  //             _isRideScreenOpen = false;
  //           });
  //     }
  //   });
  // }
  bool _hasActiveRide = false;

  void _listenToActiveRide(String userId) {
    final ridesRef = FirebaseDatabase.instance.ref("rides");

    ridesRef.orderByChild("riderId").equalTo(userId).onValue.listen((event) {
      if (!event.snapshot.exists) {
        _hasActiveRide = false;
        return;
      }

      final rides = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      // Find all active rides
      final activeRides =
          rides.entries.where((entry) {
            final status = entry.value['status']?.toString();
            return status == 'assigned' || status == 'in-progress';
          }).toList();

      if (activeRides.isEmpty) {
        // ✅ No active rides
        _hasActiveRide = false;
        return;
      }

      // ✅ At least one active ride → block new booking
      _hasActiveRide = true;
    });
  }

  Future<bool> canStartRide(String userId) async {
    final snap =
        await FirebaseDatabase.instance
            .ref("rides")
            .orderByChild("riderId")
            .equalTo(userId)
            .get();

    if (snap.exists) {
      final rides = snap.value as Map;
      return !rides.values.any(
        (ride) =>
            ride['status'] == 'assigned' || ride['status'] == 'in-progress',
      );
    }
    return true; // no rides → allow
  }

  // Future<bool> driverHasActiveRide(String driverId) async {
  //   final snap =
  //       await passengerDb
  //           .ref("rides")
  //           .orderByChild("driverId")
  //           .equalTo(driverId)
  //           .get();

  //   if (!snap.exists) return false;

  //   final rides = (snap.value as Map).values;
  //   return rides.any(
  //     (ride) => ride['status'] == 'assigned' || ride['status'] == 'in-progress',
  //   );
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // void _setupMarkers() {
  //   markers = {
  //     Marker(
  //       markerId: const MarkerId('pickup'),
  //       position: widget.pickup!,
  //       infoWindow: const InfoWindow(title: 'Pickup'),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  //     ),
  //     Marker(
  //       markerId: const MarkerId('destination'),
  //       position: widget.destination!,
  //       infoWindow: const InfoWindow(title: 'Destination'),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  //     ),
  //   };
  // }

  void _setupMarkers() {
    final newMarkers = <Marker>{};

    // Pickup Marker
    if (widget.pickup != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickup!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Destination Marker
    if (widget.destination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Intermediate Stops (only those in widget.stops)
    // stops = widget.stops ?? [];
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final LatLng stopLatLng = stop['latLng'] as LatLng;

      newMarkers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: stopLatLng,
          infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    setState(() {
      markers = newMarkers;
    });
  }

//google
  // Future<String> _getPlaceName(LatLng position) async {
  //   final apiKey = mapKey; // Google API key
  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey',
  //   );

  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     if (data['status'] == 'OK' && data['results'].isNotEmpty) {
  //       return data['results'][0]['formatted_address'];
  //     }
  //   }
  //   return "Unknown location";
  // }

  
// Future<String> _getPlaceName(LatLng position) async {
//   try {
//     // 1. Try to identify the nearest named place.
//     final nearbyPlace = await _findNearestPlace(position);

//     if (nearbyPlace != null) {
//       final name =
//           nearbyPlace['displayName']?['text']?.toString() ?? '';

//       final formattedAddress =
//           nearbyPlace['formattedAddress']?.toString() ?? '';

//       if (name.isNotEmpty) {
//         if (formattedAddress.isNotEmpty &&
//             !formattedAddress.toLowerCase().contains(
//               name.toLowerCase(),
//             )) {
//           return '$name, $formattedAddress';
//         }

//         return name;
//       }
//     }

//     // 2. Fall back to reverse geocoding.
//     final address = await _getReadableAddress(position);

//     if (address != null && address.isNotEmpty) {
//       return address;
//     }

//     // 3. Final fallback.
//     return 'Unknown location';
//   } catch (e, stackTrace) {
//     debugPrint('Error getting place name: $e');
//     debugPrintStack(stackTrace: stackTrace);

//     return 'Unknown location';
//   }
// }

Future<String> _getPlaceName(LatLng position) async {
  return await _locationService.getPlaceName(position);
}
  //mbox
//   Future<String> _getPlaceName(LatLng position) async {
//   final url = Uri.parse(
//     'https://api.mapbox.com/geocoding/v5/mapbox.places/'
//     '${position.longitude},${position.latitude}.json'
//     '?access_token=$mapboxAccessToken',
//   );

//   final response = await http.get(url);

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);

//     if (data["features"] != null && data["features"].isNotEmpty) {
//       return data["features"][0]["place_name"];
//     }
//   }

//   return "Unknown location";
// }
//google
  // Future<void> _fetchRoute() async {
  //   final origin = '${widget.pickup!.latitude},${widget.pickup!.longitude}';
  //   final destination =
  //       '${widget.destination!.latitude},${widget.destination!.longitude}';
  //   final apiKey = mapKey;

  //   // Build waypoints string if there are stops
  //   String waypoints = '';
  //   if (stops.isNotEmpty) {
  //     waypoints = stops
  //         .map(
  //           (s) =>
  //               '${(s['latLng'] as LatLng).latitude},${(s['latLng'] as LatLng).longitude}',
  //         )
  //         .join('|');
  //   }

  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/directions/json'
  //     '?origin=$origin&destination=$destination'
  //     '${waypoints.isNotEmpty ? "&waypoints=$waypoints" : ""}'
  //     '&key=$apiKey',
  //   );

  //   final response = await http.get(url);
  //   if (response.statusCode != 200) {
  //     print('Failed to fetch directions. Status: ${response.statusCode}');
  //     return;
  //   }

  //   final data = jsonDecode(response.body);
  //   if (data['status'] != 'OK') {
  //     print('Google Directions API error: ${data['status']}');
  //     return;
  //   }

  //   final route = data['routes'][0];
  //   final overviewPolyline = route['overview_polyline']['points'];
  //   final points = _decodePolyline(overviewPolyline);

  //   // Calculate total distance and duration including stops
  //   double distanceKm = 0;
  //   double durationMinutes = 0;
  //   for (var leg in route['legs']) {
  //     distanceKm += leg['distance']['value'] / 1000.0;
  //     durationMinutes += leg['duration']['value'] / 60.0;
  //   }

  //   // Midpoint of route
  //   LatLng? midPoint;
  //   if (points.isNotEmpty) {
  //     final midIndex = (points.length / 2).floor();
  //     midPoint = LatLng(points[midIndex].latitude, points[midIndex].longitude);
  //   }

  //   // Resolve addresses
  //   pickupAddress = await _getPlaceName(widget.pickup!);
  //   destinationAddress = await _getPlaceName(widget.destination!);

  //   // Add stops addresses
  //   for (int i = 0; i < stops.length; i++) {
  //     stops[i]['address'] = await _getPlaceName(stops[i]['latLng']);
  //   }

  //   if (!mounted) return;
  //   setState(() {
  //     routePoints = points;
  //     routeDistance = distanceKm;
  //     this.durationInMinutes = durationMinutes;

  //     polylines = {
  //       Polyline(
  //         polylineId: const PolylineId('route'),
  //         color: const Color(0xFF015ACE),
  //         width: 5,
  //         points: routePoints,
  //       ),
  //     };

  //     // Update markers for pickup, destination, and stops
  //     _markers
  //       ..clear()
  //       ..add(
  //         Marker(
  //           markerId: const MarkerId('pickup'),
  //           position: widget.pickup!,
  //           icon: BitmapDescriptor.defaultMarkerWithHue(
  //             BitmapDescriptor.hueGreen,
  //           ),
  //           infoWindow: InfoWindow(title: pickupAddress ?? "Pickup"),
  //         ),
  //       )
  //       ..add(
  //         Marker(
  //           markerId: const MarkerId('destination'),
  //           position: widget.destination!,
  //           icon: BitmapDescriptor.defaultMarkerWithHue(
  //             BitmapDescriptor.hueRed,
  //           ),
  //           infoWindow: InfoWindow(title: destinationAddress ?? "Destination"),
  //         ),
  //       );

  //     for (int i = 0; i < stops.length; i++) {
  //       _markers.add(
  //         Marker(
  //           markerId: MarkerId('stop_$i'),
  //           position: stops[i]['latLng'],
  //           icon: BitmapDescriptor.defaultMarkerWithHue(
  //             BitmapDescriptor.hueOrange,
  //           ),
  //           infoWindow: InfoWindow(
  //             title: stops[i]['address'] ?? "Stop ${i + 1}",
  //           ),
  //         ),
  //       );
  //     }

  //     if (midPoint != null) {
  //       _markers.add(
  //         Marker(
  //           markerId: const MarkerId('route_center'),
  //           position: midPoint,
  //           icon: BitmapDescriptor.defaultMarkerWithHue(
  //             BitmapDescriptor.hueBlue,
  //           ),
  //           infoWindow: InfoWindow(
  //             title: "${distanceKm.toStringAsFixed(1)} km",
  //             snippet: "${durationMinutes.toStringAsFixed(0)} min",
  //           ),
  //         ),
  //       );
  //     }
  //   });

  //   // Send stops to backend
  //   //_sendStopsToBackend(stops);

  //   // Update fare estimates per vehicle category
  //   await _fetchFareEstimates(distanceKm, durationMinutes);
  // }
Future<void> _fetchRoute() async {
  if (widget.pickup == null || widget.destination == null) {
    debugPrint('Cannot fetch route: pickup or destination is missing.');
    return;
  }

  try {
    final pickup = widget.pickup!;
    final destination = widget.destination!;

    // Convert coordinates into the Routes API location format.
    Map<String, dynamic> createWaypoint(LatLng location) {
      return {
        'location': {
          'latLng': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
        },
      };
    }

    // Build intermediate stops.
    final List<Map<String, dynamic>> intermediateStops = stops.map((stop) {
      final LatLng location = stop['latLng'] as LatLng;
      return createWaypoint(location);
    }).toList();

    // Routes API (New) endpoint.
    final Uri url = Uri.https(
      'routes.googleapis.com',
      '/directions/v2:computeRoutes',
    );

    final Map<String, dynamic> requestBody = {
      'origin': createWaypoint(pickup),
      'destination': createWaypoint(destination),
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      //'polylineQuality': 'HIGH',
      'polylineQuality': 'HIGH_QUALITY',
      if (intermediateStops.isNotEmpty)
        'intermediates': intermediateStops,
    };

    debugPrint('REQUESTING ROUTE FROM GOOGLE ROUTES API');
    debugPrint('Pickup: ${pickup.latitude}, ${pickup.longitude}');
    debugPrint(
      'Destination: ${destination.latitude}, ${destination.longitude}',
    );
    debugPrint('Intermediate stops: ${intermediateStops.length}');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': mapKey,
            'X-Goog-FieldMask':
                'routes.distanceMeters,'
                'routes.duration,'
                'routes.polyline.encodedPolyline,'
                'routes.legs.distanceMeters,'
                'routes.legs.duration',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('Routes API HTTP Status: ${response.statusCode}');
    debugPrint('Routes API Response: ${response.body}');

    if (response.statusCode != 200) {
      debugPrint('Google Routes API request failed.');
      return;
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic> routes = data['routes'] ?? [];

    if (routes.isEmpty) {
      debugPrint('Google Routes API returned no routes.');
      return;
    }

    final Map<String, dynamic> route =
        routes.first as Map<String, dynamic>;

    // Get encoded route polyline.
    final String? encodedPolyline =
        route['polyline']?['encodedPolyline'] as String?;

    if (encodedPolyline == null || encodedPolyline.isEmpty) {
      debugPrint('No encoded polyline returned by Routes API.');
      return;
    }

    final List<LatLng> points = _decodePolyline(encodedPolyline);

    if (points.isEmpty) {
      debugPrint('Decoded route contains no coordinates.');
      return;
    }

    // Calculate total distance and duration from all route legs.
    double distanceKm = 0;
    double durationMinutes = 0;

    final List<dynamic> legs = route['legs'] ?? [];

    for (final leg in legs) {
      final Map<String, dynamic> legData =
          leg as Map<String, dynamic>;

      final double legDistance =
          (legData['distanceMeters'] as num?)?.toDouble() ?? 0;

      final String duration =
          legData['duration']?.toString() ?? '0s';

      final double legDurationSeconds =
          double.tryParse(duration.replaceAll('s', '')) ?? 0;

      distanceKm += legDistance / 1000.0;
      durationMinutes += legDurationSeconds / 60.0;
    }

    // Midpoint of route.
    final int midIndex = (points.length / 2).floor();
    final LatLng midPoint = points[midIndex];

    debugPrint('ROUTE DISTANCE: ${distanceKm.toStringAsFixed(2)} KM');
    debugPrint(
      'ROUTE DURATION: ${durationMinutes.toStringAsFixed(2)} MINUTES',
    );

    if (!mounted) return;

    // Update route immediately.
    setState(() {
      routePoints = points;
      routeDistance = distanceKm;
      this.durationInMinutes = durationMinutes;

      polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF015ACE),
          width: 5,
          points: routePoints,
        ),
      };

      // Pickup and destination markers.
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: pickupAddress ?? 'Pickup',
            ),
          ),
        )
        ..add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: destinationAddress ?? 'Destination',
            ),
          ),
        );

      // Intermediate stop markers.
      for (int i = 0; i < stops.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: stops[i]['latLng'] as LatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: stops[i]['address'] ?? 'Stop ${i + 1}',
            ),
          ),
        );
      }

      // Route midpoint marker.
      _markers.add(
        Marker(
          markerId: const MarkerId('route_center'),
          position: midPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: '${distanceKm.toStringAsFixed(1)} km',
            snippet: '${durationMinutes.toStringAsFixed(0)} min',
          ),
        ),
      );
    });

    // Calculate fares immediately without waiting for address resolution.
    try {
      debugPrint('FETCHING FARE ESTIMATES...');
      await _fetchFareEstimates(distanceKm, durationMinutes);
    } catch (e, stackTrace) {
      debugPrint('Fare estimation failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Resolve addresses concurrently.
    try {
      final List<String> addresses = await Future.wait([
        _locationService.getPlaceName(pickup),
        _locationService.getPlaceName(destination),
        ...stops.map(
          (stop) => _locationService.getPlaceName(
            stop['latLng'] as LatLng,
          ),
        ),
      ]);

      if (!mounted) return;

      pickupAddress = addresses[0];
      destinationAddress = addresses[1];

      for (int i = 0; i < stops.length; i++) {
        stops[i]['address'] = addresses[i + 2];
      }

      setState(() {
        // Refresh marker information windows with resolved addresses.
        _markers
          ..removeWhere(
            (marker) =>
                marker.markerId.value == 'pickup' ||
                marker.markerId.value == 'destination' ||
                marker.markerId.value.startsWith('stop_'),
          )
          ..add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(title: pickupAddress ?? 'Pickup'),
            ),
          )
          ..add(
            Marker(
              markerId: const MarkerId('destination'),
              position: destination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: destinationAddress ?? 'Destination',
              ),
            ),
          );

        for (int i = 0; i < stops.length; i++) {
          _markers.add(
            Marker(
              markerId: MarkerId('stop_$i'),
              position: stops[i]['latLng'] as LatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: stops[i]['address'] ?? 'Stop ${i + 1}',
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Address resolution failed: $e');
    }
  } catch (e, stackTrace) {
    debugPrint('ROUTE FETCH ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

//mbox 
// Future<void> _fetchRoute() async {
//   final apiKey = mapboxAccessToken;

//   // Build coordinates list
//   final List<String> coordinates = [];

//   // Pickup
//   coordinates.add(
//     '${widget.pickup!.longitude},${widget.pickup!.latitude}',
//   );

//   // Stops
//   for (final stop in stops) {
//     final LatLng point = stop['latLng'] as LatLng;

//     coordinates.add(
//       '${point.longitude},${point.latitude}',
//     );
//   }

//   // Destination
//   coordinates.add(
//     '${widget.destination!.longitude},${widget.destination!.latitude}',
//   );

//   final url = Uri.parse(
//     'https://api.mapbox.com/directions/v5/mapbox/driving/'
//     '${coordinates.join(";")}'
//     '?alternatives=false'
//     '&geometries=polyline'
//     '&overview=full'
//     '&steps=true'
//     '&access_token=$apiKey',
//   );

//   final response = await http.get(url);

//   if (response.statusCode != 200) {
//     debugPrint("Mapbox HTTP Error ${response.statusCode}");
//     return;
//   }

//   final data = jsonDecode(response.body);

//   if (data["routes"] == null || data["routes"].isEmpty) {
//     debugPrint("No route returned from Mapbox");
//     return;
//   }

//   final route = data["routes"][0];

//   final String encodedPolyline = route["geometry"];

//   final List<LatLng> points = _decodePolyline(encodedPolyline);

//   // Calculate total distance and duration
//   double distanceKm = 0;
//   double durationMinutes = 0;

//   for (final leg in route["legs"]) {
//     distanceKm += (leg["distance"] as num).toDouble() / 1000;
//     durationMinutes += (leg["duration"] as num).toDouble() / 60;
//   }

//   // Route midpoint
//   LatLng? midPoint;

//   if (points.isNotEmpty) {
//     final int midIndex = points.length ~/ 2;
//     midPoint = points[midIndex];
//   }

//   // Reverse geocode addresses
//   pickupAddress = await _getPlaceName(widget.pickup!);
//   destinationAddress = await _getPlaceName(widget.destination!);

//   // Reverse geocode stop addresses
//   for (int i = 0; i < stops.length; i++) {
//     stops[i]["address"] = await _getPlaceName(
//       stops[i]["latLng"] as LatLng,
//     );
//   }

//   if (!mounted) return;

//   setState(() {
//     routePoints = points;
//     routeDistance = distanceKm;
//     durationInMinutes = durationMinutes;

//     polylines = {
//       Polyline(
//         polylineId: const PolylineId("route"),
//         color: Colors.blue,
//         width: 5,
//         points: routePoints,
//       ),
//     };

//     _markers.clear();

//     // Pickup
//     _markers.add(
//       Marker(
//         markerId: const MarkerId("pickup"),
//         position: widget.pickup!,
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//           BitmapDescriptor.hueGreen,
//         ),
//         infoWindow: InfoWindow(
//           title: pickupAddress ?? "Pickup",
//         ),
//       ),
//     );

//     // Destination
//     _markers.add(
//       Marker(
//         markerId: const MarkerId("destination"),
//         position: widget.destination!,
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//           BitmapDescriptor.hueRed,
//         ),
//         infoWindow: InfoWindow(
//           title: destinationAddress ?? "Destination",
//         ),
//       ),
//     );

//     // Stops
//     for (int i = 0; i < stops.length; i++) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId("stop_$i"),
//           position: stops[i]["latLng"] as LatLng,
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueOrange,
//           ),
//           infoWindow: InfoWindow(
//             title: stops[i]["address"] ?? "Stop ${i + 1}",
//           ),
//         ),
//       );
//     }

//     // Route info marker
//     if (midPoint != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId("route_center"),
//           position: midPoint,
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueBlue,
//           ),
//           infoWindow: InfoWindow(
//             title: "${distanceKm.toStringAsFixed(1)} km",
//             snippet:
//                 "${durationMinutes.toStringAsFixed(0)} mins",
//           ),
//         ),
//       );
//     }
//   });

//   // Calculate fares
//   await _fetchFareEstimates(
//     distanceKm,
//     durationMinutes,
//   );
// }


  // Future<void> _fetchFareEstimates(
  //   double distanceKm,
  //   double durationMinutes,
  // ) async {
  //   // Prepare stops for the API
  //   List<Map<String, double>>? fareStops;

  //   if (stops.isNotEmpty) {
  //     fareStops =
  //         stops.where((s) => s["latLng"] != null).map((s) {
  //           final LatLng latLng = s["latLng"];
  //           return {"lat": latLng.latitude, "lng": latLng.longitude};
  //         }).toList();
  //   } else {
  //     fareStops = null;
  //   }

  //   // Loop through vehicle categories
  //   for (int i = 0; i < vehicleCategories.length; i++) {
  //     final category = vehicleCategories[i];
  //     try {
  //       final estimate = await FareService.getFareEstimate(
  //         categoryId: category.id,
  //         pickupLat: widget.pickup!.latitude,
  //         pickupLng: widget.pickup!.longitude,
  //         destLat: widget.destination!.latitude,
  //         destLng: widget.destination!.longitude,
  //         distanceKm: distanceKm,
  //         durationMinutes: durationMinutes,
  //         waitingMinutes: 0,
  //         countryCode: "KE",
  //         stops: fareStops, // Pass the stops here
  //       );

  //       if (!mounted) return;
  //       setState(() => fareEstimates[i] = estimate);
  //     } catch (e) {
  //       print('❌ Failed to load fare for ${category.name}: $e');
  //       if (!mounted) return;
  //       setState(() {
  //         fareEstimates[i] = FareEstimate(
  //           fare: 0,
  //           currency: "KES",
  //           timeEstimate: durationMinutes,
  //           categoryName: category.name,
  //           distanceKm: distanceKm,
  //         );
  //       });
  //     }
  //   }
  // }
Future<void> _fetchFareEstimates(
  double distanceKm,
  double durationMinutes,
) async {
  if (widget.pickup == null || widget.destination == null) {
    debugPrint('FARE ERROR: Pickup or destination is missing.');
    return;
  }

  if (vehicleCategories.isEmpty) {
    debugPrint('FARE ERROR: No vehicle categories available.');
    return;
  }

  debugPrint('========== FARE ESTIMATION STARTED ==========');
  debugPrint('Distance: $distanceKm km');
  debugPrint('Duration: $durationMinutes minutes');
  debugPrint('Categories: ${vehicleCategories.length}');

  // Prepare intermediate stops.
  final List<Map<String, double>> fareStops = stops
      .where((s) => s['latLng'] is LatLng)
      .map((s) {
        final LatLng location = s['latLng'] as LatLng;

        return <String, double>{
          'lat': location.latitude,
          'lng': location.longitude,
        };
      })
      .toList();

  debugPrint('Intermediate stops: ${fareStops.length}');

  if (fareEstimates.length < vehicleCategories.length) {
    debugPrint(
      'FARE WARNING: fareEstimates list is smaller than vehicleCategories.',
    );
    return;
  }

  final pickup = widget.pickup!;
  final destination = widget.destination!;

  // Request estimates for all vehicle categories.
  final results = await Future.wait(
    vehicleCategories.asMap().entries.map((entry) async {
      final int index = entry.key;
      final category = entry.value;

      try {
        debugPrint(
          'REQUESTING FARE: ${category.name} | Category ID: ${category.id}',
        );

        final estimate = await FareService.getFareEstimate(
          categoryId: category.id,
          pickupLat: pickup.latitude,
          pickupLng: pickup.longitude,
          destLat: destination.latitude,
          destLng: destination.longitude,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          waitingMinutes: 0,
          countryCode: 'KE',
          stops: fareStops.isNotEmpty ? fareStops : null,
        );

        debugPrint(
          'FARE SUCCESS: ${category.name} | '
          '${estimate.currency} ${estimate.fare}',
        );

        return MapEntry(index, estimate);
      } catch (e, stackTrace) {
        debugPrint('FARE FAILED: ${category.name} | $e');
        debugPrintStack(stackTrace: stackTrace);

        return MapEntry(
          index,
          FareEstimate(
            fare: 0,
            currency: 'KES',
            timeEstimate: durationMinutes,
            categoryName: category.name,
            distanceKm: distanceKm,
          ),
        );
      }
    }),
  );

  if (!mounted) return;

  setState(() {
    for (final result in results) {
      fareEstimates[result.key] = result.value;
    }
  });

  debugPrint('========== FARE ESTIMATION COMPLETED ==========');
}
  // Helper method to calculate midpoint
  LatLng _getMidPoint(LatLng p1, LatLng p2) {
    final midLat = (p1.latitude + p2.latitude) / 2;
    final midLng = (p1.longitude + p2.longitude) / 2;
    return LatLng(midLat, midLng);
  }

  // Decode encoded polyline from Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _navigateToWhereTo() {
    if (_hasActiveRide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already have an active ride. Complete or cancel it before booking a new one.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // ❌ Prevent booking
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => WhereToScreen(
              category: VehicleCategory.passenger,
              initialPickupLocation: currentLocation,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(linkedDriverProvider);
    final rideConfirmed = ref.watch(rideConfirmedProvider);

    //final pickup = widget.pickup;
    final pickup = widget.pickup ?? currentLocation;
    final destination = widget.destination;
    final dropAddressAsync = ref.watch(dropAddressProvider);

    //final distance = Distance();
    final selectedFare =
        (selectedIndex >= 0 && selectedIndex < fareEstimates.length)
            ? fareEstimates[selectedIndex]?.fare ?? 0.0
            : 0.0;
    // final tripDistanceKm = distance.as(
    //   LengthUnit.Kilometer,
    //   pickup!,
    //   destination!,
    // );

    double? tripDistanceKm;
    LatLng? midPoint;

   

    // if (pickup != null && destination != null) {
    //   // tripDistanceKm = distance.as(LengthUnit.Kilometer, pickup, destination);

    //   midPoint = LatLng(
    //     (pickup.latitude + destination.latitude) / 2,
    //     (pickup.longitude + destination.longitude) / 2,
    //   );
    // }
    if (pickup != null && destination != null) {
      tripDistanceKm = routeDistance;

      final tripDuration = durationInMinutes;

      //_calculateDistanceKm(pickup, destination);
      midPoint = LatLng(
        (pickup.latitude + destination.latitude) / 2,
        (pickup.longitude + destination.longitude) / 2,
      );
    }
    if (rideConfirmed) {
      if (driver == null) {
        return const Center(child: Text('No driver linked'));
      }
    }
    if (midPoint != null) {
      midPoint = LatLng(
        (pickup!.latitude + destination!.latitude) / 2,
        (pickup.longitude + destination.longitude) / 2,
      );
    }

    return Scaffold(
      //appBar: AppBar(title: const Text("Amini Ride")),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        widget.pickup ??
                        _initialFallback, // fallback only on pickup just to avoid null
                    zoom: 12,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;

                    if (widget.destination != null) {
                      _initMap(widget.pickup!, widget.destination!);
                      //      _moveCameraToBounds(
                      //   pickup,
                      //   destination,
                      // );
                      _moveCameraToBounds(widget.pickup!, widget.destination!);
                    } else if (widget.pickup != null) {
                      // Move camera to just pickup location without destination
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          widget.pickup!,
                          14,
                        ), // adjust zoom as needed
                      );
                    }
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),

              if (routeDistance != null && durationInMinutes > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 6),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${pickupAddress ?? 'Pickup'} → ${destinationAddress ?? 'Destination'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${routeDistance!.toStringAsFixed(1)} km • ${durationInMinutes.toStringAsFixed(0)} min",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                // Navigate to search screen or open modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => WhereToScreen(
                          category: VehicleCategory.passenger,
                          initialPickupLocation: pickup ?? currentLocation,
                        ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dropAddressAsync.when(
                          data: (address) => address ?? 'Select Destination',
                          loading: () => 'Loading...',
                          error: (err, _) => 'Error',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (tripDistanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Distance: ${tripDistanceKm.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => const AlertDialog(
                                title: Text("Add Stop"),
                                content: Text(
                                  "Add stop functionality coming soon.",
                                ),
                              ),
                        );
                      },
                      child: const Icon(Icons.add, color: Color(0xFF015ACE),),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: GestureDetector(
              onTap: _navigateToWhereTo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.destination != null)

            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final sheetExtent = notification.extent; // 0.35 - 0.8
                final scrollFraction = (sheetExtent - 0.35) / (0.8 - 0.35);
                // 0 = sheet minimized, 1 = sheet fully expanded
                onDraggableScroll(scrollFraction);
                return true;
              },

              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.35,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  if (_scrollController.hasClients &&
                      _scrollController != scrollController) {
                    _scrollController = scrollController;
                  }

                  if (widget.pickup != null && widget.destination != null) {
                    _moveCameraToBounds(widget.pickup!, widget.destination!);
                  }
    void _navigateToScheduleRide() {
    if (_hasActiveRide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already have an active ride. Complete or cancel it first.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const WhereToScreen(
              category: VehicleCategory.passenger,
              IsScheduled: true, // 🔥 THIS IS THE FIX
            ),
      ),
    );
  }

                  final validEstimates =
                      fareEstimates.where((e) => e != null).toList();

                  // final double minFare =
                  //     validEstimates.isNotEmpty
                  //         ? validEstimates
                  //             .map((e) => e!.fare)
                  //             .reduce((a, b) => a < b ? a : b)
                  //         : 0;

                  // final int minTime =
                  //     validEstimates.isNotEmpty
                  //         ? validEstimates
                  //             .map((e) => e!.timeEstimate)
                  //             .reduce((a, b) => a < b ? a : b)
                  //             .toInt()
                  //         : 0;

                  final availableCategories = <Map<String, dynamic>>[];

                  for (int i = 0; i < vehicleCategories.length; i++) {
                    final isAvailable =
                        driverAvailability.isNotEmpty && driverAvailability[i];

                    if (isAvailable) {
                      availableCategories.add({
                        "category": vehicleCategories[i],
                        "estimate": fareEstimates[i],
                        "index": i,
                      });
                    }
                  }

                  // compute min fare/time only from available categories
                  final double minFare =
                      availableCategories.isNotEmpty
                          ? availableCategories
                              .map(
                                (e) =>
                                    (e["estimate"] as FareEstimate?)?.fare ??
                                    double.infinity,
                              )
                              .reduce((a, b) => a < b ? a : b)
                          : 0;

                  final validTimes =
                      availableCategories
                          .map(
                            (e) =>
                                (e["estimate"] as FareEstimate?)?.timeEstimate,
                          )
                          .where((e) => e != null)
                          .cast<double>()
                          .toList();

                  final int minTime =
                      validTimes.isNotEmpty
                          ? validTimes.reduce((a, b) => a < b ? a : b).toInt()
                          : 0; // fallback if no estimates
                  //  : 0;

                  //selectedPayment = 'Cash';
                  //appBalance = 50;
                  bool hasVisaCard = false;

                  // final availableCategories = <Map<String, dynamic>>[];

                  // for (int i = 0; i < vehicleCategories.length; i++) {
                  //   final isAvailable =
                  //       driverAvailability.isNotEmpty && driverAvailability[i];

                  //   if (isAvailable) {
                  //     availableCategories.add({
                  //       "category": vehicleCategories[i],
                  //       "estimate": fareEstimates[i],
                  //       "index": i,
                  //     });
                  //   }
                  // }

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🚀 CATEGORY LIST
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(12),
                            //itemCount: vehicleCategories.length,
                            itemCount: availableCategories.length,

                            itemBuilder: (context, index) {
                              final item = availableCategories[index];
                              final category = item["category"];
                              final estimate = item["estimate"];
                              final originalIndex = item["index"];

                              final isSelected = selectedIndex == originalIndex;

                              // final category = vehicleCategories[index];
                              //final estimate = fareEstimates[index];

                              // final isSelected = selectedIndex == index;
                              final isAvailable =
                                  driverAvailability.isNotEmpty &&
                                  driverAvailability[index];

                              final isCheapest = estimate?.fare == minFare;
                              final isFastest =
                                  estimate?.timeEstimate == minTime;

                              final name = category.name;
                              final passengers = category.maxPassengers;

                              final timeAway =
                                  estimate != null
                                      ? "${estimate.timeEstimate.round()} min"
                                      : "--";

                              // ✅ DISCOUNT LOGIC (NO % SHOWN)
                              final hasDiscount = index == 0 || index == 2;
                              final originalFare = estimate?.fare ?? 0;
                              final discountedFare =
                                  hasDiscount
                                      ? originalFare * 0.85
                                      : originalFare;

                              final currency = estimate?.currency ?? "";

                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap:
                                        isAvailable
                                            ? () {
                                              setState(
                                                () => selectedIndex = index,
                                              );
                                              ref
                                                  .read(
                                                    selectedCategoryProvider
                                                        .notifier,
                                                  )
                                                  .state = category;
                                            }
                                            : null,
                                    child: Opacity(
                                      opacity: isAvailable ? 1 : 0.5,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Color(0xFFF0D000),
                                                    width: 2.5,
                                                  )
                                                  : null,
                                        ),

                                  child: Row(
                                          children: [
                                            // 🚗 IMAGE
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child:
                                                  category.iconUrl != null &&
                                                          category
                                                              .iconUrl!
                                                              .isNotEmpty
                                                      ? Image.network(
                                                        "$ImageUrl${category.iconUrl}",
                                                        width: 60,
                                                        height: 60,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Image.asset(
                                                        'assets/imgs/Sedan2.png',
                                                        width: 60,
                                                        height: 60,
                                                      ),
                                            ),

                                            const SizedBox(width: 12),

                                            // 📊 DETAILS
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 🔥 NAME + PRICE
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),

                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              if (hasDiscount)
                                                                Text(
                                                                  "$currency ${originalFare.toStringAsFixed(0)}",
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough,
                                                                  ),
                                                                ),
                                                              if (hasDiscount)
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),

                                                              Text(
                                                                "$currency ${discountedFare.toStringAsFixed(0)}",
                                                                style: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 6),

                                                  // 🏷 BADGES
                                                  Row(
                                                    children: [
                                                      if (isCheapest)
                                                        _badge("Cheapest"),
                                                      if (isFastest)
                                                        _badge("Fastest"),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 6),

                                                  // ⏱ TIME + 👥 PASSENGERS
                                                  Row(
                                                    children: [
                                                      Text(
                                                        timeAway,
                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        "$passengers seats",
                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  if (!isAvailable)
                                                    const Text(
                                                      "No drivers nearby",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 🔥 DIVIDER BETWEEN CARDS
                                  Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),


Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Text(
      //   'Payment method',
      //   style: GoogleFonts.spaceGrotesk(
      //     fontSize: 13,
      //     fontWeight: FontWeight.w700,
      //     color: Colors.black87,
      //   ),
      // ),

      //const SizedBox(height: 8),

      SizedBox(
        height: 58,
        child: Row(
          children: [
            _paymentMethodCard(
              method: 'Cash',
              icon: Icons.money_rounded,
              fare: selectedFare
            ),

            const SizedBox(width: 10),

            _paymentMethodCard(
              method: 'AMiNi',
              icon: Icons.account_balance_wallet_rounded,
              fare: selectedFare
            ),
          ],
        ),
      ),

      const SizedBox(height: 10),

      Consumer(
        builder: (context, ref, child) {
          final selected = ref.watch(selectedCategoryProvider);

          final category = selected?.name ?? '';
          final categoryId = selected?.id ?? 0;
        //  final isEnabled = category.isNotEmpty;
          final isEnabled = category.isNotEmpty &&
    pickupAddress != null &&
    pickupAddress!.trim().isNotEmpty &&
    destinationAddress != null &&
    destinationAddress!.trim().isNotEmpty;
          final passengers = selected?.maxPassengers ?? 0;

Future<void> _navigateToConfirmRide() async {
  // Ensure both addresses are available.
  if (pickupAddress == null ||
      pickupAddress!.trim().isEmpty ||
      destinationAddress == null ||
      destinationAddress!.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please wait while pickup and destination are loading.'),
      ),
    );
    return;
  }

  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ConfirmRideScreen(
        pickup: widget.pickup!,
        fare: selectedFare,
        destination: widget.destination!,
        category: categoryId,
        optionSelected: category,
        isScheduled: widget.isScheduled,
        scheduledDate: widget.scheduledDate,
        passengerCount: passengers,
        selectedPayment: selectedPayment,
        pickuUp: pickupAddress!,
        destinationUp: destinationAddress!,
      ),
    ),
  );
}

     

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _navigateToScheduleRide,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF015ACE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  
                  // onPressed: isEnabled
                  //     ? () async {
                  //         // -----------------------------------------
                  //         // 1. Validate fare
                  //         // -----------------------------------------

                  //         if (selectedFare <= 0) {
                  //           _showFareUnavailable();
                  //           return;
                  //         }

                  //         // -----------------------------------------
                  //         // 2. Validate AMiNi wallet
                  //         // -----------------------------------------

                  //         if (selectedPayment == 'AMiNi') {
                  //           if (appBalance < selectedFare) {
                  //             await _openAddFundsScreen();
                  //             return;
                  //           }
                  //         }

                  //         // -----------------------------------------
                  //         // 3. Continue to confirmation
                  //         // -----------------------------------------

                  //         if (!context.mounted) return;

                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (_) => ConfirmRideScreen(
                  //               pickup: widget.pickup!,
                  //               fare: selectedFare,
                  //               destination: widget.destination!,
                  //               category: categoryId,
                  //               optionSelected: category,
                  //               isScheduled: widget.isScheduled,
                  //               scheduledDate: widget.scheduledDate,
                  //               passengerCount: passengers,
                  //               selectedPayment: selectedPayment,
                  //             ),
                  //           ),
                  //         );
                  //       }
                  //     : null,
onPressed: isEnabled
    ? () async {
        // -----------------------------------------
        // 1. Validate fare
        // -----------------------------------------

        if (selectedFare <= 0) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7D6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          size: 30,
                          color: Color(0xFFF0D000),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Fare unavailable',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'We couldn’t calculate a fare for this trip. '
                        'Please check your pickup and destination, '
                        'then try again.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF015ACE),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Got it',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          return;
        }

        await _navigateToConfirmRide();
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => ConfirmRideScreen(
        //       pickup: widget.pickup!,
        //       fare: selectedFare,
        //       destination: widget.destination!,
        //       category: categoryId,
        //       optionSelected: category,
        //       isScheduled: widget.isScheduled,
        //       scheduledDate: widget.scheduledDate,
        //       passengerCount: passengers,
        //       selectedPayment: selectedPayment,
        //       pickuUp: pickupAddress,
        //       destinationUp: destinationAddress,
        //     ),
        //   ),
        // );
      }
    : null,



                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015ACE),
                    disabledBackgroundColor: Colors.grey.shade400,
                    minimumSize: const Size(0, 55),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.isScheduled == true && isEnabled
                        ? "Book $category"
                        : "Select ${category.isNotEmpty ? category : 'Category'}",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  ),
)








//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),

//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 60,
//                                 height: 50,

//                                 // elevation: 12, // creates shadow separation
//                                 //color: Colors.white., // solid background
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   //color: Colors.blue,
//                                   color: Color(0xFFF0D000),
//                                   borderRadius: BorderRadius.circular(8),
//                                   //foreground: Color.white
//                                   border: Border.all(
//                                     color: Colors.grey.shade300,
//                                   ),
//                                 ),
//                                 child: FittedBox(
//                                   fit: BoxFit.scaleDown,
//                                   child: DropdownButtonHideUnderline(
//                                     child: DropdownButton<String>(
//                                       value: selectedPayment,
//                                       icon: const Icon(
//                                         Icons.arrow_drop_down,
//                                         size: 20,
//                                       ),
//                                       items:
//                                           ['Cash', 'Visa', 'AMiNi'].map((
//                                             method,
//                                           ) {
//                                             Icon methodIcon;
//                                             switch (method) {
//                                               case 'Cash':
//                                                 methodIcon = const Icon(
//                                                   Icons.money,
//                                                   size: 18,
//                                                 );
//                                                 break;
//                                               case 'Visa':
//                                                 methodIcon = const Icon(
//                                                   Icons.credit_card,
//                                                   size: 18,
//                                                 );
//                                                 break;
//                                               case 'AMiNi':
//                                                 methodIcon = const Icon(
//                                                   Icons.account_balance_wallet,
//                                                   size: 18,
//                                                 );
//                                                 break;
//                                               default:
//                                                 methodIcon = const Icon(
//                                                   Icons.payment,
//                                                   size: 18,
//                                                 );
//                                             }
//                                             return DropdownMenuItem<String>(
//                                               value: method,
//                                               child: Row(
//                                                 children: [
//                                                   methodIcon,
//                                                   const SizedBox(
//                                                     width: 2,
//                                                   ), // reduce spacing
//                                                   Text(
//                                                     method,
//                                                     style: const TextStyle(
//                                                       fontSize: 12,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             );
//                                           }).toList(),
//                                       onChanged: (value) {
//                                         if (value != null)
//                                           setState(
//                                             () => selectedPayment = value,
//                                           );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 6), // small spacing
                         


//                               Consumer(
//   builder: (context, ref, child) {
//     final selected = ref.watch(selectedCategoryProvider);
//     final category = selected?.name ?? 'N/A';
//     final categoryId = selected?.id ?? 0;
//     final isEnabled = category.isNotEmpty;
//     final passengers=selected?.maxPassengers??0;

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//          GestureDetector(
//       onTap: _navigateToScheduleRide,
//       child: Container(
//         width: 55,
//         height: 55,
//         decoration: BoxDecoration(
//           color: const Color(0xFF015ACE),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         alignment: Alignment.center,
//         child: const Icon(
//           Icons.calendar_month_rounded,
//           color: Colors.white,
//           size: 28,
//         ),
//       ),
//     ),

//     const SizedBox(width: 12),

//         Expanded(
//           child: ElevatedButton(
//             onPressed:
//                 isEnabled
//                     ? () {
//                       // Payment validations
//                       if (selectedPayment == 'AMiNi' &&
//                           appBalance < selectedFare) {
//                         showDialog(
//                           context: context,
//                           builder:
//                               (_) => const AlertDialog(
//                                 title: Text('Insufficient Balance'),
//                                 content: Text(
//                                   'You do not have enough funds in your AMiNi wallet. Please top up.',
//                                 ),
//                               ),
//                         );
//                         return;
//                       }

//                       if (selectedPayment == 'Visa' && !hasVisaCard) {
//                         showDialog(
//                           context: context,
//                           builder:
//                               (_) => const AlertDialog(
//                                 title: Text('No Visa Card Added'),
//                                 content: Text(
//                                   'You have not added a Visa card. Please add one to continue.',
//                                 ),
//                               ),
//                         );
//                         return;
//                       }

// if (selectedFare <= 0) {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.transparent,
//     isScrollControlled: true,
//     builder: (context) {
//       return Container(
//         margin: const EdgeInsets.all(16),
//         padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(28),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.12),
//               blurRadius: 30,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           top: false,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Icon
//               Container(
//                 width: 64,
//                 height: 64,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF7D6),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.payments_outlined,
//                   size: 30,
//                   color: Color(0xFFF0D000),
//                 ),
//               ),

//               const SizedBox(height: 18),

//               // Title
//               Text(
//                 'Fare unavailable',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.spaceGrotesk(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                 ),
//               ),

//               const SizedBox(height: 8),

//               // Message
//               Text(
//                 'We couldn’t calculate a fare for this trip. '
//                 'Please check your pickup and destination, then try again.',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.nunitoSans(
//                   fontSize: 14,
//                   height: 1.5,
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),

//               const SizedBox(height: 22),

//               // Action
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF015ACE),
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   child: Text(
//                     'Got it',
//                     style: GoogleFonts.spaceGrotesk(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );

//   return;
// }

// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => ConfirmRideScreen(
//       pickup: widget.pickup!,
//       fare: selectedFare,
//       destination: widget.destination!,
//       category: categoryId,
//       optionSelected: category,
//       isScheduled: widget.isScheduled,
//       scheduledDate: widget.scheduledDate,
//       passengerCount: passengers,
//       selectedPayment: selectedPayment,
//     ),
//   ),
// );


//                     }
//                     : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF015ACE),
//               disabledBackgroundColor: Colors.grey.shade400,
//               minimumSize: const Size(0, 55),
//               padding: const EdgeInsets.symmetric(
//                 vertical: 16,
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: Text(
//               widget.isScheduled == true && isEnabled
//                   ? "Book $category"
//                   : "Select ${category ?? 'Category'}",
//               style: const TextStyle(
//                 fontSize: 17,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   },
// )
//                             ],
//                           ),
//                         ),
                    
                    
                    





                    
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }


Future<void> _openAddFundsScreen() async {
  if (!mounted) return;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const WalletScreen(),
    ),
  );

  if (!mounted) return;

  // If Add Funds returned successfully, refresh wallet balance.
  if (result == true) {
    // Call your existing wallet balance method here.
    //
    // Example:
      _loadWalletBalance();

    setState(() {});
  }
}

// Widget _paymentMethodCard({
//   required String method,
//   required IconData icon,
// }) {
//   final bool isSelected = selectedPayment == method;

//   return Expanded(
//     child: Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () {
//           setState(() {
//             selectedPayment = method;
//           });
//         },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 180),
//           curve: Curves.easeOut,
//           height: 54,
//           padding: const EdgeInsets.symmetric(
//             horizontal: 12,
//           ),
//           decoration: BoxDecoration(
//             color: isSelected
//                 ? const Color(0xFFF0D000)
//                 : Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected
//                   ? const Color(0xFFF0D000)
//                   : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(
//                   isSelected ? 0.08 : 0.04,
//                 ),
//                 blurRadius: isSelected ? 8 : 5,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 21,
//                 color: Colors.black87,
//               ),

//               const SizedBox(width: 8),

//               Text(
//                 method,
//                 style: GoogleFonts.spaceGrotesk(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                 ),
//               ),

//               if (isSelected) ...[
//                 const SizedBox(width: 6),

//                 const Icon(
//                   Icons.check_circle_rounded,
//                   size: 17,
//                   color: Colors.black,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }
// Widget _paymentMethodCard({
//   required String method,
//   required IconData icon,
//   required double fare,
// }) {
//   final bool isSelected = selectedPayment == method;

//   return Expanded(
//     child: Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),

//         onTap: () async {
//           // -----------------------------------------
//           // CASH
//           // -----------------------------------------
//           if (method == 'Cash') {
//             if (!mounted) return;

//             setState(() {
//               selectedPayment = 'Cash';
//             });

//             return;
//           }

//           // -----------------------------------------
//           // AMiNi
//           // -----------------------------------------
//           if (method == 'AMiNi') {
//             if (!mounted) return;

//             setState(() {
//               selectedPayment = 'AMiNi';
//             });

//             // -----------------------------------------
//             // Fare not calculated yet
//             // -----------------------------------------
//             if (fare <= 0) {
//               return;
//             }

//             // -----------------------------------------
//             // Wallet balance is still loading
//             // -----------------------------------------
//             if (isWalletLoading) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text(
//                     'Checking your AMiNi wallet balance...',
//                   ),
//                   duration: Duration(seconds: 2),
//                 ),
//               );

//               return;
//             }

//             // -----------------------------------------
//             // Check wallet balance
//             // -----------------------------------------
//             if (appBalance < fare) {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const WalletScreen(),
//                 ),
//               );

//               if (!mounted) return;

//               // -----------------------------------------
//               // User cancelled wallet
//               // -----------------------------------------
//               if (result != true) {
//                 setState(() {
//                   selectedPayment = 'Cash';
//                 });

//                 return;
//               }

//               // -----------------------------------------
//               // User successfully added funds
//               //
//               // IMPORTANT:
//               // Reload balance from API
//               // -----------------------------------------
//               await _loadWalletBalance();

//               if (!mounted) return;

//               // -----------------------------------------
//               // Check NEW balance
//               // -----------------------------------------
//               if (appBalance >= fare) {
//                 setState(() {
//                   selectedPayment = 'AMiNi';
//                 });

//                 debugPrint(
//                   'AMiNi payment selected. '
//                   'Balance: KES ${appBalance.toStringAsFixed(2)}, '
//                   'Fare: KES ${fare.toStringAsFixed(2)}',
//                 );
//               } else {
//                 setState(() {
//                   selectedPayment = 'Cash';
//                 });

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       'Your AMiNi balance is still insufficient. '
//                       'Required: KES ${fare.toStringAsFixed(2)}, '
//                       'Available: KES ${appBalance.toStringAsFixed(2)}.',
//                     ),
//                     duration: const Duration(seconds: 3),
//                   ),
//                 );
//               }
//             }
//           }
//         },

//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 180),
//           curve: Curves.easeOut,
//           height: 54,
//           padding: const EdgeInsets.symmetric(
//             horizontal: 12,
//           ),
//           decoration: BoxDecoration(
//             color: isSelected
//                 ? const Color(0xFFF0D000)
//                 : Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected
//                   ? const Color(0xFFF0D000)
//                   : Colors.grey.shade300,
//               width: isSelected ? 1.5 : 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(
//                   isSelected ? 0.08 : 0.04,
//                 ),
//                 blurRadius: isSelected ? 8 : 5,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 21,
//                 color: Colors.black87,
//               ),

//               const SizedBox(width: 8),

//               Text(
//                 method,
//                 style: GoogleFonts.spaceGrotesk(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                 ),
//               ),

//               if (isSelected) ...[
//                 const SizedBox(width: 6),

//                 const Icon(
//                   Icons.check_circle_rounded,
//                   size: 17,
//                   color: Colors.black,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }


Widget _paymentMethodCard({
  required String method,
  required IconData icon,
  required double fare,
}) {
  final bool isSelected = selectedPayment == method;

  return Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: () async {
          // -----------------------------------------
          // CASH
          // -----------------------------------------
          if (method == 'Cash') {
            if (!mounted) return;

            setState(() {
              selectedPayment = 'Cash';
            });

            return;
          }

          // -----------------------------------------
          // AMiNi
          // -----------------------------------------
          if (method == 'AMiNi') {
            // Fare not calculated yet
            if (fare <= 0) {
              if (!mounted) return;

              _showFareUnavailable();

              return;
            }

            // Wallet balance is still loading
            if (isWalletLoading) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Checking your AMiNi wallet balance...',
                  ),
                ),
              );

              return;
            }

            debugPrint(
              'AMiNi Payment Check: '
              'Balance = KES ${appBalance.toStringAsFixed(2)}, '
              'Fare = KES ${fare.toStringAsFixed(2)}',
            );

            // -----------------------------------------
            // SUFFICIENT BALANCE
            // -----------------------------------------
            if (appBalance >= fare) {
              if (!mounted) return;

              setState(() {
                selectedPayment = 'AMiNi';
              });

              return;
            }

            // -----------------------------------------
            // INSUFFICIENT BALANCE
            // -----------------------------------------
            final addFunds = await _showInsufficientAMiNiBalance(
              fare,
            );

            if (!mounted) return;

            // -----------------------------------------
            // User selected Add Funds
            // -----------------------------------------
            if (addFunds == true) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletScreen(),
                ),
              );

              if (!mounted) return;

              // -----------------------------------------
              // Refresh wallet after returning
              // -----------------------------------------
              if (result == true) {
                await _loadWalletBalance();

                if (!mounted) return;

                // -----------------------------------------
                // Check refreshed balance
                // -----------------------------------------
                if (appBalance >= fare) {
                  setState(() {
                    selectedPayment = 'AMiNi';
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'AMiNi wallet funded successfully.',
                      ),
                    ),
                  );
                } else {
                  setState(() {
                    selectedPayment = 'Cash';
                  });

                  _showStillInsufficientAMiNiBalance(fare);
                }
              }
            }
          }
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 54,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF0D000)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF0D000)
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isSelected ? 0.08 : 0.04,
                ),
                blurRadius: isSelected ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: Colors.black87,
              ),

              const SizedBox(width: 8),

              Text(
                method,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              if (isSelected) ...[
                const SizedBox(width: 6),

                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: Colors.black,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}


Widget _walletAmountRow({
  required String label,
  required String amount,
  bool bold = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 13,
          fontWeight: bold
              ? FontWeight.w700
              : FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),

      Text(
        amount,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    ],
  );
}





  double _deg2rad(double deg) => deg * (pi / 180);

  void _moveCameraToBounds(LatLng pickup, LatLng destination) {
    final southwest = LatLng(
      min(pickup.latitude, destination.latitude),
      min(pickup.longitude, destination.longitude),
    );
    final northeast = LatLng(
      max(pickup.latitude, destination.latitude),
      max(pickup.longitude, destination.longitude),
    );

    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    ); // padding of 100
  }

  double _initialZoom = 14.0; // your fixed zoom
  LatLngBounds? _bounds;

  void _initMap(LatLng pickup, LatLng destination) async {
    if (_mapController == null) return;

    // Calculate bounds with small horizontal padding to keep from/to fully visible horizontally
    final bounds = LatLngBounds(
      southwest: LatLng(
        min(pickup.latitude, destination.latitude),
        min(pickup.longitude, destination.longitude),
      ),
      northeast: LatLng(
        max(pickup.latitude, destination.latitude),
        max(pickup.longitude, destination.longitude),
      ),
    );

    _bounds = bounds;

    // Move camera to show bounds with fixed padding once
    await _mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds, 50));

    // Fix zoom level
    await _mapController!.moveCamera(CameraUpdate.zoomTo(_initialZoom));
  }

  double _lastScrollFraction = 0;

  void onDraggableScroll(double scrollFraction) {
    if (_mapController == null || _bounds == null) return;

    // Only update if fraction changes meaningfully
    if ((_lastScrollFraction - scrollFraction).abs() < 0.01) return;
    _lastScrollFraction = scrollFraction;

    // Map visible area adjusts with bottom sheet
    // fraction = 0 minimized, 1 fully expanded
    final bottomPadding =
        100 + 250 * scrollFraction; // tweak 250 to sheet height range

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(_bounds!, bottomPadding),
    );
  }

  Widget _badge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF015ACE),
        //Colors.blue, 
        
        // ⬅️ blue background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white, // ⬅️ white text
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

     // 🔹 Expanded Select/Book Button
                              
                              
                              // Consumer(
                              //   builder: (context, ref, child) {
                              //     final selected = ref.watch(
                              //       selectedCategoryProvider,
                              //     );
                              //     final category = selected?.name ?? 'N/A';
                              //     final categoryId = selected?.id ?? 0;
                              //     final isEnabled =
                              //         category.toString().isNotEmpty;

                              //     return SizedBox(
                              //       width: double.infinity,
                              //       child: ElevatedButton(
                              //         onPressed:
                              //             isEnabled
                              //                 ? () {
                              //                   // Payment validations
                              //                   if (selectedPayment ==
                              //                           'AMiNi' &&
                              //                       appBalance < selectedFare) {
                              //                     showDialog(
                              //                       context: context,
                              //                       builder:
                              //                           (
                              //                             _,
                              //                           ) => const AlertDialog(
                              //                             title: Text(
                              //                               'Insufficient Balance',
                              //                             ),
                              //                             content: Text(
                              //                               'You do not have enough funds in your AMiNi wallet. Please top up.',
                              //                             ),
                              //                           ),
                              //                     );
                              //                     return;
                              //                   }

                              //                   if (selectedPayment == 'Visa' &&
                              //                       !hasVisaCard) {
                              //                     showDialog(
                              //                       context: context,
                              //                       builder:
                              //                           (
                              //                             _,
                              //                           ) => const AlertDialog(
                              //                             title: Text(
                              //                               'No Visa Card Added',
                              //                             ),
                              //                             content: Text(
                              //                               'You have not added a Visa card. Please add one to continue.',
                              //                             ),
                              //                           ),
                              //                     );
                              //                     return;
                              //                   }

                              //                   Navigator.push(
                              //                     context,
                              //                     MaterialPageRoute(
                              //                       builder:
                              //                           (
                              //                             _,
                              //                           ) => ConfirmRideScreen(
                              //                             pickup:
                              //                                 widget.pickup!,
                              //                             fare: selectedFare,
                              //                             destination:
                              //                                 widget
                              //                                     .destination!,
                              //                             category: categoryId,
                              //                             optionSelected:
                              //                                 category,
                              //                             isScheduled:
                              //                                 widget
                              //                                     .isScheduled,
                              //                             scheduledDate:
                              //                                 widget
                              //                                     .scheduledDate,
                              //                           ),
                              //                     ),
                              //                   );
                              //                 }
                              //                 : null,
                              //         style: ElevatedButton.styleFrom(
                              //          // backgroundColor: Colors.blue,

                              //           backgroundColor: const Color(0xFF015ACE),
                              //           padding: const EdgeInsets.symmetric(
                              //             vertical: 16,
                              //           ),
                              //           shape: RoundedRectangleBorder(
                              //             borderRadius: BorderRadius.circular(
                              //               12,
                              //             ),
                              //           ),
                              //         ),
                              //         child: Text(
                              //           (widget.isScheduled == true &&
                              //                   isEnabled)
                              //               ? "Book $category"
                              //               : "Select ${category ?? 'Category'}",
                              //           style: const TextStyle(
                              //             fontSize: 17,
                              //             color: Colors.white,
                              //           ),
                              //         ),
                              //       ),
                              //     );
                              //   },
                              // ),