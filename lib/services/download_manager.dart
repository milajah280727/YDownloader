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
    required String type // 'video' atau 'audio'
  }) async {
    _isDownloading = true;
    _progress = 0.0;
    _currentTask = filename;
    notifyListeners();

    try {
      // 1. Ambil path direktori storage
      Directory? extDir = await getExternalStorageDirectory();
      
      if (extDir != null) {
        // 2. LOGIKA PATH BARU
        // Kita harus naik 4 level (parent x4) untuk keluar dari folder Android/data/packagename
        // dan mencapai root /storage/emulated/0
        
        // Contoh struktur di HP Anda:
        // .../files (extDir saat ini)
        // .../com.example.ydownloader (1)
        // .../data (2)
        // .../Android (3)
        // .../0 (4) <- Ini tujuan kita
        
        String rootPath = extDir.parent.parent.parent.parent.path;
        
        // Target: /storage/emulated/0/Download/Ydownloader
        final publicDownloadPath = Directory('$rootPath/Download/Ydownloader');
        
        if (!await publicDownloadPath.exists()) {
          await publicDownloadPath.create(recursive: true);
        }
        
        String fileExt = type == 'video' ? 'mp4' : 'mp3';
        String fullPath = '${publicDownloadPath.path}/$filename.$fileExt';

        // 3. Mulai Download
        await _dio.download(
          url,
          fullPath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              _progress = received / total;
              notifyListeners();
            }
          },
        );

        // 4. Scan File
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