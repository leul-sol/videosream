import 'package:go_router/go_router.dart';
import '../features/video_player/presentation/screens/video_feed_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const VideoFeedScreen(),
    ),
  ],
);
