import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niceapp/Container/utils/keys.dart';
import 'vehicle_subcategory.dart';

Future<List<VehicleSubCategory>> fetchVehicleSubCategoriesByType(
  int type,
) async {
  final response = await http.get(
    Uri.parse(
      '$baseUrl/rides/categories?type=$type',
    ), // e.g., type=0 for RideBooking
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);

    // Flatten all subCategories from all categories
    final List<dynamic> allSubCategories =
        jsonList.expand((category) => category['subCategories'] ?? []).toList();

    return allSubCategories.map((e) => VehicleSubCategory.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load vehicle categories');
  }
}

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:niceapp/Container/utils/keys.dart';
// import 'vehicle_subcategory.dart';

// Future<List<VehicleSubCategory>> fetchVehicleSubCategories() async {
//   final response = await http.get(
//     //Uri.parse('$baseUrl/vehicles/getsubcategories'),
//     Uri.parse('$baseUrl/rides/categories'),
//   );
//   if (response.statusCode == 200) {
//     final Map<String, dynamic> jsonMap = json.decode(response.body);
//     final List<dynamic> jsonList =
//         jsonMap['subCategories']; // adjust key based on your actual response
//     return jsonList.map((e) => VehicleSubCategory.fromJson(e)).toList();
//   } else {
//     throw Exception('Failed to load vehicle categories');
//   }
// }
//   if (response.statusCode == 200) {
//     final List<dynamic> jsonList = json.decode(response.body);
//     return jsonList.map((e) => VehicleSubCategory.fromJson(e)).toList();
//   } else {
//     throw Exception('Failed to load vehicle categories');
//   }
// }

///working with map
// Future<List<VehicleSubCategory>> fetchVehicleSubCategories() async {
//   final response = await http.get(
//     Uri.parse('$baseUrl/vehicles/getsubcategories'),
//   );

//   if (response.statusCode == 200) {
//     // final List<dynamic> jsonList = json.decode(response.body);
//     // return jsonList.map((e) => VehicleSubCategory.fromJson(e)).toList();

//     final Map<String, dynamic> jsonMap = json.decode(response.body);
//     final List<dynamic> jsonList = jsonMap['\$values']; // Note the escaped $

//     return jsonList.map((e) => VehicleSubCategory.fromJson(e)).toList();
//   } else {
//     throw Exception('Failed to load vehicle categories');
//   }
// }
