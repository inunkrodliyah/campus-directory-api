import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../services/favorites_manager.dart';
import 'detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool isLoading = false;
  List<Place> allPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    if (ApiService.cachedPlaces != null) {
      setState(() {
        allPlaces = ApiService.cachedPlaces!;
      });
    } else {
      setState(() => isLoading = true);
      try {
        final data = await ApiService.getPlaces();
        setState(() {
          allPlaces = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = FavoritesManager.getSavedIds();
    final savedPlaces = allPlaces.where((p) => savedIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Menggunakan abu-abu slate premium agar kartu berwarna terlihat kontras
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Tempat Tersimpan',
          style: TextStyle(
            color: Colors.blue.shade900, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue.shade800))
          : savedPlaces.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: savedPlaces.length,
                  itemBuilder: (context, index) {
                    return _buildSavedPlaceCard(savedPlaces[index]);
                  },
                ),
    );
  }

  // ROMBAK TOTAL EMPTY STATE: Menggunakan kombinasi warna pastel lingkaran biru transparan yang sangat menarik
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade100.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded, 
                size: 64, 
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Favorit',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tandai tempat fotocopy pilihanmu agar muncul di halaman favorit ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PERBAIKAN WARNA KARTU LIST: Menggunakan latar belakang Blue-Sky Pastel segar dengan soft shadow ungu/biru samar
  Widget _buildSavedPlaceCard(Place place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE), // Mengganti putih polos menjadi Sky Blue Pastel yang cerah dan sejuk
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(place: place),
            ),
          ).then((_) {
            setState(() {});
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: place.photoUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 76,
                    height: 76,
                    color: Colors.blue.shade100,
                    child: Icon(Icons.store_rounded, color: Colors.blue.shade400, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF0369A1), // Biru tua pekat agar teks terbaca tajam
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: Colors.blue.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.blue.shade800.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (place.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7), // Kontras badge di dalam kanvas kartu pastel
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              place.category.first,
                              style: TextStyle(
                                fontSize: 10, 
                                color: Colors.blue.shade900, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              place.rating.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0369A1),
                              ),
                            )
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            FavoritesManager.removeSaved(place.id);
                            setState(() {});
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${place.name} dihapus dari Saved.'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(
                              Icons.bookmark_rounded, 
                              color: Colors.amber, 
                              size: 22,
                            ),
                          ),
                        ),
                      ],
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