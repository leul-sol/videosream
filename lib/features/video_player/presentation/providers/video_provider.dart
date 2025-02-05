import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/video.dart';
import '../../data/repositories/video_repository.dart';

final videoRepositoryProvider = Provider((ref) => VideoRepository());

final videosProvider = Provider<List<Video>>((ref) {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getVideos();
});

final currentVideoIndexProvider = StateProvider<int>((ref) => 0);

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (result) => result != ConnectivityResult.none,
      );
});

final isPlayingProvider = StateProvider<bool>((ref) => true);
