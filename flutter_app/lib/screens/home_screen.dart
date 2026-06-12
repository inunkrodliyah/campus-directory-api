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

  String selectedSort = 'default';
  String selectedCategory = 'Semua';

  // ✅ Tambahan kategori
  final List<String> categories = [
    'Semua',
    'Fotocopy & Printing',
    '24 Jam',
    'Warnet & Rental Komputer',
    'Percetakan & Digital Printing',
  ];

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

      _filterPlaces();
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

  // ✅ UPDATED FILTER (MULTI CATEGORY)
  void _filterPlaces() {
    setState(() {
      filteredPlaces = allPlaces.where((place) {
        final searchMatch =
            _searchController.text.isEmpty ||
                place.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                place.address.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );

        final categoryMatch =
        selectedCategory == 'Semua'
            ? true
            : place.category.contains(selectedCategory);

        final bukaMatch =
        selectedSort == 'buka24'
            ? place.openHours.toLowerCase().contains('24')
            : true;

        return searchMatch && categoryMatch && bukaMatch;
      }).toList();

      if (selectedSort == 'terdekat' && userLocation != null) {
        filteredPlaces.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation!.longitude,
            a.latitude,
            a.longitude,
          );

          final distB = Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation!.longitude,
            b.latitude,
            b.longitude,
          );

          return distA.compareTo(distB);
        });
      } else if (selectedSort == 'rating') {
        filteredPlaces.sort(
              (a, b) => b.rating.compareTo(a.rating),
        );
      }
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
            const Icon(Icons.wifi_off,
                size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(errorMessage,
                style:
                const TextStyle(color: Colors.grey)),
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
          // SEARCH
          Container(
            color: Colors.blue[800],
            padding:
            const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterPlaces();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari tempat fotocopy...',
                hintStyle:
                const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.white70),
                suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _filterPlaces();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.blue[700],
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ FILTER BAR (2 DROPDOWN)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    prefixIcon:
                    const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedCategory = value;
                    });

                    _filterPlaces();
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedSort,
                  decoration: InputDecoration(
                    labelText: "Urutkan",
                    prefixIcon: const Icon(Icons.sort),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'default',
                        child: Text('Semua')),
                    DropdownMenuItem(
                        value: 'terdekat',
                        child: Text('Terdekat')),
                    DropdownMenuItem(
                        value: 'rating',
                        child: Text(
                            'Rating Tertinggi ⭐')),
                    DropdownMenuItem(
                        value: 'buka24',
                        child: Text('Buka 24 Jam')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedSort = value;
                    });

                    _filterPlaces();
                  },
                ),
              ],
            ),
          ),

          // RESULT COUNT
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${filteredPlaces.length} tempat ditemukan',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: filteredPlaces.isEmpty
                ? const Center(
                child: Text(
                    'Tidak ada tempat yang ditemukan'))
                : RefreshIndicator(
              onRefresh: fetchPlaces,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    12, 4, 12, 12),
                itemCount: filteredPlaces.length,
                itemBuilder: (context, index) {
                  final place =
                  filteredPlaces[index];

                  return _PlaceCard(
                    place: place,
                    distance: _getDistance(place),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetailScreen(
                                place: place,
                                userLocation:
                                userLocation,
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: place.photoUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding:
              const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),

                  const SizedBox(height: 8),

                  // ✅ KATEGORI CHIP
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                    place.category.map((category) {
                      return Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                          Colors.blue.shade50,
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[800],
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  Text(place.address,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey)),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 16,
                          color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(place.rating.toString()),
                      const Spacer(),
                      Text(distance),
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