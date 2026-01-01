import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'pages/home_page.dart';
import 'pages/music_page.dart';
import 'pages/favorites_page.dart';
import 'pages/history_page.dart';
import 'widgets/player_page.dart';
import 'pages/search_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primaryColor: Colors.grey[800],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  
  // Controller untuk PageView (Geser Kiri Kanan)
  final PageController _pageController = PageController();
  
  // State untuk Menampilkan/Menyembunyikan Player
  bool _showPlayer = false;
  bool _isPlayerFullscreen = false;

  // Fungsi menerima status fullscreen dari player_page
  void _handleFullScreenChanged(bool isFull) {
    setState(() {
      _isPlayerFullscreen = isFull;
    });
  }

  // Fungsi saat GNav diklik
  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fungsi saat User melakukan Swipe di PageView
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openPlayer() {
    setState(() {
      _showPlayer = true;
    });
  }

  void _closePlayer() {
    setState(() {
      _showPlayer = false;
    });
  }

  // Fungsi untuk pindah ke halaman pencarian
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      
      // Drawer Kosong
      drawer: const Drawer(),

      // Tidak menggunakan AppBar standar
      body: Column(
        children: [
          // Header (Menu + Search Bar)
          // HANYA muncul JIKA player TIDAK ditampilkan DAN TIDAK fullscreen
          if (!(_showPlayer || _isPlayerFullscreen))
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    // 1. Tombol Menu (Kiri)
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    
                    const SizedBox(width: 10),
                    
                    // 2. Search Bar (Tengah)
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        onTap: _openSearch,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Cari...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[850],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.pink, width: 1),
                          ),
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),

          // Bagian Konten (PageView & Player Overlay)
          Expanded(
            child: Stack(
              children: [
                // Layer 1: Halaman Utama (PageView)
                Offstage(
                  offstage: _showPlayer,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      // Tab 0: Beranda
                      HomePage(onOpenPlayer: _openPlayer),
                      // Tab 1: Musik
                      const MusicPage(),
                      // Tab 2: Favorit
                      const FavoritesPage(),
                      // Tab 3: Histori
                      const HistoryPage(),
                    ],
                  ),
                ),

                // Layer 2: Player Overlay
                if (_showPlayer)
                  MediaPlayerPage(
                    onBack: _closePlayer,
                    onFullScreenChanged: _handleFullScreenChanged,
                  ),
              ],
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: (_showPlayer || _isPlayerFullscreen)
          ? null
          : Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 52, 51, 51),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: const Color.fromARGB(255, 149, 149, 149).withOpacity(.1),
                  )
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                  child: GNav(
                    gap: 8,
                    activeColor: const Color.fromARGB(255, 255, 255, 255),
                    iconSize: 24,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    duration: Duration(milliseconds: 400),
                    tabBackgroundColor: const Color.fromARGB(255, 248, 106, 154),
                    color: const Color.fromARGB(255, 181, 180, 180),
                    tabs: [
                      GButton(
                        icon: LineIcons.home,
                        text: 'Beranda',
                      ),
                      GButton(
                        icon: LineIcons.music,
                        text: 'Musik',
                      ),
                      GButton(
                        icon: LineIcons.heart,
                        text: 'Favorit',
                      ),
                      GButton(
                        icon: LineIcons.history,
                        text: 'Histori',
                      ),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      _onItemTapped(index);
                    },
                  ),
                ),
              ),
            ),
    );
  }
}