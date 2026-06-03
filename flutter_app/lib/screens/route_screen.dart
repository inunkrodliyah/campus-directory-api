import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class RouteScreen extends StatefulWidget {
  final Place place;
  final LatLng userLocation;

  const RouteScreen({
    super.key,
    required this.place,
    required this.userLocation,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  List<LatLng> routePoints = [];
  bool isLoading = true;
  
  String distanceInfo = "";
  String durationInfo = "";
  
  late LatLng currentUserLocation;
  StreamSubscription<Position>? positionStream;
  
  // Fitur Baru: Pengendali Kamera dan Mode Kendaraan
  final MapController _mapController = MapController();
  bool _isFollowingUser = true; // Status apakah kamera sedang mengunci user
  String _transportMode = 'driving'; // Bisa 'driving' atau 'foot'

  @override
  void initState() {
    super.initState();
    currentUserLocation = widget.userLocation;
    _getRoute();
    _startLiveTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // Modifikasi: Menggunakan variabel _transportMode untuk URL OSRM
  Future<void> _getRoute() async {
    setState(() => isLoading = true);
    
    final start = currentUserLocation; 
    final end = LatLng(widget.place.latitude, widget.place.longitude);

    // --- BAGIAN YANG DIUBAH ---
    // Memilih server khusus berdasarkan mode transportasi
    String serverPath = _transportMode == 'driving' ? 'routed-car' : 'routed-foot';
    
    final url =
        'https://routing.openstreetmap.de/$serverPath/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';
    // -------------------------

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        
        final double distanceMeters = data['routes'][0]['distance'].toDouble();
        final double durationSeconds = data['routes'][0]['duration'].toDouble();

        setState(() {
          routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
              
          if (distanceMeters < 1000) {
            distanceInfo = '${distanceMeters.toStringAsFixed(0)} m';
          } else {
            distanceInfo = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
          }

          final int minutes = (durationSeconds / 60).round();
          if (minutes < 60) {
            durationInfo = '$minutes mnt';
          } else {
            final int hours = minutes ~/ 60;
            final int remainingMins = minutes % 60;
            durationInfo = '$hours jam $remainingMins mnt';
          }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute: $e");
      setState(() => isLoading = false);
    }
  }

  // Modifikasi: Menggerakkan kamera saat GPS update
  void _startLiveTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Ditingkatkan untuk navigasi
      distanceFilter: 3, // Update setiap 3 meter
    );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          currentUserLocation = newLocation;
        });

        // Jika mode Follow sedang aktif, paksa kamera pindah ke lokasi user
        if (_isFollowingUser) {
          _mapController.move(newLocation, 17.5);
        }
      }
    });
  }

  // Fungsi untuk mengganti mode kendaraan
  void _changeTransportMode(String mode) {
    if (_transportMode == mode) return;
    setState(() {
      _transportMode = mode;
    });
    _getRoute(); // Hitung ulang rute
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.place.latitude, widget.place.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text('Navigasi ke ${widget.place.name}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Layer Peta
          FlutterMap(
            mapController: _mapController, // Pasang controller di sini
            options: MapOptions(
              initialCenter: currentUserLocation,
              initialZoom: 17.5,
              // Jika user menggeser peta secara manual, matikan mode Follow
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && _isFollowingUser) {
                  setState(() => _isFollowingUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_directory',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 6.0,
                    color: _transportMode == 'driving' ? Colors.blueAccent : Colors.green,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                  // Marker User
                  Marker(
                    point: currentUserLocation,
                    width: 45,
                    height: 45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        // Efek border agar terlihat seperti penunjuk navigasi
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.my_location, color: Colors.blue, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Tombol Pilihan Kendaraan (Di bagian atas peta)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton('driving', Icons.directions_car, 'Berkendara'),
                const SizedBox(width: 12),
                _buildModeButton('foot', Icons.directions_walk, 'Jalan Kaki'),
              ],
            ),
          ),

          // Tombol "Recenter" / Kembali fokus ke user
          if (!_isFollowingUser)
            Positioned(
              bottom: 100, // Di atas panel info
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() => _isFollowingUser = true);
                  _mapController.move(currentUserLocation, 17.5);
                },
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),

          // Loading overlay saat menghitung rute
          if (isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          // Panel Informasi Perjalanan
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    _transportMode == 'driving' ? Icons.directions_car : Icons.directions_walk, 
                    _transportMode == 'driving' ? Colors.blue : Colors.green, 
                    'Waktu', 
                    durationInfo
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[300]),
                  _buildInfoItem(Icons.route, Colors.orange, 'Jarak', distanceInfo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bantuan: Tombol Pilih Mode
  Widget _buildModeButton(String mode, IconData icon, String label) {
    final isSelected = _transportMode == mode;
    return ElevatedButton.icon(
      onPressed: () => _changeTransportMode(mode),
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.blue[800]),
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.blue[800]),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[800] : Colors.white,
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Widget Bantuan: Info Jarak & Waktu
  Widget _buildInfoItem(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value.isEmpty ? '-' : value, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ],
    );
  }
}