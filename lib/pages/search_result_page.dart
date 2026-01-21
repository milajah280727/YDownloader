import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import '../widgets/player_page.dart';
import 'package:provider/provider.dart';
import '../services/download_manager.dart';
class SearchResultPage extends StatefulWidget {
  final String searchQuery;
  
  const SearchResultPage({super.key, required this.searchQuery});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
} 

class _SearchResultPageState extends State<SearchResultPage> {
  late TextEditingController _searchController;
  
  final YoutubeExplode _yt = YoutubeExplode();
  List<Video> _videos = [];
  bool _isLoading = false;
  
  String _baseUrl = ''; 
  final String _remoteConfigUrl = 'https://gist.githubusercontent.com/milajah280727/216157b20454e7bd30721e2106c0efb7/raw/config.json';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _fetchRemoteConfig();
    _performSearch(widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yt.close();
    super.dispose();
  }

  // Fungsi untuk mengambil URL Server dari Gist
  Future<void> _fetchRemoteConfig() async {
    try {
      final response = await http.get(Uri.parse(_remoteConfigUrl)).timeout(
        const Duration(seconds: 3), // Dipercepat timeoutnya menjadi 3 detik
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> config = json.decode(response.body);
        final String? newUrl = config['api_base_url'];

        if (newUrl != null && newUrl.isNotEmpty) {
          setState(() {
            _baseUrl = newUrl;
          });
          print("✅ URL Server berhasil diperbarui: $newUrl");
        }
      }
    } catch (e) {
      print("⚠️ Gagal refresh config, menggunakan URL sebelumnya (jika ada): $e");
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _videos = [];
    });

    try {
      var searchResults = await _yt.search.search(query);
      var videoList = searchResults.take(10).toList();
      
      setState(() {
        _videos = videoList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error searching: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openPlayer(Video video) async {
    // 1. Tampilkan loading indicator sebentar agar user tahu aplikasi memproses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
    );

    // 2. OTOMATIS REFRESH GIST saat user klik video
    await _fetchRemoteConfig();

    // Sembunyikan loading
    if (mounted) Navigator.pop(context);

    // 3. Cek apakah URL valid
    if (_baseUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat konfigurasi server! Cek koneksi.')),
        );
      }
      return;
    }

    // 4. Siapkan URL Video
    String youtubeUrl = 'https://www.youtube.com/watch?v=${video.id}';
    String streamUrl = '$_baseUrl/stream-video?url=$youtubeUrl&resolution=720';

    String thumbnailUrl = video.thumbnails.highResUrl;
    String title = video.title;
    
    // 5. Buka Player
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPlayerPage(
            onBack: () => Navigator.pop(context),
            customVideoUrl: streamUrl, 
            thumbnailUrl: thumbnailUrl,
            title: title,
            youtubeUrl: youtubeUrl,
            baseUrl: _baseUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          readOnly: true,
                          onTap: () => Navigator.pop(context),
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
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),

              // Tampilan Status URL
              if (_baseUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done, color: Colors.green, size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Server: ${Uri.parse(_baseUrl).host}",
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    : _videos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 80, color: Colors.grey),
                                const SizedBox(height: 20),
                                const Text('Tidak ada hasil ditemukan', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: _videos.length,
                            itemBuilder: (context, index) {
                              final video = _videos[index];
                              return Card(
                                color: Colors.grey[900],
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: SizedBox(
                                    width: 110, 
                                    height: 140, 
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                          ),
                                          child: Image.network(
                                            video.thumbnails.mediumResUrl,
                                            width: 110,
                                            height: 140,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 5,
                                          right: 5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              _formatDuration(video.duration),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                    video.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    video.author,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  onTap: () => _openPlayer(video),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // --- TAMBAHAN PROGRESS BAR GLOBAL DI SEARCH PAGE ---
          Consumer<DownloadManager>(
            builder: (context, downloadMgr, child) {
              return downloadMgr.isDownloading
                  ? Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        color: Colors.black.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: downloadMgr.progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                              minHeight: 4,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Downloading ${downloadMgr.currentTask}...",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${(downloadMgr.progress * 100).toInt()}%",
                                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
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