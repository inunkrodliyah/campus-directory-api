import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class RouteScreen extends StatefulWidget {
  final Place place;
  final ll2.LatLng userLocation;

  const RouteScreen({
    super.key,
    required this.place,
    required this.userLocation,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  GoogleMapController? _mapController;
  
  // Variabel untuk menyimpan gambar panah custom
  BitmapDescriptor? _navigationArrowIcon; 
  
  List<LatLng> routePoints = [];
  bool isLoading = true;
  
  String distanceInfo = "";
  String durationInfo = "";
  
  late LatLng currentUserLocation;
  double currentHeading = 0.0; 
  StreamSubscription<Position>? positionStream;
  
  bool _isFollowingUser = true; 
  String _transportMode = 'driving'; 
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    currentUserLocation = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);
    _loadCustomMarker(); // Memuat gambar panah saat layar dibuka
    _getRoute();
    _startLiveTracking();
  }

  // Fungsi untuk memuat gambar assets/arrow.png menjadi Marker Peta
  Future<void> _loadCustomMarker() async {
    _navigationArrowIcon = await BitmapDescriptor.fromAssetImage(
      // Sesuaikan ukurannya di sini jika panah terlihat terlalu besar/kecil di peta
      const ImageConfiguration(size: Size(64, 64)), 
      'assets/arrow.png', 
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getRoute() async {
    setState(() => isLoading = true);
    
    final start = currentUserLocation; 
    final end = LatLng(widget.place.latitude, widget.place.longitude);

    String serverPath = _transportMode == 'driving' ? 'routed-car' : 'routed-foot';
    final url = 'https://routing.openstreetmap.de/$serverPath/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';

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
        
        _updateCamera(); 
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute: $e");
      setState(() => isLoading = false);
    }
  }

  void _startLiveTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, 
    );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (mounted) {
        setState(() {
          currentUserLocation = LatLng(position.latitude, position.longitude);
          if (position.heading > 0) {
            currentHeading = position.heading;
          }
        });
        
        if (_isFollowingUser) {
          _updateCamera();
        }
      }
    });
  }

  void _updateCamera() {
    if (_mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentUserLocation,
          zoom: _isNavigating ? 19.0 : 16.5,
          tilt: _isNavigating ? 65.0 : 0.0,
          bearing: _isNavigating ? currentHeading : 0.0, 
        ),
      ),
    );
  }

  void _changeTransportMode(String mode) {
    if (_transportMode == mode || _isNavigating) return;
    setState(() => _transportMode = mode);
    _getRoute(); 
  }

  void _toggleNavigation() {
    setState(() {
      _isNavigating = !_isNavigating;
      _isFollowingUser = true;
    });
    _updateCamera();
  }

  @override
  Widget build(BuildContext context) {
    final destination = LatLng(widget.place.latitude, widget.place.longitude);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isNavigating 
        ? null 
        : AppBar(
            title: Text('Menuju ${widget.place.name}', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentUserLocation,
              zoom: 16.5,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            
            // MAGIC TRICK: Matikan titik biru bawaan HANYA jika sedang navigasi
            myLocationEnabled: !_isNavigating,       
            
            myLocationButtonEnabled: false, 
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            tiltGesturesEnabled: true,
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: routePoints,
                color: _transportMode == 'driving' ? Colors.blue[600]! : Colors.green,
                width: _isNavigating ? 12 : 6,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
                zIndex: 1,
              ),
            },
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: destination,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: widget.place.name),
              ),
              
              // MUNCULKAN MARKER PANAH KETIKA NAVIGASI DIMULAI
              if (_isNavigating && _navigationArrowIcon != null)
                Marker(
                  markerId: const MarkerId('navigation_arrow'),
                  position: currentUserLocation,
                  icon: _navigationArrowIcon!,
                  rotation: currentHeading, // Berputar menyesuaikan arah jalan
                  anchor: const Offset(0.5, 0.5), // Poros rotasi tepat di tengah panah
                  flat: true, // PENTING: Membuat panah merebah rata di jalan (efek 3D)
                  zIndex: 2,
                ),
            },
            onCameraMoveStarted: () {
              if (_isFollowingUser) {
                setState(() => _isFollowingUser = false);
              }
            },
          ),
          
          if (!_isNavigating)
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

          if (!_isFollowingUser)
            Positioned(
              bottom: 150, 
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() => _isFollowingUser = true);
                  _updateCamera();
                },
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),

          if (isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        _transportMode == 'driving' ? Icons.directions_car : Icons.directions_walk, 
                        _transportMode == 'driving' ? Colors.blue : Colors.green, 
                        'Estimasi Waktu', 
                        durationInfo
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _buildInfoItem(Icons.route, Colors.orange, 'Jarak Tempuh', distanceInfo),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: routePoints.isEmpty ? null : _toggleNavigation,
                      icon: Icon(_isNavigating ? Icons.close : Icons.navigation, color: Colors.white),
                      label: Text(
                        _isNavigating ? 'Akhiri Perjalanan' : 'Mulai Perjalanan', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNavigating ? Colors.red[600] : Colors.blue[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon, String label) {
    final isSelected = _transportMode == mode;
    return ElevatedButton.icon(
      onPressed: () => _changeTransportMode(mode),
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.blue[800]),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blue[800])),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[800] : Colors.white,
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}