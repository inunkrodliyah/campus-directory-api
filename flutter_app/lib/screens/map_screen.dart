import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Place> places = [];
  ll2.LatLng? userLocation;
  bool isLoading = ApiService.cachedPlaces == null;
  GoogleMapController? _googleMapController;
  final LatLng defaultCenter = const LatLng(-7.2704, 112.7609);

  @override
  void initState() {
    super.initState();
    if (ApiService.cachedPlaces != null) {
      places = ApiService.cachedPlaces!;
    }
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_fetchPlaces(), _getUserLocation()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchPlaces() async {
    try {
      final data = await ApiService.getPlaces();
      if (mounted) setState(() => places = data);
    } catch (e) {
      debugPrint('Error fetch places: $e');
    }
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
          userLocation = ll2.LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    }
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

  // Tampilkan Detail Ringkas di Bottom Sheet
  void _showPlaceSummary(Place place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRidge(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: place.photoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(color: Colors.grey[200]),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image),
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${place.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_getDistance(place).isNotEmpty) ...[
                              Icon(
                                Icons.directions_walk,
                                color: Colors.blue[800],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getDistance(place),
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DetailScreen(
                              place: place,
                              userLocation: userLocation,
                            ),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat Detail Lengkap',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markerSet = {};

    // 1. Marker lokasi user jika ada
    if (userLocation != null) {
      markerSet.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLocation!.latitude, userLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        ),
      );
    }

    // 2. Marker tempat-tempat fotocopy
    for (final place in places) {
      markerSet.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _showPlaceSummary(place),
        ),
      );
    }

    return markerSet;
  }

  @override
  Widget build(BuildContext context) {
    final LatLng cameraTarget = userLocation != null
        ? LatLng(userLocation!.latitude, userLocation!.longitude)
        : defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peta Kampus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: cameraTarget,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _googleMapController = controller;
              },
              markers: _buildMarkers(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              buildingsEnabled: true, // Gedung 3D
              tiltGesturesEnabled: true,
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          await _getUserLocation();
          if (userLocation != null && _googleMapController != null) {
            _googleMapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(userLocation!.latitude, userLocation!.longitude),
                15,
              ),
            );
          }
        },
        child: Icon(Icons.my_location, color: Colors.blue[800]),
      ),
    );
  }
}

// Widget Bantuan
class ClipRidge extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  const ClipRidge({super.key, required this.child, required this.borderRadius});
  @override
  Widget build(BuildContext context) =>
      ClipRRect(borderRadius: borderRadius, child: child);
}
