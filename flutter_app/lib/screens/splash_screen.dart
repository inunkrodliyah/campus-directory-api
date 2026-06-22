import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Memulai proses pramuat data dan navigasi transisi mulus
    _preloadDataAndNavigate();
  }

  Future<void> _preloadDataAndNavigate() async {
    // Jalankan pengambilan API bersamaan dengan durasi minimal tampilan splash (3 detik)
    await Future.wait([
      ApiService.getPlaces().catchError((_) => []),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (mounted) {
      // PERBAIKAN UTAMA: Mengganti MaterialPageRoute bawaan dengan PageRouteBuilder kustom
      // untuk menciptakan efek transisi memudar (Fade Transition) yang sangat halus saat masuk ke halaman utama (MainScreen)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Durasi dan kurva kehalusan transisi dikendalikan oleh animasi transisi internal
            var curve = Curves.easeInOut;
            var curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800), // Durasi transisi memudar (800ms) agar terasa premium
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon pembungkus dengan bayangan halus
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.print_rounded, // Menggunakan versi rounded agar serasi dengan sudut tumpul
                    size: 60,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 24),
                // Nama aplikasi
                const Text(
                  'Fotocopy Sekitar Kampus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Temukan tempat fotocopy terdekat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),
                // Indikator Loading bawah
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.9),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}