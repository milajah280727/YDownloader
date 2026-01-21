import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _history = [];

  List<Map<String, dynamic>> get history => _history;

  HistoryProvider() {
    loadHistory();
  }

  // Load data dari SharedPreferences
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('video_history');

    if (historyString != null) {
      final List<dynamic> decoded = json.decode(historyString);
      _history = decoded.cast<Map<String, dynamic>>();
      notifyListeners();
    }
  }

  // Tambah video ke histori
  Future<void> addToHistory(Video video, String baseUrl) async {
    // Ambil data penting
    Map<String, dynamic> newHistoryItem = {
      'id': video.id.value,
      'title': video.title,
      'author': video.author,
      'duration': video.duration?.inSeconds,
      'thumbnail': video.thumbnails.highResUrl,
      // --- TAMBAHKAN TIMESTAMP DI SINI ---
      'timestamp': DateTime.now().millisecondsSinceEpoch, 
    };

    // Cek duplikasi: Jika video sudah ada, hapus dulu (agar pindah ke paling atas)
    _history.removeWhere((item) => item['id'] == newHistoryItem['id']);

    // Masukkan ke posisi paling atas
    _history.insert(0, newHistoryItem);

    // Batasi histori
    if (_history.length > 50) {
      _history.removeLast();
    }

    await _save();
    notifyListeners();
  }

  // Hapus satu item histori
  Future<void> removeFromHistory(String id) async {
    _history.removeWhere((item) => item['id'] == id);
    await _save();
    notifyListeners();
  }

  // Hapus semua histori
  Future<void> clearHistory() async {
    _history = [];
    await _save();
    notifyListeners();
  }

  // Simpan ke SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('video_history', json.encode(_history));
  }
}