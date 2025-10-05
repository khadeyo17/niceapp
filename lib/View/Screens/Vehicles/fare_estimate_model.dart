// class FareEstimate {
//   final double fare;
//   final int estimatedTimeMinutes;
//   final String currency;
//   final String? timeEstimate;
//   final String categoryName;
//   final String iconUrl;

//   FareEstimate({
//     required this.fare,
//     required this.estimatedTimeMinutes,
//     required this.currency,
//     this.timeEstimate,
//     required this.categoryName,
//     required this.iconUrl,
//   });

//   factory FareEstimate.fromJson(Map<String, dynamic> json) {
//     return FareEstimate(
//       fare: json['fare'].toDouble(),
//       estimatedTimeMinutes: json['estimatedTimeMinutes'],
//       currency: json['currency'],
//       categoryName: json['categoryName'],
//       iconUrl: json['iconUrl'],
//     );
//   }
// }
class FareEstimate {
  final String currency;
  final double fare;
  final double timeEstimate;
  final String categoryName;
  final double distanceKm;
  final String? iconUrl;

  FareEstimate({
    required this.currency,
    required this.fare,
    required this.timeEstimate,
    required this.categoryName,
    required this.distanceKm,
    this.iconUrl,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json');
    return FareEstimate(
      currency: json['currency'] ?? 'KES',
      fare: (json['estimatedFare'] ?? 0).toDouble(), // ✅ corrected
      timeEstimate:
          (json['estimatedTimeMinutes'] ?? 0).toDouble(), // ✅ corrected
      categoryName: json['categoryName'] ?? 'Unknown',
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      //iconUrl: json['iconUrl'],
      iconUrl: json['iconUrl'] ?? '',
    );
  }
}
