import 'package:flutter/material.dart';

class SearchResultPage extends StatefulWidget {
  final String searchQuery;
  
  const SearchResultPage({super.key, required this.searchQuery});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Mengisi controller dengan teks yang dikirim dari halaman pencarian
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      body: Column(
        children: [
          // Bagian Atas: Custom Header (Back + Search Field)
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  // 1. Tombol Back (Kiri)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // 2. Search Field (Tengah) - Isi Query Pencarian
                  Expanded(
                    child: TextField(
                      controller: _searchController, // Mengisi field dengan hasil pencarian
                      readOnly: true, // Agar user tidak mengetik langsung di sini, tapi klik untuk kembali
                      onTap: () {
                        // Jika diklik, kembali ke halaman pencarian
                        Navigator.pop(context);
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Cari...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[850],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        // Border Radius sama dengan halaman lain
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
          ),

          // Bagian Konten Hasil
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.find_in_page, size: 80, color: Colors.pinkAccent),
                  const SizedBox(height: 20),
                  const Text(
                    'Menampilkan Hasil Untuk:',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.searchQuery,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Hasil belum tersedia (Contoh Only)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
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