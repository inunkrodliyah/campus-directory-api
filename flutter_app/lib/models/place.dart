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
  final String category;
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
    return Place(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      phone: json['phone'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      openHours: json['open_hours'] ?? '-',
      category: json['category'] ?? '',
    );
  }
}