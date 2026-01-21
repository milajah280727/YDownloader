import 'dart:io'; // <--- TETAP PENTING
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/download_manager.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart'; // Import ini

class MediaPlayerPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool)? onFullScreenChanged;

  final String? customVideoUrl;
  final String? customAudioUrl;
  final String? thumbnailUrl;
  final String? title;

  // Parameter baru untuk kebutuhan download
  final String? youtubeUrl; 
  final String? baseUrl;

  // Parameter File Lokal
  final String? localFilePath;

  const MediaPlayerPage({
    super.key,
    this.onBack,
    this.onFullScreenChanged,
    this.customVideoUrl,
    this.customAudioUrl,
    this.thumbnailUrl,
    this.title,
    this.youtubeUrl,
    this.baseUrl,
    this.localFilePath,
  });

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

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
  late VideoPlayerController _videoController;

  bool _isVideoMode = false; // Default Audio Mode
  bool _isFullScreen = false;
  bool _showControlsOverlay = true;
  bool _isRepeating = false;

  static const Color _accentColor = Color.fromARGB(255, 248, 106, 154);

  @override
  void initState() {
    super.initState();

    // --- 1. INISIALISASI OTOMATIS BERDASARKAN TIPE FILE ---
    if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
      // Cek ekstensi file
      if (widget.localFilePath!.endsWith('.mp4')) {
        _isVideoMode = true;
      } else {
        _isVideoMode = false; // Audio
      }

      final file = File(widget.localFilePath!);
      _videoController = VideoPlayerController.file(file);
      
      // Auto-play jika ingin langsung main (opsional)
      _videoController.initialize().then((_) {
        if(mounted) {
          _videoController.play();
          setState(() {
            _videoController.setLooping(_isRepeating);
          });
        }
      });
    } else {
      // Streaming
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

    _videoController.addListener(() {
      setState(() {});
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

  // --- FUNGSI DOWNLOAD ---
  void _showDownloadMenu() {
    if (widget.localFilePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ini file lokal yang sudah diunduh.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.white),
              title: const Text('Download Video', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showResolutionDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.white),
              title: const Text('Download Audio', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startAudioDownload();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResolutionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Pilih Resolusi Video', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResolutionOption('360'),
            _buildResolutionOption('480'),
            _buildResolutionOption('720'),
            _buildResolutionOption('1080'),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionOption(String quality) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context);
        _startVideoDownload(quality);
      },
      child: Text(
        quality,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

    // ... bagian atas file tetap sama ...

  void _startVideoDownload(String quality) {
    if (widget.youtubeUrl == null || widget.baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan informasi URL untuk download.')),
      );
      return;
    }

    String safeTitle = widget.title?.replaceAll(RegExp(r'[\\/:*?"<>|]'), '') ?? "video_${DateTime.now().millisecondsSinceEpoch}";
    String downloadUrl = "${widget.baseUrl}/download?url=${widget.youtubeUrl}&quality=$quality";

    final downloadMgr = Provider.of<DownloadManager>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mulai mendownload video $quality...'), duration: Duration(seconds: 2)),
    );

    downloadMgr.downloadFile(
      url: downloadUrl,
      filename: safeTitle,
      type: 'video',
      thumbnailUrl: widget.thumbnailUrl, // <--- KIRIM THUMBNAIL KE SINI
    ).then((_) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Download Selesai!'), backgroundColor: Colors.green),
         );
       }
    }).catchError((error) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download Gagal: $error'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _startAudioDownload() {
    if (widget.youtubeUrl == null || widget.baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan informasi URL untuk download.')),
      );
      return;
    }

    String safeTitle = widget.title?.replaceAll(RegExp(r'[\\/:*?"<>|]'), '') ?? "audio_${DateTime.now().millisecondsSinceEpoch}";
    String downloadUrl = "${widget.baseUrl}/download-audio?url=${widget.youtubeUrl}";

    final downloadMgr = Provider.of<DownloadManager>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mulai mendownload audio...'), duration: Duration(seconds: 2)),
    );

    downloadMgr.downloadFile(
      url: downloadUrl,
      filename: safeTitle,
      type: 'audio',
      thumbnailUrl: widget.thumbnailUrl, // <--- KIRIM THUMBNAIL KE SINI
    ).then((_) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download Selesai!'), backgroundColor: Colors.green),
        );
      }
    }).catchError((error) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download Gagal: $error'), backgroundColor: Colors.red),
        );
      }
    });
  }

  // ... sisa file tetap sama ...

    Widget _buildModeButtons() {
    // Cek jika file lokal, sembunyikan tombol switch mode & favorit (opsional)
    if (widget.localFilePath != null) {
      return const SizedBox.shrink();
    }

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
        const SizedBox(width: 10),

        // --- TAMBAHAN: TOMBOL FAVORIT ---
        Consumer<FavoritesProvider>(
          builder: (context, favProvider, child) {
            // Cek apakah video ini sudah difavoritkan
            // Kita gunakan widget.youtubeUrl sebagai kunci unik
            final isFav = favProvider.isFavorite(widget.youtubeUrl ?? '');
            
            return IconButton(
              onPressed: () {
                if (widget.youtubeUrl != null) {
                  favProvider.toggleFavorite(
                    youtubeUrl: widget.youtubeUrl!,
                    title: widget.title ?? 'Tanpa Judul',
                    thumbnailUrl: widget.thumbnailUrl ?? '',
                  );
                  
                  // Feedback kecil (opsional)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFav ? 'Dihapus dari Favorit' : 'Ditambahkan ke Favorit'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
              ),
              color: isFav ? Colors.pinkAccent : Colors.white70,
              iconSize: 24,
            );
          },
        ),
        const SizedBox(width: 10),
        // --------------------------------

        // Tombol Download (More)
        if (widget.youtubeUrl != null)
          IconButton(
            onPressed: _showDownloadMenu,
            icon: const Icon(Icons.more_vert),
            color: Colors.white70,
            iconSize: 24,
          )
        else
          Container(width: 24),
      ],
    );
  }

  Widget _buildCustomProgressBar() {
    return SizedBox(
      width: double.infinity,
      height: 5,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: double.infinity,
            height: 8,
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
      appBar: null,
      body: _buildNormalView(),
    );
  }

  Widget _buildNormalView() {
    return Stack( // --- GUNAKAN STACK UNTUK TAMBAHAN PROGRESS BAR ---
      children: [
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: widget.onBack,
                      ),
                    const Spacer(),
                    _buildModeButtons(),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
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
        ),
        // --- TAMBAHAN PROGRESS DOWNLOAD DI PLAYER ---
        Consumer<DownloadManager>(
          builder: (context, downloadMgr, child) {
            return downloadMgr.isDownloading
                ? Positioned(
                    bottom: 0, // Di atas kontrol bawah player
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(
                            value: downloadMgr.progress,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                            minHeight: 4,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Downloading ${downloadMgr.currentTask}...",
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${(downloadMgr.progress * 100).toInt()}%",
                                style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildFullScreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
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
          // --- PROGRESS DOWNLOAD DI FULLSCREEN ---
          Consumer<DownloadManager>(
            builder: (context, downloadMgr, child) {
              return downloadMgr.isDownloading
                  ? Positioned(
                      top: 20, // Di tengah atas layar fullscreen
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: downloadMgr.progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                              minHeight: 4,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Downloading ${downloadMgr.currentTask}...",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${(downloadMgr.progress * 100).toInt()}%",
                                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
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
          ? VideoPlayer(controller)
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                image: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.thumbnailUrl!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: (widget.thumbnailUrl == null || widget.thumbnailUrl!.isEmpty)
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _toggleFullScreen();
                    },
                  ),
                  _buildModeButtons(),
                  const SizedBox(width: 48)
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