import '../models/video.dart';

class VideoRepository {
  static final List<String> _videoIds = [
    'eFDFooCflDdkcFcYxeKDSXeyW00FA00nXeOoMJeakvVSA',
    'w9qAyPlIaEAaeSuoB36r22xutGF800mXxZ00skcDKsjFc',
    'g5CwrZaaTWYdjb2peU818fzGkSvASW00tHnziQAQJq5I',
    'WrEk1kQpRcqAeTGCnrU00nJOUekJesdIL43NrYz01RYc',
    'zNvlO3QKLbe5Yu0101yQO8SRUDeycIL01cLOB02dhAvjhho',
    'TU4tu02tS7702jWUDVk5275JZvlNgv5WmyT6kLcV6awDw',
    'WVy89Zrbw15xAy8nFAGRljwAGGZq36BwNZSckOz1HU4',
    'ApFgkkaJc1SPL64C7XF2dA00Nh1iny00Dr67kVZxRptfQ',
  ];

  List<Video> getVideos() {
    return _videoIds
        .map((id) => Video(
              id: id,
              title: 'Video $id',
            ))
        .toList();
  }
}
