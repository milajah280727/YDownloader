import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String youtubeUrl;
  final String title;
  final String thumbnailUrl;
  final String type; // 'video' atau 'audio' opsional, sesuaikan kebutuhan

  FavoriteItem({
    required this.youtubeUrl,
    required this.title,
    required this.thumbnailUrl,
    this.type = 'video',
  });

  // Konversi ke Map untuk simpan ke SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'youtubeUrl': youtubeUrl,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'type': type,
    };
  }

  // Buat objek dari Map
  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      youtubeUrl: map['youtubeUrl'] ?? '',
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      type: map['type'] ?? 'video',
    );
  }
}

class FavoritesProvider with ChangeNotifier {
  List<FavoriteItem> _favorites = [];

  List<FavoriteItem> get favorites => _favorites;

  FavoritesProvider() {
    loadFavorites();
  }

  // Cek apakah item sudah ada di favorit (berdasarkan Youtube URL)
  bool isFavorite(String youtubeUrl) {
    return _favorites.any((item) => item.youtubeUrl == youtubeUrl);
  }

  // Toggle (Tambah/Hapus)
  Future<void> toggleFavorite({
    required String youtubeUrl,
    required String title,
    required String thumbnailUrl,
  }) async {
    if (isFavorite(youtubeUrl)) {
      // Hapus jika sudah ada
      _favorites.removeWhere((item) => item.youtubeUrl == youtubeUrl);
    } else {
      // Tambah jika belum ada
      _favorites.add(FavoriteItem(
        youtubeUrl: youtubeUrl,
        title: title,
        thumbnailUrl: thumbnailUrl,
      ));
    }
    
    await _saveFavorites();
    notifyListeners();
  }

  // Hapus spesifik (biasanya dipanggil dari halaman Favorit)
  Future<void> removeFavorite(String youtubeUrl) async {
    _favorites.removeWhere((item) => item.youtubeUrl == youtubeUrl);
    await _saveFavorites();
    notifyListeners();
  }

  // Simpan ke Local Storage
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _favorites.map((item) => item.toMap()).toList(),
    );
    await prefs.setString('favorites_list', encodedData);
  }

  // Muat dari Local Storage
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('favorites_list');
    
    if (encodedData != null) {
      List<dynamic> decodedList = json.decode(encodedData);
      _favorites = decodedList.map((item) => FavoriteItem.fromMap(item)).toList();
    }
    notifyListeners();
  }
}