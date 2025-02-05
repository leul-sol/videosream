import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/video_provider.dart';

class VideoControlsOverlay extends ConsumerWidget {
  final VoidCallback onPlayPause;

  const VideoControlsOverlay({
    required this.onPlayPause,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);

    return GestureDetector(
      onTap: onPlayPause,
      child: Container(
        color: Colors.black26,
        child: Center(
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 60.0,
          ),
        ),
      ),
    );
  }
}
