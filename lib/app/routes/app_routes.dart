part of 'app_pages.dart';

abstract class Routes {
  static const HOME        = _Paths.HOME;
  static const TRASH       = _Paths.TRASH;
  static const KEPT        = _Paths.KEPT;
  static const DUPLICATES  = _Paths.DUPLICATES;
  static const SCREENSHOT  = _Paths.SCREENSHOT;
  static const VIDEO       = _Paths.VIDEO;
  static const VIDEO_TRASH = _Paths.VIDEO_TRASH;
  static const VIDEO_KEPT  = _Paths.VIDEO_KEPT;
}

abstract class _Paths {
  static const HOME        = '/home';
  static const TRASH       = '/trash';
  static const KEPT        = '/kept';
  static const DUPLICATES  = '/duplicates';
  static const SCREENSHOT  = '/screenshot';
  static const VIDEO       = '/video';
  static const VIDEO_TRASH = '/video/trash';
  static const VIDEO_KEPT  = '/video/kept';
}