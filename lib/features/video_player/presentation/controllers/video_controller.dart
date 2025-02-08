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
  bool _isDisposed = false;
  int _retryCount = 0;
  static const int maxRetries = 3;
  String? _currentVideoUrl;

  Future<bool> _checkVideoAvailability(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking video availability: $e');
      return false;
    }
  }

  Future<void> initialize(Video video, {bool forceReload = false}) async {
    if (!mounted || _isDisposed) return;

    // If already initializing this video, wait
    if (_isInitializing && _currentVideoUrl == video.streamUrl) {
      return;
    }

    // If initializing a different video, cancel current initialization
    if (_isInitializing && _currentVideoUrl != video.streamUrl) {
      _isInitializing = false;
    }

    _isInitializing = true;
    _currentVideoUrl = video.streamUrl;

    try {
      final previousController = _controller;
      VideoPlayerController? newController;

      if (!forceReload) {
        // Try to get video from cache first
        final cachedFile =
            await _cacheService.getVideoFromCache(video.streamUrl);

        if (cachedFile != null) {
          try {
            newController = VideoPlayerController.file(
              cachedFile,
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false,
                allowBackgroundPlayback: false,
              ),
            );
            await newController.initialize();
          } catch (e) {
            print('Error loading cached file: $e');
            newController?.dispose();
            newController = null;
            // Remove corrupted cache
            await _cacheService.removeFromCache(video.streamUrl);
          }
        }
      }

      // If cache loading failed or force reload, try network
      if (newController == null) {
        // Only check availability for network loading
        final isAvailable = await _checkVideoAvailability(video.streamUrl);
        if (!isAvailable) {
          throw Exception('Video not available');
        }

        if (_isDisposed || !mounted || _currentVideoUrl != video.streamUrl) {
          return;
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

      if (_isDisposed || !mounted || _currentVideoUrl != video.streamUrl) {
        await newController?.dispose();
        return;
      }

      // Setup error listener
      newController.addListener(() {
        if (newController!.value.hasError && mounted && !_isDisposed) {
          print('Video player error: ${newController.value.errorDescription}');
          _handleVideoError(video);
        }
      });

      // Update controller reference and state
      if (!_isDisposed && mounted && _currentVideoUrl == video.streamUrl) {
        _controller = newController;
        state = AsyncValue.data(newController);
        _retryCount = 0; // Reset retry count on successful initialization
      } else {
        await newController.dispose();
      }

      // Dispose previous controller after successful initialization
      if (previousController != null && previousController != newController) {
        await previousController.dispose();
      }
    } catch (e, stack) {
      print('Error initializing video: $e');
      if (!_isDisposed && mounted && _currentVideoUrl == video.streamUrl) {
        if (_retryCount < maxRetries) {
          _retryCount++;
          print('Retrying initialization (attempt $_retryCount)...');
          _isInitializing = false;
          await Future.delayed(Duration(seconds: _retryCount));
          initialize(video, forceReload: true);
          return;
        }
        state = AsyncValue.error(e, stack);
      }
    } finally {
      if (_currentVideoUrl == video.streamUrl) {
        _isInitializing = false;
      }
    }
  }

  void _handleVideoError(Video video) async {
    if (_isDisposed) return;

    print('Handling video error for: ${video.streamUrl}');

    // Clear cache for this video
    await _cacheService.removeFromCache(video.streamUrl);

    // Try to reinitialize
    if (!_isDisposed && mounted && _retryCount < maxRetries) {
      _retryCount++;
      print('Retrying after error (attempt $_retryCount)...');
      initialize(video, forceReload: true);
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
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
