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

  const VideoPlayerWidget({
    required this.video,
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
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading video. Please try again.',
                    style: TextStyle(color: Colors.white),
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
