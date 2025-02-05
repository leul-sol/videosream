// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
// import '../../data/models/video.dart';
// import '../../services/cache_service.dart';
// import '../../services/platform_video_service.dart';

// class VideoController extends StateNotifier<VideoPlayerController?> {
//   final VideoCacheService _cacheService;

//   VideoController(this._cacheService) : super(null);

//   Future<void> initialize(Video video) async {
//     try {
//       // Try to get cached video
//       final fileInfo =
//           await _cacheService.cacheManager.getFileFromCache(video.streamUrl);

//       final VideoPlayerController controller;
//       if (fileInfo != null) {
//         controller = VideoPlayerController.file(fileInfo.file);
//       } else if (video.streamUrl.endsWith('.m3u8')) {
//         controller = VideoPlayerController.network(video.streamUrl);
//       } else {
//         controller = VideoPlayerController.networkUrl(
//           Uri.parse(video.streamUrl),
//           videoPlayerOptions: VideoPlayerOptions(
//             mixWithOthers: true,
//             allowBackgroundPlayback: true,
//           ),
//         );
//         // Start caching for future use
//         _cacheService.preloadVideo(video.streamUrl);
//         PlatformVideoService.preloadVideo(video.streamUrl);
//       }

//       await controller.initialize();
//       state = controller;
//       controller.play();
//       print('Video initialized and playing: ${video.streamUrl}');
//     } catch (e, stackTrace) {
//       print('Error initializing video: $e');
//       print('Stack trace: $stackTrace');
//       state = null;
//     }
//   }

//   Future<void> dispose() async {
//     await state?.dispose();
//     state = null;
//   }
// }

// final videoControllerProvider = StateNotifierProvider.family<VideoController,
//     VideoPlayerController?, Video>(
//   (ref, video) => VideoController(VideoCacheService()),
// );
// import 'dart:async';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:video_player/video_player.dart';
// import '../../data/models/video.dart';
// import '../../services/cache_service.dart';
// import '../../services/platform_video_service.dart';

// class VideoController
//     extends StateNotifier<AsyncValue<VideoPlayerController?>> {
//   final VideoCacheService _cacheService;
//   VideoPlayerController? _controller;

//   VideoController(this._cacheService) : super(const AsyncValue.loading());

//   Future<void> initialize(Video video) async {
//     if (_controller != null) {
//       await _controller!.dispose();
//       _controller = null;
//     }

//     state = const AsyncValue.loading();

//     try {
//       // Pre-check cache
//       final fileInfo =
//           await _cacheService.cacheManager.getFileFromCache(video.streamUrl);

//       // Initialize controller based on cache status
//       _controller = fileInfo != null
//           ? VideoPlayerController.file(fileInfo.file)
//           : VideoPlayerController.networkUrl(
//               Uri.parse(video.streamUrl),
//               videoPlayerOptions: VideoPlayerOptions(
//                 mixWithOthers: false, // Prevent audio overlap
//                 allowBackgroundPlayback: false, // Prevent background playback
//               ),
//             );

//       // Initialize with timeout
//       await Future.wait([
//         _controller!.initialize(),
//         // Cache the video if not already cached
//         if (fileInfo == null) _cacheService.preloadVideo(video.streamUrl),
//       ]).timeout(
//         const Duration(seconds: 10),
//         onTimeout: () =>
//             throw TimeoutException('Video initialization timed out'),
//       );

//       // Set playback speed for better initial loading
//       await _controller!.setPlaybackSpeed(1.0);

//       // Update state with initialized controller
//       state = AsyncValue.data(_controller);
//     } catch (e, stack) {
//       print('Error initializing video: $e');
//       state = AsyncValue.error(e, stack);
//       _controller?.dispose();
//       _controller = null;
//     }
//   }

//   Future<void> dispose() async {
//     await _controller?.dispose();
//     _controller = null;
//   }

//   void pause() {
//     _controller?.pause();
//   }

//   void play() {
//     _controller?.play();
//   }
// }

// final videoControllerProvider = StateNotifierProvider.family<VideoController,
//     AsyncValue<VideoPlayerController?>, Video>(
//   (ref, video) => VideoController(VideoCacheService()),
// );
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

      // Set up error listeners before initialization
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
