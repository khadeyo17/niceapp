import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class RideDetailsScreen extends StatefulWidget {
  final RideHistory ride;

  const RideDetailsScreen({super.key, required this.ride});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  GoogleMapController? _mapController;
  List<LatLng> routePoints = [];
  double? routeDistance;
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    final pickup = LatLng(
      widget.ride.pickupLatitude,
      widget.ride.pickupLongitude,
    );
    final destination = LatLng(
      widget.ride.destinationLatitude,
      widget.ride.destinationLongitude,
    );
    updateRoute(pickup, destination);
    //fetchRoute();
  }

  Future<void> generateAndPrintReceipt() async {
    final pdf = pw.Document();
    final ride = widget.ride;

    // Load the logo
    final logoBytes = await rootBundle.load('assets/imgs/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo and Title
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Image(logoImage, height: 60),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        "Ride Receipt",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Divider(),
                    ],
                  ),
                ),

                // Pickup & Destination
                pw.SizedBox(height: 12),
                pw.Text(
                  "Trip Summary",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "From:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        ride.pickupLocation,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "To:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        ride.destination,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                pw.Text(
                  "Details",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                // Trip Details Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Ride Category",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(ride.subCategory.toString()),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Driver Name",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(ride.contactName.toString()),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Rating",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            ride.rating?.toStringAsFixed(1) ?? "N/A",
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Fare",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("KES ${ride.fare.toStringAsFixed(0)}"),
                        ),
                      ],
                    ),
                    if (routeDistance != null)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              "Distance",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              "${routeDistance!.toStringAsFixed(2)} km",
                            ),
                          ),
                        ],
                      ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            "Date",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            ride.dropoffTime
                                    ?.toLocal()
                                    .toString()
                                    .split('.')
                                    .first ??
                                'N/A',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 24),
                pw.Center(
                  child: pw.Text(
                    "Thank you for riding with Amini!",
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // await Printing.layoutPdf(
    //   onLayout: (PdfPageFormat format) async => pdf.save(),
    // );
  }

  Future<List<LatLng>> fetchGoogleRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    // final apiKey = 'YOUR_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$mapKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final steps = data['routes'][0]['legs'][0]['steps'] as List;
        List<LatLng> route = [];

        for (var step in steps) {
          final polyline = step['polyline']['points'];
          route.addAll(decodePolyline(polyline));
        }
        return route;
      }
    }
    return [];
  }

  List<LatLng> decodePolyline(String encoded) {
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

  // List<LatLng> routePoints = [];

  void updateRoute(LatLng origin, LatLng destination) async {
    final points = await fetchGoogleRoute(origin, destination);
    if (mounted && points.isNotEmpty) {
      // Calculate distance in km between route points
      double totalDistance = 0;
      for (int i = 0; i < points.length - 1; i++) {
        totalDistance += _calculateDistance(points[i], points[i + 1]);
      }

      setState(() {
        routePoints = points;
        routeDistance = totalDistance;
        polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ),
        };
        // Optionally: move camera to show whole route
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList([origin, destination]),
            50,
          ),
        );
      });
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371; // km
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Utility to get bounds for camera update
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list[0].latitude;
    double x1 = list[0].latitude;
    double y0 = list[0].longitude;
    double y1 = list[0].longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(
      widget.ride.pickupLatitude,
      widget.ride.pickupLongitude,
    );
    final destination = LatLng(
      widget.ride.destinationLatitude,
      widget.ride.destinationLongitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride Details"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: pickup,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              },
              polylines: polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          // Ride Info Section - same as your existing code, just UI widgets
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup and Dropoff UI (same as your existing code)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: const [
                            Icon(Icons.circle, size: 12, color: Colors.green),
                            SizedBox(height: 4),
                            Icon(Icons.arrow_downward, color: Colors.grey),
                            SizedBox(height: 4),
                            Icon(Icons.location_pin, color: Colors.red),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ride.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.ride.destination,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ride Category: ${widget.ride.subCategory}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const Divider(height: 24),
                            Text(
                              "Driver: ${widget.ride.contactName}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  "Rating: ",
                                  style: TextStyle(fontSize: 16),
                                ),
                                Icon(Icons.star, color: Colors.amber[700]),
                                Text(
                                  widget.ride.rating?.toStringAsFixed(1) ??
                                      "N/A",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Fare: KES ${widget.ride.fare.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            if (routeDistance != null)
                              Text(
                                "Distance: ${routeDistance!.toStringAsFixed(2)} km",
                                style: const TextStyle(fontSize: 16),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              "Date: ${widget.ride.dropoffTime?.toLocal().toString().split('.').first ?? 'N/A'}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Receipt",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[900],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: generateAndPrintReceipt,
                            icon: const Icon(Icons.receipt_long),
                            label: const Text("Print Receipt"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Lost item reported!"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.report_problem),
                            label: const Text("Report Lost Item"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// //import 'package:printing/printing.dart';

// class RideDetailsScreen extends StatefulWidget {
//   final RideHistory ride;

//   const RideDetailsScreen({super.key, required this.ride});

//   @override
//   State<RideDetailsScreen> createState() => _RideDetailsScreenState();
// }

// class _RideDetailsScreenState extends State<RideDetailsScreen> {
//   final MapController _mapController = MapController();
//   List<LatLng> routePoints = [];
//   double? routeDistance;

//   @override
//   void initState() {
//     super.initState();
//     fetchRoute();
//   }

//   Future<void> generateAndPrintReceipt() async {
//     final pdf = pw.Document();
//     final ride = widget.ride;

//     // Load the logo
//     final logoBytes = await rootBundle.load('assets/imgs/logo.png');
//     final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

//     pdf.addPage(
//       pw.Page(
//         build: (context) {
//           return pw.Padding(
//             padding: const pw.EdgeInsets.all(24),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 // Logo and Title
//                 pw.Center(
//                   child: pw.Column(
//                     children: [
//                       pw.Image(logoImage, height: 60),
//                       pw.SizedBox(height: 12),
//                       pw.Text(
//                         "Ride Receipt",
//                         style: pw.TextStyle(
//                           fontSize: 22,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.black,
//                         ),
//                       ),
//                       pw.SizedBox(height: 16),
//                       pw.Divider(),
//                     ],
//                   ),
//                 ),

//                 // Pickup & Destination
//                 pw.SizedBox(height: 12),
//                 pw.Text(
//                   "Trip Summary",
//                   style: pw.TextStyle(
//                     fontSize: 16,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 10),
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text(
//                       "From:",
//                       style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                     ),
//                     pw.Expanded(
//                       child: pw.Text(
//                         ride.pickupLocation,
//                         textAlign: pw.TextAlign.right,
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 5),
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text(
//                       "To:",
//                       style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                     ),
//                     pw.Expanded(
//                       child: pw.Text(
//                         ride.destination,
//                         textAlign: pw.TextAlign.right,
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 10),

//                 pw.Text(
//                   "Details",
//                   style: pw.TextStyle(
//                     fontSize: 16,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 8),

//                 // Trip Details Table
//                 pw.Table(
//                   border: pw.TableBorder.all(color: PdfColors.grey),
//                   children: [
//                     pw.TableRow(
//                       children: [
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             "Ride Category",
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(ride.subCategory.toString()),
//                         ),
//                       ],
//                     ),
//                     pw.TableRow(
//                       children: [
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             "Driver Name",
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(ride.contactName.toString()),
//                         ),
//                       ],
//                     ),
//                     pw.TableRow(
//                       children: [
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             "Rating",
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             ride.rating?.toStringAsFixed(1) ?? "N/A",
//                           ),
//                         ),
//                       ],
//                     ),
//                     pw.TableRow(
//                       children: [
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             "Fare",
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text("KES ${ride.fare.toStringAsFixed(0)}"),
//                         ),
//                       ],
//                     ),
//                     if (routeDistance != null)
//                       pw.TableRow(
//                         children: [
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(8),
//                             child: pw.Text(
//                               "Distance",
//                               style: pw.TextStyle(
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(8),
//                             child: pw.Text(
//                               "${routeDistance!.toStringAsFixed(2)} km",
//                             ),
//                           ),
//                         ],
//                       ),
//                     pw.TableRow(
//                       children: [
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             "Date",
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                           ),
//                         ),
//                         pw.Padding(
//                           padding: const pw.EdgeInsets.all(8),
//                           child: pw.Text(
//                             ride.dropoffTime
//                                     ?.toLocal()
//                                     .toString()
//                                     .split('.')
//                                     .first ??
//                                 'N/A',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 pw.SizedBox(height: 24),
//                 pw.Center(
//                   child: pw.Text(
//                     "Thank you for riding with Amini!",
//                     style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );

//     // await Printing.layoutPdf(
//     //   onLayout: (PdfPageFormat format) async => pdf.save(),
//     // );
//   }

//   //assets/images/logo.png
//   Future<void> fetchRoute() async {
//     final pickup = LatLng(
//       widget.ride.pickupLatitude,
//       widget.ride.pickupLongitude,
//     );
//     final destination = LatLng(
//       widget.ride.destinationLatitude,
//       widget.ride.destinationLongitude,
//     );

//     final url =
//         'http://router.project-osrm.org/route/v1/driving/${pickup.longitude},${pickup.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

//     final res = await http.get(Uri.parse(url));
//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);
//       final coords = data['routes'][0]['geometry']['coordinates'] as List;
//       final distance = data['routes'][0]['distance'];
//       final points = coords.map((c) => LatLng(c[1], c[0])).toList();

//       if (mounted) {
//         setState(() {
//           routePoints = points;
//           routeDistance = distance / 1000;

//           _mapController.fitBounds(
//             LatLngBounds.fromPoints([pickup, destination]),
//             options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
//           );
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pickup = LatLng(
//       widget.ride.pickupLatitude,
//       widget.ride.pickupLongitude,
//     );
//     final destination = LatLng(
//       widget.ride.destinationLatitude,
//       widget.ride.destinationLongitude,
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Ride Details"),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: Column(
//         children: [
//           // Map Section
//           Expanded(
//             flex: 2,
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(center: pickup, zoom: 13),
//               children: [
//                 TileLayer(
//                   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                   userAgentPackageName: 'com.example.niceapp',
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: pickup,
//                       width: 40,
//                       height: 40,
//                       builder:
//                           (_) => const Icon(
//                             Icons.location_pin,
//                             color: Colors.green,
//                             size: 40,
//                           ),
//                     ),
//                     Marker(
//                       point: destination,
//                       width: 40,
//                       height: 40,
//                       builder:
//                           (_) => const Icon(
//                             Icons.flag,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                     ),
//                     if (routePoints.isNotEmpty && routeDistance != null)
//                       Marker(
//                         point: routePoints[routePoints.length ~/ 2],
//                         builder:
//                             (_) => Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: Colors.black87,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 "${routeDistance!.toStringAsFixed(2)} km",
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                       ),
//                   ],
//                 ),
//                 if (routePoints.isNotEmpty)
//                   PolylineLayer(
//                     polylines: [
//                       Polyline(
//                         points: routePoints,
//                         strokeWidth: 4.0,
//                         color: Colors.blueAccent,
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),

//           // Ride Info Section
//           Expanded(
//             flex: 3,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               color: Colors.grey[100],
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Pickup and Dropoff UI
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Column(
//                         children: const [
//                           Icon(Icons.circle, size: 12, color: Colors.green),
//                           SizedBox(height: 4),
//                           Icon(Icons.arrow_downward, color: Colors.grey),
//                           SizedBox(height: 4),
//                           Icon(Icons.location_pin, color: Colors.red),
//                         ],
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.ride.pickupLocation,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               widget.ride.destination,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 2,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 16,
//                         horizontal: 20,
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Ride Category: ${widget.ride.subCategory}",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.deepPurple,
//                             ),
//                           ),
//                           const Divider(height: 24),

//                           Text(
//                             "Driver: ${widget.ride.contactName}",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(height: 8),

//                           Row(
//                             children: [
//                               const Text(
//                                 "Rating: ",
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                               Icon(Icons.star, color: Colors.amber[700]),
//                               Text(
//                                 widget.ride.rating?.toStringAsFixed(1) ?? "N/A",
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),

//                           Text(
//                             "Fare: KES ${widget.ride.fare.toStringAsFixed(0)}",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(height: 8),

//                           if (routeDistance != null)
//                             Text(
//                               "Distance: ${routeDistance!.toStringAsFixed(2)} km",
//                               style: const TextStyle(fontSize: 16),
//                             ),

//                           const SizedBox(height: 8),
//                           Text(
//                             "Date: ${widget.ride.dropoffTime?.toLocal().toString().split('.').first ?? 'N/A'}",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                           const SizedBox(height: 16),

//                           const Text(
//                             "Receipt",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   //  const Spacer(),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blueGrey[900],
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                           ),
//                           onPressed: () {
//                             generateAndPrintReceipt();
//                           },
//                           icon: const Icon(Icons.receipt_long),
//                           label: const Text("Print Receipt"),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.black,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                           ),
//                           onPressed: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text("Lost item reported!"),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.report_problem),
//                           label: const Text("Report Lost Item"),
//                         ),
//                       ),
//                     ],
//                   ),

//                   // Center(
//                   //   child: ElevatedButton.icon(
//                   //     style: ElevatedButton.styleFrom(
//                   //       backgroundColor: Colors.blueGrey[900],
//                   //       foregroundColor: Colors.white,
//                   //       shape: RoundedRectangleBorder(
//                   //         borderRadius: BorderRadius.circular(8),
//                   //       ),
//                   //       padding: const EdgeInsets.symmetric(
//                   //         horizontal: 24,
//                   //         vertical: 12,
//                   //       ),
//                   //     ),
//                   //     onPressed: () {
//                   //       generateAndPrintReceipt(); // 🔗 Hooked here
//                   //     },
//                   //     icon: const Icon(Icons.receipt_long),
//                   //     label: const Text("Print Receipt"),
//                   //   ),
//                   // ),

//                   // Center(
//                   //   child: ElevatedButton.icon(
//                   //     style: ElevatedButton.styleFrom(
//                   //       backgroundColor: Colors.black,
//                   //       foregroundColor: Colors.white,
//                   //       shape: RoundedRectangleBorder(
//                   //         borderRadius: BorderRadius.circular(8),
//                   //       ),
//                   //       padding: const EdgeInsets.symmetric(
//                   //         horizontal: 24,
//                   //         vertical: 12,
//                   //       ),
//                   //     ),
//                   //     onPressed: () {
//                   //       // Handle lost item report
//                   //       ScaffoldMessenger.of(context).showSnackBar(
//                   //         const SnackBar(content: Text("Lost item reported!")),
//                   //       );
//                   //     },
//                   //     icon: const Icon(Icons.report_problem),
//                   //     label: const Text("Report Lost Item"),
//                   //   ),
//                   // ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:latlong2/latlong.dart';
// // import 'package:niceapp/View/Screens/Vehicles/ride_history_model.dart';

// // class RideDetailsScreen extends StatefulWidget {
// //   final RideHistory ride;

// //   const RideDetailsScreen({super.key, required this.ride});

// //   @override
// //   State<RideDetailsScreen> createState() => _RideDetailsScreenState();
// // }

// // class _RideDetailsScreenState extends State<RideDetailsScreen> {
// //   final MapController _mapController = MapController();
// //   List<LatLng> routePoints = [];
// //   double? routeDistance;

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchRoute();
// //   }

// //   Future<void> fetchRoute() async {
// //     final pickup = LatLng(
// //       widget.ride.pickupLatitude,
// //       widget.ride.pickupLongitude,
// //     );
// //     final destination = LatLng(
// //       widget.ride.destinationLatitude,
// //       widget.ride.destinationLongitude,
// //     );

// //     final url =
// //         'http://router.project-osrm.org/route/v1/driving/${pickup.longitude},${pickup.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

// //     final res = await http.get(Uri.parse(url));

// //     if (res.statusCode == 200) {
// //       final data = jsonDecode(res.body);
// //       final coords = data['routes'][0]['geometry']['coordinates'] as List;
// //       final distance = data['routes'][0]['distance']; // in meters

// //       final points = coords.map((c) => LatLng(c[1], c[0])).toList();

// //       if (mounted) {
// //         setState(() {
// //           routePoints = points;
// //           routeDistance = distance / 1000; // convert to KM

// //           // Auto-zoom to fit bounds
// //           _mapController.fitBounds(
// //             LatLngBounds.fromPoints([pickup, destination]),
// //             options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
// //           );
// //         });
// //       }
// //     } else {
// //       debugPrint("Failed to fetch route: ${res.statusCode}");
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final pickup = LatLng(
// //       widget.ride.pickupLatitude,
// //       widget.ride.pickupLongitude,
// //     );
// //     final destination = LatLng(
// //       widget.ride.destinationLatitude,
// //       widget.ride.destinationLongitude,
// //     );

// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Ride Details")),
// //       body: Column(
// //         children: [
// //           // Map section
// //           Expanded(
// //             flex: 2,
// //             child: FlutterMap(
// //               mapController: _mapController,
// //               options: MapOptions(center: pickup, zoom: 13),
// //               children: [
// //                 TileLayer(
// //                   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
// //                   userAgentPackageName: 'com.example.niceapp',
// //                 ),
// //                 MarkerLayer(
// //                   markers: [
// //                     Marker(
// //                       point: pickup,
// //                       width: 40,
// //                       height: 40,
// //                       builder:
// //                           (_) => const Icon(
// //                             Icons.location_pin,
// //                             color: Colors.green,
// //                             size: 40,
// //                           ),
// //                     ),
// //                     Marker(
// //                       point: destination,
// //                       width: 40,
// //                       height: 40,
// //                       builder:
// //                           (_) => const Icon(
// //                             Icons.flag,
// //                             color: Colors.red,
// //                             size: 40,
// //                           ),
// //                     ),
// //                     if (routePoints.isNotEmpty && routeDistance != null)
// //                       Marker(
// //                         point: routePoints[routePoints.length ~/ 2],
// //                         builder:
// //                             (_) => Container(
// //                               padding: const EdgeInsets.all(6),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.black87,
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                               child: Text(
// //                                 "${routeDistance!.toStringAsFixed(2)} km",
// //                                 style: const TextStyle(
// //                                   color: Colors.white,
// //                                   fontSize: 12,
// //                                 ),
// //                               ),
// //                             ),
// //                       ),
// //                   ],
// //                 ),
// //                 if (routePoints.isNotEmpty)
// //                   PolylineLayer(
// //                     polylines: [
// //                       Polyline(
// //                         points: routePoints,
// //                         strokeWidth: 4.0,
// //                         color: Colors.blueAccent,
// //                       ),
// //                     ],
// //                   ),
// //               ],
// //             ),
// //           ),

// //           // Ride details
// //           Expanded(
// //             flex: 3,
// //             child: ListView(
// //               padding: const EdgeInsets.all(16),
// //               children: [
// //                 Text("From: ${widget.ride.pickupLocation}"),
// //                 Text("To: ${widget.ride.destination}"),
// //                 Text("Fare: KES ${widget.ride.fare.toStringAsFixed(0)}"),
// //                 Text("Driver: ${widget.ride.contactName}"),
// //                 Text(
// //                   "Date: ${widget.ride.dropoffTime?.toLocal().toString().split('.').first ?? 'N/A'}",
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }