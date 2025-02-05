import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const VideoProgressBar({
    Key? key,
    required this.controller,
    required this.onDragStart,
    required this.onDragEnd,
  }) : super(key: key);

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  bool _dragging = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, VideoPlayerValue value, child) {
        final duration = value.duration;
        final position = value.position;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: Colors.red,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.red,
                        overlayColor: Colors.red.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        min: 0,
                        max: duration.inMilliseconds.toDouble(),
                        onChangeStart: (_) {
                          _dragging = true;
                          widget.onDragStart();
                        },
                        onChanged: (value) {
                          widget.controller.seekTo(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                        onChangeEnd: (_) {
                          _dragging = false;
                          widget.onDragEnd();
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
