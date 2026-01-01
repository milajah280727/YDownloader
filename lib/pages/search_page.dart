import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ydownloader/providers/search_provider.dart';
import 'search_result_page.dart';
// import 'widgets/mini_player_widget.dart'; // Uncomment jika Anda punya widget ini

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Muat riwayat saat halaman dibuka (Sesuai request logic snippet)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).loadSearchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk melakukan pencarian dan menyimpan ke riwayat
  void _searchSongs(String query) {
    if (query.isEmpty) return;
    
    // 1. Simpan ke Provider
    Provider.of<SearchProvider>(context, listen: false).addToSearchHistory(query);
    
    // 2. Navigasi ke halaman hasil pencarian
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultPage(searchQuery: query),
      ),
    );
  }

  // Dialog hapus satu item (Sesuai request logic snippet)
  void _showDeleteDialog(String query) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E), // Warna background dialog dari snippet
        title: const Text(
          'Hapus Riwayat',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$query" dari riwayat pencarian?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SearchProvider>(context, listen: false)
                  .removeFromSearchHistory(query);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Dialog hapus semua (Sesuai request logic snippet)
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          'Hapus Semua Riwayat',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat pencarian?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
                Provider.of<SearchProvider>(context, listen: false)
                    .clearSearchHistory();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua riwayat telah dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      // Menggunakan background style "sebelumnya" (Hitam Pekat)
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Kustom (Style Sebelumnya: Back Icon + Rounded TextField)
              _buildCustomAppBar(context, padding),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: padding.bottom + 70),
                  child: Consumer<SearchProvider>(
                    builder: (context, searchProvider, child) {
                      // LOGIC: Jika ada riwayat
                      if (searchProvider.searchHistory.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Riwayat
                              Padding(
                                padding: const EdgeInsets.only(top: 15, right: 15, left: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pencarian Terakhir',
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                      ),
                                    ),
                                    // Tombol Hapus Semua
                                    TextButton(
                                      onPressed: () => _showClearAllDialog(),
                                      child: const Text(
                                        'Hapus Semua',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(right: 15, left: 15),
                                child: Wrap(  
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: searchProvider.searchHistory.map((query) {
                                    // Logic Hapus: Long Press
                                    return GestureDetector(
                                      onLongPress: () => _showDeleteDialog(query),
                                      child: ActionChip(
                                        backgroundColor: const Color.fromARGB(255, 42, 42, 42),
                                        label: Text(
                                          query,
                                          style: const TextStyle(color: Color.fromARGB(255, 240, 240, 240)),
                                        ),
                                        onPressed: () {
                                          _searchController.text = query;
                                          _searchSongs(query);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Style Sebelumnya: Jika tidak ada riwayat
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: Color.fromARGB(255, 117, 117, 117)),
                            SizedBox(height: 20),
                            Text(
                              'Cari Apa Hari Ini?',
                              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Ketik kata kunci di atas dan tekan Enter untuk melihat hasil.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
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
          
          // MiniPlayer di Bawah (Sesuai request snippet)
          // Jika belum ada widget aslinya, saya beri placeholder agar tidak error
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // child: MiniPlayerWidget(), // Ganti baris ini dengan widget asli Anda
            child: SizedBox(height: 60, child: Center(child: Text("Mini Player Area", style: TextStyle(color: Colors.white30)))),
          ),
        ],
      ),
    );
  }

  // Widget Header Style Sebelumnya (Tanpa AppBar)
  Widget _buildCustomAppBar(BuildContext context, EdgeInsets padding) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            // TextField Style Sebelumnya
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true, // Sesuai request snippet
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (value) => _searchSongs(value),
                decoration: InputDecoration(
                  hintText: "Cari...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  // Border Rounded Style Sebelumnya
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.pink, width: 1),
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
    );
  }
}