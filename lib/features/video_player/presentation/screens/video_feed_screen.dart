import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_provider.dart';
import '../widgets/video_player_widget.dart';
import '../controllers/video_controller.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _lastPreloadedIndex = -1;
  bool _isFirstLoadComplete = false;

  @override
  void initState() {
    super.initState();
    // Delay the initial load slightly to ensure proper widget mounting
    Future.microtask(() => _initializeFirstVideo());
  }

  Future<void> _initializeFirstVideo() async {
    if (_isFirstLoadComplete) return;

    final videos = ref.read(videosProvider);
    if (videos.isNotEmpty) {
      // Initialize first video
      await ref
          .read(videoControllerProvider(videos[0]).notifier)
          .initialize(videos[0]);

      if (mounted) {
        setState(() {
          _isFirstLoadComplete = true;
        });

        // Start preloading next videos after first video is ready
        _preloadVideos(0);
      }
    }
  }

  void _preloadVideos(int currentIndex) {
    if (currentIndex == _lastPreloadedIndex) return;
    _lastPreloadedIndex = currentIndex;

    final videos = ref.read(videosProvider);

    // Preload next videos
    for (int i = currentIndex + 1;
        i < currentIndex + 2 && i < videos.length;
        i++) {
      final video = videos[i];
      ref.read(videoControllerProvider(video).notifier).initialize(video);
    }

    // Preload previous video if available
    if (currentIndex > 0) {
      final previousVideo = videos[currentIndex - 1];
      ref
          .read(videoControllerProvider(previousVideo).notifier)
          .initialize(previousVideo);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(videosProvider);
    final isOnline = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isOnline.when(
          data: (online) {
            if (!online) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, size: 48, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }

            if (videos.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              onPageChanged: (index) {
                ref.read(currentVideoIndexProvider.notifier).state = index;
                _preloadVideos(index);
              },
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return VideoPlayerWidget(
                  key: ValueKey(video.id),
                  video: video,
                  isInitialVideo: index == 0 && !_isFirstLoadComplete,
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(connectivityProvider);
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
