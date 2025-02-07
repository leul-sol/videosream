import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../data/models/video.dart';
import '../../services/cache_manager.dart';

class VideoController
    extends StateNotifier<AsyncValue<VideoPlayerController?>> {
  VideoController(this.video) : super(const AsyncValue.loading()) {
    _cacheService = EnhancedCacheService();
    _initialize();
  }

  final Video video;
  late final EnhancedCacheService _cacheService;
  VideoPlayerController? _controller;
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

  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final cachedFile = await _cacheService.getVideoFromCache(video.streamUrl);

      VideoPlayerController newController;
      if (cachedFile != null) {
        print('Loading video from cache: ${video.streamUrl}');
        newController = VideoPlayerController.file(
          cachedFile,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
      } else {
        print('Loading video from network: ${video.streamUrl}');
        final isAvailable = await _checkVideoAvailability(video.streamUrl);
        if (!isAvailable) {
          throw Exception('Video not available');
        }
        newController = VideoPlayerController.networkUrl(
          Uri.parse(video.streamUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          httpHeaders: {
            'Content-Type': 'application/x-mpegURL',
            'Accept': 'application/x-mpegURL',
          },
        );

        _cacheService.cacheVideo(video.streamUrl).then((_) {
          print('Video cached successfully: ${video.streamUrl}');
        }).catchError((error) {
          print('Error caching video: $error');
        });
      }

      await newController.initialize();
      _controller = newController;

      if (mounted) {
        state = AsyncValue.data(newController);
      }
    } catch (e, stack) {
      print('Error initializing video: $e');
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> play() async {
    await _controller?.play();
  }

  Future<void> pause() async {
    await _controller?.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

final videoControllerProvider = StateNotifierProvider.family<VideoController,
    AsyncValue<VideoPlayerController?>, Video>(
  (ref, video) => VideoController(video),
);
