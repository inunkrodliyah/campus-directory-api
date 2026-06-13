import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import 'route_screen.dart';

class DetailScreen extends StatelessWidget {
  final Place place;
  final LatLng? userLocation;

  const DetailScreen({
    super.key,
    required this.place,
    this.userLocation,
  });

  String _getDistance() {
    if (userLocation == null) return 'Mencari lokasi...';
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

  void _openRoute(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background bersih
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: place.photoUrl,
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: place.category.map((cat) {
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
                    value: '${place.rating} / 5.0',
                    trailing: Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < place.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                  ),
                  _infoCard(icon: Icons.location_on_rounded, color: Colors.red.shade400, label: 'Alamat', value: place.address),
                  _infoCard(icon: Icons.access_time_filled_rounded, color: Colors.blue.shade400, label: 'Jam Buka', value: place.openHours),
                  _infoCard(icon: Icons.phone_rounded, color: Colors.green.shade400, label: 'Telepon', value: place.phone.isEmpty ? 'Tidak ada nomor' : place.phone),
                  _infoCard(icon: Icons.directions_walk_rounded, color: Colors.orange.shade400, label: 'Jarak dari lokasi Anda', value: _getDistance()),

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
        ],
      ),
    );
  }

  // Tampilan Info Card Material 3 (Flat, No Shadow)
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