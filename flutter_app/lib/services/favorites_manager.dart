import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _key = 'saved_place_ids';
  static List<String> _cachedIds = [];
  static bool _isInitialized = false;

  // Mendapatkan listener agar UI dapat mendengarkan perubahan secara reaktif
  static final ValueNotifier<List<String>> favoritesNotifier = ValueNotifier<List<String>>([]);

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedIds = prefs.getStringList(_key) ?? [];
      favoritesNotifier.value = List.from(_cachedIds);
    } catch (e) {
      debugPrint('Gagal memuat favorit: $e');
      _cachedIds = [];
      favoritesNotifier.value = [];
    }
    _isInitialized = true;
  }

  static List<String> getSavedIds() {
    return _cachedIds;
  }

  static bool isSaved(String id) {
    return _cachedIds.contains(id);
  }

  static Future<void> toggleSaved(String id) async {
    await init(); // Pastikan terinisialisasi
    if (_cachedIds.contains(id)) {
      _cachedIds.remove(id);
    } else {
      _cachedIds.add(id);
    }
    favoritesNotifier.value = List.from(_cachedIds);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _cachedIds);
    } catch (e) {
      debugPrint('Gagal menyimpan favorit: $e');
    }
  }

  static Future<void> removeSaved(String id) async {
    await init();
    if (_cachedIds.contains(id)) {
      _cachedIds.remove(id);
      favoritesNotifier.value = List.from(_cachedIds);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_key, _cachedIds);
      } catch (e) {
        debugPrint('Gagal menghapus favorit: $e');
      }
    }
  }
}
