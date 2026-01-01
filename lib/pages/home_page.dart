import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final Function()? onOpenPlayer; // Callback untuk membuka player

  const HomePage({super.key, this.onOpenPlayer});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Agar state tidak hilang saat digeser

  @override
  Widget build(BuildContext context) {
    super.build(context); // Penting untuk AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Selamat Datang di Beranda',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pilih media untuk diputar',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 30),

          // Konten Card ke Player
          GestureDetector(
            onTap: widget.onOpenPlayer,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 248, 106, 154), 
                      Colors.purple.shade300
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.white, size: 80),
                      SizedBox(height: 15),
                      Text(
                        'Buka Player Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Video & Audio Controller',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}