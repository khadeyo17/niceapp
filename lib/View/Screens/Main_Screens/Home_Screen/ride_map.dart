import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';

class RideMap extends StatefulWidget {
  final LatLng? pickup;
  final LatLng? destination;
  //final String googleApiKey;

  const RideMap({
    super.key,
    this.pickup,
    this.destination,
    //required this.googleApiKey,
  });

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double? _routeDistance;
  LatLng? _currentLocation;
  LatLng _initialFallback = const LatLng(-1.286389, 36.817223);

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
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
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _setInitialMarkers();
    if (widget.destination != null) {
      _getRoute();
    }
  }

  void _setInitialMarkers() {
    final pickupPos = widget.pickup ?? _currentLocation;
    if (pickupPos != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (widget.destination != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    void _setInitialMarkers() {
      final pickupPos = widget.pickup ?? _currentLocation;
      if (pickupPos != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
      if (widget.destination != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      // ✅ Fit camera immediately if both are available
      if (pickupPos != null && widget.destination != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds([pickupPos, widget.destination!]);
        });
      }
    }

    // // ✅ Fit camera to both markers if available
    // if (pickupPos != null && widget.destination != null) {
    //   _fitBounds([pickupPos, widget.destination!]);
    // }
  }

  Future<void> _getRoute() async {
    final pickupPos = widget.pickup ?? _currentLocation;
    if (pickupPos == null || widget.destination == null) return;

    final start = '${pickupPos.latitude},${pickupPos.longitude}';
    final end =
        '${widget.destination!.latitude},${widget.destination!.longitude}';

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$start&destination=$end&mode=driving&key=$mapKey';
    //{widget.googleApiKey}
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final polylinePoints = _decodePolyline(
          route['overview_polyline']['points'],
        );
        final distanceMeters = route['legs'][0]['distance']['value'];

        setState(() {
          _routeDistance = distanceMeters / 1000; // in KM
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 4,
              points: polylinePoints,
            ),
          };
        });

        _fitBounds(polylinePoints);
      } else {
        debugPrint('Google Directions API error: ${data['status']}');
      }
    } else {
      debugPrint('HTTP error: ${res.statusCode}');
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    // Wait until we have either a pickup or current location before showing map
    // if (widget.pickup == null && _currentLocation == null) {
    //   return const Center(child: CircularProgressIndicator());
    // }
    final initialPos = widget.pickup ?? _currentLocation ?? _initialFallback;

    // final initialPos = widget.pickup ?? _currentLocation!;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialPos, zoom: 13),
          onMapCreated: (controller) => _mapController = controller,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        if (_routeDistance != null)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_routeDistance!.toStringAsFixed(2)} km",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
