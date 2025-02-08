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
  EnhancedCacheService._internal() {
    _initCacheManager();
  }

  late CacheManager cacheManager;
  final Set<String> _activeDownloads = {};

  Future<void> _initCacheManager() async {
    try {
      final cacheDir = await _getCacheDirectory();
      cacheManager = CacheManager(
        Config(
          'videoCache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 20,
          repo: JsonCacheInfoRepository(databaseName: 'videoCache'),
          fileService: CustomHttpFileService(),
          fileSystem: IOFileSystem(cacheDir.path),
        ),
      );
    } catch (e) {
      print('Error initializing cache manager: $e');
      // Fallback to default cache manager if custom initialization fails
      cacheManager = CacheManager(
        Config(
          'videoCache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 20,
          repo: JsonCacheInfoRepository(databaseName: 'videoCache'),
          fileService: CustomHttpFileService(),
        ),
      );
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/video_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<File?> getVideoFromCache(String url) async {
    try {
      final cacheKey = generateCacheKey(url);
      final fileInfo = await cacheManager.getFileFromCache(cacheKey);

      if (fileInfo != null) {
        if (await fileInfo.file.exists()) {
          final fileSize = await fileInfo.file.length();
          if (fileSize > 0) {
            // Verify file integrity
            try {
              final file = File(fileInfo.file.path);
              final randomAccessFile = await file.open(mode: FileMode.read);
              await randomAccessFile.close();
              print('Cache hit: $url');
              return fileInfo.file;
            } catch (e) {
              print('Cached file corrupted, removing: $e');
              await cacheManager.removeFile(cacheKey);
              return null;
            }
          }
        }
        // Remove invalid cache entry
        await cacheManager.removeFile(cacheKey);
      }

      print('Cache miss: $url');
      return null;
    } catch (e) {
      print('Error getting video from cache: $e');
      return null;
    }
  }

  Future<File?> cacheVideo(String url) async {
    if (_activeDownloads.contains(url)) {
      print('Download already in progress for: $url');
      return null;
    }

    try {
      _activeDownloads.add(url);
      final cacheKey = generateCacheKey(url);

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
        force: true, // Force redownload if needed
      );

      if (await fileInfo.file.exists()) {
        final fileSize = await fileInfo.file.length();
        if (fileSize > 0) {
          return fileInfo.file;
        }
      }

      // If we get here, the download failed or file is invalid
      await cacheManager.removeFile(cacheKey);
      return null;
    } catch (e) {
      print('Error caching video: $e');
      return null;
    } finally {
      _activeDownloads.remove(url);
    }
  }

  Future<void> removeFromCache(String url) async {
    try {
      final cacheKey = generateCacheKey(url);
      await cacheManager.removeFile(cacheKey);
    } catch (e) {
      print('Error removing video from cache: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await cacheManager.emptyCache();

      // Clear the cache directory
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      // Reinitialize cache manager
      await _initCacheManager();

      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<bool> isVideoCached(String url) async {
    final file = await getVideoFromCache(url);
    return file != null;
  }
}
