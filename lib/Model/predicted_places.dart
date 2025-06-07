// class PredictedPlaces {
//   String? placeId;
//   String? mainText;
//   String? secText;

//   PredictedPlaces({this.placeId, this.mainText, this.secText});

//   PredictedPlaces.fromJson(Map<String, dynamic> jsonData) {
//     placeId = jsonData["place_id"];
//     mainText = jsonData["structured_formatting"]["main_text"];
//     secText = jsonData["structured_formatting"]["secondary_text"];
//   }
// }
// class PredictedPlaces {
//   String? placeId;
//   String? mainText;
//   String? secText;
//   String? lat; // Latitude (as a string, will need to be parsed)
//   String? lon;
//   String? display_name;
//   // Longitude (as a string, will need to be parsed)

//   PredictedPlaces({
//     this.placeId,
//     this.mainText,
//     this.secText,
//     this.lat,
//     this.lon,
//     this.display_name,
//   });

//   PredictedPlaces.fromJson(Map<String, dynamic> jsonData) {
//     placeId = jsonData["place_id"];
//     mainText = jsonData["structured_formatting"]["main_text"];
//     secText = jsonData["structured_formatting"]["secondary_text"];
//     lat =
//         jsonData["geometry"]["location"]["lat"]
//             .toString(); // Assuming you get lat/lon from 'geometry.location'
//     lon =
//         jsonData["geometry"]["location"]["lng"]
//             .toString(); // Assuming you get lat/lon from 'geometry.location'
//   }
// }

class PredictedPlaces {
  String? placeId;
  String? mainText;
  String? secText;
  String? lat; // Latitude
  String? lon; // Longitude
  String? display_name; // Full display name (if available)

  PredictedPlaces({
    this.placeId,
    this.mainText,
    this.secText,
    this.lat,
    this.lon,
    this.display_name,
  });

  // This constructor parses JSON from Google Places API
  PredictedPlaces.fromJson(Map<String, dynamic> jsonData) {
    placeId = jsonData["place_id"];
    mainText = jsonData["structured_formatting"]["main_text"];
    secText = jsonData["structured_formatting"]["secondary_text"];
    lat = jsonData["geometry"]["location"]["lat"].toString();
    lon = jsonData["geometry"]["location"]["lng"].toString();
    display_name =
        jsonData["description"] ?? "${mainText ?? ""}, ${secText ?? ""}";
  }

  // ✅ Add a safe getter
  String get displayName => display_name ?? mainText ?? "Unnamed";
}
