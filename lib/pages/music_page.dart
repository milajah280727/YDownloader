import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../providers/history_provider.dart';
import '../widgets/player_page.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // --- 1. DAFTAR 10 QUERY MUSIK ---
  final List<String> _musicQueries = [
    'Musik Indonesia Terbaru',
    'KPop Hits 2024',
    'JPop Anime Opening',
    'Lofi Hip Hop Mix',
    'Rock Barat Klasik',
    'Lagu Galau Indonesia',
    'Top 100 Global',
    'DJ Remix Terbaru',
    'Pop Punk Playlist',
    'Gitar Akustik',
  ];

  int _currentQueryIndex = 0; // Indeks kategori saat ini
  String _currentCategoryTitle = ''; // Judul kategori untuk ditampilkan di UI

  final YoutubeExplode _yt = YoutubeExplode();
  List<Video> _musicVideos = [];
  bool _isLoading = true;

  // Config Server
  String _baseUrl = '';
  final String _remoteConfigUrl =
      'https://gist.githubusercontent.com/milajah280727/216157b20454e7bd30721e2106c0efb7/raw/config.json';

  @override
  void initState() {
    super.initState();
    // Set judul kategori awal
    _currentCategoryTitle = _musicQueries[_currentQueryIndex];
    _fetchRemoteConfig();
    _fetchMusic();
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
      debugPrint("Gagal load config di MusicPage: $e");
    }
  }

  // --- 2. LOGIKA REFRESH (GANTI KATEGORI) ---
  Future<void> _fetchMusic() async {
    if (_musicQueries.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil query berdasarkan index saat ini
      String query = _musicQueries[_currentQueryIndex];
      
      // Cari video
      final searchList = await _yt.search.search(query);
      final iterator = searchList.iterator;
      
      List<Video> results = [];
      int count = 0;
      // Ambil 30 video per kategori
      while (iterator.moveNext() && count < 30) {
        results.add(iterator.current);
        count++;
      }

      setState(() {
        _musicVideos = results;
        _currentCategoryTitle = query; // Update judul kategori
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("Error fetch music: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeCategory() async {
    // Logika perpindahan index (0 -> 1 -> ... -> 9 -> 0)
    setState(() {
      _currentQueryIndex = (_currentQueryIndex + 1) % _musicQueries.length;
    });
    
    // Fetch data baru
    await _fetchMusic();
  }

  // Fungsi putar video
  void _playVideo(Video video) async {
    Provider.of<HistoryProvider>(context, listen: false).addToHistory(video, _baseUrl);

    if (_baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat server!'), backgroundColor: Colors.red),
      );
      _fetchRemoteConfig();
      return;
    }

    final youtubeUrl = 'https://www.youtube.com/watch?v=${video.id}';
    final streamUrl = '$_baseUrl/stream-video?url=$youtubeUrl&resolution=720';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPlayerPage(
          onBack: () => Navigator.pop(context),
          customVideoUrl: streamUrl,
          thumbnailUrl: video.thumbnails.highResUrl,
          title: video.title,
          youtubeUrl: youtubeUrl,
          baseUrl: _baseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: RefreshIndicator(
        onRefresh: _changeCategory, // Saat ditarik, ganti kategori
        color: Colors.pinkAccent,
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              
              // Header Judul Kategori
              Row(
                children: [
                  const Icon(Icons.library_music, color: Colors.pinkAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilihan Musik',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading ? 'Memuat musik...' : 'Kategori: $_currentCategoryTitle',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
                ],
              ),
              
              const SizedBox(height: 25),

              // List Video Musik
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  ),
                )
              else if (_musicVideos.isEmpty)
                Center(
                  child: Column(
                    children: const [
                      Icon(Icons.music_off, size: 60, color: Colors.grey),
                      SizedBox(height: 20),
                      Text('Gagal memuat musik.', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hint Text Refresh
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Tarik ke bawah untuk ganti kategori musik',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    
                    ..._musicVideos.map((video) {
                      final durationText = _formatDuration(video.duration);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: GestureDetector(
                          onTap: () => _playVideo(video),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      video.thumbnails.mediumResUrl,
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
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          durationText,
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      video.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Lagu',
                                      style: TextStyle(color: Colors.pinkAccent, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}