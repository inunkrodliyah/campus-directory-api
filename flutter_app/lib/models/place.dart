class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String phone;
  final String photoUrl;
  final String openHours;

  // Multi kategori
  final List<String> category;

  bool isFavorite;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.phone,
    required this.photoUrl,
    required this.openHours,
    required this.category,
    this.isFavorite = false,
  });

factory Place.fromJson(Map<String, dynamic> json) {
    // Fungsi bantuan untuk memastikan output selalu String dengan aman
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is List) {
        // Jika API mengembalikan array, ambil item pertamanya saja
        return value.isNotEmpty ? value.first.toString() : '';
      }
      return value.toString();
    }

    return Place(
      id: parseString(json['id']),
      name: parseString(json['name']),
      address: parseString(json['address']),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      phone: parseString(json['phone']),
      photoUrl: parseString(json['photo_url']),
      openHours: json['open_hours'] != null ? parseString(json['open_hours']) : '-',
      category: json['category'] != null
          ? (json['category'] is List
              ? List<String>.from(json['category'].map((x) => x.toString()))
              : [json['category'].toString()])
          : [],
    );
}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'phone': phone,
      'photo_url': photoUrl,
      'open_hours': openHours,
      'category': category,
    };
  }
}