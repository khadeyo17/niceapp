class VehicleSubCategory {
  final int id;
  final String name;
  final String description;
  final double baseFare;
  final double pricePerKilometer;
  final int seatingCapacity;
  final int maxPassengers;
  final bool isElectric;
  final bool isMotorbike;
  final bool isForLadiesOnly;
  final String? iconUrl;

  VehicleSubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.baseFare,
    required this.pricePerKilometer,
    required this.seatingCapacity,
    required this.maxPassengers,
    required this.isElectric,
    required this.isMotorbike,
    required this.isForLadiesOnly,
    this.iconUrl,
  });

  factory VehicleSubCategory.fromJson(Map<String, dynamic> json) {
    return VehicleSubCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      baseFare: (json['baseFare'] as num).toDouble(),
      pricePerKilometer: (json['pricePerKilometer'] as num).toDouble(),
      seatingCapacity: json['seatingCapacity'],
      maxPassengers: json['maxPassengers'],
      isElectric: json['isElectric'],
      isMotorbike: json['isMotorbike'],
      isForLadiesOnly: json['isForLadiesOnly'],
      iconUrl: json['iconUrl'],
    );
  }
}
