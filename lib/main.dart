import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import paket izin

import 'pages/home_page.dart';
import 'pages/music_page.dart';
import 'pages/favorites_page.dart';
import 'pages/history_page.dart';
import 'pages/download_page.dart';
import 'widgets/player_page.dart';
import 'pages/search_page.dart';
import 'providers/search_provider.dart';
import 'services/download_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => DownloadManager()),
      ],
      child: MaterialApp(
        title: 'My App',
        theme: ThemeData(
          primaryColor: Colors.grey[800],
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainPage(),
      ),
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
  final PageController _pageController = PageController();
  bool _showPlayer = false;
  bool _isPlayerFullscreen = false;

  // --- VARIABEL IZIN ---
  bool _hasCheckedPermission = false; 

  void _handleFullScreenChanged(bool isFull) {
    setState(() {
      _isPlayerFullscreen = isFull;
    });
  }

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

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  
  // --- FUNGSI CEK IZIN (SUDAH DIPERBARUI) ---
  Future<void> _checkPermissions() async {
    // Cek status spesifik untuk video dan audio (penting untuk Android 13+)
    final videoStatus = await Permission.videos.status;
    final audioStatus = await Permission.audio.status;
    final photosStatus = await Permission.photos.status; // Kadang perlu juga

    // Jika video/audio belum granted (dan bukan limited), tampilkan dialog
    if (!(videoStatus.isGranted || videoStatus.isLimited) || !(audioStatus.isGranted)) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan klik di luar
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          'Izin Penyimpanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Aplikasi membutuhkan izin akses penyimpanan (Video & Audio) untuk menyimpan file unduhan ke folder Galeri.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Tutup dialog (Tidak disarankan jika butuh download)
              Navigator.pop(context);
            },
            child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog custom

              // --- LOGIKA PERMINTA IZIN BARU (GRANULAR) ---
              // Meminta izin secara spesifik (Video & Audio) agar popup sistem muncul
              Map<Permission, PermissionStatus> statuses = await [
                Permission.photos,
                Permission.videos,
                Permission.audio,
              ].request();

              // Ambil status video untuk dijadikan patokan utama
              final videoResult = statuses[Permission.videos];
              
              if (mounted) {
                if (videoResult != null && videoResult.isPermanentlyDenied) {
                   // Jika user centang "Jangan tanya lagi" (Don't ask again)
                   _showOpenSettingsDialog();
                } else if (videoResult != null && videoResult.isDenied) {
                  // Jika user klik "Tolak" biasa
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Izin ditolak. Tanpa izin ini, file tidak dapat disimpan.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  // Granted (Berhasil)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Izin berhasil diberikan!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 248, 106, 154),
            ),
            child: const Text('Izinkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Izin Ditolak', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Anda telah memilih untuk menolak izin dan tidak menanyakannya lagi.\n\nSilakan buka Pengaturan Aplikasi untuk mengaktifkannya.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Membuka halaman pengaturan HP
            },
            child: const Text('Buka Pengaturan', style: TextStyle(color: Colors.pinkAccent)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Panggil fungsi cek izin saat awal
    _checkPermissions();
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
      body: Stack(
        children: [
          Column(
            children: [
              if (!(_showPlayer || _isPlayerFullscreen))
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
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
                              suffixIcon: const Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: Offstage(
                  offstage: _showPlayer,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      HomePage(onOpenPlayer: _openPlayer),
                      const MusicPage(),
                      const FavoritesPage(),
                      const HistoryPage(),
                      const DownloadPage(),
                    ],
                  ),
                ),
              ),

              if (!(_showPlayer || _isPlayerFullscreen))
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 52, 51, 51),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: const Color.fromARGB(255, 149, 149, 149).withOpacity(.1),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 30),
                    child: GNav(
                      gap: 5,
                      activeColor: const Color.fromARGB(255, 255, 255, 255),
                      iconSize: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      duration: const Duration(milliseconds: 400),
                      tabBackgroundColor: const Color.fromARGB(255, 248, 106, 154),
                      color: const Color.fromARGB(255, 181, 180, 180),
                      tabs: [
                        GButton(icon: LineIcons.home, text: 'Beranda'),
                        GButton(icon: LineIcons.music, text: 'Musik'),
                        GButton(icon: LineIcons.heart, text: 'Favorit'),
                        GButton(icon: LineIcons.history, text: 'Histori'),
                        GButton(icon: LineIcons.download, text: 'Unduhan'),
                      ],
                      selectedIndex: _selectedIndex,
                      onTabChange: (index) {
                        _onItemTapped(index);
                      },
                    ),
                  ),
                ),
            ],
          ),

          if (_showPlayer)
            MediaPlayerPage(
              onBack: _closePlayer,
              onFullScreenChanged: _handleFullScreenChanged,
              thumbnailUrl: '',
              youtubeUrl: '',
              baseUrl: '',
            ),
        ],
      ),
    );
  }
}