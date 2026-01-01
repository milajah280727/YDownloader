import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class MediaPlayerPage extends StatefulWidget {
  // Callback untuk kembali ke home
  final VoidCallback? onBack;
  // Callback untuk memberi tahu main.dart jika fullscreen aktif/nonaktif
  final Function(bool)? onFullScreenChanged;
  
  // Parameter URL dari pencarian
  final String? customVideoUrl;
  final String? customAudioUrl;
  // Parameter Thumbnail & Judul
  final String? thumbnailUrl;
  final String? title;

  const MediaPlayerPage({
    super.key, 
    this.onBack, 
    this.onFullScreenChanged, 
    this.customVideoUrl, 
    this.customAudioUrl,
    this.thumbnailUrl,
    this.title
  });

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  late VideoPlayerController _videoController;
  late VideoPlayerController _audioController;
  bool _isVideoMode = true;
  bool _isFullScreen = false;

  // State untuk slider mode (0 = Video, 1 = Audio)
  int _modeSegment = 0; 

  // State untuk mengontrol visibilitas overlay di fullscreen
  bool _showControlsOverlay = true;
  
  // State untuk Repeat (Loop)
  bool _isRepeating = false;

  // --- KONFIGURASI WARNA PINK AKSEN ---
  static const Color _accentColor = Color.fromARGB(255, 248, 106, 154);

  @override
  void initState() {
    super.initState();
    
    // Cek apakah ada custom URL (dari pencarian), jika tidak gunakan default
    String vidUrl = widget.customVideoUrl ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
    String audUrl = widget.customAudioUrl ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

    // INISIALISASI BERSAMAAN
    _videoController = VideoPlayerController.networkUrl(Uri.parse(vidUrl));
    _audioController = VideoPlayerController.networkUrl(Uri.parse(audUrl));

    _videoController.addListener(() {
      setState(() {});
    });
    _audioController.addListener(() {
      setState(() {});
    });

    Future.wait([
      _videoController.initialize(),
      _audioController.initialize(),
    ]).then((_) {
      setState(() {
        _videoController.setLooping(_isRepeating);
        _audioController.setLooping(_isRepeating);
      });
    });
  }

  @override
  void dispose() {
    _videoController.removeListener(() {});
    _audioController.removeListener(() {});
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

  void _toggleMode(bool isVideo) {
    if (_isVideoMode == isVideo) return; 

    // Update state slider agar ikon bergerak
    setState(() {
      _modeSegment = isVideo ? 0 : 1; // 0 Video, 1 Audio
    });

    // Simpan status dan posisi
    final wasPlaying = _activeController.value.isPlaying;
    final currentPosition = _activeController.value.position;

    _videoController.pause();
    _audioController.pause();

    setState(() {
      _isVideoMode = isVideo;
    });

    // Sinkronisasi posisi
    Future.microtask(() {
      if (_activeController.value.isInitialized) {
        _activeController.seekTo(currentPosition);
        if (wasPlaying) {
          _activeController.play();
        }
      }
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeating = !_isRepeating;
      _activeController.setLooping(_isRepeating);
    });
  }

  // Widget Slider Mode (Dipisah agar bisa dipanggil di beberapa tempat)
  Widget _buildModeSegment() {
    return SizedBox(
      width: 160, // Lebar tetap agar rapi
      child: SegmentedButton<int>(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return _accentColor; 
            }
            return Colors.white.withOpacity(0.15);
          }),
          iconColor: MaterialStateProperty.all(Colors.white),
          padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8)),
        ),
        segments: const [
          ButtonSegment<int>(
            value: 0,
            icon: Icon(Icons.videocam, size: 18),
            label: Text('Video', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
          ButtonSegment<int>(
            value: 1,
            icon: Icon(Icons.music_note, size: 18),
            label: Text('Audio', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
        selected: {_modeSegment},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            _modeSegment = newSelection.first;
            _toggleMode(_modeSegment == 0);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenView();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 75, 75, 75), // Transparan/Hitam Pudar
        elevation: 0,
        // Title dihapus
        leading: widget.onBack != null
            ? IconButton(
                // Icon back diubah jadi putih
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: widget.onBack,
              )
            : null,
        // Actions dihapus karena slider pindah ke body
      ),
      body: _buildNormalView(),
    );
  }

  // --- TAMPILAN NORMAL ---
  Widget _buildNormalView() {
    return Column(
      children: [
        // 1. Slider Mode Dipindahkan ke Atas Tengah Body
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Center(child: _buildModeSegment()),
        ),
        
        // 2. Area Visual
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: _buildVisualArea(isFull: false),
            ),
          ),
        ),
        
        // 3. Kontrol Bawah
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
          _buildVisualArea(isFull: true),
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

  Widget _buildVisualArea({required bool isFull}) {
    final controller = _activeController;

    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_isVideoMode) {
      if (isFull) {
        return Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        );
      } else {
        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      }
    } else {
      double size = isFull ? 150 : 200;
      bool hasThumbnail = widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty;

      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hasThumbnail ? Colors.transparent : _accentColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            image: hasThumbnail 
                ? DecorationImage(
                    image: NetworkImage(widget.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasThumbnail 
              ? const Icon(Icons.music_note, size: 80, color: Colors.white)
              : null,
        ),
      );
    }
  }

  Widget _buildFullScreenOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.2), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bagian Atas: Slider Mode (Pindah ke sini, menggantikan Text Status)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: _buildModeSegment()),
            ),
          ),
          
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
              child: Row(
                children: [
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
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _activeController,
                      builder: (context, VideoPlayerValue value, child) {
                        return Slider(
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
                  IconButton(
                    onPressed: _toggleRepeat,
                    icon: const Icon(Icons.repeat),
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

  Widget _buildUnifiedControls() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          widget.title ?? "Media Player",
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder(
          valueListenable: _activeController,
          builder: (context, VideoPlayerValue value, child) {
            return Slider(
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
            IconButton(
              onPressed: _toggleRepeat,
              icon: const Icon(Icons.repeat),
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