import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import '../widgets/player_page.dart';

class SearchResultPage extends StatefulWidget {
  final String searchQuery;
  
  const SearchResultPage({super.key, required this.searchQuery});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late TextEditingController _searchController;
  
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();
  List<Video> _videos = [];
  bool _isLoading = false;
  final String _baseUrl = 'https://struck-economics-wedding-seafood.trycloudflare.com';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _performSearch(widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yt.close();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _videos = [];
    });

    try {
      var searchResults = await _yt.search.search(query);
      var videoList = await searchResults.take(10).toList();
      
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
    String youtubeUrl = 'https://www.youtube.com/watch?v=${video.id}';
    
    String streamVideoUrl = '$_baseUrl/stream-video?url=$youtubeUrl&resolution=720';
    String streamAudioUrl = '$_baseUrl/stream-audio?url=$youtubeUrl';

    String thumbnailUrl = video.thumbnails.highResUrl;

    // Ambil Judul Video
    String title = video.title;

    try {
      await _dio.head(streamVideoUrl).timeout(const Duration(seconds:20));
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaPlayerPage(
              onBack: () => Navigator.pop(context),
              customVideoUrl: streamVideoUrl,
              customAudioUrl: streamAudioUrl,
              thumbnailUrl: thumbnailUrl,
              title: title, // <--- KIRIM JUDUL KE SINI
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat stream video dari API: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: Column(
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
                ],
              ),
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
                              leading: Container(
                                width: 120,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(video.thumbnails.mediumResUrl),
                                    fit: BoxFit.cover,
                                  ),
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
                              trailing: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _formatDuration(video.duration),
                                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                                ),
                              ),
                              onTap: () => _openPlayer(video),
                            ),
                          );
                        },
                      ),
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