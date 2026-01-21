import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../widgets/player_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final String _remoteConfigUrl =
      'https://gist.githubusercontent.com/milajah280727/216157b20454e7bd30721e2106c0efb7/raw/config.json';
  
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchRemoteConfig();
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '$_remoteConfigUrl?t=$timestamp';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> config = json.decode(response.body);
        final String? newUrl = config['api_base_url'];

        if (newUrl != null && newUrl.isNotEmpty) {
          setState(() {
            _baseUrl = newUrl;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal load config di Favorites: $e");
    }
  }

  Future<void> _playFavorite(FavoriteItem item) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }

    if (_baseUrl.isEmpty) {
      await _fetchRemoteConfig();
    }

    if (mounted) Navigator.pop(context);

    if (_baseUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat server! Cek koneksi.')),
        );
      }
      return;
    }

    String youtubeUrl = item.youtubeUrl;
    String streamUrl = '$_baseUrl/stream-video?url=$youtubeUrl&resolution=720';

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPlayerPage(
            customVideoUrl: streamUrl,
            thumbnailUrl: item.thumbnailUrl,
            title: item.title,
            youtubeUrl: item.youtubeUrl,
            baseUrl: _baseUrl,
            localFilePath: null, 
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: Consumer<FavoritesProvider>(
        builder: (context, favProvider, child) {
          final favorites = favProvider.favorites;

          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Belum ada Favorit',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Tekan ikon hati di player',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          // Menggunakan removeTop agar menyatu dengan atas
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                
                // UI STYLE HORIZONTAL
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      // Thumbnail di Kiri
                      GestureDetector(
                        onTap: () => _playFavorite(item),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.network(
                                item.thumbnailUrl,
                                width: 120,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Container(
                                  width: 120,
                                  height: 90,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Detail di Kanan
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _playFavorite(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Status "Favorit" sebagai ganti timestamp
                              const Text(
                                "Ditambahkan ke Favorit",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.type == 'audio' ? "Audio File" : "Video File",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tombol Hapus
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Color.fromARGB(255, 255, 40, 40), size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF2E2E2E),
                              title: const Text('Hapus Favorit?', style: TextStyle(color: Colors.white)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    favProvider.removeFavorite(item.youtubeUrl);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}