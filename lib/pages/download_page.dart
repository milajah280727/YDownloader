import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../widgets/player_page.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

    Future<void> _loadDownloadedFiles() async {
    try {
      Directory? extDir = await getExternalStorageDirectory();
      List<FileSystemEntity> newFiles = [];
      
      if (extDir != null) {
        // --- LOGIKA PATH BARU (SAMA SEPERTI DI DOWNLOAD MANAGER) ---
        String rootPath = extDir.parent.parent.parent.parent.path;
        final ydownloaderPath = '$rootPath/Download/Ydownloader';
        final directory = Directory(ydownloaderPath);

        if (await directory.exists()) {
          List<FileSystemEntity> entities = directory.listSync();
          newFiles = entities.where((entity) {
            return entity is File && 
                   (entity.path.endsWith('.mp4') || entity.path.endsWith('.mp3'));
          }).toList();
        }
      }

      if (mounted) {
        setState(() {
          _files = newFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error memuat file download: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getFileType(String path) {
    if (path.endsWith('.mp4')) return 'video';
    return 'audio';
  }

  Future<Uint8List?> _getVideoThumbnail(String path) async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 200,
      quality: 75,
    );
    return uint8list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : RefreshIndicator(
              onRefresh: _loadDownloadedFiles,
              child: _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_done_outlined, size: 80, color: Colors.grey[600]),
                          const SizedBox(height: 20),
                          const Text('Belum ada unduhan', style: TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text('Disimpan di: /Download/Ydownloader', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index] as File;
                        final fileName = _getFileName(file.path);
                        final type = _getFileType(file.path);
                        
                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 90,
                                height: 60,
                                child: type == 'video'
                                    ? FutureBuilder<Uint8List?>(
                                        future: _getVideoThumbnail(file.path),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 90,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            );
                                          } else if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Container(
                                              width: 90, height: 60, color: Colors.black,
                                              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                            );
                                          } else {
                                            return Container(
                                              width: 90, height: 60,
                                              color: Colors.red,
                                              child: const Icon(Icons.broken_image, color: Colors.white),
                                            );
                                          }
                                        },
                                      )
                                    : Container(
                                        width: 90, height: 60,
                                        color: Colors.pink,
                                        child: const Icon(Icons.music_note, color: Colors.white, size: 30),
                                      ),
                              ),
                            ),
                            title: Text(
                              fileName,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              type == 'video' ? "Video MP4" : "Audio MP3",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_circle_filled, color: Colors.green, size: 35),
                              onPressed: () {
                                // --- INTEGRASI PLAYER LOKAL ---
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MediaPlayerPage(
                                      onBack: () => Navigator.pop(context),
                                      title: fileName,
                                      localFilePath: file.path, // Mengirim path file lokal
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}