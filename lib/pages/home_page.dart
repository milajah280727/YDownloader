import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../providers/history_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/player_page.dart';

class HomePage extends StatefulWidget {
  final Function()? onOpenPlayer;

  const HomePage({super.key, this.onOpenPlayer});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Variabel Config Server
  String _baseUrl = '';
  final String _remoteConfigUrl =
      'https://gist.githubusercontent.com/milajah280727/216157b20454e7bd30721e2106c0efb7/raw/config.json';

  // Variabel untuk Rekomendasi
  final YoutubeExplode _yt = YoutubeExplode();
  List<Video> _recommendations = [];
  bool _isLoadingRecs = true;

  @override
  void initState() {
    super.initState();
    _fetchRemoteConfig();
    _fetchRecommendations();
  }

  // Fungsi ambil config server
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
      debugPrint("Gagal load config di HomePage: $e");
    }
  }

  // --- LOGIKA UPDATE: 5 KEYWORD x 6 VIDEO = 30 KONTEN ---
  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoadingRecs = true;
    });

    try {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      
      // Ambil 5 kata kunci pencarian terakhir
      List<String> recentSearches = searchProvider.searchHistory.take(5).toList();
      
      if (recentSearches.isEmpty) {
        setState(() {
          _recommendations = [];
          _isLoadingRecs = false;
        });
        return;
      }

      List<Video> combinedResults = [];

      // Untuk setiap kata kunci, cari 6 video baru
      for (String keyword in recentSearches) {
        try {
          final searchList = await _yt.search.search(keyword);
          final iterator = searchList.iterator;
          
          int count = 0;
          // Ambil 6 video per kata kunci
          while (iterator.moveNext() && count < 6) {
            combinedResults.add(iterator.current);
            count++;
          }
        } catch (e) {
          debugPrint("Gagal search rekomendasi untuk $keyword: $e");
        }
      }

      setState(() {
        _recommendations = combinedResults;
        _isLoadingRecs = false;
      });

    } catch (e) {
      debugPrint("Error fetch rekomendasi: $e");
      setState(() {
        _isLoadingRecs = false;
      });
    }
  }

  // Fungsi putar video
  void _playRecommendation(Video video) async {
    // Tambahkan ke history saat diputar
    Provider.of<HistoryProvider>(context, listen: false).addToHistory(video, _baseUrl);

    if (_baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memuat server... silakan coba lagi sebentar.'),
          backgroundColor: Colors.orange,
        ),
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
        onRefresh: _fetchRecommendations,
        color: Colors.pinkAccent,
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header Sapaan
              const Text(
                'Selamat Datang',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tarik ke bawah untuk rekomendasi baru',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 25),

              // Logic Tampilan
              if (_isLoadingRecs)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  ),
                )
              else if (_recommendations.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Column(
                      children: const [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Belum ada rekomendasi.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Cari lagu atau video favoritmu sekarang!',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Render 30 item
                    ..._recommendations.map((video) {
                      final durationText = _formatDuration(video.duration);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: GestureDetector(
                          onTap: () => _playRecommendation(video),
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
                              // Info Judul
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
                                      'Rekomendasi Pencarian',
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