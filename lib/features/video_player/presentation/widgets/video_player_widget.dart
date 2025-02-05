// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:visibility_detector/visibility_detector.dart';
// import '../../data/models/video.dart';
// import '../controllers/video_controller.dart';
// import '../providers/video_provider.dart';
// import 'video_controls_overlay.dart';

// class VideoPlayerWidget extends ConsumerStatefulWidget {
//   final Video video;
//   final Video? nextVideo;

//   const VideoPlayerWidget({
//     required this.video,
//     this.nextVideo,
//     Key? key,
//   }) : super(key: key);

//   @override
//   ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
//   ChewieController? _chewieController;
//   bool _isVisible = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//   }

//   void _initializePlayer() async {
//     await ref
//         .read(videoControllerProvider(widget.video).notifier)
//         .initialize(widget.video);
//     if (widget.nextVideo != null) {
//       ref
//           .read(videoControllerProvider(widget.nextVideo!).notifier)
//           .initialize(widget.nextVideo!);
//     }
//   }

//   @override
//   void dispose() {
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   void _togglePlayPause() {
//     final controller = ref.read(videoControllerProvider(widget.video));
//     if (controller == null) return;

//     if (controller.value.isPlaying) {
//       controller.pause();
//       ref.read(isPlayingProvider.notifier).state = false;
//     } else {
//       controller.play();
//       ref.read(isPlayingProvider.notifier).state = true;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final videoController = ref.watch(videoControllerProvider(widget.video));

//     return VisibilityDetector(
//       key: Key(widget.video.id),
//       onVisibilityChanged: (info) {
//         if (mounted) {
//           setState(() => _isVisible = info.visibleFraction > 0.5);
//           if (videoController != null) {
//             if (_isVisible) {
//               videoController.play();
//               ref.read(isPlayingProvider.notifier).state = true;
//             } else {
//               videoController.pause();
//               ref.read(isPlayingProvider.notifier).state = false;
//             }
//           }
//         }
//       },
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           if (videoController != null) ...[
//             _buildVideoPlayer(videoController),
//             VideoControlsOverlay(
//               onPlayPause: _togglePlayPause,
//             ),
//           ] else
//             const Center(
//               child: CircularProgressIndicator(color: Colors.white),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVideoPlayer(VideoPlayerController videoController) {
//     _chewieController ??= ChewieController(
//       videoPlayerController: videoController,
//       autoPlay: _isVisible,
//       looping: false,
//       aspectRatio: 9 / 16,
//       autoInitialize: true,
//       showControls: true,
//       showControlsOnInitialize: false,
//       hideControlsTimer: const Duration(seconds: 3),
//       placeholder: Container(
//         color: Colors.black,
//         child: const Center(
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       ),
//       materialProgressColors: ChewieProgressColors(
//         playedColor: Colors.red,
//         handleColor: Colors.red,
//         backgroundColor: Colors.grey,
//         bufferedColor: Colors.white.withOpacity(0.5),
//       ),
//     );

//     return Chewie(controller: _chewieController!);
//   }
// }
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
// import 'package:visibility_detector/visibility_detector.dart';
// import '../../data/models/video.dart';
// import '../controllers/video_controller.dart';
// import '../providers/video_provider.dart';
// import 'video_proress_bar.dart';

// class VideoPlayerWidget extends ConsumerStatefulWidget {
//   final Video video;
//   final Video? nextVideo;

//   const VideoPlayerWidget({
//     required this.video,
//     this.nextVideo,
//     Key? key,
//   }) : super(key: key);

//   @override
//   ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
//   bool _isVisible = true;
//   bool _showControls = false;
//   Timer? _controlsTimer;

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//   }

//   void _initializePlayer() async {
//     await ref
//         .read(videoControllerProvider(widget.video).notifier)
//         .initialize(widget.video);
//     // Only preload next video when current is ready
//     if (widget.nextVideo != null) {
//       ref
//           .read(videoControllerProvider(widget.nextVideo!).notifier)
//           .initialize(widget.nextVideo!);
//     }
//   }

//   @override
//   void dispose() {
//     _controlsTimer?.cancel();
//     super.dispose();
//   }

//   void _togglePlayPause() {
//     final controllerState = ref.read(videoControllerProvider(widget.video));
//     final controller = controllerState.value;
//     if (controller == null) return;

//     if (controller.value.isPlaying) {
//       controller.pause();
//       ref.read(isPlayingProvider.notifier).state = false;
//     } else {
//       controller.play();
//       ref.read(isPlayingProvider.notifier).state = true;
//     }
//   }

//   void _showControlsTemporarily() {
//     setState(() => _showControls = true);
//     _controlsTimer?.cancel();
//     _controlsTimer = Timer(const Duration(seconds: 3), () {
//       if (mounted) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controllerState = ref.watch(videoControllerProvider(widget.video));

//     return VisibilityDetector(
//       key: Key(widget.video.id),
//       onVisibilityChanged: (info) {
//         if (mounted) {
//           final wasVisible = _isVisible;
//           _isVisible = info.visibleFraction > 0.5;

//           if (wasVisible != _isVisible) {
//             controllerState.whenData((controller) {
//               if (controller != null) {
//                 if (_isVisible) {
//                   controller.play();
//                   ref.read(isPlayingProvider.notifier).state = true;
//                 } else {
//                   controller.pause();
//                   ref.read(isPlayingProvider.notifier).state = false;
//                 }
//               }
//             });
//           }
//         }
//       },
//       child: GestureDetector(
//         onTap: _showControlsTemporarily,
//         onDoubleTap: _togglePlayPause,
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             controllerState.when(
//               data: (controller) {
//                 if (controller == null) {
//                   return const Center(child: Text('Failed to load video'));
//                 }
//                 return AspectRatio(
//                   aspectRatio: controller.value.aspectRatio,
//                   child: VideoPlayer(controller),
//                 );
//               },
//               loading: () => const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//               error: (error, stack) => Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.error_outline,
//                         color: Colors.red, size: 48),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Error: ${error.toString()}',
//                       style: const TextStyle(color: Colors.white),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _initializePlayer,
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // Custom controls overlay
//             if (_showControls)
//               AnimatedOpacity(
//                 opacity: _showControls ? 1.0 : 0.0,
//                 duration: const Duration(milliseconds: 300),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black54,
//                         Colors.transparent,
//                         Colors.transparent,
//                         Colors.black54,
//                       ],
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Top controls (if needed)
//                       const SizedBox(height: 40),
//                       // Center play/pause button
//                       IconButton(
//                         icon: Icon(
//                           ref.watch(isPlayingProvider)
//                               ? Icons.pause
//                               : Icons.play_arrow,
//                           size: 60,
//                           color: Colors.white,
//                         ),
//                         onPressed: _togglePlayPause,
//                       ),
//                       // Bottom controls with progress bar
//                       Align(
//                         alignment: Alignment.bottomCenter,
//                         child: controllerState.whenData((controller) {
//                               if (controller == null) return const SizedBox();
//                               return VideoProgressBar(
//                                 controller: controller,
//                                 onDragStart: () {
//                                   _controlsTimer?.cancel();
//                                 },
//                                 onDragEnd: () {
//                                   _showControlsTemporarily();
//                                 },
//                               );
//                             }).value ??
//                             const SizedBox(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../data/models/video.dart';
import '../controllers/video_controller.dart';
import '../providers/video_provider.dart';
// import '../providers/video_providers.dart';

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final Video video;
  final Video? nextVideo;

  const VideoPlayerWidget({
    required this.video,
    this.nextVideo,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  ChewieController? _chewieController;
  bool _isVisible = true;
  bool _isInitialized = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _deferredInitialization();
  }

  void _deferredInitialization() {
    if (_isRetrying) return;

    Future.microtask(() async {
      if (!_isInitialized && mounted) {
        _isInitialized = true;
        await ref
            .read(videoControllerProvider(widget.video).notifier)
            .initialize(widget.video);
      }
    });
  }

  Future<void> _retryInitialization() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      _isInitialized = false;
      await ref.read(videoControllerProvider(widget.video).notifier).dispose();
      await ref
          .read(videoControllerProvider(widget.video).notifier)
          .initialize(widget.video);
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  void _initializeChewieController(VideoPlayerController controller) {
    _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: _isVisible,
      looping: false,
      aspectRatio: 9 / 16,
      autoInitialize: true,
      showOptions: false,
      showControlsOnInitialize: false,
      hideControlsTimer: const Duration(seconds: 2),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 42),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_isRetrying)
                ElevatedButton(
                  onPressed: _retryInitialization,
                  child: const Text('Retry'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(videoControllerProvider(widget.video));

    return VisibilityDetector(
      key: Key(widget.video.id),
      onVisibilityChanged: (info) {
        if (mounted) {
          final wasVisible = _isVisible;
          _isVisible = info.visibleFraction > 0.5;

          if (wasVisible != _isVisible) {
            controllerState.whenData((controller) {
              if (controller != null) {
                if (_isVisible) {
                  controller.play();
                  ref.read(isPlayingProvider.notifier).state = true;
                } else {
                  controller.pause();
                  ref.read(isPlayingProvider.notifier).state = false;
                }
              }
            });
          }
        }
      },
      child: Container(
        color: Colors.black,
        child: controllerState.when(
          data: (controller) {
            if (controller == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (!_isRetrying)
                      ElevatedButton(
                        onPressed: _retryInitialization,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              );
            }

            if (_chewieController?.videoPlayerController != controller) {
              _initializeChewieController(controller);
            }

            return _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator());
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading video. Please try again.',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isRetrying)
                  ElevatedButton(
                    onPressed: _retryInitialization,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
