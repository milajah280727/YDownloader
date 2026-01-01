import 'package:flutter/material.dart';
import 'search_result_page.dart'; // Import halaman hasil pencarian

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi baru untuk menangani Enter
  void _submitSearch(String query) {
    // 1. Sembunyikan keyboard
    FocusScope.of(context).unfocus();
    
    // 2. Navigasi ke halaman hasil dan kirim teks (query)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultPage(searchQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: Column(
        children: [
          // Header Kustom
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
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      // TAMBAHKAN onSubmitted DI SINI
                      onSubmitted: _submitSearch, 
                      decoration: InputDecoration(
                        hintText: "Ketik judul lagu...",
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Konten Halaman
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey[600]),
                  const SizedBox(height: 20),
                  const Text(
                    'Cari Apa Hari Ini?',
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Ketik kata kunci di atas dan tekan Enter untuk melihat hasil.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}