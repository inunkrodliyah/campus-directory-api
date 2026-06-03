import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    _getRoute();
  }

  // Mengambil data rute jalan dari API OSRM
  Future<void> _getRoute() async {
    final start = widget.userLocation;
    final end = LatLng(widget.place.latitude, widget.place.longitude);

    final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        
        setState(() {
          // OSRM mengembalikan koordinat dalam format [longitude, latitude]
          // Kita harus membaliknya menjadi [latitude, longitude] untuk latlong2
          routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.place.latitude, widget.place.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text('Rute ke ${widget.place.name}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                // Posisikan kamera di tengah-tengah antara user dan tujuan
                initialCenter: LatLng(
                  (widget.userLocation.latitude + destination.latitude) / 2,
                  (widget.userLocation.longitude + destination.longitude) / 2,
                ),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.campus_directory',
                ),
                // Layer untuk menggambar garis rute jalan
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
                // Layer untuk pin lokasi user dan tujuan
                MarkerLayer(
                  markers: [
                    // Marker User
                    Marker(
                      point: widget.userLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                    ),
                    // Marker Tujuan
                    Marker(
                      point: destination,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}