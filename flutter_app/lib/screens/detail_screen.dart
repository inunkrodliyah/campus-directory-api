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
    if (userLocation == null) return 'GPS tidak aktif';

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
        const SnackBar(
          content: Text('Tunggu sebentar, lokasi Anda belum ditemukan.'),
        ),
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // HEADER FOTO
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: place.photoUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA TEMPAT
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ KATEGORI (CHIP)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: place.category.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: Colors.blue.shade50,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // INFO
                  _infoRow(
                    Icons.star,
                    Colors.amber,
                    'Rating',
                    '${place.rating} / 5.0',
                  ),
                  _infoRow(
                    Icons.location_on,
                    Colors.red,
                    'Alamat',
                    place.address,
                  ),
                  _infoRow(
                    Icons.access_time,
                    Colors.blue,
                    'Jam Buka',
                    place.openHours,
                  ),
                  _infoRow(
                    Icons.phone,
                    Colors.green,
                    'Telepon',
                    place.phone.isEmpty ? '-' : place.phone,
                  ),
                  _infoRow(
                    Icons.directions_walk,
                    Colors.orange,
                    'Jarak',
                    _getDistance(),
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL RUTE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _openRoute(context),
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        'Lihat Rute Perjalanan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}