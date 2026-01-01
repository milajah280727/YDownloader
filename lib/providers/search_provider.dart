import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchProvider extends ChangeNotifier {
  List<String> _searchHistory = [];

  List<String> get searchHistory => _searchHistory;

  SearchProvider() {
    loadSearchHistory();
  }

  // Muat data dari penyimpanan lokal
  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('search_history') ?? [];
    notifyListeners();
  }

  // Tambah pencarian baru ke riwayat
  Future<void> addToSearchHistory(String query) async {
    // Hapus jika sudah ada (agar duplikat pindah ke atas)
    if (_searchHistory.contains(query)) {
      _searchHistory.remove(query);
    }
    // Masukkan ke posisi paling atas (indeks 0)
    _searchHistory.insert(0, query);
    
    // Batasi riwayat maksimal 10
    if (_searchHistory.length > 10) {
      _searchHistory.removeLast();
    }
    
    await _save();
    notifyListeners();
  }

  // Hapus satu item
  Future<void> removeFromSearchHistory(String query) async {
    _searchHistory.remove(query);
    await _save();
    notifyListeners();
  }

  // Hapus semua riwayat
  Future<void> clearSearchHistory() async {
    _searchHistory = [];
    await _save();
    notifyListeners();
  }

  // Fungsi simpan ke SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }
}