import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';

class DownloadManager extends ChangeNotifier {
  final Dio _dio = Dio();

  bool _isDownloading = false;
  double _progress = 0.0;
  String _currentTask = ""; 

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  String get currentTask => _currentTask;

  Future<void> downloadFile({
    required String url, 
    required String filename, 
    required String type,
    String? thumbnailUrl // Tambah parameter ini
  }) async {
    _isDownloading = true;
    _progress = 0.0;
    _currentTask = filename;
    notifyListeners();

    try {
      Directory? extDir = await getExternalStorageDirectory();
      
      if (extDir != null) {
        String rootPath = extDir.parent.parent.parent.parent.path;
        final publicDownloadPath = Directory('$rootPath/Download/Ydownloader');
        
        if (!await publicDownloadPath.exists()) {
          await publicDownloadPath.create(recursive: true);
        }
        
        String fileExt = type == 'video' ? 'mp4' : 'mp3';
        String fullPath = '${publicDownloadPath.path}/$filename.$fileExt';
        String imagePath = '${publicDownloadPath.path}/$filename.jpg'; // Path untuk thumbnail

        // 1. Download File Utama (Video/Audio)
        await _dio.download(
          url,
          fullPath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              _progress = (received / total) * 0.8; // 80% progress untuk file utama
              notifyListeners();
            }
          },
        );

        // 2. Download Thumbnail (Jika URL tersedia)
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
          try {
            await _dio.download(
              thumbnailUrl!,
              imagePath,
              onReceiveProgress: (received, total) {
                if (total != -1) {
                  _progress = 0.8 + ((received / total) * 0.2); // Sisa 20% untuk thumbnail
                  notifyListeners();
                }
              },
            );
            // Scan image agar muncul di galeri
            await MediaScanner.loadMedia(path: imagePath);
          } catch (e) {
            // Jika gagal download thumbnail, tidak apa-apa, jangan crash
            debugPrint("Gagal download thumbnail: $e");
          }
        }

        // 3. Scan File Utama
        await MediaScanner.loadMedia(path: fullPath);

        if (kDebugMode) {
          print("✅ Download selesai: $fullPath");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error download: $e");
      }
      rethrow; 
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}