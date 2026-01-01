import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class MediaPlayerPage extends StatefulWidget {
  // Callback untuk kembali ke home
  final VoidCallback? onBack;
  // Callback untuk memberi tahu main.dart jika fullscreen aktif/nonaktif
  final Function(bool)? onFullScreenChanged;

  const MediaPlayerPage({super.key, this.onBack, this.onFullScreenChanged});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  late VideoPlayerController _videoController;
  late VideoPlayerController _audioController;
  bool _isVideoMode = true;
  bool _isFullScreen = false;

  // State untuk mengontrol visibilitas overlay di fullscreen
  bool _showControlsOverlay = true;
  
  // State untuk Repeat (Loop)
  bool _isRepeating = false;

  // --- KONFIGURASI WARNA PINK AKSEN ---
  static const Color _accentColor = Color.fromARGB(255, 248, 106, 154);

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
    );

    _audioController = VideoPlayerController.networkUrl(
      Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
    );

    _videoController.initialize().then((_) => setState(() {}));
    _audioController.initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  VideoPlayerController get _activeController {
    return _isVideoMode ? _videoController : _audioController;
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControlsOverlay = true;
      
      // Beri tahu parent (MainPage) jika status fullscreen berubah
      if (widget.onFullScreenChanged != null) {
        widget.onFullScreenChanged!(_isFullScreen);
      }

      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  // Fungsi baru untuk mengaktifkan/menonaktifkan Repeat
  void _toggleRepeat() {
    setState(() {
      _isRepeating = !_isRepeating;
      // Terapkan status repeat ke controller yang aktif sekarang
      _activeController.setLooping(_isRepeating);
    });
  }

  void _toggleMode(bool isVideo) {
    setState(() {
      _videoController.pause();
      _audioController.pause();
      _isVideoMode = isVideo;
      // Pastikan status repeat sinkron saat ganti mode
      _activeController.setLooping(_isRepeating);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenView();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Unified Player'),
        centerTitle: true,
        // Tombol Back di kiri atas
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          Switch(
            value: _isVideoMode,
            onChanged: (value) {
              _videoController.pause();
              _audioController.pause();
              _toggleMode(value);
            },
          )
        ],
      ),
      body: _buildNormalView(),
    );
  }

  // --- TAMPILAN NORMAL ---
  Widget _buildNormalView() {
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: _buildVisualArea(isFull: false),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20, top: 20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildUnifiedControls(),
        ),
      ],
    );
  }

  // --- TAMPILAN FULLSCREEN ---
  Widget _buildFullScreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Video/Audio
          _buildVisualArea(isFull: true),

          // 2. Layer Interaksi (Show/Hide)
          if (_showControlsOverlay)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControlsOverlay = false;
                });
              },
              child: Container(
                color: Colors.transparent, 
                child: _buildFullScreenOverlay(),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControlsOverlay = true;
                });
              },
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
        ],
      ),
    );
  }

  // Widget Konten Visual (Video/Audio)
  Widget _buildVisualArea({required bool isFull}) {
    if (!_activeController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_isVideoMode) {
      if (isFull) {
        return Center(
          child: AspectRatio(
            aspectRatio: _activeController.value.aspectRatio,
            child: VideoPlayer(_activeController),
          ),
        );
      } else {
        return AspectRatio(
          aspectRatio: _activeController.value.aspectRatio,
          child: VideoPlayer(_activeController),
        );
      }
    } else {
      double size = isFull ? 150 : 200;
      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // Ganti warna box audio jadi Pink
            color: _accentColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                // Ganti warna shadow jadi Pink transparan
                color: _accentColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note,
            size: 80,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  // Layout Overlay untuk Fullscreen
  Widget _buildFullScreenOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.2), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // BARIS ATAS: Judul
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  _isVideoMode ? "Butterfly Video" : "SoundHelix Song 1",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BARIS TENGAH: 3 Tombol Utama
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    _activeController.seekTo(
                      _activeController.value.position - const Duration(seconds: 10),
                    );
                  },
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  iconSize: 48,
                ),
                const SizedBox(width: 20),

                ValueListenableBuilder(
                  valueListenable: _activeController,
                  builder: (context, VideoPlayerValue value, child) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          if (value.isPlaying) {
                            _activeController.pause();
                          } else {
                            _activeController.play();
                          }
                        });
                      },
                      icon: Icon(
                        value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      iconSize: 80,
                    );
                  },
                ),
                const SizedBox(width: 20),

                IconButton(
                  onPressed: () {
                    _activeController.seekTo(
                      _activeController.value.position + const Duration(seconds: 10),
                    );
                  },
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  iconSize: 48,
                ),
              ],
            ),
          ),

          // BARIS BAWAH: Progress Bar & Tombol
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
              child: Row(
                children: [
                  // Teks Waktu Kiri
                  ValueListenableBuilder(
                    valueListenable: _activeController,
                    builder: (context, VideoPlayerValue value, child) {
                      return Text(
                        _formatDuration(value.position),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  
                  // Progress Bar
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _activeController,
                      builder: (context, VideoPlayerValue value, child) {
                        return Slider(
                          // Ganti warna slider jadi Pink
                          activeColor: _accentColor,
                          inactiveColor: Colors.white54,
                          value: value.position.inSeconds.toDouble(),
                          max: value.duration.inSeconds.toDouble(),
                          onChanged: (double newValue) {
                            _activeController.seekTo(Duration(seconds: newValue.toInt()));
                          },
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  // Teks Waktu Kanan
                  ValueListenableBuilder(
                    valueListenable: _activeController,
                    builder: (context, VideoPlayerValue value, child) {
                      return Text(
                        _formatDuration(value.duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      );
                    },
                  ),
                  const SizedBox(width: 10),

                  // Tombol Repeat (Pindah ke KANAN)
                  IconButton(
                    onPressed: _toggleRepeat,
                    icon: const Icon(Icons.repeat),
                    // Ganti warna repeat aktif jadi Pink
                    color: _isRepeating ? _accentColor : Colors.white70, 
                    iconSize: 30,
                  ),
                  IconButton(
                    onPressed: _toggleFullScreen,
                    icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                    iconSize: 30,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Kontrol Normal (Portrait) ---
  Widget _buildUnifiedControls() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          _isVideoMode ? "Butterfly Video" : "SoundHelix Song 1",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder(
          valueListenable: _activeController,
          builder: (context, VideoPlayerValue value, child) {
            return Slider(
              // Ganti warna slider jadi Pink
              activeColor: _accentColor,
              inactiveColor: Colors.grey,
              value: value.position.inSeconds.toDouble(),
              max: value.duration.inSeconds.toDouble(),
              onChanged: (double newValue) {
                _activeController.seekTo(Duration(seconds: newValue.toInt()));
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder(
                valueListenable: _activeController,
                builder: (context, VideoPlayerValue value, child) {
                  return Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white70));
                },
              ),
              ValueListenableBuilder(
                valueListenable: _activeController,
                builder: (context, VideoPlayerValue value, child) {
                  return Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white70));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _toggleFullScreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white), iconSize: 30),
            const SizedBox(width: 15),
            IconButton(
              onPressed: () => _activeController.seekTo(_activeController.value.position - const Duration(seconds: 10)),
              icon: const Icon(Icons.replay_10, color: Colors.white), iconSize: 30),
            const SizedBox(width: 15),
            ValueListenableBuilder(
              valueListenable: _activeController,
              builder: (context, VideoPlayerValue value, child) {
                return FloatingActionButton(
                  // Ganti warna FAB jadi Pink
                  backgroundColor: _accentColor,
                  onPressed: () {
                    setState(() {
                      if (value.isPlaying) _activeController.pause();
                      else _activeController.play();
                    });
                  },
                  child: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                );
              },
            ),
            const SizedBox(width: 15),
            IconButton(
              onPressed: () => _activeController.seekTo(_activeController.value.position + const Duration(seconds: 10)),
              icon: const Icon(Icons.forward_10, color: Colors.white), iconSize: 30),
            const SizedBox(width: 15),
            // Tombol Repeat Juga ditambahkan di mode normal agar sinkron
            IconButton(
              onPressed: _toggleRepeat,
              icon: const Icon(Icons.repeat),
              // Ganti warna repeat aktif jadi Pink
              color: _isRepeating ? _accentColor : Colors.white70,
              iconSize: 30),
          ],
        ),
        const SizedBox(height: 95), 
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}