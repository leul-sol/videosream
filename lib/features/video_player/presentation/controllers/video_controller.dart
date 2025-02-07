import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../data/models/video.dart';
import '../../services/cache_manager.dart';

class VideoController
    extends StateNotifier<AsyncValue<VideoPlayerController?>> {
  VideoController() : super(const AsyncValue.loading());
  VideoPlayerController? _controller;
  final _cacheService = EnhancedCacheService();
  bool _isInitializing = false;

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
    if (!mounted || _isInitializing) return;

    _isInitializing = true;
    // Don't immediately show loading state if we have a previous controller
    if (state.value == null) {
      state = const AsyncValue.loading();
    }

    try {
      final previousController = _controller;
      VideoPlayerController? newController;

      // Try to get video from cache first
      final cachedFile = await _cacheService.getVideoFromCache(video.streamUrl);

      if (cachedFile != null) {
        print('Loading video from cache: ${video.streamUrl}');
        try {
          newController = VideoPlayerController.file(
            cachedFile,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: false,
              allowBackgroundPlayback: false,
            ),
          );
          await newController.initialize();
        } catch (cacheError) {
          print('Error loading from cache: $cacheError');
          newController?.dispose();
          newController = null;
          // Don't throw here, let it try network loading
        }
      }
      // If cache loading failed or file wasn't cached, try network
      if (newController == null) {
        print('Loading video from network: ${video.streamUrl}');
        final isAvailable = await _checkVideoAvailability(video.streamUrl);
        if (!isAvailable) {
          throw Exception('Video not available');
        }

        newController = VideoPlayerController.networkUrl(
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

        await newController.initialize();

        // Cache the video for future use
        _cacheService.cacheVideo(video.streamUrl).then((file) {
          print('Video cached successfully: ${video.streamUrl}');
        }).catchError((error) {
          print('Error caching video: $error');
        });
      }

      // Setup error listener
      newController.addListener(() {
        if (newController!.value.hasError && mounted) {
          print('Video player error: ${newController?.value.errorDescription}');
          // Only show error if it's still the current controller
          if (_controller == newController) {
            state = AsyncValue.error(
              Exception(newController!.value.errorDescription),
              StackTrace.current,
            );
          }
        }
      });

      // Update controller reference and state
      _controller = newController;
      if (mounted) {
        state = AsyncValue.data(newController);
      }

      // Dispose previous controller after successful initialization
      if (previousController != null && previousController != newController) {
        await previousController.dispose();
      }
    } catch (e, stack) {
      print('Error initializing video: $e');
      if (mounted) {
        // Add a small delay before showing error to prevent flash
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && _controller == null) {
          state = AsyncValue.error(e, stack);
        }
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    super.dispose();
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
