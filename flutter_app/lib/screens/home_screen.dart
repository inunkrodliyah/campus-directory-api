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
        // Menambahkan .toString() sebelum .toLowerCase() agar kebal terhadap error tipe data List
        final searchMatch = _searchController.text.isEmpty ||
            place.name
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            place.address
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final categoryMatch = selectedCategory == 'Semua'
            ? true
            : place.category.toString().toLowerCase().trim() ==
                selectedCategory.toLowerCase().trim();

        final ratingMatch = place.rating >= minRating;

        return searchMatch && categoryMatch && ratingMatch;
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
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white70),
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
                    // List diubah menjadi Grid yang Responsif
                    Expanded(
                      child: filteredPlaces.isEmpty
                          ? const Center(
                              child: Text('Tidak ada tempat yang ditemukan'),
                            )
                          : RefreshIndicator(
                              onRefresh: fetchPlaces,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Deteksi lebar layar: >800 (3 kolom), >500 (2 kolom), sisanya 1 kolom (HP)
                                  int crossAxisCount = constraints.maxWidth > 800
                                      ? 3
                                      : (constraints.maxWidth > 500 ? 2 : 1);

                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      // Sesuaikan proporsi kartu berdasarkan jumlah kolom
                                      childAspectRatio: crossAxisCount == 1 ? 1.1 : 0.85,
                                    ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Foto
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: place.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                    // Label Jarak di atas gambar
                    if (distance.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_walk,
                                  size: 14, color: Colors.blue[800]),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Bagian Teks
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place.address,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                place.rating.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled,
                                  size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                place.openHours,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}