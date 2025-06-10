import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/favorite_location_model.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/favorite_location_service.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

class WhereToScreen extends ConsumerStatefulWidget {
  const WhereToScreen({super.key});

  @override
  ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends ConsumerState<WhereToScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _selectingPickup = false;
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    final pickup = ref.read(pickupLocationProvider);
    if (pickup != null) {
      pickupController.text = "Pickup location set";
    }

    pickupController.addListener(_onSearchChanged);
    destinationController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text =
        _selectingPickup ? pickupController.text : destinationController.text;
    if (text.trim().isEmpty) return;
    _fetchSuggestions(text);
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoading = true;
      _suggestions.clear();
    });

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
    );
    final res = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() {
        _suggestions = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      _showError("Suggestion fetch failed");
    }
  }

  // void _onSuggestionTap(Map<String, dynamic> place) {
  //   final lat = double.parse(place['lat']);
  //   final lon = double.parse(place['lon']);
  //   final latLng = LatLng(lat, lon);

  //   setState(() {
  //     if (_selectingPickup) {
  //       ref.read(pickupLocationProvider.notifier).state = latLng;
  //       pickupController.text = place['display_name'];
  //     } else {
  //       ref.read(destinationLocationProvider.notifier).state = latLng;
  //       destinationController.text = place['display_name'];
  //     }
  //     _suggestions.clear();
  //   });
  // }

  // void _onSuggestionTap(Map<String, dynamic> place) {
  //   final lat = double.parse(place['lat']);
  //   final lon = double.parse(place['lon']);
  //   final latLng = LatLng(lat, lon);
  //   final displayName = place['display_name'];

  //   setState(() {
  //     if (_selectingPickup) {
  //       ref.read(pickupLocationProvider.notifier).state = latLng;
  //       pickupController.text = displayName;
  //     } else {
  //       ref.read(destinationLocationProvider.notifier).state = latLng;
  //       destinationController.text = displayName;

  //       // After selecting destination, treat it like Uber stop
  //       _addStop(place);
  //     }
  //     _suggestions.clear();
  //   });
  // }

  // void _onSuggestionTap(Map<String, dynamic> place) {
  //   final lat = double.parse(place['lat']);
  //   final lon = double.parse(place['lon']);
  //   final latLng = LatLng(lat, lon);
  //   final displayName = place['display_name'];

  //   setState(() {
  //     _selectedPlace = place;

  //     if (_selectingPickup) {
  //       ref.read(pickupLocationProvider.notifier).state = latLng;
  //       pickupController.text = displayName;
  //     } else {
  //       destinationController.text = displayName;
  //     }

  //     _suggestions.clear();
  //   });
  // }
  // void _onSuggestionTap(Map<String, dynamic> place) {
  //   final lat = double.parse(place['lat']);
  //   final lon = double.parse(place['lon']);
  //   final latLng = LatLng(lat, lon);
  //   final displayName = place['display_name'];

  //   final pickup = ref.read(pickupLocationProvider);

  //   setState(() {
  //     _selectedPlace = place;
  //     _suggestions.clear();
  //   });

  //   if (_selectingPickup) {
  //     ref.read(pickupLocationProvider.notifier).state = latLng;
  //     pickupController.text = displayName;
  //   } else {
  //     ref.read(destinationLocationProvider.notifier).state = latLng;
  //     destinationController.text = displayName;

  //     // If pickup is set, proceed to HomeScreen automatically
  //     if (pickup != null) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder:
  //               (_) => HomeScreen(
  //                 pickup: pickup,
  //                 destination: latLng,
  //                 stops: ref.read(stopsProvider),
  //               ),
  //         ),
  //       );
  //     } else {
  //       _showError("Please set pickup location first.");
  //     }
  //   }
  // }

  void _onSuggestionTap(Map<String, dynamic> place) async {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final displayName = place['display_name'];

    final latLng = LatLng(lat, lon);

    setState(() {
      _selectedPlace = place;
      _suggestions.clear();
    });

    final favorite = FavoriteLocation(name: displayName, lat: lat, lon: lon);
    await FavoriteLocationService.addFavorite(favorite);
    //_showMessage("Added to favorites");

    if (_selectingPickup) {
      ref.read(pickupLocationProvider.notifier).state = latLng;
      pickupController.text = displayName;
    } else {
      ref.read(destinationLocationProvider.notifier).state = latLng;
      destinationController.text = displayName;

      final pickup = ref.read(pickupLocationProvider);
      if (pickup != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => HomeScreen(
                  pickup: pickup,
                  destination: latLng,
                  stops: ref.read(stopsProvider),
                ),
          ),
        );
      } else {
        _showError("Please set pickup location first.");
      }
    }
  }

  // void _addStop() {
  //   final destination = ref.read(destinationLocationProvider);
  //   if (destination == null) {
  //     _showError("Select destination first.");
  //     return;
  //   }
  //   final stops = ref.read(stopsProvider);
  //   if (!stops.contains(destination)) {
  //     ref.read(stopsProvider.notifier).state = [...stops, destination];
  //     _showMessage("Stop added.");
  //   } else {
  //     _showError("This stop is already added.");
  //   }
  // }

  // void _saveLocation() {
  //   final pickup = ref.read(pickupLocationProvider);
  //   final destination = ref.read(destinationLocationProvider);

  //   if (pickup != null && destination != null) {
  //     context.go('/select_route');
  //   } else {
  //     _showError('Please select both pickup and destination.');
  //   }
  // }

  // void _addToFavourites(String name, LatLng latLng) {
  //   final favourites = ref.read(favouriteLocationsProvider);
  //   final newFav = FavouriteLocation(
  //     name: name,
  //     latitude: latLng.latitude,
  //     longitude: latLng.longitude,
  //   );

  //   final isDuplicate = favourites.any(
  //     (fav) =>
  //         fav.latitude == latLng.latitude && fav.longitude == latLng.longitude,
  //   );

  //   if (isDuplicate) {
  //     _showError("Location already in favourites.");
  //     return;
  //   }

  //   ref.read(favouriteLocationsProvider.notifier).state = [
  //     ...favourites,
  //     newFav,
  //   ];
  //   _showMessage("Location saved to favourites.");
  // }

  void _addStop(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final latLng = LatLng(lat, lon);
    final address = place['display_name'];

    final currentStops = ref.read(stopsProvider);

    final isDuplicate = currentStops.any(
      (stop) =>
          stop['latLng'].latitude == lat && stop['latLng'].longitude == lon,
    );

    if (isDuplicate) {
      _showError("This stop is already added.");
      return;
    }

    ref.read(stopsProvider.notifier).state = [
      ...currentStops,
      {'latLng': latLng, 'address': address},
    ];
    _showMessage("Stop added.");
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final stops = ref.watch(stopsProvider);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Where to?", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.my_location, color: Colors.green),
                    title: TextField(
                      controller: pickupController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Set Pickup Location",
                      ),
                      onTap: () {
                        setState(() {
                          _selectingPickup = true;
                          _suggestions.clear();
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Destination",
                      ),
                      onTap: () {
                        setState(() {
                          _selectingPickup = false;
                          _suggestions.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (_, index) {
                    final place = _suggestions[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place['display_name']),
                        onTap: () => _onSuggestionTap(place),
                      ),
                    );
                  },
                ),
              ),
            if (_suggestions.isEmpty)
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: stops.length,
              //     itemBuilder: (_, index) {
              //       final stop = stops[index];
              //       return ListTile(
              //         leading: const Icon(
              //           Icons.stop_circle,
              //           color: Colors.orange,
              //         ),
              //         title: Text(
              //           'Stop ${index + 1}: ${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
              //         ),
              //       );
              //     },
              //   ),
              // ),
              Expanded(
                child: ListView.builder(
                  itemCount: stops.length,
                  itemBuilder: (_, index) {
                    final stop = stops[index];
                    final latLng = stop['latLng'] as LatLng;
                    final address = stop['address'] as String;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(address),
                      subtitle: Text(
                        '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          final updatedStops = [...stops]..removeAt(index);
                          ref.read(stopsProvider.notifier).state = updatedStops;
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: () {
                //       if (_selectedPlace != null) {
                //         _addStop(_selectedPlace!);
                //         _selectedPlace = null;
                //       } else {
                //         _showError(
                //           "Please select a place from suggestions first.",
                //         );
                //       }
                //     },
                //     icon: const Icon(Icons.add),
                //     label: const Text("Add Stop"),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.orange[800],
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 10),
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: _confirmRouteAndGoToHome,
                //     icon: const Icon(Icons.check),
                //     label: const Text("Confirm & Go"),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.blue,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// // import 'package:vicsacs/constants/constants.dart';
// // import 'package:vicsacs/providers/location_providers.dart';
// // import 'package:vicsacs/screens/passenger/home/confirm_location_screen.dart';
// // import 'package:vicsacs/theme/palette.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupController = TextEditingController();
//   final TextEditingController destinationController = TextEditingController();
//   final FocusNode destinationFocusNode = FocusNode();
//   List<Map<String, dynamic>> _suggestions = [];
//   bool _selectingPickup = true;

//   Future<void> _searchLocation(String input) async {
//     if (input.isEmpty) {
//       setState(() {
//         _suggestions = [];
//       });
//       return;
//     }
//     final url =
//         'https://nominatim.openstreetmap.org/search?q=$input&format=json&addressdetails=1&limit=5';
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(response.body);
//       setState(() {
//         _suggestions = List<Map<String, dynamic>>.from(data);
//       });
//     }
//   }

//   void _onSuggestionTap(Map<String, dynamic> place) {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final latLng = LatLng(lat, lon);
//     final displayName = place['display_name'];

//     setState(() {
//       if (_selectingPickup) {
//         ref.read(pickupLocationProvider.notifier).state = latLng;
//         pickupController.text = displayName;
//       } else {
//         ref.read(destinationLocationProvider.notifier).state = latLng;
//         destinationController.text = displayName;
//         _addStop(place);
//       }
//       _suggestions.clear();
//     });
//   }

//   void _addStop(Map<String, dynamic> place) {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final latLng = LatLng(lat, lon);
//     final address = place['display_name'];

//     final currentStops = ref.read(stopsProvider);
//     final isDuplicate = currentStops.any(
//       (stop) =>
//           stop['latLng'].latitude == lat && stop['latLng'].longitude == lon,
//     );

//     if (isDuplicate) {
//       _showError("This stop is already added.");
//       return;
//     }

//     ref.read(stopsProvider.notifier).state = [
//       ...currentStops,
//       {'latLng': latLng, 'address': address},
//     ];
//     _showMessage("Stop added.");
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.green),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final stops = ref.watch(stopsProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Where to?'),
//         backgroundColor: Colors.yellow, //Pallete.yellowColor,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: pickupController,
//               decoration: const InputDecoration(
//                 labelText: 'Pickup Location',
//                 prefixIcon: Icon(Icons.my_location),
//               ),
//               onTap: () => setState(() => _selectingPickup = true),
//               onChanged: _searchLocation,
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: destinationController,
//               focusNode: destinationFocusNode,
//               decoration: const InputDecoration(
//                 labelText: 'Destination',
//                 prefixIcon: Icon(Icons.location_on),
//               ),
//               onTap: () => setState(() => _selectingPickup = false),
//               onChanged: _searchLocation,
//             ),
//             const SizedBox(height: 10),
//             if (_suggestions.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _suggestions.length,
//                   itemBuilder: (context, index) {
//                     final suggestion = _suggestions[index];
//                     return ListTile(
//                       title: Text(suggestion['display_name'] ?? ''),
//                       onTap: () => _onSuggestionTap(suggestion),
//                     );
//                   },
//                 ),
//               )
//             else if (stops.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: stops.length,
//                   itemBuilder: (_, index) {
//                     final stop = stops[index];
//                     final latLng = stop['latLng'] as LatLng;
//                     final address = stop['address'] as String;

//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.blue,
//                         child: Text('${index + 1}'),
//                       ),
//                       title: Text(address),
//                       subtitle: Text(
//                         '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(
//                           Icons.remove_circle,
//                           color: Colors.red,
//                         ),
//                         onPressed: () {
//                           final updatedStops = [...stops]..removeAt(index);
//                           ref.read(stopsProvider.notifier).state = updatedStops;
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 if (ref.read(pickupLocationProvider) == null ||
//                     ref.read(destinationLocationProvider) == null) {
//                   _showError('Please select both pickup and destination.');
//                   return;
//                 }
//                 context.go('/confirm-location');
//               },
//               child: const Text('Confirm'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     pickupController.dispose();
//     destinationController.dispose();
//     destinationFocusNode.dispose();
//     super.dispose();
//   }
// }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';

// import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/home_screen.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/favorite_location_model.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/favorite_location_service.dart';
// import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/location_providers.dart';

// class WhereToScreen extends ConsumerStatefulWidget {
//   const WhereToScreen({super.key});

//   @override
//   ConsumerState<WhereToScreen> createState() => _WhereToScreenState();
// }

// class _WhereToScreenState extends ConsumerState<WhereToScreen> {
//   final TextEditingController pickupController = TextEditingController();
//   final TextEditingController destinationController = TextEditingController();

//   List<Map<String, dynamic>> _suggestions = [];
//   bool _isLoading = false;
//   bool _selectingPickup = false;
//   Map<String, dynamic>? _selectedPlace;

//   @override
//   void initState() {
//     super.initState();
//     final pickup = ref.read(pickupLocationProvider);
//     if (pickup != null) {
//       pickupController.text = "Pickup location set";
//     }

//     pickupController.addListener(_onSearchChanged);
//     destinationController.addListener(_onSearchChanged);
//   }

//   void _onSearchChanged() {
//     final text =
//         _selectingPickup ? pickupController.text : destinationController.text;
//     if (text.trim().isEmpty) return;
//     _fetchSuggestions(text);
//   }

//   Future<void> _fetchSuggestions(String query) async {
//     setState(() {
//       _isLoading = true;
//       _suggestions.clear();
//     });

//     final url = Uri.parse(
//       "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5",
//     );
//     final res = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       setState(() {
//         _suggestions = data.cast<Map<String, dynamic>>();
//         _isLoading = false;
//       });
//     } else {
//       _showError("Suggestion fetch failed");
//     }
//   }

//   void _onSuggestionTap(Map<String, dynamic> place) async {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final displayName = place['display_name'];

//     final latLng = LatLng(lat, lon);

//     setState(() {
//       _selectedPlace = place;
//       _suggestions.clear();
//     });

//     final favorite = FavoriteLocation(name: displayName, lat: lat, lon: lon);
//     await FavoriteLocationService.addFavorite(favorite);
//     _showMessage("Added to favorites");

//     if (_selectingPickup) {
//       ref.read(pickupLocationProvider.notifier).state = latLng;
//       pickupController.text = displayName;
//     } else {
//       ref.read(destinationLocationProvider.notifier).state = latLng;
//       destinationController.text = displayName;

//       final pickup = ref.read(pickupLocationProvider);
//       if (pickup != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => HomeScreen(
//                   pickup: pickup,
//                   destination: latLng,
//                   stops: ref.read(stopsProvider),
//                 ),
//           ),
//         );
//       } else {
//         _showError("Please set pickup location first.");
//       }
//     }
//   }

//   void _addStop(Map<String, dynamic> place) {
//     final lat = double.parse(place['lat']);
//     final lon = double.parse(place['lon']);
//     final latLng = LatLng(lat, lon);
//     final address = place['display_name'];

//     final currentStops = ref.read(stopsProvider);

//     final isDuplicate = currentStops.any(
//       (stop) =>
//           stop['latLng'].latitude == lat && stop['latLng'].longitude == lon,
//     );

//     if (isDuplicate) {
//       _showError("This stop is already added.");
//       return;
//     }

//     ref.read(stopsProvider.notifier).state = [
//       ...currentStops,
//       {'latLng': latLng, 'address': address},
//     ];
//     _showMessage("Stop added.");
//   }

//   void _showMessage(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   void _showError(String error) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
//   }

//   @override
//   void dispose() {
//     pickupController.dispose();
//     destinationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Where To?')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: pickupController,
//                     decoration: const InputDecoration(
//                       labelText: 'Pickup Location',
//                       prefixIcon: Icon(Icons.my_location),
//                     ),
//                     onTap: () {
//                       _selectingPickup = true;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: destinationController,
//                     decoration: const InputDecoration(
//                       labelText: 'Destination',
//                       prefixIcon: Icon(Icons.location_on),
//                     ),
//                     onTap: () {
//                       _selectingPickup = false;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             if (_isLoading)
//               const CircularProgressIndicator()
//             else
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _suggestions.length,
//                   itemBuilder: (context, index) {
//                     final place = _suggestions[index];
//                     return ListTile(
//                       title: Text(place['display_name']),
//                       onTap: () => _onSuggestionTap(place),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
