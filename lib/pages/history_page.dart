import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../providers/history_provider.dart';
import '../widgets/player_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _baseUrl = '';
  final String _remoteConfigUrl =
      'https://gist.githubusercontent.com/milajah280727/216157b20454e7bd30721e2106c0efb7/raw/config.json';

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
      debugPrint("Gagal refresh config di HistoryPage: $e");
    }
  }

  // --- FUNGSI REFRESH BARU ---
  Future<void> _onRefresh() async {
    // 1. Cek ulang config server
    await _fetchRemoteConfig();
    
    // 2. Paksa rebuild widget agar timestamp "X menit yang lalu" terupdate
    setState(() {});
  }

  // Fungsi helper untuk format waktu
  String _getTimeAgo(int? timestamp) {
    if (timestamp == null) return "Baru saja";

    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return "Baru saja";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} menit yang lalu";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} hari yang lalu";
    } else if (difference.inDays < 30) {
      return "${(difference.inDays / 7).floor()} minggu yang lalu";
    } else {
      return "${(difference.inDays / 30).floor()} bulan yang lalu";
    }
  }

  void _playVideo(BuildContext context, Map<String, dynamic> historyData) {
    final videoId = historyData['id'];
    final title = historyData['title'];
    final thumbnailUrl = historyData['thumbnail'];
    final storedBaseUrl = historyData['baseUrl'];

    String activeBaseUrl = (storedBaseUrl != null && storedBaseUrl.isNotEmpty) ? storedBaseUrl : _baseUrl;

    if (activeBaseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat server video. Cek koneksi internet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
    final streamUrl = '$activeBaseUrl/stream-video?url=$youtubeUrl&resolution=720';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPlayerPage(
          onBack: () => Navigator.pop(context),
          customVideoUrl: streamUrl,
          thumbnailUrl: thumbnailUrl,
          title: title,
          youtubeUrl: youtubeUrl,
          baseUrl: activeBaseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: RefreshIndicator( // --- TAMBAHKAN REFRESH INDICATOR DI SINI ---
        onRefresh: _onRefresh,
        color: Colors.pinkAccent,
        backgroundColor: Colors.grey[900],
        child: Consumer<HistoryProvider>(
          builder: (context, historyProvider, child) {
            if (historyProvider.history.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada histori',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              );
            }
        
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                itemCount: historyProvider.history.length,
                itemBuilder: (context, index) {
                  final item = historyProvider.history[index];
                  final videoId = item['id'];
                  final title = item['title'];
                  final timestamp = item['timestamp']; 
                  final durationSeconds = item['duration'];
                  final thumbnail = item['thumbnail'];
        
                  final durationText = _formatDuration(Duration(seconds: durationSeconds));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        // Thumbnail
                        GestureDetector(
                          onTap: () => _playVideo(context, item),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Image.network(
                                  thumbnail,
                                  width: 120,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 90,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    );
                                  },
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
                        ),
                        const SizedBox(width: 15),
                        
                        // Detail
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _playVideo(context, item),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
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
                                  _getTimeAgo(timestamp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item['author'] ?? "Unknown",
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
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF2E2E2E),
                                title: const Text('Hapus dari Histori?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                content: const Text('Video ini akan dihapus dari daftar riwayat tontonan Anda.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      historyProvider.removeFromHistory(videoId);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}