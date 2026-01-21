import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class MediaPlayerPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool)? onFullScreenChanged;
  
  final String? customVideoUrl;
  final String? customAudioUrl; 
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

// --- CUSTOM SLIDER TRACK SHAPE ---
class _CustomSliderTrackShape extends RectangularSliderTrackShape {
  const _CustomSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx; 
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width; 
    
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  // --- HANYA SATU CONTROLLER (VIDEO) ---
  late VideoPlayerController _videoController;
  
  bool _isVideoMode = false; // Default Audio Mode
  bool _isFullScreen = false;
  bool _showControlsOverlay = true;
  bool _isRepeating = false;

  static const Color _accentColor = Color.fromARGB(255, 248, 106, 154);

  @override
  void initState() {
    super.initState();
    
    String vidUrl = widget.customVideoUrl ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

    _videoController = VideoPlayerController.networkUrl(Uri.parse(vidUrl));

    _videoController.addListener(() {
      setState(() {});
    });

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setLooping(_isRepeating);
      });
    });
  }

  @override
  void dispose() {
    _videoController.removeListener(() {});
    _videoController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  VideoPlayerController get _activeController {
    return _videoController;
  }
  
  Duration _getBufferedEnd(VideoPlayerValue value) {
    final ranges = value.buffered;
    if (ranges.isEmpty) return Duration.zero;
    return ranges.last.end;
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

    setState(() {
      _isVideoMode = isVideo;
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeating = !_isRepeating;
      _videoController.setLooping(_isRepeating);
    });
  }

  // --- WIDGET UNTUK TOOMBOL MODE (IKON TANPA CEKLIS) ---
  Widget _buildModeButtons() {
    return Row(
      children: [
        // Tombol Video
        IconButton(
          onPressed: () => _toggleMode(true),
          icon: const Icon(Icons.videocam),
          color: _isVideoMode ? _accentColor : Colors.white70,
          iconSize: 24,
        ),
        const SizedBox(width: 10),
        // Tombol Audio
        IconButton(
          onPressed: () => _toggleMode(false),
          icon: const Icon(Icons.music_note),
          color: !_isVideoMode ? _accentColor : Colors.white70,
          iconSize: 24,
        ),
      ],
    );
  }

  // --- CUSTOM PROGRESS BAR ---
  Widget _buildCustomProgressBar() {
    return SizedBox(
      width: double.infinity,
      height: 4, 
      child: Stack(
        alignment: Alignment.centerLeft, 
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          ValueListenableBuilder(
            valueListenable: _activeController,
            builder: (context, VideoPlayerValue value, child) {
              final bufferedEnd = _getBufferedEnd(value);
              final totalDuration = value.duration;
              final progress = totalDuration.inMilliseconds > 0 
                  ? (bufferedEnd.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0) 
                  : 0.0;

              return FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), 
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),

          ValueListenableBuilder(
            valueListenable: _activeController,
            builder: (context, VideoPlayerValue value, child) {
              return SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
                  trackShape: const _CustomSliderTrackShape(),
                  inactiveTrackColor: Colors.transparent,
                  activeTrackColor: _accentColor,
                  thumbColor: (_accentColor),
                  overlayColor: (_accentColor.withOpacity(0.2)),
                ),
                child: Slider(
                  value: value.position.inSeconds.toDouble(),
                  max: value.duration.inSeconds.toDouble(),
                  onChanged: (double newValue) {
                    _activeController.seekTo(Duration(seconds: newValue.toInt()));
                  },
                ),
              );
            },
          ),
        ],
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
      appBar: null, // AppBar dihapus, kita buat custom top bar
      body: _buildNormalView(),
    );
  }

  Widget _buildNormalView() {
    return Column(
      children: [
        // --- CUSTOM TOP BAR (SEJAJAR BACK BUTTON & MODE) ---
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // Tombol Kembali di Kiri
                if (widget.onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                
                // Spacer agar mode tombol ada di kanan (atau tengah jika diinginkan)
                const Spacer(),
                
                // Tombol Mode (Video & Audio)
                _buildModeButtons(),
                
                const SizedBox(width: 10), // Padding kanan
              ],
            ),
          ),
        ),
        
        // --- VISUAL AREA (VIDEO & THUMBNAIL) ---
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: _buildVisualArea(isFull: false),
            ),
          ),
        ),
        
        // --- BOTTOM CONTROLS ---
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

    Widget _buildFullScreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        // --- TAMBAHKAN BARIS INI ---
        alignment: Alignment.center, 
        // ---------------------------
        
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

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: _isVideoMode
          ? VideoPlayer(controller) // Video otomatis mengikuti AspectRatio controller
          : Container(
              // Tampilkan Thumbnail
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black, // Tambahkan background hitam agar konten kontras
                image: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.thumbnailUrl!),
                        // --- UBAH BARIS INI ---
                        fit: BoxFit.contain, 
                        // ---------------------
                      )
                    : null,
              ),
              child: widget.thumbnailUrl == null || widget.thumbnailUrl!.isEmpty
                  ? const Icon(Icons.music_note, size: 80, color: Colors.white)
                  : null,
            ),
    );
  }

  Widget _buildFullScreenOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.2), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Back di Fullscreen
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _toggleFullScreen(); // Keluar dari fullscreen
                    },
                  ),
                  // Tombol Mode di Fullscreen
                  _buildModeButtons(),
                  const SizedBox(width: 48) // Spacer balance (karena back button ada kiri)
                ],
              ),
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
              padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 16.0, bottom: 40.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ValueListenableBuilder(
                        valueListenable: _activeController,
                        builder: (context, VideoPlayerValue value, child) {
                          return Text(
                            _formatDuration(value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4), 
                  
                  Center(
                    child: SizedBox(
                      width: 680, 
                      child: _buildCustomProgressBar(),
                    ),
                  ),
                  
                  const SizedBox(height: 4), 
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                    ],
                  ),
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
        
        Center(
          child: SizedBox(
            width: 300, 
            child: _buildCustomProgressBar(),
          ),
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
                      if (value.isPlaying) {
                        _activeController.pause();
                      } else {
                        _activeController.play();
                      }
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