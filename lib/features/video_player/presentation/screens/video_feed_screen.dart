import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_provider.dart';
import '../widgets/video_player_widget.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(videosProvider);
    final currentIndex = ref.watch(currentVideoIndexProvider);
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
              },
              itemCount: videos.length,
              itemBuilder: (context, index) {
                if ((index - currentIndex).abs() <= 1) {
                  final video = videos[index];

                  return VideoPlayerWidget(
                    video: video,
                  );
                } else {
                  return Container(color: Colors.black);
                }
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
