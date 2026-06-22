import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: MaterialApp(
        title: 'Campus Directory',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // Menggunakan varian Blue 800
            background: Colors.white,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SavedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // PERBAIKAN TOTAL WARNA: Menu bawah diubah dari putih polos menjadi Slate Blue pastel segar dengan border penanda tegas
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8), // Background bernuansa sejuk, tidak putih polos kaku
          border: Border(
            top: BorderSide(
              color: Colors.blue.shade100, // Garis pembatas biru tipis estetik
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          indicatorColor: Colors.blue.shade200, // Efek lingkaran aktif lebih menyala kontras
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: Color(0xFF475569)),
              selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFF0D47A1)),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline_rounded, color: Color(0xFF475569)),
              selectedIcon: Icon(Icons.bookmark_rounded, color: Color(0xFF0D47A1)),
              label: 'Saved',
            ),
          ],
        ),
      ),
    );
  }
}