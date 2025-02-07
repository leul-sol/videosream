import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../data/models/video.dart';
import '../controllers/video_controller.dart';
import '../providers/video_provider.dart';

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
  bool _isVisible = false;

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
              ElevatedButton(
                onPressed: () {
                  ref.refresh(videoControllerProvider(widget.video));
                },
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
              return const Center(child: CircularProgressIndicator());
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
                const Text(
                  'Error loading video. Please try again.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(videoControllerProvider(widget.video));
                  },
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
