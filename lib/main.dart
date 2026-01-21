import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; 

import 'pages/home_page.dart';
import 'pages/music_page.dart';
import 'pages/favorites_page.dart';
import 'pages/history_page.dart';
import 'pages/download_page.dart';
import 'widgets/player_page.dart';
import 'pages/search_page.dart';
import 'providers/search_provider.dart';
import 'providers/history_provider.dart';
import 'providers/favorites_provider.dart'; // <--- 1. TAMBAHKAN IMPORT INI
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
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()), // <--- 2. DAFTARKAN PROVIDER DI SINI
      ],
      child: MaterialApp(
        title: 'My App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromARGB(255, 26, 26, 26),
          brightness: Brightness.dark,
          primaryColor: Colors.grey[800],
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark, 
          ),
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            },
          ),
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

  
  Future<void> _checkPermissions() async {
    final videoStatus = await Permission.videos.status;
    final audioStatus = await Permission.audio.status;
    final photosStatus = await Permission.photos.status; 

    if (!(videoStatus.isGranted || videoStatus.isLimited) || !(audioStatus.isGranted)) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
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
              Navigator.pop(context);
            },
            child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); 

              Map<Permission, PermissionStatus> statuses = await [
                Permission.photos,
                Permission.videos,
                Permission.audio,
              ].request();

              final videoResult = statuses[Permission.videos];
              
              if (mounted) {
                if (videoResult != null && videoResult.isPermanentlyDenied) {
                   _showOpenSettingsDialog();
                } else if (videoResult != null && videoResult.isDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Izin ditolak. Tanpa izin ini, file tidak dapat disimpan.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
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
              openAppSettings(); 
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