import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../data/models/video.dart';

class VideoController
    extends StateNotifier<AsyncValue<VideoPlayerController?>> {
  VideoController() : super(const AsyncValue.loading());
  VideoPlayerController? _controller;

  Future<bool> _checkVideoAvailability(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking video availability: $e');
      return false;
    }
  }

  Future<void> initialize(Video video) async {
    if (!mounted) return;

    state = const AsyncValue.loading();

    try {
      // Dispose previous controller if exists
      await _controller?.dispose();
      _controller = null;

      // Check if video is available before initializing
      final isAvailable = await _checkVideoAvailability(video.streamUrl);
      if (!isAvailable) {
        throw Exception('Video not available');
      }

      // Initialize new controller
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(video.streamUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: {
          'Content-Type': 'application/x-mpegURL',
          'Accept': 'application/x-mpegURL',
        },
      );

      // listen error before initialization
      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          print('Video player error: ${_controller!.value.errorDescription}');
          if (mounted) {
            state = AsyncValue.error(
              Exception(_controller!.value.errorDescription),
              StackTrace.current,
            );
          }
        }
      });

      await _controller!.initialize();

      if (mounted) {
        state = AsyncValue.data(_controller);
      }
    } catch (e, stack) {
      print('Error initializing video: $e');
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
      await _controller?.dispose();
      _controller = null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  void play() {
    _controller?.play();
  }

  void pause() {
    _controller?.pause();
  }
}

final videoControllerProvider = StateNotifierProvider.family<VideoController,
    AsyncValue<VideoPlayerController?>, Video>(
  (ref, _) => VideoController(),
);
