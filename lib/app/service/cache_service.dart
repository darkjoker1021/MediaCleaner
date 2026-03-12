import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences.
/// All encode/decode of size maps is done lazily and cached in-memory
/// to avoid repeated jsonDecode on every read.
class CacheService {
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kKeptIds    = 'kept_ids';
  static const _kTrashIds   = 'trash_ids';
  static const _kFreedBytes = 'freed_bytes_total';
  static const _kSizeMap    = 'size_map';

  static const _kVideoKeptIds    = 'video_kept_ids';
  static const _kVideoTrashIds   = 'video_trash_ids';
  static const _kVideoFreedBytes = 'video_freed_bytes_total';
  static const _kVideoSizeMap    = 'video_size_map';

  SharedPreferences? _prefs;

  // ── In-memory cache for size maps (avoids repeated JSON decode) ───────────
  Map<String, int>? _sizeMapCache;
  Map<String, int>? _videoSizeMapCache;

  Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  // ── Photos: read ──────────────────────────────────────────────────────────

  Set<String> getKeptIds()  =>
      Set<String>.from(_prefs?.getStringList(_kKeptIds)  ?? const []);
  Set<String> getTrashIds() =>
      Set<String>.from(_prefs?.getStringList(_kTrashIds) ?? const []);
  int getFreedBytes() => _prefs?.getInt(_kFreedBytes) ?? 0;

  Map<String, int> getSizeMap() =>
      _sizeMapCache ??= _decodeMap(_prefs?.getString(_kSizeMap));

  // ── Photos: write ─────────────────────────────────────────────────────────

  Future<void> saveKeptIds(Set<String> ids) =>
      _prefs!.setStringList(_kKeptIds, ids.toList());

  Future<void> saveTrashIds(Set<String> ids) =>
      _prefs!.setStringList(_kTrashIds, ids.toList());

  Future<void> addFreedBytes(int extra) =>
      _prefs!.setInt(_kFreedBytes, getFreedBytes() + extra);

  Future<void> saveSizeMap(Map<String, int> map) {
    _sizeMapCache = map; // update cache
    return _prefs!.setString(_kSizeMap, jsonEncode(map));
  }

  Future<void> clearAll() async {
    await Future.wait([
      _prefs!.remove(_kKeptIds),
      _prefs!.remove(_kTrashIds),
    ]);
  }

  Future<void> resetStats() async {
    await clearAll();
    await _prefs!.setInt(_kFreedBytes, 0);
  }

  // ── Videos: read ─────────────────────────────────────────────────────────

  Set<String> getVideoKeptIds()  =>
      Set<String>.from(_prefs?.getStringList(_kVideoKeptIds)  ?? const []);
  Set<String> getVideoTrashIds() =>
      Set<String>.from(_prefs?.getStringList(_kVideoTrashIds) ?? const []);
  int getVideoFreedBytes() => _prefs?.getInt(_kVideoFreedBytes) ?? 0;

  Map<String, int> getVideoSizeMap() =>
      _videoSizeMapCache ??= _decodeMap(_prefs?.getString(_kVideoSizeMap));

  // ── Videos: write ────────────────────────────────────────────────────────

  Future<void> saveVideoKeptIds(Set<String> ids) =>
      _prefs!.setStringList(_kVideoKeptIds, ids.toList());

  Future<void> saveVideoTrashIds(Set<String> ids) =>
      _prefs!.setStringList(_kVideoTrashIds, ids.toList());

  Future<void> addVideoFreedBytes(int extra) =>
      _prefs!.setInt(_kVideoFreedBytes, getVideoFreedBytes() + extra);

  Future<void> saveVideoSizeMap(Map<String, int> map) {
    _videoSizeMapCache = map; // update cache
    return _prefs!.setString(_kVideoSizeMap, jsonEncode(map));
  }

  Future<void> clearVideoData() async {
    await Future.wait([
      _prefs!.remove(_kVideoKeptIds),
      _prefs!.remove(_kVideoTrashIds),
    ]);
  }

  Future<void> resetVideoStats() async {
    await clearVideoData();
    await _prefs!.setInt(_kVideoFreedBytes, 0);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, int> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }
}