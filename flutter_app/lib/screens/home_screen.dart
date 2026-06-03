import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> allPlaces = [];
  List<Place> filteredPlaces = [];
  LatLng? userLocation;
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'Semua';
  double minRating = 0;

  @override
  void initState() {
    super.initState();
    fetchPlaces();
    _getUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  Future<void> fetchPlaces() async {
    try {
      final data = await ApiService.getPlaces();
      setState(() {
      allPlaces = data;
      filteredPlaces = data;
      isLoading = false;
    });

    _filterPlaces();
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data. Cek koneksi internet.';
        isLoading = false;
      });
    }
  }

  void _filterPlaces() {
  setState(() {
    filteredPlaces = allPlaces.where((place) {

      final searchMatch =
          _searchController.text.isEmpty ||
          place.name.toLowerCase().contains(
              _searchController.text.toLowerCase()) ||
          place.address.toLowerCase().contains(
              _searchController.text.toLowerCase());

      final categoryMatch =
          selectedCategory == 'Semua'
          ? true
          : place.category.toLowerCase().trim() ==
          selectedCategory.toLowerCase().trim();

      final ratingMatch =
          place.rating >= minRating;

      return searchMatch &&
          categoryMatch &&
          ratingMatch;
    }).toList();
  });
}

  void _onSearch(String query) {
  _filterPlaces();
}

  String _getDistance(Place place) {
    if (userLocation == null) return '';
    final distanceInMeters = Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      place.latitude,
      place.longitude,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Fotocopy Sekitar Kampus',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(errorMessage,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => isLoading = true);
                          fetchPlaces();
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Container(
                      color: Colors.blue[800],
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _onSearch(value);
                          setState(() {});
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Cari tempat fotocopy...',
                          hintStyle:
                              const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white70),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white70),
                                  onPressed: () {
                                  _searchController.clear();

                                  setState(() {
                                    filteredPlaces = allPlaces;
                                  });

                                  _filterPlaces();
                                },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.blue[700],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),

                    Container(
  color: Colors.white,
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
  child: Column(
    children: [

      DropdownButtonFormField<String>(
  initialValue: selectedCategory,
  decoration: InputDecoration(
    labelText: "Kategori",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  items: const [
    DropdownMenuItem(
      value: 'Semua',
      child: Text('Semua'),
    ),
    DropdownMenuItem(
      value: 'fotocopy',
      child: Text('Fotocopy'),
    ),
  ],
  onChanged: (value) {
    if (value == null) return;

    setState(() {
      selectedCategory = value;
    });

    _filterPlaces();
  },
),

const SizedBox(height: 12),

      Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Text(
            'Rating minimal: ${minRating.toStringAsFixed(1)}',
          ),
        ],
      ),

      Slider(
        value: minRating,
        min: 0,
        max: 5,
        divisions: 10,
        label: minRating.toStringAsFixed(1),
        onChanged: (value) {
          setState(() {
            minRating = value;
          });

          _filterPlaces();
        },
      ),
    ],
  ),
),
                    // Jumlah hasil
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${filteredPlaces.length} tempat ditemukan',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: filteredPlaces.isEmpty
                          ? const Center(
                              child: Text('Tidak ada tempat yang ditemukan'),
                            )
                          : RefreshIndicator(
                              onRefresh: fetchPlaces,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                                itemCount: filteredPlaces.length,
                                itemBuilder: (context, index) {
                                  final place = filteredPlaces[index];
                                  return _PlaceCard(
                                    place: place,
                                    distance: _getDistance(place),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailScreen(
                                            place: place,
                                            userLocation: userLocation,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final String distance;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, // ← INI yang bikin bisa diklik ke detail
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            CachedNetworkImage(
              imageUrl: place.photoUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported,
                    size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        place.openHours,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                      if (distance.isNotEmpty) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            distance,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}