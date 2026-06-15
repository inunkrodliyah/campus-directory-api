import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class ApiService {
  static const String baseUrl =
      'https://campus-directory-api.vercel.app';

static List<Place>? cachedPlaces;

  // =========================
  // GET ALL PLACES
  // =========================
static Future<List<Place>> getPlaces({bool forceRefresh = false}) async {
    // Jika data sudah ada di cache, langsung kembalikan tanpa request API lagi
    if (!forceRefresh && cachedPlaces != null) {
      return cachedPlaces!;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/places'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Simpan data hasil fetch ke cache
        cachedPlaces = data.map((json) => Place.fromJson(json)).toList();
        
        return cachedPlaces!;
      }

      throw Exception('Server Error (${response.statusCode})');
    } catch (e) {
      throw Exception('Gagal mengambil data tempat: $e');
    }
  }
  // =========================
  // ADD PLACE
  // =========================
  static Future<void> addPlace(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/places'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambah tempat',
      );
    }
  }

  // =========================
  // UPDATE PLACE
  // =========================
  static Future<void> updatePlace(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/places/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengubah tempat',
      );
    }
  }

  // =========================
  // DELETE PLACE
  // =========================
  static Future<void> deletePlace(
    String id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/places/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghapus tempat',
      );
    }
  }
}