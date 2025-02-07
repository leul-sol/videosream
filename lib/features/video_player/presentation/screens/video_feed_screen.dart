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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVideos(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _preloadVideos(int currentIndex) {
    final videos = ref.read(videosProvider);
    for (int i = currentIndex; i < currentIndex + 3 && i < videos.length; i++) {
      ref.read(videoControllerProvider(videos[i]));
    }
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
                return VideoPlayerWidget(video: video);
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
