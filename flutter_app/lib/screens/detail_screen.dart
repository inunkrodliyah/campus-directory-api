import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/favorites_manager.dart';
import 'route_screen.dart';

class DetailScreen extends StatefulWidget {
  final Place place;
  final LatLng? userLocation;

  const DetailScreen({
    super.key,
    required this.place,
    this.userLocation,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _getDistance() {
    if (widget.userLocation == null) return 'Mencari lokasi...';
    final distanceInMeters = Geolocator.distanceBetween(
      widget.userLocation!.latitude,
      widget.userLocation!.longitude,
      widget.place.latitude,
      widget.place.longitude,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  void _openRoute(BuildContext context) {
    if (widget.userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunggu sebentar, lokasi Anda belum ditemukan.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteScreen(
          place: widget.place,
          userLocation: widget.userLocation!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            elevation: 0,
            // PERBAIKAN: Menghapus properti actions [] dari sini agar ikon bookmark di pojok kanan atas hilang!
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.place.photoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.blue[900],
                      child: const Icon(Icons.store, size: 80, color: Colors.white30),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.place.name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.place.category.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              cat.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('Informasi Tempat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      _infoCard(
                        icon: Icons.star_rounded,
                        color: Colors.amber.shade600,
                        label: 'Rating',
                        value: '${widget.place.rating} / 5.0',
                        trailing: Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < widget.place.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                      ),
                      _infoCard(icon: Icons.location_on_rounded, color: Colors.red.shade400, label: 'Alamat', value: widget.place.address),
                      _infoCard(icon: Icons.access_time_filled_rounded, color: Colors.blue.shade400, label: 'Jam Buka', value: widget.place.openHours),
                      _infoCard(icon: Icons.phone_rounded, color: Colors.green.shade400, label: 'Telepon', value: widget.place.phone.isEmpty ? 'Tidak ada nomor' : widget.place.phone),
                      _infoCard(icon: Icons.directions_walk_rounded, color: Colors.orange.shade400, label: 'Jarak dari lokasi Anda', value: _getDistance()),

                      const SizedBox(height: 12),

                      // PERBAIKAN: Memasang tanda Saved (Bookmark) berbentuk kartu yang sejajar dengan kartu informasi lainnya di bawah
                      ValueListenableBuilder<List<String>>(
                        valueListenable: FavoritesManager.favoritesNotifier,
                        builder: (context, savedIds, _) {
                          final isSaved = savedIds.contains(widget.place.id);
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              FavoritesManager.toggleSaved(widget.place.id);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSaved
                                        ? '${widget.place.name} dihapus dari Saved.'
                                        : '${widget.place.name} disimpan ke Saved.',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSaved ? Colors.amber.shade50.withOpacity(0.4) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSaved ? Colors.amber.shade200 : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSaved ? Colors.amber.shade100 : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: isSaved ? Colors.amber.shade800 : Colors.grey.shade600,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Simpan Tempat',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isSaved ? 'Toko ini ada di daftar favorit Anda' : 'Ketuk untuk menambahkan ke favorit',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: isSaved ? Colors.amber.shade800 : Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _openRoute(context),
                          icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                          label: const Text('Navigasi Sekarang', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required Color color, required String label, required String value, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}