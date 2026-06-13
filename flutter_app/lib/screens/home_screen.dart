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
  
  // Konfigurasi Kategori Baru (Sesuai kodemu)
  String selectedCategory = 'Semua';
  final List<Map<String, dynamic>> categories = [
    {'value': 'Semua', 'icon': Icons.apps},
    {'value': 'Fotocopy & Printing', 'icon': Icons.print},
    {'value': '24 Jam', 'icon': Icons.access_time},
    {'value': 'Warnet & Rental Komputer', 'icon': Icons.computer},
    {'value': 'Percetakan & Digital Printing', 'icon': Icons.local_printshop},
  ];

  // State untuk Rating
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
      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });
        _filterPlaces(); // Filter ulang saat lokasi didapat (untuk update jarak)
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  Future<void> fetchPlaces() async {
    try {
      final data = await ApiService.getPlaces();
      if (mounted) {
        setState(() {
          allPlaces = data;
          filteredPlaces = data;
          isLoading = false;
        });
        _filterPlaces();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat data. Cek koneksi internet.';
          isLoading = false;
        });
      }
    }
  }

  void _filterPlaces() {
    setState(() {
      filteredPlaces = allPlaces.where((place) {
        final searchMatch = _searchController.text.isEmpty ||
            place.name.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
            place.address.toString().toLowerCase().contains(_searchController.text.toLowerCase());

        // Logika kategori disesuaikan dengan format kodemu
        final categoryMatch = selectedCategory == 'Semua'
            ? true
            : place.category.contains(selectedCategory);

        final ratingMatch = place.rating >= minRating;

        return searchMatch && categoryMatch && ratingMatch;
      }).toList();
    });
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

  // Menampilkan Bottom Sheet untuk Filter (Desain Profesional)
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar (garis kecil di atas bottom sheet)
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Filter Pencarian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Bagian Kategori yang menggunakan List-mu
                  const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['value'] as String,
                        child: Row(
                          children: [
                            Icon(
                              cat['icon'] as IconData, 
                              size: 20, 
                              color: selectedCategory == cat['value'] ? Colors.blue[800] : Colors.grey[600]
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat['value'] as String,
                                style: TextStyle(
                                  color: selectedCategory == cat['value'] ? Colors.blue[800] : Colors.black87,
                                  fontWeight: selectedCategory == cat['value'] ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedCategory = value);
                        _filterPlaces();
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bagian Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimal Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(minRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: Colors.blue[800],
                    inactiveColor: Colors.blue[100],
                    onChanged: (value) {
                      setModalState(() => minRating = value);
                      _filterPlaces();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Tombol Terapkan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Terapkan Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Eksplor Kampus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? _buildErrorState()
              : Column(
                  children: [
                    // Header Area with Search & Filter Icon
                    Container(
                      color: Colors.blue[800],
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => _filterPlaces(),
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Cari tempat...',
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterPlaces();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Buka Filter (BottomSheet)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune, color: Colors.white),
                              onPressed: _showFilterBottomSheet,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Jumlah hasil
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            '${filteredPlaces.length} Tempat Ditemukan',
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Grid List
                    Expanded(
                      child: filteredPlaces.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: fetchPlaces,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: crossAxisCount == 1 ? 1.15 : 0.85,
                                    ),
                                    itemCount: filteredPlaces.length,
                                    itemBuilder: (context, index) {
                                      final place = filteredPlaces[index];
                                      return _PlaceCard(
                                        place: place,
                                        distance: _getDistance(place),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => DetailScreen(place: place, userLocation: userLocation)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Ups! Tidak ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Coba gunakan kata kunci atau filter lain.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(errorMessage, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => isLoading = true);
              fetchPlaces();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
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

  const _PlaceCard({required this.place, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: place.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                    ),
                    if (distance.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_walk, size: 14, color: Colors.blue[800]),
                              const SizedBox(width: 4),
                              Text(distance, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place.address,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                              const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(place.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time_filled, size: 14, color: Colors.blue[300]),
                              const SizedBox(width: 4),
                              Text(place.openHours, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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