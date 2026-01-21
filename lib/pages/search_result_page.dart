import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import '../widgets/player_page.dart';
import 'package:provider/provider.dart';
import '../services/download_manager.dart';
import '../providers/history_provider.dart'; 

class SearchResultPage extends StatefulWidget {
  final String searchQuery;

  const SearchResultPage({super.key, required this.searchQuery});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  final YoutubeExplode _yt = YoutubeExplode();
  
  List<Video> _videos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNext = true;
  
  VideoSearchList? _searchList; 
  Iterator<Video>? _searchIterator; 

  String _baseUrl = '';
  final String _remoteConfigUrl =
      'https://gist.githubusercontent.com/milajah280727/216157b20454e7bd30721e2106c0efb7/raw/config.json';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _loadMore();
      }
    });

    _fetchRemoteConfig();
    _performSearch(widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yt.close();
    _scrollController.dispose();
    super.dispose();
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
          debugPrint("✅ URL Server berhasil diperbarui: $newUrl");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Gagal refresh config: $e");
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _videos = [];
      _hasNext = true;
      _searchIterator = null; 
    });

    try {
      _searchList = await _yt.search.search(query);
      _searchIterator = _searchList!.iterator;
      await _loadMore(isInitial: true);

    } catch (e) {
      debugPrint("Error searching: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore({bool isInitial = false}) async {
    if (_isLoadingMore || !_hasNext) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      int count = 0;
      const int batchSize = 25;

      if (_searchIterator == null) return;

      while (count < batchSize) {
        if (_searchIterator!.moveNext()) {
          final item = _searchIterator!.current;
          _videos.add(item);
          count++;
        } else {
          setState(() {
            _hasNext = false;
          });
          break;
        }
      }

    } catch (e) {
      debugPrint("Error loading more: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchRemoteConfig();
    await _performSearch(_searchController.text);
  }

  Future<void> _openPlayer(Video video) async {
    // Tambah ke histori
    Provider.of<HistoryProvider>(context, listen: false).addToHistory(video, _baseUrl);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      ),
    );

    await _fetchRemoteConfig();

    if (mounted) Navigator.pop(context);

    if (_baseUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat konfigurasi server! Cek koneksi.'),
          ),
        );
      }
      return;
    }

    String youtubeUrl = 'https://www.youtube.com/watch?v=${video.id}';
    String streamUrl = '$_baseUrl/stream-video?url=$youtubeUrl&resolution=720';

    String thumbnailUrl = video.thumbnails.highResUrl;
    String title = video.title;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Cari...",
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[850],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Colors.pink,
                                width: 1,
                              ),
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

              if (_baseUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Server: ${Uri.parse(_baseUrl).host}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading && _videos.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.pinkAccent,
                        ),
                      )
                    : _videos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Tidak ada hasil ditemukan',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: Colors.pinkAccent,
                            backgroundColor: Colors.grey[900],
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                              itemCount: _videos.length + 1, 
                              itemBuilder: (context, index) {
                                // Logic Loading Indicator
                                if (index == _videos.length) {
                                  if (_isLoadingMore && _hasNext) {
                                    return const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Center(
                                        child: SizedBox(
                                          width: 30, 
                                          height: 30, 
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, 
                                            color: Colors.pinkAccent
                                          )
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Center(
                                        child: Text(
                                          "Sudah mencapai akhir pencarian",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  }
                                }

                                final video = _videos[index];
                                
                                // UI STYLE HORIZONTAL
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: Row(
                                    children: [
                                      // Thumbnail di Kiri
                                      GestureDetector(
                                        onTap: () => _openPlayer(video),
                                        child: ClipRRect(
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
                                                    _formatDuration(video.duration),
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
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
                                          onTap: () => _openPlayer(video),
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
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),

          // Widget Download (Tetap di bawah)
          Consumer<DownloadManager>(
            builder: (context, downloadMgr, child) {
              return downloadMgr.isDownloading
                  ? Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: downloadMgr.progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.pinkAccent,
                              ),
                              minHeight: 4,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Downloading ${downloadMgr.currentTask}...",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${(downloadMgr.progress * 100).toInt()}%",
                                  style: const TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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