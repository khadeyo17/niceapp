class FavoriteLocation {
  final String name;
  final double lat;
  final double lon;

  FavoriteLocation({required this.name, required this.lat, required this.lon});

  Map<String, dynamic> toMap() => {'name': name, 'lat': lat, 'lon': lon};

  static FavoriteLocation fromMap(Map<String, dynamic> map) =>
      FavoriteLocation(name: map['name'], lat: map['lat'], lon: map['lon']);
}
