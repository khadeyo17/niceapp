// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:niceapp/Model/predicted_places.dart';

// final whereToPredictedPlacesProvider =
//     StateProvider.autoDispose<List<PredictedPlaces>?>((ref) {
//       return null;
//     });

// final whereToLoadingProvider = StateProvider.autoDispose<bool>((ref) {
//   return false;
// });

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:dio/dio.dart';

// final predictedPlacesProvider =
//     StateNotifierProvider<PredictedPlacesNotifier, List<Map<String, dynamic>>>(
//       (ref) => PredictedPlacesNotifier(),
//     );

// class PredictedPlacesNotifier
//     extends StateNotifier<List<Map<String, dynamic>>> {
//   PredictedPlacesNotifier() : super([]);

//   Future<void> searchLocation(String query) async {
//     try {
//       final response = await Dio().get(
//         "https://nominatim.openstreetmap.org/search",
//         queryParameters: {"q": query, "format": "json"},
//       );

//       if (response.statusCode == 200 && response.data.isNotEmpty) {
//         state = List<Map<String, dynamic>>.from(response.data);
//       } else {
//         state = [];
//       }
//     } catch (e) {
//       print("Error fetching locations: $e");
//     }
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:niceapp/Model/predicted_places.dart'; // Import your model

// StateProvider for loading state
final whereToLoadingProvider = StateProvider.autoDispose<bool>((ref) {
  return false; // Initially, not loading
});

// StateProvider for the list of predicted places
final whereToPredictedPlacesProvider =
    StateProvider.autoDispose<List<PredictedPlaces>?>((ref) {
      return null; // Initially, no places are available
    });

// StateNotifier to manage the API call
final predictedPlacesNotifierProvider =
    StateNotifierProvider<PredictedPlacesNotifier, List<PredictedPlaces>>(
      (ref) => PredictedPlacesNotifier(ref),
    );

class PredictedPlacesNotifier extends StateNotifier<List<PredictedPlaces>> {
  final Ref ref;

  PredictedPlacesNotifier(this.ref) : super([]);

  Future<void> searchLocation(String query) async {
    try {
      // Set loading state to true when the request starts
      ref.read(whereToLoadingProvider.notifier).state = true;

      final response = await Dio().get(
        "https://maps.googleapis.com/maps/api/place/textsearch/json",
        queryParameters: {
          "query": query,
          "key":
              "AIzaSyCj89S5821WHuOjfnh7JUS2DzeFaYVUQU0", // Replace with your actual API key
        },
      );

      if (response.statusCode == 200 && response.data["results"].isNotEmpty) {
        // Update the predicted places state
        state = List<PredictedPlaces>.from(
          response.data["results"].map(
            (place) => PredictedPlaces.fromJson(place),
          ),
        );
      } else {
        state = [];
      }
    } catch (e) {
      print("Error fetching locations: $e");
      state = [];
    } finally {
      // Set loading state to false after the request finishes
      ref.read(whereToLoadingProvider.notifier).state = false;
    }
  }
}

// class PredictedPlacesNotifier extends StateNotifier<List<PredictedPlaces>> {
//   PredictedPlacesNotifier() : super([]);

//   Future<void> searchLocation(String query) async {
//     try {
//       final response = await Dio().get(
//         "https://nominatim.openstreetmap.org/search",
//         queryParameters: {"q": query, "format": "json", "addressdetails": 1},
//       );

//       if (response.statusCode == 200 && response.data.isNotEmpty) {
//         // Map the response to PredictedPlaces objects
//         List<PredictedPlaces> places = List<PredictedPlaces>.from(
//           response.data.map((place) => PredictedPlaces.fromJson(place)),
//         );

//         state = places;
//       } else {
//         state = [];
//       }
//     } catch (e) {
//       print("Error fetching locations: $e");
//       state = [];
//     }
//   }
// }
