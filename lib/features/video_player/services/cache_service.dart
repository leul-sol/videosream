import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  final CacheManager cacheManager = CacheManager(
    Config(
      'videoCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: 'videoCache'),
      fileService: HttpFileService(),
    ),
  );

  Future<void> preloadVideo(String url) async {
    try {
      await cacheManager.downloadFile(url);
    } catch (e) {
      print('Error caching video: $e');
    }
  }

  Future<void> clearCache() async {
    await cacheManager.emptyCache();
  }
}
