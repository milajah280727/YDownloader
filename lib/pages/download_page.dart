import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:metadata_god/metadata_god.dart' as meta; 
import '../widgets/player_page.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
        String rootPath = extDir.parent.parent.parent.parent.path;
        final ydownloaderPath = '$rootPath/Download/Ydownloader';
        final directory = Directory(ydownloaderPath);

        if (await directory.exists()) {
          List<FileSystemEntity> entities = directory.listSync();
          // Filter hanya file utama (mp4/mp3), jangan masukkan file jpg ke list
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
      debugPrint("Error memuat file download: $e");
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

  // Helper untuk ambil path file gambar berdasarkan nama file mp4/mp3
  String _getThumbnailPath(String mainFilePath) {
    return mainFilePath.replaceAll(RegExp(r'\.\w+$'), '.jpg');
  }

  String _getFileType(String path) {
    if (path.endsWith('.mp4')) return 'video';
    return 'audio';
  }

  String _getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _deleteFile(File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Hapus File?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'File ini akan dihapus dari penyimpanan lokal Anda selamanya.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await file.delete();
                
                // Hapus juga file gambarnya jika ada
                String thumbPath = _getThumbnailPath(file.path);
                File thumbFile = File(thumbPath);
                if (await thumbFile.exists()) {
                  await thumbFile.delete();
                }

                if (mounted) {
                  Navigator.pop(ctx); 
                  _loadDownloadedFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File dihapus')),
                  );
                }
              } catch (e) {
                debugPrint("Gagal hapus file: $e");
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI THUMBNAIL OPTIMASI ---
  Future<Uint8List?> _getThumbnail(String path, String type) async {
    // 1. Cek lagi di dalam fungsi async (double check)
    String thumbPath = _getThumbnailPath(path);
    File thumbFile = File(thumbPath);

    if (await thumbFile.exists()) {
      return await thumbFile.readAsBytes();
    }

    // 2. Fallback: Generate baru (Berat, tapi dilakukan di FutureBuilder)
    try {
      if (type == 'video') {
        return await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 200,
          quality: 75,
        );
      } else {
        final metadata = await meta.MetadataGod.readMetadata(file: path);
        return metadata.picture?.data; 
      }
    } catch (e) {
      debugPrint("Error thumbnail fallback: $e");
      return null;
    }
  }

  void _playFile(File file) {
    final fileName = _getFileName(file.path);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPlayerPage(
          onBack: () => Navigator.pop(context),
          title: fileName,
          localFilePath: file.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      // --- LOGIKA BARU: SELALU GUNAKAN LISTVIEW ---
      body: RefreshIndicator(
        onRefresh: _loadDownloadedFiles, // Refresh tetap bekerja meski kosong
        color: Colors.pinkAccent,
        backgroundColor: Colors.grey[900],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
            : MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  // JIKA KOSONG, COUNT = 1 (UNTUK UI KOSONG), JIKA ADA, COUNT = PANJANG LIST
                  itemCount: _files.isEmpty ? 1 : _files.length,
                  itemBuilder: (context, index) {
                    // JIKA FILE KOSONG, RENDER WIDGET "BELUM ADA UNDUHAN"
                    if (_files.isEmpty) {
                      return SizedBox(
                        // Beri tinggi agar bisa discroll (penting untuk RefreshIndicator)
                        height: MediaQuery.of(context).size.height - 100, 
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_done_outlined, size: 80, color: Colors.grey[600]),
                            const SizedBox(height: 20),
                            const Text('Belum ada unduhan', style: TextStyle(color: Colors.white, fontSize: 18)),
                            const SizedBox(height: 10),
                            Text('Disimpan di: /Download/Ydownloader', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(height: 20),
                            Text('Tarik ke bawah untuk memperbarui', style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    }

                    // LOGIKA LIST FILE YANG ADA (OPTIMASI DI SINI)
                    final file = _files[index] as File;
                    final fileName = _getFileName(file.path);
                    final type = _getFileType(file.path);
                    
                    // Logic Cek Thumbnail Cepat
                    String thumbPath = _getThumbnailPath(file.path);
                    File thumbFile = File(thumbPath);
                    bool thumbExists = thumbFile.existsSync();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          // Thumbnail (Kiri)
                          GestureDetector(
                            onTap: () => _playFile(file),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 120,
                                height: 90,
                                child: Stack(
                                  children: [
                                    // JIKA THUMBNAIL SUDAH ADA DI FILE, GUNAKAN IMAGE.FILE (RINGAN)
                                    if (thumbExists)
                                      Image.file(
                                        thumbFile,
                                        width: 120,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        cacheWidth: 120,
                                        cacheHeight: 90,
                                      )
                                    // JIKA BELUM ADA, GENERATE BARU (BERAT, TAPI DILAKUKAN DI FUTURE BUILDER)
                                    else
                                      FutureBuilder<Uint8List?>(
                                        future: _getThumbnail(file.path, type),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 120,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            );
                                          } else if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Container(
                                              width: 120,
                                              height: 90,
                                              color: Colors.grey[800],
                                              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                            );
                                          } else {
                                            return Container(
                                              width: 120,
                                              height: 90,
                                              color: Colors.grey[800],
                                              child: Icon(
                                                type == 'video' ? Icons.broken_image : Icons.music_note,
                                                color: Colors.white70,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    // Icon Play Overlay
                                    const Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          
                          // Detail (Tengah)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _playFile(file),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
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
                                    _getFileSize(file),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    type == 'video' ? 'MP4 Video File' : 'MP3 Audio File',
                                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Tombol Hapus (Kanan)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () => _deleteFile(file),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}