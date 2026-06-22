import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'route_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> allPlaces = [];
  List<Place> filteredPlaces = [];
  LatLng? userLocation;
  bool isLoading = ApiService.cachedPlaces == null;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  String selectedCategory = 'Semua';
  
  final List<Map<String, dynamic>> uiCategories = [
    {
      'label': 'Fotocopy',
      'value': 'Fotocopy & Printing',
      'icon': Icons.copy_all_rounded
    },
    {
      'label': 'Print',
      'value': 'Percetakan & Digital Printing',
      'icon': Icons.print_rounded
    },
    {
      'label': 'Warnet',
      'value': 'Warnet & Rental Komputer',
      'icon': Icons.computer_rounded
    },
    {
      'label': 'Jilid',
      'value': 'Jilid',
      'icon': Icons.menu_book_rounded
    },
    {
      'label': 'ATK',
      'value': 'ATK',
      'icon': Icons.border_color_rounded
    },
  ];

  double minRating = 0;

  @override
  void initState() {
    super.initState();

    if (ApiService.cachedPlaces != null) {
      allPlaces = ApiService.cachedPlaces!;
      filteredPlaces = allPlaces;
    }

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
        _filterPlaces();
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

        bool categoryMatch = false;
        if (selectedCategory == 'Semua') {
          categoryMatch = true;
        } else if (selectedCategory == 'Jilid') {
          categoryMatch = place.category.any((c) => c.toLowerCase().contains('jilid')) ||
              place.name.toLowerCase().contains('jilid');
        } else if (selectedCategory == 'ATK') {
          categoryMatch = place.category.any((c) => c.toLowerCase().contains('atk')) ||
              place.name.toLowerCase().contains('atk');
        } else {
          categoryMatch = place.category.contains(selectedCategory);
        }

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
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _getOperationalStatusText(Place place) {
    if (place.openHours == '24 jam' || place.openHours == '24 Jam') {
      return 'Buka • 24 Jam';
    }
    if (place.openHours == '-' || place.openHours.isEmpty) {
      return 'Tutup';
    }

    try {
      final cleanHours = place.openHours
          .replaceAll('–', '-')
          .replaceAll('.', ':')
          .trim();

      final parts = cleanHours.split('-');
      if (parts.length == 2) {
        final startPart = parts[0].trim();
        final endPart = parts[1].trim();

        final now = DateTime.now();

        final startHourParts = startPart.split(':');
        final startHour = int.parse(startHourParts[0]);
        final startMin = int.parse(startHourParts[1]);

        final endHourParts = endPart.split(':');
        final endHour = int.parse(endHourParts[0]);
        final endMin = int.parse(endHourParts[1]);

        final startTime = DateTime(now.year, now.month, now.day, startHour, startMin);
        var endTime = DateTime(now.year, now.month, now.day, endHour, endMin);

        if (endTime.isBefore(startTime)) {
          endTime = endTime.add(const Duration(days: 1));
        }

        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          return 'Buka • ${place.openHours}';
        } else {
          return 'Tutup • Buka ${place.openHours}';
        }
      }
    } catch (e) {
      debugPrint('Error parsing open hours: ${place.openHours} ($e)');
    }

    return 'Buka • ${place.openHours}';
  }

  void _openRoute(Place place) {
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunggu sebentar, lokasi Anda belum ditemukan.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteScreen(
          place: place,
          userLocation: userLocation!,
        ),
      ),
    );
  }

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
                      setModalState(() {
                        minRating = value;
                      });
                      setState(() {
                        minRating = value;
                      });
                      _filterPlaces();
                    },
                  ),
                  const SizedBox(height: 16),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isDesktop = screenWidth > 750;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 0.0),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: Colors.blue[800], size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Fotocopy Sekitar Kampus',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            actions: const [], 
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? _buildErrorState()
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? screenWidth * 0.08 : 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => _filterPlaces(),
                                decoration: InputDecoration(
                                  hintText: 'Cari jasa cetak atau fotocopy...',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                          onPressed: () {
                                            _searchController.clear();
                                            _filterPlaces();
                                          },
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.tune_rounded, color: Colors.grey[700]),
                                        onPressed: _showFilterBottomSheet,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Colors.blue.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                            _buildInteractiveMapBanner(),
                            _buildResponsiveCategorySection(),

                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                              child: Text(
                                'Penyedia Terdekat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            filteredPlaces.isEmpty
                                ? _buildEmptyState()
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                                    child: isDesktop
                                        ? GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: filteredPlaces.length,
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: screenWidth > 1100 ? 3 : 2,
                                              crossAxisSpacing: 20,
                                              mainAxisSpacing: 20,
                                              mainAxisExtent: 395,
                                            ),
                                            itemBuilder: (context, index) {
                                              final place = filteredPlaces[index];
                                              return _buildResponsiveCardItem(place);
                                            },
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: filteredPlaces.length,
                                            itemBuilder: (context, index) {
                                              final place = filteredPlaces[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 16),
                                                child: _buildResponsiveCardItem(place),
                                              );
                                            },
                                          ),
                                  ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildResponsiveCardItem(Place place) {
    return _PlaceCard(
      place: place,
      distance: _getDistance(place),
      statusText: _getOperationalStatusText(place),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(
            place: place,
            userLocation: userLocation,
          ),
        ),
      ),
      onNavigateTap: () => _openRoute(place),
    );
  }

  Widget _buildInteractiveMapBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=600',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.65), Colors.black.withOpacity(0.15)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'PETA INTERAKTIF',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lihat Semua Lokasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCategorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Kategori Layanan',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, catConstraints) {
              final bool useWideStretch = catConstraints.maxWidth > 600;

              return Wrap(
                alignment: useWideStretch ? WrapAlignment.spaceBetween : WrapAlignment.start,
                runSpacing: 16, 
                spacing: useWideStretch ? 0 : 12, 
                children: uiCategories.map((cat) {
                  final bool isSelected = selectedCategory == cat['value'] ||
                      (selectedCategory == 'Jilid' && cat['value'] == 'Jilid') ||
                      (selectedCategory == 'ATK' && cat['value'] == 'ATK');

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedCategory = 'Semua';
                        } else {
                          selectedCategory = cat['value'];
                        }
                      });
                      _filterPlaces();
                    },
                    child: SizedBox(
                      width: 82,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected 
                                      ? const Color(0xFF1565C0).withOpacity(0.25)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: isSelected ? 10 : 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
            icon: const Icon(Icons.refresh_rounded),
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
  final String statusText;
  final VoidCallback onTap;
  final VoidCallback onNavigateTap;

  const _PlaceCard({
    required this.place,
    required this.distance,
    required this.statusText,
    required this.onTap,
    required this.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOpen = statusText.startsWith('Buka');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.03), // Memperhalus bayangan luar kartu toko utama
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: place.photoUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: Colors.blue.shade50,
                      child: Icon(Icons.store_rounded, color: Colors.blue.shade200, size: 40),
                    ),
                  ),
                  // PERBAIKAN: Mengubah badge rating menjadi emas pastel yang kaya warna
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6), // Kuning emas pastel lembut
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            place.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7F5F00)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // PERBAIKAN: Mengubah indikator jam operasional menjadi warna premium (Hijau Emerald / Merah Rose)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6), // Emerald pastel vs Rose pastel
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isOpen ? const Color(0xFFA8DAB5) : const Color(0xFFF9A825).withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: isOpen ? const Color(0xFF137333) : const Color(0xFFC5221F), 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                          ),
                        ),
                        if (distance.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded, size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 2),
                              Text(
                                distance,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.address,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: place.category.map((cat) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: onNavigateTap,
                        icon: const Icon(Icons.directions_walk_rounded, size: 18),
                        label: const Text('Navigasi Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}