import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:niceapp/Container/utils/keys.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';



class SavedPlace {
  final int id;
  final String type;
  final String title;
  final String address;
  final double? latitude;
  final double? longitude;

  SavedPlace({
    required this.id,
    required this.type,
    required this.title,
    required this.address,
    this.latitude,
    this.longitude,
  });

// double? selectedLatitude;
// double? selectedLongitude;


  factory SavedPlace.fromJson(
    Map<String, dynamic> json,
  ) {
    return SavedPlace(
      id: json['id'] ??
          json['Id'] ??
          0,

      type: json['type'] ??
          json['Type'] ??
          'Other',

      title: json['title'] ??
          json['Title'] ??
          '',

      address: json['address'] ??
          json['Address'] ??
          '',

      latitude: _toDouble(
        json['latitude'] ??
            json['Latitude'],
      ),

      longitude: _toDouble(
        json['longitude'] ??
            json['Longitude'],
      ),
    );
  }

  static double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}


class SavedPlacesApi {



  static String get savedPlacesUrl =>
      '${baseUrl}/saved-places';



  static Future<String?> _token() async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {

      debugPrint(
        'SAVED PLACES: No authenticated user.',
      );

      return null;
    }

    debugPrint(
      'SAVED PLACES UID: ${user.uid}',
    );

    final token =
        await user.getIdToken();

    if (token == null ||
        token.trim().isEmpty) {

      debugPrint(
        'SAVED PLACES: Firebase token unavailable.',
      );

      return null;
    }

    return token;
  }


  static Future<List<SavedPlace>> getSavedPlaces() async {
  final token = await _token();

  if (token == null) {
    throw Exception(
      'Your session has expired. Please sign in again.',
    );
  }



  final url = '${baseUrl}/saved-places/get-palce';

  debugPrint('----------------------------------------');
  debugPrint('GET SAVED PLACES');
  debugPrint('URL: $url');
  debugPrint('TOKEN AVAILABLE: ${token.isNotEmpty}');
  debugPrint('----------------------------------------');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('----------------------------------------');
    debugPrint('SAVED PLACES RESPONSE');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('----------------------------------------');

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        return [];
      }

      final dynamic data = jsonDecode(response.body);

      // Backend returns:
      //
      // [
      //   {
      //     "id": 1,
      //     "type": "Home",
      //     "title": "Home",
      //     "address": "...",
      //     "latitude": -1.2,
      //     "longitude": 36.8
      //   }
      // ]

      if (data is List) {
        return data
            .map(
              (item) => SavedPlace.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      // Also support:
      //
      // {
      //   "data": [...]
      // }

      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map(
              (item) => SavedPlace.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      debugPrint(
        'Unexpected saved places response format.',
      );

      return [];
    }

    if (response.statusCode == 401) {
      throw Exception(
        'You are not authorized to view saved places.',
      );
    }

    throw Exception(
      _extractError(
        response.body,
        'Unable to load saved places.',
      ),
    );
  } catch (e) {
    debugPrint(
      'ERROR LOADING SAVED PLACES: $e',
    );

    rethrow;
  }
}


  // ==============================================================
  // CREATE
  // ==============================================================

  static Future<SavedPlace>
      createSavedPlace({

    required String type,

    required String title,

    required String address,

    double? latitude,

    double? longitude,

  }) async {

    final token =
        await _token();

    if (token == null) {

      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }


    final body = {

      'type': type,

      'title': title,

      'address': address,

      'latitude': latitude,

      'longitude': longitude,
    };


    debugPrint(
      '----------------------------------------',
    );

    debugPrint(
      'POST SAVED PLACE',
    );

    debugPrint(
      'URL: $savedPlacesUrl',
    );

    debugPrint(
      'BODY: ${jsonEncode(body)}',
    );


    final response =
        await http.post(
      Uri.parse(
        savedPlacesUrl,
      ),
      headers: {

        'Content-Type':
            'application/json',

        'Accept':
            'application/json',

        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode(
        body,
      ),
    );


    debugPrint(
      'STATUS: ${response.statusCode}',
    );

    debugPrint(
      'BODY: ${response.body}',
    );

    debugPrint(
      '----------------------------------------',
    );


    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      return SavedPlace.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            response.body,
          ),
        ),
      );
    }


    if (response.statusCode == 401) {

      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }


    throw Exception(
      _extractError(
        response.body,
        'Unable to save this place.',
      ),
    );
  }


  // ==============================================================
  // UPDATE
  // ==============================================================

  static Future<SavedPlace>
      updateSavedPlace({

    required int id,

    required String type,

    required String title,

    required String address,

    double? latitude,

    double? longitude,

  }) async {

    final token =
        await _token();

    if (token == null) {

      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }


    final url =
        '$savedPlacesUrl/$id';


    final body = {

      'type': type,

      'title': title,

      'address': address,

      'latitude': latitude,

      'longitude': longitude,
    };


    debugPrint(
      '----------------------------------------',
    );

    debugPrint(
      'PUT SAVED PLACE',
    );

    debugPrint(
      'URL: $url',
    );

    debugPrint(
      'BODY: ${jsonEncode(body)}',
    );


    final response =
        await http.put(
      Uri.parse(
        url,
      ),
      headers: {

        'Content-Type':
            'application/json',

        'Accept':
            'application/json',

        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode(
        body,
      ),
    );


    debugPrint(
      'STATUS: ${response.statusCode}',
    );

    debugPrint(
      'BODY: ${response.body}',
    );


    if (response.statusCode == 200) {

      return SavedPlace.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            response.body,
          ),
        ),
      );
    }


    if (response.statusCode == 401) {

      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }


    throw Exception(
      _extractError(
        response.body,
        'Unable to update this place.',
      ),
    );
  }


  // ==============================================================
  // DELETE
  // ==============================================================

  static Future<void>
      deleteSavedPlace(
    int id,
  ) async {

    final token =
        await _token();

    if (token == null) {

      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }


    final url =
        '$savedPlacesUrl/$id';


    debugPrint(
      '----------------------------------------',
    );

    debugPrint(
      'DELETE SAVED PLACE',
    );

    debugPrint(
      'URL: $url',
    );


    final response =
        await http.delete(
      Uri.parse(
        url,
      ),
      headers: {

        'Accept':
            'application/json',

        'Authorization':
            'Bearer $token',
      },
    );


    debugPrint(
      'STATUS: ${response.statusCode}',
    );

    debugPrint(
      'BODY: ${response.body}',
    );


    if (response.statusCode == 200 ||
        response.statusCode == 204) {

      return;
    }


    if (response.statusCode == 401) {

      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }


    throw Exception(
      _extractError(
        response.body,
        'Unable to delete this place.',
      ),
    );
  }


  // ==============================================================
  // ERROR
  // ==============================================================

  static String _extractError(
    String body,
    String fallback,
  ) {

    if (body.trim().isEmpty) {
      return fallback;
    }


    try {

      final dynamic data =
          jsonDecode(body);


      if (data is Map) {

        return data['message']
                ?.toString() ??

            data['Message']
                ?.toString() ??

            data['error']
                ?.toString() ??

            data['title']
                ?.toString() ??

            fallback;
      }

    } catch (_) {}


    return fallback;
  }
}


// ================================================================
// SAVED PLACES MANAGEMENT SCREEN
// ================================================================

class SavedPlacesScreen
    extends StatefulWidget {

  const SavedPlacesScreen({
    super.key,
  });

  @override
  State<SavedPlacesScreen>
      createState() =>
          _SavedPlacesScreenState();
}


class _SavedPlacesScreenState
    extends State<SavedPlacesScreen> {

  List<SavedPlace> _places = [];

  bool _isLoading = true;

  bool _isSaving = false;


  @override
  void initState() {

    super.initState();

    _loadSavedPlaces();
  }


  // ==============================================================
  // LOAD
  // ==============================================================

  Future<void>
      _loadSavedPlaces() async {

    if (mounted) {

      setState(() {

        _isLoading = true;

      });
    }


    try {

      final places =
          await SavedPlacesApi
              .getSavedPlaces();


      if (!mounted) {
        return;
      }


      setState(() {

        _places = places;

        _isLoading = false;

      });

    } catch (e) {

      if (!mounted) {
        return;
      }


      setState(() {

        _isLoading = false;

      });


      _showError(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }


  // ==============================================================
  // ADD
  // ==============================================================

  Future<void>
      _addPlace() async {

    final result =
        await _showPlaceDialog();


    if (result == null) {
      return;
    }


    try {

      setState(() {

        _isSaving = true;

      });


      final place =
          await SavedPlacesApi
              .createSavedPlace(

        type: result['type'],

        title: result['title'],

        address: result['address'],

        latitude:
            result['latitude'],

        longitude:
            result['longitude'],
      );


      if (!mounted) {
        return;
      }


      setState(() {

        _places.add(
          place,
        );

        _isSaving = false;

      });


      _showSuccess(
        'Saved place added successfully.',
      );

    } catch (e) {

      if (!mounted) {
        return;
      }


      setState(() {

        _isSaving = false;

      });


      _showError(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }


  // ==============================================================
  // EDIT
  // ==============================================================

  Future<void>
      _editPlace(
    SavedPlace place,
  ) async {

    final result =
        await _showPlaceDialog(
      place: place,
    );


    if (result == null) {
      return;
    }


    try {

      setState(() {

        _isSaving = true;

      });


      final updated =
          await SavedPlacesApi
              .updateSavedPlace(

        id: place.id,

        type: result['type'],

        title: result['title'],

        address: result['address'],

        latitude:
            result['latitude'],

        longitude:
            result['longitude'],
      );


      if (!mounted) {
        return;
      }


      setState(() {

        final index =
            _places.indexWhere(
          (x) =>
              x.id ==
              place.id,
        );


        if (index != -1) {

          _places[index] =
              updated;
        }


        _isSaving = false;

      });


      _showSuccess(
        'Saved place updated.',
      );

    } catch (e) {

      if (!mounted) {
        return;
      }


      setState(() {

        _isSaving = false;

      });


      _showError(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }


  // ==============================================================
  // DELETE
  // ==============================================================

  Future<void>
      _deletePlace(
    SavedPlace place,
  ) async {

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {

        return AlertDialog(

          backgroundColor:
              Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title: Text(
            'Remove saved place?',
            style:
                GoogleFonts.spaceGrotesk(
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          content: Text(
            'Remove "${place.title}" from your saved places?',
            style:
                GoogleFonts.nunitoSans(
              fontSize: 14,
              color:
                  Colors.black54,
            ),
          ),

          actions: [

            TextButton(

              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),

              child: Text(
                'Cancel',
                style:
                    GoogleFonts.spaceGrotesk(
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Colors.black54,
                ),
              ),
            ),

            TextButton(

              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),

              child: Text(
                'Remove',
                style:
                    GoogleFonts.spaceGrotesk(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      const Color(
                    0xFF015ACE,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );


    if (confirmed != true) {
      return;
    }


    try {

      setState(() {

        _isSaving = true;

      });


      await SavedPlacesApi
          .deleteSavedPlace(
        place.id,
      );


      if (!mounted) {
        return;
      }


      setState(() {

        _places.removeWhere(
          (x) =>
              x.id ==
              place.id,
        );

        _isSaving = false;

      });


      _showSuccess(
        'Saved place removed.',
      );

    } catch (e) {

      if (!mounted) {
        return;
      }


      setState(() {

        _isSaving = false;

      });


      _showError(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }


  // ==============================================================
  // ADD / EDIT BOTTOM SHEET
  // ==============================================================

  Future<Map<String, dynamic>?>
      _showPlaceDialog({
    SavedPlace? place,
  }) async {

    final titleController =
        TextEditingController(
      text:
          place?.title ?? '',
    );
double? selectedLatitude;
double? selectedLongitude;


    final addressController =
        TextEditingController(
      text:
          place?.address ?? '',
    );


    String selectedType =
        place?.type ??
            'Home';


    return showModalBottomSheet<
        Map<String, dynamic>>(
      context: context,

      isScrollControlled:
          true,

      backgroundColor:
          Colors.transparent,

      builder: (context) {

        return StatefulBuilder(

          builder: (
            context,
            setModalState,
          ) {

            return Container(

              decoration:
                  const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(
                    28,
                  ),
                ),
              ),

              child: Padding(

                padding:
                    EdgeInsets.only(

                  left: 20,

                  right: 20,

                  top: 12,

                  bottom:
                      MediaQuery.of(
                        context,
                      )
                          .viewInsets
                          .bottom +
                      24,
                ),

                child:
                    SingleChildScrollView(

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      // ------------------------------------------------
                      // HANDLE
                      // ------------------------------------------------

                      Center(

                        child:
                            Container(

                          width: 42,

                          height: 4,

                          decoration:
                              BoxDecoration(

                            color:
                                Colors.black12,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(
                        height: 22,
                      ),


                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------

                      Text(

                        place == null
                            ? 'Add Saved Place'
                            : 'Edit Saved Place',

                        style:
                            GoogleFonts
                                .spaceGrotesk(

                          fontSize: 23,

                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),


                      const SizedBox(
                        height: 6,
                      ),


                      Text(

                        place == null
                            ? 'Save a location for faster bookings.'
                            : 'Update your saved location.',

                        style:
                            GoogleFonts
                                .nunitoSans(

                          fontSize: 13,

                          color:
                              Colors.black54,
                        ),
                      ),


                      const SizedBox(
                        height: 24,
                      ),


                      // ------------------------------------------------
                      // TYPE
                      // ------------------------------------------------

                      Text(

                        'Place Type',

                        style:
                            GoogleFonts
                                .spaceGrotesk(

                          fontSize: 14,

                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),


                      const SizedBox(
                        height: 10,
                      ),


                      Row(

                        children: [

                          _typeButton(

                            label:
                                'Home',

                            icon:
                                Icons.home_rounded,

                            selected:
                                selectedType ==
                                    'Home',

                            onTap: () {

                              setModalState(() {

                                selectedType =
                                    'Home';

                              });
                            },
                          ),


                          const SizedBox(
                            width: 10,
                          ),


                          _typeButton(

                            label:
                                'Work',

                            icon:
                                Icons.work_rounded,

                            selected:
                                selectedType ==
                                    'Work',

                            onTap: () {

                              setModalState(() {

                                selectedType =
                                    'Work';

                              });
                            },
                          ),


                          const SizedBox(
                            width: 10,
                          ),


                          _typeButton(

                            label:
                                'Other',

                            icon:
                                Icons.location_on_rounded,

                            selected:
                                selectedType ==
                                    'Other',

                            onTap: () {

                              setModalState(() {

                                selectedType =
                                    'Other';

                              });
                            },
                          ),
                        ],
                      ),


                      const SizedBox(
                        height: 22,
                      ),


                      _field(

                        controller:
                            titleController,

                        label:
                            'Place Name',

                        hint:
                            'Home, Office, Gym...',
                      ),


                      const SizedBox(
                        height: 16,
                      ),


                      // _field(

                      //   controller:
                      //       addressController,

                      //   label:
                      //       'Address',

                      //   hint:
                      //       'Enter your address',

                      //   maxLines:
                      //       2,
                      // ),
                      GestureDetector(
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WhereToScreen(
          category: VehicleCategory.passenger,
          isLocationPicker: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        addressController.text =
            result["address"]?.toString() ?? "";

        selectedLatitude =
            (result["latitude"] as num?)?.toDouble();

        selectedLongitude =
            (result["longitude"] as num?)?.toDouble();
      });
    }
  },
  child: AbsorbPointer(
    child: _field(
      controller: addressController,
      label: 'Address',
      hint: 'Select your address',
      maxLines: 2,
    ),
  ),
),



                      const SizedBox(
                        height: 26,
                      ),


                      // ------------------------------------------------
                      // SAVE BUTTON
                      // ------------------------------------------------

                      SizedBox(

                        width:
                            double.infinity,

                        height:
                            54,

                        child:
                            ElevatedButton(

                          onPressed: () {

                            final title =
                                titleController
                                    .text
                                    .trim();


                            final address =
                                addressController
                                    .text
                                    .trim();


                            if (title.isEmpty ||
                                address.isEmpty) {

                              return;
                            }


                            Navigator.pop(

                              context,

                              {

                                'type':
                                    selectedType,

                                'title':
                                    title,

                                'address':
                                    address,

                                'latitude':
                                    place?.latitude,

                                'longitude':
                                    place?.longitude,
                              },
                            );
                          },

                          style:
                              ElevatedButton
                                  .styleFrom(

                            backgroundColor:
                                const Color(
                              0xFF015ACE,
                            ),

                            foregroundColor:
                                Colors.white,

                            elevation:
                                0,

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                          ),

                          child:
                              Text(

                            place == null
                                ? 'Save Place'
                                : 'Update Place',

                            style:
                                GoogleFonts
                                    .spaceGrotesk(

                              fontSize:
                                  15,

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ==============================================================
  // TYPE BUTTON
  // ==============================================================

  Widget _typeButton({

    required String label,

    required IconData icon,

    required bool selected,

    required VoidCallback onTap,

  }) {

    return Expanded(

      child:
          GestureDetector(

        onTap:
            onTap,

        child:
            AnimatedContainer(

          duration:
              const Duration(
            milliseconds: 180,
          ),

          padding:
              const EdgeInsets.symmetric(
            vertical: 13,
          ),

          decoration:
              BoxDecoration(

            color: selected
                ? const Color(
                    0xFFEAF3FF,
                  )
                : const Color(
                    0xFFF5F6F8,
                  ),

            borderRadius:
                BorderRadius.circular(
              14,
            ),

            border:
                Border.all(

              color: selected
                  ? const Color(
                      0xFF015ACE,
                    )
                  : Colors.transparent,
            ),
          ),

          child:
              Column(

            children: [

              Icon(

                icon,

                size: 22,

                color: selected
                    ? const Color(
                        0xFF015ACE,
                      )
                    : Colors.black54,
              ),

              const SizedBox(
                height: 5,
              ),

              Text(

                label,

                style:
                    GoogleFonts.nunitoSans(

                  fontSize:
                      12,

                  fontWeight:
                      FontWeight.w700,

                  color: selected
                      ? const Color(
                          0xFF015ACE,
                        )
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==============================================================
  // TEXT FIELD
  // ==============================================================

  Widget _field({

    required TextEditingController
        controller,

    required String label,

    required String hint,

    int maxLines = 1,

  }) {

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style:
              GoogleFonts.spaceGrotesk(

            fontSize:
                14,

            fontWeight:
                FontWeight.w700,
          ),
        ),


        const SizedBox(
          height: 8,
        ),


        TextField(

          controller:
              controller,

          maxLines:
              maxLines,

          style:
              GoogleFonts.nunitoSans(

            fontSize:
                14,
          ),

          decoration:
              InputDecoration(

            hintText:
                hint,

            hintStyle:
                GoogleFonts.nunitoSans(

              color:
                  Colors.black38,
            ),

            filled:
                true,

            fillColor:
                const Color(
              0xFFF5F6F8,
            ),

            border:
                OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              borderSide:
                  BorderSide.none,
            ),

            enabledBorder:
                OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              borderSide:
                  BorderSide.none,
            ),

            focusedBorder:
                OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              borderSide:
                  const BorderSide(

                color:
                    Color(
                  0xFF015ACE,
                ),

                width:
                    1.2,
              ),
            ),

            contentPadding:
                const EdgeInsets.symmetric(

              horizontal:
                  15,

              vertical:
                  15,
            ),
          ),
        ),
      ],
    );
  }


  // ==============================================================
  // ICON
  // ==============================================================

  IconData _iconForType(
    String type,
  ) {

    switch (
        type.toLowerCase()) {

      case 'home':

        return Icons.home_rounded;

      case 'work':

        return Icons.work_rounded;

      default:

        return Icons.location_on_rounded;
    }
  }


  // ==============================================================
  // REFRESH
  // ==============================================================

  Future<void>
      _refresh() async {

    await _loadSavedPlaces();
  }


  // ==============================================================
  // SUCCESS
  // ==============================================================

  void _showSuccess(
    String message,
  ) {

    if (!mounted) {
      return;
    }


    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();


    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            const Color(
          0xFF1F2937,
        ),

        margin:
            const EdgeInsets.all(
          16,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        content:
            Row(

          children: [

            const Icon(

              Icons.check_circle_outline,

              color:
                  Color(
                0xFF4ADE80,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(

              child:
                  Text(

                message,

                style:
                    GoogleFonts.nunitoSans(

                  color:
                      Colors.white,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==============================================================
  // ERROR
  // ==============================================================

  void _showError(
    String message,
  ) {

    if (!mounted) {
      return;
    }


    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();


    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            const Color(
          0xFF1F2937,
        ),

        margin:
            const EdgeInsets.all(
          16,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        content:
            Row(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Icon(

              Icons.error_outline_rounded,

              color:
                  Color(
                0xFFFF6B6B,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(

              child:
                  Text(

                message,

                style:
                    GoogleFonts.nunitoSans(

                  color:
                      Colors.white,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF7F8FA,
      ),


      appBar:
          AppBar(

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation:
            0.5,

        centerTitle:
            true,

        title:
            Text(

          'Saved Places',

          style:
              GoogleFonts.spaceGrotesk(

            fontSize:
                20,

            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),


      body:
          Stack(

        children: [

          RefreshIndicator(

            color:
                const Color(
              0xFF015ACE,
            ),

            onRefresh:
                _refresh,

            child:
                _isLoading

                    ? ListView(

                        children: [

                          SizedBox(

                            height:
                                MediaQuery.of(
                                  context,
                                ).size.height *
                                .65,

                            child:
                                const Center(

                              child:
                                  CircularProgressIndicator(

                                strokeWidth:
                                    2.5,

                                color:
                                    Color(
                                  0xFF015ACE,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )

                    : ListView(

                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          35,
                        ),

                        children: [

                          // ------------------------------------------------
                          // HEADER
                          // ------------------------------------------------

                          Text(

                            'Your places',

                            style:
                                GoogleFonts.spaceGrotesk(

                              fontSize:
                                  24,

                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),


                          const SizedBox(
                            height: 5,
                          ),


                          Text(

                            'Save your favourite locations for faster bookings.',

                            style:
                                GoogleFonts.nunitoSans(

                              fontSize:
                                  13,

                              color:
                                  Colors.black54,
                            ),
                          ),


                          const SizedBox(
                            height: 20,
                          ),


                          // ------------------------------------------------
                          // PLACES
                          // ------------------------------------------------

                          if (_places.isEmpty)

                            _emptyState()

                          else

                            ..._places.map(

                              (place) =>
                                  _savedPlaceCard(
                                place,
                              ),
                            ),


                          const SizedBox(
                            height: 10,
                          ),


                          // ------------------------------------------------
                          // ADD BUTTON
                          // ------------------------------------------------

                          SizedBox(

                            height:
                                54,

                            child:
                                OutlinedButton.icon(

                              onPressed:
                                  _isSaving
                                      ? null
                                      : _addPlace,

                              icon:
                                  const Icon(

                                Icons.add_rounded,

                                color:
                                    Color(
                                  0xFF015ACE,
                                ),
                              ),

                              label:
                                  Text(

                                'Add Saved Place',

                                style:
                                    GoogleFonts.spaceGrotesk(

                                  fontSize:
                                      14,

                                  fontWeight:
                                      FontWeight.w700,

                                  color:
                                      const Color(
                                    0xFF015ACE,
                                  ),
                                ),
                              ),

                              style:
                                  OutlinedButton.styleFrom(

                                side:
                                    const BorderSide(

                                  color:
                                      Color(
                                    0xFF015ACE,
                                  ),
                                ),

                                shape:
                                    RoundedRectangleBorder(

                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),


          // ------------------------------------------------
          // SAVING OVERLAY
          // ------------------------------------------------

          if (_isSaving)

            Container(

              color:
                  Colors.black.withOpacity(
                .06,
              ),

              child:
                  const Center(

                child:
                    CircularProgressIndicator(

                  strokeWidth:
                      2.5,

                  color:
                      Color(
                    0xFF015ACE,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _emptyState() {

    return Container(

      margin:
          const EdgeInsets.only(
        top: 15,
        bottom: 15,
      ),

      padding:
          const EdgeInsets.all(
        28,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE9EBEF,
          ),
        ),
      ),

      child:
          Column(

        children: [

          Container(

            width:
                72,

            height:
                72,

            decoration:
                const BoxDecoration(

              color:
                  Color(
                0xFFEAF3FF,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(

              Icons.location_on_rounded,

              size:
                  34,

              color:
                  Color(
                0xFF015ACE,
              ),
            ),
          ),


          const SizedBox(
            height: 17,
          ),


          Text(

            'No saved places yet',

            style:
                GoogleFonts.spaceGrotesk(

              fontSize:
                  19,

              fontWeight:
                  FontWeight.w700,
            ),
          ),


          const SizedBox(
            height: 7,
          ),


          Text(

            'Save Home, Work or your favourite destinations to book rides faster.',

            textAlign:
                TextAlign.center,

            style:
                GoogleFonts.nunitoSans(

              fontSize:
                  13,

              height:
                  1.45,

              color:
                  Colors.black54,
            ),
          ),
        ],
      ),
    );
  }


  // ==============================================================
  // PLACE CARD
  // ==============================================================

  Widget _savedPlaceCard(
    SavedPlace place,
  ) {

    return GestureDetector(

      onTap:
          () => _editPlace(
        place,
      ),

      child:
          Container(

        margin:
            const EdgeInsets.only(
          bottom: 11,
        ),

        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(

          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            19,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFFE9EBEF,
            ),
          ),

          boxShadow: [

            BoxShadow(

              color:
                  Colors.black.withOpacity(
                .025,
              ),

              blurRadius:
                  12,

              offset:
                  const Offset(
                0,
                4,
              ),
            ),
          ],
        ),

        child:
            Row(

          children: [

            // ------------------------------------------------
            // ICON
            // ------------------------------------------------

            Container(

              width:
                  48,

              height:
                  48,

              decoration:
                  const BoxDecoration(

                color:
                    Color(
                  0xFFEAF3FF,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  Icon(

                _iconForType(
                  place.type,
                ),

                color:
                    const Color(
                  0xFF015ACE,
                ),

                size:
                    22,
              ),
            ),


            const SizedBox(
              width: 13,
            ),


            // ------------------------------------------------
            // DETAILS
            // ------------------------------------------------

            Expanded(

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    place.title,

                    maxLines:
                        1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        GoogleFonts.spaceGrotesk(

                      fontSize:
                          15,

                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),


                  const SizedBox(
                    height: 3,
                  ),


                  Text(

                    place.address,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        GoogleFonts.nunitoSans(

                      fontSize:
                          12.5,

                      height:
                          1.3,

                      color:
                          Colors.black54,
                    ),
                  ),
                ],
              ),
            ),


            // ------------------------------------------------
            // MENU
            // ------------------------------------------------

            PopupMenuButton<String>(

              icon:
                  const Icon(

                Icons.more_vert_rounded,

                color:
                    Colors.black45,
              ),

              onSelected:
                  (value) {

                if (value ==
                    'edit') {

                  _editPlace(
                    place,
                  );
                }

                if (value ==
                    'delete') {

                  _deletePlace(
                    place,
                  );
                }
              },

              itemBuilder:
                  (context) => [

                PopupMenuItem(

                  value:
                      'edit',

                  child:
                      Text(

                    'Edit',

                    style:
                        GoogleFonts.nunitoSans(

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                PopupMenuItem(

                  value:
                      'delete',

                  child:
                      Text(

                    'Delete',

                    style:
                        GoogleFonts.nunitoSans(

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ================================================================
// UBER-STYLE SAVED PLACES SELECTOR
//
// Use this widget on your pickup/destination screen.
// ================================================================

class SavedPlacesSelector
    extends StatefulWidget {

  final ValueChanged<SavedPlace>
      onPlaceSelected;

  const SavedPlacesSelector({

    super.key,

    required this.onPlaceSelected,
  });


  @override
  State<SavedPlacesSelector>
      createState() =>
          _SavedPlacesSelectorState();
}


class _SavedPlacesSelectorState
    extends State<SavedPlacesSelector> {

  List<SavedPlace> _places = [];

  bool _loading = true;


  @override
  void initState() {

    super.initState();

    _loadPlaces();
  }


  Future<void>
      _loadPlaces() async {

    try {

      final places =
          await SavedPlacesApi
              .getSavedPlaces();


      if (!mounted) {
        return;
      }


      setState(() {

        _places = places;

        _loading = false;

      });

    } catch (_) {

      if (!mounted) {
        return;
      }


      setState(() {

        _loading = false;

      });
    }
  }


  IconData _iconForType(
    String type,
  ) {

    switch (
        type.toLowerCase()) {

      case 'home':

        return Icons.home_rounded;

      case 'work':

        return Icons.work_rounded;

      default:

        return Icons.location_on_rounded;
    }
  }


  @override
  Widget build(
    BuildContext context,
  ) {

    if (_loading) {

      return const SizedBox(

        height:
            82,

        child:
            Center(

          child:
              SizedBox(

            width:
                20,

            height:
                20,

            child:
                CircularProgressIndicator(

              strokeWidth:
                  2,

              color:
                  Color(
                0xFF015ACE,
              ),
            ),
          ),
        ),
      );
    }


    if (_places.isEmpty) {

      return const SizedBox.shrink();
    }


    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(

          'SAVED PLACES',

          style:
              GoogleFonts.spaceGrotesk(

            fontSize:
                10.5,

            fontWeight:
                FontWeight.w700,

            letterSpacing:
                1.15,

            color:
                Colors.black45,
          ),
        ),


        const SizedBox(
          height: 10,
        ),


        SizedBox(

          height:
              82,

          child:
              ListView.separated(

            scrollDirection:
                Axis.horizontal,

            itemCount:
                _places.length,

            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              width: 10,
            ),

            itemBuilder:
                (context, index) {

              final place =
                  _places[index];


              return GestureDetector(

                onTap: () {

                  widget
                      .onPlaceSelected(
                    place,
                  );
                },

                child:
                    Container(

                  width:
                      175,

                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),

                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFE8EAF0,
                      ),
                    ),

                    boxShadow: [

                      BoxShadow(

                        color:
                            Colors.black.withOpacity(
                          .035,
                        ),

                        blurRadius:
                            12,

                        offset:
                            const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
                  ),

                  child:
                      Row(

                    children: [

                      Container(

                        width:
                            42,

                        height:
                            42,

                        decoration:
                            const BoxDecoration(

                          color:
                              Color(
                            0xFFEAF3FF,
                          ),

                          shape:
                              BoxShape.circle,
                        ),

                        child:
                            Icon(

                          _iconForType(
                            place.type,
                          ),

                          size:
                              20,

                          color:
                              const Color(
                            0xFF015ACE,
                          ),
                        ),
                      ),


                      const SizedBox(
                        width: 9,
                      ),


                      Expanded(

                        child:
                            Column(

                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(

                              place.title,

                              maxLines:
                                  1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  GoogleFonts.spaceGrotesk(

                                fontSize:
                                    13.5,

                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),


                            const SizedBox(
                              height: 3,
                            ),


                            Text(

                              place.address,

                              maxLines:
                                  1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  GoogleFonts.nunitoSans(

                                fontSize:
                                    10.5,

                                color:
                                    Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}




// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'package:niceapp/View/Screens/Other_Screens/saved_places_screen.dart';

// // Change this import to your existing API settings file.


// class SavedPlace {
//   final int id;
//   final String type;
//   final String title;
//   final String address;
//   final double? latitude;
//   final double? longitude;

//   SavedPlace({
//     required this.id,
//     required this.type,
//     required this.title,
//     required this.address,
//     this.latitude,
//     this.longitude,
//   });

//   factory SavedPlace.fromJson(Map<String, dynamic> json) {
//     return SavedPlace(
//       id: json['id'] ?? json['Id'] ?? 0,
//       type: json['type'] ?? json['Type'] ?? 'Other',
//       title: json['title'] ?? json['Title'] ?? '',
//       address: json['address'] ?? json['Address'] ?? '',
//       latitude: _toDouble(json['latitude'] ?? json['Latitude']),
//       longitude: _toDouble(json['longitude'] ?? json['Longitude']),
//     );
//   }

//   static double? _toDouble(dynamic value) {
//     if (value == null) return null;

//     if (value is num) {
//       return value.toDouble();
//     }

//     return double.tryParse(value.toString());
//   }
// }


// class SavedPlacesApi {
//   //static String get baseUrl => baseUrl;

//   static Future<String?> _token() async {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return null;
//     }

//     return await user.getIdToken();
//   }

//   static Future<List<SavedPlace>> getSavedPlaces() async {
//     final token = await _token();

//     if (token == null) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     final response = await http.get(
//       Uri.parse('${baseUrl}api/saved-places'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     if (response.statusCode == 200) {
//       final dynamic data = jsonDecode(response.body);

//       if (data is List) {
//         return data
//             .map(
//               (item) => SavedPlace.fromJson(
//                 Map<String, dynamic>.from(item),
//               ),
//             )
//             .toList();
//       }

//       if (data is Map && data['data'] is List) {
//         return (data['data'] as List)
//             .map(
//               (item) => SavedPlace.fromJson(
//                 Map<String, dynamic>.from(item),
//               ),
//             )
//             .toList();
//       }

//       return [];
//     }

//     if (response.statusCode == 401) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     throw Exception(
//       _extractError(response.body, 'Unable to load saved places.'),
//     );
//   }

//   static Future<SavedPlace> createSavedPlace({
//     required String type,
//     required String title,
//     required String address,
//     double? latitude,
//     double? longitude,
//   }) async {
//     final token = await _token();

//     if (token == null) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     final response = await http.post(
//       Uri.parse('${baseUrl}/saved-places'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode({
//         'type': type,
//         'title': title,
//         'address': address,
//         'latitude': latitude,
//         'longitude': longitude,
//       }),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return SavedPlace.fromJson(
//         Map<String, dynamic>.from(
//           jsonDecode(response.body),
//         ),
//       );
//     }

//     if (response.statusCode == 401) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     throw Exception(
//       _extractError(response.body, 'Unable to save this place.'),
//     );
//   }

//   static Future<SavedPlace> updateSavedPlace({
//     required int id,
//     required String type,
//     required String title,
//     required String address,
//     double? latitude,
//     double? longitude,
//   }) async {
//     final token = await _token();

//     if (token == null) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     final response = await http.put(
//       Uri.parse('${baseUrl}/saved-places/$id'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode({
//         'type': type,
//         'title': title,
//         'address': address,
//         'latitude': latitude,
//         'longitude': longitude,
//       }),
//     );

//     if (response.statusCode == 200) {
//       return SavedPlace.fromJson(
//         Map<String, dynamic>.from(
//           jsonDecode(response.body),
//         ),
//       );
//     }

//     if (response.statusCode == 401) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     throw Exception(
//       _extractError(response.body, 'Unable to update this place.'),
//     );
//   }

//   static Future<void> deleteSavedPlace(int id) async {
//     final token = await _token();

//     if (token == null) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     final response = await http.delete(
//       Uri.parse('${baseUrl}/saved-places/$id'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     if (response.statusCode == 200 ||
//         response.statusCode == 204) {
//       return;
//     }

//     if (response.statusCode == 401) {
//       throw Exception('Your session has expired. Please sign in again.');
//     }

//     throw Exception(
//       _extractError(response.body, 'Unable to delete this place.'),
//     );
//   }

//   static String _extractError(
//     String body,
//     String fallback,
//   ) {
//     try {
//       final data = jsonDecode(body);

//       if (data is Map) {
//         return data['message']?.toString() ??
//             data['Message']?.toString() ??
//             data['error']?.toString() ??
//             data['title']?.toString() ??
//             fallback;
//       }
//     } catch (_) {}

//     return fallback;
//   }
// }


// class SavedPlacesScreen extends StatefulWidget {
//   const SavedPlacesScreen({super.key});

//   @override
//   State<SavedPlacesScreen> createState() =>
//       _SavedPlacesScreenState();
// }


// class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
//   List<SavedPlace> _places = [];

//   bool _isLoading = true;
//   bool _isSaving = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedPlaces();
//   }

//   Future<void> _loadSavedPlaces() async {
//     if (mounted) {
//       setState(() {
//         _isLoading = true;
//       });
//     }

//     try {
//       final places =
//           await SavedPlacesApi.getSavedPlaces();

//       if (!mounted) return;

//       setState(() {
//         _places = places;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isLoading = false;
//       });

//       _showError(
//         e.toString().replaceFirst(
//           'Exception: ',
//           '',
//         ),
//       );
//     }
//   }

//   Future<void> _addPlace() async {
//     final result = await _showPlaceDialog();

//     if (result == null) return;

//     try {
//       setState(() {
//         _isSaving = true;
//       });

//       final place =
//           await SavedPlacesApi.createSavedPlace(
//         type: result['type'],
//         title: result['title'],
//         address: result['address'],
//         latitude: result['latitude'],
//         longitude: result['longitude'],
//       );

//       if (!mounted) return;

//       setState(() {
//         _places.add(place);
//         _isSaving = false;
//       });

//       _showSuccess('Saved place added successfully.');
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isSaving = false;
//       });

//       _showError(
//         e.toString().replaceFirst(
//           'Exception: ',
//           '',
//         ),
//       );
//     }
//   }

//   Future<void> _editPlace(
//     SavedPlace place,
//   ) async {
//     final result = await _showPlaceDialog(
//       place: place,
//     );

//     if (result == null) return;

//     try {
//       setState(() {
//         _isSaving = true;
//       });

//       final updated =
//           await SavedPlacesApi.updateSavedPlace(
//         id: place.id,
//         type: result['type'],
//         title: result['title'],
//         address: result['address'],
//         latitude: result['latitude'],
//         longitude: result['longitude'],
//       );

//       if (!mounted) return;

//       setState(() {
//         final index =
//             _places.indexWhere(
//           (x) => x.id == place.id,
//         );

//         if (index != -1) {
//           _places[index] = updated;
//         }

//         _isSaving = false;
//       });

//       _showSuccess('Saved place updated.');
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isSaving = false;
//       });

//       _showError(
//         e.toString().replaceFirst(
//           'Exception: ',
//           '',
//         ),
//       );
//     }
//   }

//   Future<void> _deletePlace(
//     SavedPlace place,
//   ) async {
//     final confirmed =
//         await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(18),
//           ),
//           title: Text(
//             'Delete Saved Place?',
//             style: GoogleFonts.spaceGrotesk(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           content: Text(
//             'Are you sure you want to remove ${place.title}?',
//             style: GoogleFonts.nunitoSans(
//               fontSize: 14,
//               color: Colors.black54,
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () =>
//                   Navigator.pop(context, false),
//               child: Text(
//                 'Cancel',
//                 style: GoogleFonts.spaceGrotesk(
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black54,
//                 ),
//               ),
//             ),
//             TextButton(
//               onPressed: () =>
//                   Navigator.pop(context, true),
//               child: Text(
//                 'Delete',
//                 style: GoogleFonts.spaceGrotesk(
//                   fontWeight: FontWeight.w700,
//                   color: const Color(0xFF015ACE),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed != true) return;

//     try {
//       setState(() {
//         _isSaving = true;
//       });

//       await SavedPlacesApi.deleteSavedPlace(
//         place.id,
//       );

//       if (!mounted) return;

//       setState(() {
//         _places.removeWhere(
//           (x) => x.id == place.id,
//         );

//         _isSaving = false;
//       });

//       _showSuccess('Saved place removed.');
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isSaving = false;
//       });

//       _showError(
//         e.toString().replaceFirst(
//           'Exception: ',
//           '',
//         ),
//       );
//     }
//   }

//   Future<Map<String, dynamic>?> _showPlaceDialog({
//     SavedPlace? place,
//   }) async {
//     final titleController =
//         TextEditingController(
//       text: place?.title ?? '',
//     );

//     final addressController =
//         TextEditingController(
//       text: place?.address ?? '',
//     );

//     String selectedType =
//         place?.type ?? 'Home';

//     return showModalBottomSheet<
//         Map<String, dynamic>>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(24),
//         ),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (
//             context,
//             setModalState,
//           ) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 top: 20,
//                 bottom:
//                     MediaQuery.of(context)
//                             .viewInsets
//                             .bottom +
//                         20,
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 42,
//                         height: 4,
//                         decoration:
//                             BoxDecoration(
//                           color:
//                               Colors.black12,
//                           borderRadius:
//                               BorderRadius.circular(
//                             10,
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     Text(
//                       place == null
//                           ? 'Add Saved Place'
//                           : 'Edit Saved Place',
//                       style:
//                           GoogleFonts.spaceGrotesk(
//                         fontSize: 21,
//                         fontWeight:
//                             FontWeight.w700,
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     Text(
//                       'Place Type',
//                       style:
//                           GoogleFonts.spaceGrotesk(
//                         fontWeight:
//                             FontWeight.w600,
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     Row(
//                       children: [
//                         _typeButton(
//                           label: 'Home',
//                           icon: Icons.home_outlined,
//                           selected:
//                               selectedType ==
//                                   'Home',
//                           onTap: () {
//                             setModalState(() {
//                               selectedType =
//                                   'Home';
//                             });
//                           },
//                         ),

//                         const SizedBox(width: 10),

//                         _typeButton(
//                           label: 'Work',
//                           icon: Icons.work_outline,
//                           selected:
//                               selectedType ==
//                                   'Work',
//                           onTap: () {
//                             setModalState(() {
//                               selectedType =
//                                   'Work';
//                             });
//                           },
//                         ),

//                         const SizedBox(width: 10),

//                         _typeButton(
//                           label: 'Other',
//                           icon: Icons.place_outlined,
//                           selected:
//                               selectedType ==
//                                   'Other',
//                           onTap: () {
//                             setModalState(() {
//                               selectedType =
//                                   'Other';
//                             });
//                           },
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     _field(
//                       controller: titleController,
//                       label: 'Name',
//                       hint:
//                           'e.g. Home, Office, Gym',
//                     ),

//                     const SizedBox(height: 15),

//                     _field(
//                       controller:
//                           addressController,
//                       label: 'Address',
//                       hint:
//                           'Enter your address',
//                       maxLines: 2,
//                     ),

//                     const SizedBox(height: 25),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 52,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           final title =
//                               titleController
//                                   .text
//                                   .trim();

//                           final address =
//                               addressController
//                                   .text
//                                   .trim();

//                           if (title.isEmpty ||
//                               address.isEmpty) {
//                             return;
//                           }

//                           Navigator.pop(
//                             context,
//                             {
//                               'type':
//                                   selectedType,
//                               'title':
//                                   title,
//                               'address':
//                                   address,
//                               'latitude':
//                                   place?.latitude,
//                               'longitude':
//                                   place?.longitude,
//                             },
//                           );
//                         },
//                         style:
//                             ElevatedButton
//                                 .styleFrom(
//                           backgroundColor:
//                               const Color(
//                             0xFF015ACE,
//                           ),
//                           foregroundColor:
//                               Colors.white,
//                           elevation: 0,
//                           shape:
//                               RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius
//                                     .circular(
//                               14,
//                             ),
//                           ),
//                         ),
//                         child: Text(
//                           place == null
//                               ? 'Save Place'
//                               : 'Update Place',
//                           style:
//                               GoogleFonts.spaceGrotesk(
//                             fontSize: 15,
//                             fontWeight:
//                                 FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _typeButton({
//     required String label,
//     required IconData icon,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration:
//               const Duration(milliseconds: 180),
//           padding:
//               const EdgeInsets.symmetric(
//             vertical: 12,
//           ),
//           decoration: BoxDecoration(
//             color: selected
//                 ? const Color(0xFFEAF3FF)
//                 : const Color(0xFFF5F5F5),
//             borderRadius:
//                 BorderRadius.circular(12),
//             border: Border.all(
//               color: selected
//                   ? const Color(0xFF015ACE)
//                   : Colors.transparent,
//             ),
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 icon,
//                 size: 21,
//                 color: selected
//                     ? const Color(0xFF015ACE)
//                     : Colors.black54,
//               ),

//               const SizedBox(height: 4),

//               Text(
//                 label,
//                 style:
//                     GoogleFonts.nunitoSans(
//                   fontSize: 12,
//                   fontWeight:
//                       FontWeight.w600,
//                   color: selected
//                       ? const Color(
//                           0xFF015ACE,
//                         )
//                       : Colors.black54,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _field({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     int maxLines = 1,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.spaceGrotesk(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//           ),
//         ),

//         const SizedBox(height: 8),

//         TextField(
//           controller: controller,
//           maxLines: maxLines,
//           style: GoogleFonts.nunitoSans(
//             fontSize: 14,
//           ),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle:
//                 GoogleFonts.nunitoSans(
//               color: Colors.black38,
//             ),
//             filled: true,
//             fillColor:
//                 const Color(0xFFF5F6F8),
//             border: OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(13),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder:
//                 OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(13),
//               borderSide: BorderSide.none,
//             ),
//             focusedBorder:
//                 OutlineInputBorder(
//               borderRadius:
//                   BorderRadius.circular(13),
//               borderSide:
//                   const BorderSide(
//                 color: Color(0xFF015ACE),
//                 width: 1.2,
//               ),
//             ),
//             contentPadding:
//                 const EdgeInsets.symmetric(
//               horizontal: 15,
//               vertical: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   IconData _iconForType(String type) {
//     switch (type.toLowerCase()) {
//       case 'home':
//         return Icons.home_outlined;

//       case 'work':
//         return Icons.work_outline;

//       default:
//         return Icons.place_outlined;
//     }
//   }

//   Future<void> _refresh() async {
//     await _loadSavedPlaces();
//   }

//   void _showSuccess(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//         .hideCurrentSnackBar();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior:
//             SnackBarBehavior.floating,
//         backgroundColor:
//             const Color(0xFF1F2937),
//         margin: const EdgeInsets.all(16),
//         shape: RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(14),
//         ),
//         content: Row(
//           children: [
//             const Icon(
//               Icons.check_circle_outline,
//               color: Color(0xFF4ADE80),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style:
//                     GoogleFonts.nunitoSans(
//                   color: Colors.white,
//                   fontWeight:
//                       FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showError(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//         .hideCurrentSnackBar();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior:
//             SnackBarBehavior.floating,
//         backgroundColor:
//             const Color(0xFF1F2937),
//         margin: const EdgeInsets.all(16),
//         shape: RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(14),
//         ),
//         content: Row(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             const Icon(
//               Icons.error_outline_rounded,
//               color: Color(0xFFFF6B6B),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style:
//                     GoogleFonts.nunitoSans(
//                   color: Colors.white,
//                   fontWeight:
//                       FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//           const Color(0xFFF9F9F9),

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         foregroundColor: Colors.black,
//         title: Text(
//           'Saved Places',
//           style: GoogleFonts.spaceGrotesk(
//             fontSize: 20,
//             fontWeight:
//                 FontWeight.w700,
//           ),
//         ),
//         centerTitle: true,
//       ),

//       body: Stack(
//         children: [
//           RefreshIndicator(
//             color: const Color(0xFF015ACE),
//             onRefresh: _refresh,
//             child: _isLoading
//                 ? ListView(
//                     children: [
//                       SizedBox(
//                         height:
//                             MediaQuery.of(context)
//                                     .size
//                                     .height *
//                                 .4,
//                         child: const Center(
//                           child:
//                               CircularProgressIndicator(
//                             color: Color(
//                               0xFF015ACE,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : ListView(
//                     padding:
//                         const EdgeInsets.all(20),
//                     children: [
//                       if (_places.isEmpty)
//                         _emptyState()
//                       else
//                         ..._places.map(
//                           (place) =>
//                               _savedPlace(
//                             place,
//                           ),
//                         ),

//                       const SizedBox(height: 15),

//                       OutlinedButton.icon(
//                         onPressed:
//                             _isSaving
//                                 ? null
//                                 : _addPlace,
//                         icon: const Icon(
//                           Icons.add,
//                           color:
//                               Color(0xFF015ACE),
//                         ),
//                         label: Text(
//                           'Add Saved Place',
//                           style:
//                               GoogleFonts.spaceGrotesk(
//                             fontWeight:
//                                 FontWeight.w600,
//                             color:
//                                 const Color(
//                               0xFF015ACE,
//                             ),
//                           ),
//                         ),
//                         style:
//                             OutlinedButton
//                                 .styleFrom(
//                           padding:
//                               const EdgeInsets
//                                   .symmetric(
//                             vertical: 14,
//                           ),
//                           side:
//                               const BorderSide(
//                             color: Color(
//                               0xFF015ACE,
//                             ),
//                           ),
//                           shape:
//                               RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius
//                                     .circular(
//                               13,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//           ),

//           if (_isSaving)
//             Container(
//               color: Colors.black
//                   .withOpacity(.08),
//               child: const Center(
//                 child:
//                     CircularProgressIndicator(
//                   color: Color(0xFF015ACE),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyState() {
//     return Container(
//       margin:
//           const EdgeInsets.only(top: 50),
//       padding:
//           const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius:
//             BorderRadius.circular(18),
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 65,
//             height: 65,
//             decoration: BoxDecoration(
//               color:
//                   const Color(0xFFEAF3FF),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.location_on_outlined,
//               color: Color(0xFF015ACE),
//               size: 31,
//             ),
//           ),

//           const SizedBox(height: 15),

//           Text(
//             'No Saved Places',
//             style: GoogleFonts.spaceGrotesk(
//               fontSize: 18,
//               fontWeight:
//                   FontWeight.w700,
//             ),
//           ),

//           const SizedBox(height: 6),

//           Text(
//             'Save your home, work and favourite destinations for faster booking.',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.nunitoSans(
//               fontSize: 13,
//               color: Colors.black54,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _savedPlace(
//     SavedPlace place,
//   ) {
//     return GestureDetector(
//       onTap: () => _editPlace(place),
//       child: Container(
//         margin:
//             const EdgeInsets.only(bottom: 10),
//         padding:
//             const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color:
//               const Color(0xFFF1F2F4),
//           borderRadius:
//               BorderRadius.circular(15),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius:
//                     BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 _iconForType(place.type),
//                 color:
//                     const Color(0xFF015ACE),
//               ),
//             ),

//             const SizedBox(width: 14),

//             Expanded(
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     place.title,
//                     style:
//                         GoogleFonts.spaceGrotesk(
//                       fontSize: 16,
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),

//                   const SizedBox(height: 3),

//                   Text(
//                     place.address,
//                     maxLines: 2,
//                     overflow:
//                         TextOverflow.ellipsis,
//                     style:
//                         GoogleFonts.nunitoSans(
//                       fontSize: 13,
//                       color:
//                           Colors.black54,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             PopupMenuButton<String>(
//               icon: const Icon(
//                 Icons.more_vert_rounded,
//                 color: Colors.black45,
//               ),
//               onSelected: (value) {
//                 if (value == 'edit') {
//                   _editPlace(place);
//                 }

//                 if (value == 'delete') {
//                   _deletePlace(place);
//                 }
//               },
//               itemBuilder: (context) => [
//                 PopupMenuItem(
//                   value: 'edit',
//                   child: Text(
//                     'Edit',
//                     style:
//                         GoogleFonts.nunitoSans(
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 PopupMenuItem(
//                   value: 'delete',
//                   child: Text(
//                     'Delete',
//                     style:
//                         GoogleFonts.nunitoSans(
//                       fontWeight:
//                           FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






// // import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';

// // class SavedPlacesScreen extends StatelessWidget {
// //   const SavedPlacesScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF9F9F9),

// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 1,
// //         foregroundColor: Colors.black,
// //         title: Text(
// //           "Saved Places",
// //           style: GoogleFonts.spaceGrotesk(
// //             fontSize: 20,
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         centerTitle: true,
// //       ),

// //       body: ListView(
// //         padding: const EdgeInsets.all(20),
// //         children: [
// //           _savedPlace(
// //             icon: Icons.home_outlined,
// //             title: "Home",
// //             address: "Add your home address",
// //           ),

// //           _savedPlace(
// //             icon: Icons.work_outline,
// //             title: "Work",
// //             address: "Add your work address",
// //           ),

// //           const SizedBox(height: 15),

// //           OutlinedButton.icon(
// //             onPressed: () {},
// //             icon: const Icon(
// //               Icons.add,
// //               color: Color(0xFF015ACE),
// //             ),
// //             label: Text(
// //               "Add Saved Place",
// //               style: GoogleFonts.spaceGrotesk(
// //                 fontWeight: FontWeight.w600,
// //                 color: const Color(0xFF015ACE),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _savedPlace({
// //     required IconData icon,
// //     required String title,
// //     required String address,
// //   }) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 10),
// //       padding: const EdgeInsets.all(15),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF1F2F4),
// //         borderRadius: BorderRadius.circular(15),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 44,
// //             height: 44,
// //             decoration: BoxDecoration(
// //               color: Colors.white,
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //             child: Icon(
// //               icon,
// //               color: const Color(0xFF015ACE),
// //             ),
// //           ),

// //           const SizedBox(width: 14),

// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   title,
// //                   style: GoogleFonts.spaceGrotesk(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 3),
// //                 Text(
// //                   address,
// //                   style: GoogleFonts.nunitoSans(
// //                     fontSize: 13,
// //                     color: Colors.black54,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           const Icon(
// //             Icons.chevron_right,
// //             color: Colors.black38,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }