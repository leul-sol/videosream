import 'package:flutter/services.dart';

class PlatformVideoService {
  static const platform = MethodChannel('com.example.videostream/video');

  static Future<void> preloadVideo(String url) async {
    try {
      await platform.invokeMethod('preloadVideo', {'url': url});
    } catch (e) {
      print('Error in native preload: $e');
    }
  }

  static Future<void> clearCache() async {
    try {
      await platform.invokeMethod('clearCache');
    } catch (e) {
      print('Error clearing native cache: $e');
    }
  }
}
