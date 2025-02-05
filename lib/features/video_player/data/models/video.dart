import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/app_constants.dart';

part 'video.freezed.dart';
part 'video.g.dart';

@freezed
class Video with _$Video {
  const Video._();

  const factory Video({
    required String id,
    required String title,
    String? thumbnail,
  }) = _Video;

  String get streamUrl => '${AppConstants.baseUrl}/$id.m3u8';

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}
