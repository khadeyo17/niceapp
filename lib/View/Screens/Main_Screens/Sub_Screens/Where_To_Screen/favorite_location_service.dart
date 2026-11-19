import 'dart:convert';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/favorite_location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteLocationService {
  static const _key = 'favorite_locations';

  static Future<List<FavoriteLocation>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((s) => FavoriteLocation.fromMap(json.decode(s))).toList();
  }

  static Future<void> addFavorite(FavoriteLocation fav) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getFavorites();

    final updated = [...existing, fav];
    final encoded = updated.map((f) => json.encode(f.toMap())).toList();
    await prefs.setStringList(_key, encoded);
  }

  static Future<void> removeFavorite(FavoriteLocation fav) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getFavorites();
    final updated = existing.where((f) => f.name != fav.name).toList();
    final encoded = updated.map((f) => json.encode(f.toMap())).toList();
    await prefs.setStringList(_key, encoded);
  }
}
