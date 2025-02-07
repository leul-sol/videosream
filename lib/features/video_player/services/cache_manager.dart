import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CustomHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return super.get(
      url,
      headers: {
        'Content-Type': 'application/x-mpegURL',
        'Accept': 'application/x-mpegURL',
        ...?headers,
      },
    );
  }
}

class EnhancedCacheService {
  static final EnhancedCacheService _instance =
      EnhancedCacheService._internal();
  factory EnhancedCacheService() => _instance;
  EnhancedCacheService._internal();

  final CacheManager cacheManager = CacheManager(
    Config(
      'videoCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: 'videoCache'),
      fileService: CustomHttpFileService(),
    ),
  );

  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<File?> getVideoFromCache(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final fileInfo = await cacheManager.getFileFromCache(cacheKey);

      if (fileInfo != null) {
        // Verify file exists and is valid
        if (await fileInfo.file.exists()) {
          final fileSize = await fileInfo.file.length();
          if (fileSize > 0) {
            print('Cache hit: $url');
            return fileInfo.file;
          }
        }
      }

      print('Cache miss: $url');
      return null;
    } catch (e) {
      print('Error getting video from cache: $e');
      return null;
    }
  }

  Future<File?> cacheVideo(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);

      // Check if already cached
      final existingFile = await getVideoFromCache(url);
      if (existingFile != null) {
        return existingFile;
      }

      // Download and cache the file
      print('Caching video: $url');
      final fileInfo = await cacheManager.downloadFile(
        url,
        key: cacheKey,
      );

      return fileInfo.file;
    } catch (e) {
      print('Error caching video: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await cacheManager.emptyCache();

      // Also clear temporary directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }

      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int size = 0;

      await for (var entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }

      return size;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  Future<bool> isVideoCached(String url) async {
    final file = await getVideoFromCache(url);
    return file != null;
  }
}
