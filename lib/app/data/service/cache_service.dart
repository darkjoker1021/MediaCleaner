import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  // ── Chiavi foto ───────────────────────────────────────────────────────────
  static const _kKeptIds    = 'kept_ids';
  static const _kTrashIds   = 'trash_ids';
  static const _kFreedBytes = 'freed_bytes_total';
  static const _kSizeMap    = 'size_map';

  // ── Chiavi video ──────────────────────────────────────────────────────────
  static const _kVideoKeptIds    = 'video_kept_ids';
  static const _kVideoTrashIds   = 'video_trash_ids';
  static const _kVideoFreedBytes = 'video_freed_bytes_total';
  static const _kVideoSizeMap    = 'video_size_map';

  SharedPreferences? _prefs;

  Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  // ── Foto: lettura ─────────────────────────────────────────────────────────

  Set<String> getKeptIds()  =>
      Set<String>.from(_prefs?.getStringList(_kKeptIds)  ?? []);
  Set<String> getTrashIds() =>
      Set<String>.from(_prefs?.getStringList(_kTrashIds) ?? []);
  int getFreedBytes() => _prefs?.getInt(_kFreedBytes) ?? 0;
  Map<String, int> getSizeMap() => _decodeMap(_prefs?.getString(_kSizeMap));

  // ── Foto: scrittura ───────────────────────────────────────────────────────

  Future<void> saveKeptIds(Set<String> ids) =>
      _prefs!.setStringList(_kKeptIds, ids.toList());
  Future<void> saveTrashIds(Set<String> ids) =>
      _prefs!.setStringList(_kTrashIds, ids.toList());
  Future<void> addFreedBytes(int extra) =>
      _prefs!.setInt(_kFreedBytes, getFreedBytes() + extra);
  Future<void> saveSizeMap(Map<String, int> map) =>
      _prefs!.setString(_kSizeMap, jsonEncode(map));

  Future<void> clearAll() async {
    await _prefs!.remove(_kKeptIds);
    await _prefs!.remove(_kTrashIds);
  }

  Future<void> resetStats() async {
    await clearAll();
    await _prefs!.setInt(_kFreedBytes, 0);
  }

  // ── Video: lettura ────────────────────────────────────────────────────────

  Set<String> getVideoKeptIds()  =>
      Set<String>.from(_prefs?.getStringList(_kVideoKeptIds)  ?? []);
  Set<String> getVideoTrashIds() =>
      Set<String>.from(_prefs?.getStringList(_kVideoTrashIds) ?? []);
  int getVideoFreedBytes() => _prefs?.getInt(_kVideoFreedBytes) ?? 0;
  Map<String, int> getVideoSizeMap() =>
      _decodeMap(_prefs?.getString(_kVideoSizeMap));

  // ── Video: scrittura ──────────────────────────────────────────────────────

  Future<void> saveVideoKeptIds(Set<String> ids) =>
      _prefs!.setStringList(_kVideoKeptIds, ids.toList());
  Future<void> saveVideoTrashIds(Set<String> ids) =>
      _prefs!.setStringList(_kVideoTrashIds, ids.toList());
  Future<void> addVideoFreedBytes(int extra) =>
      _prefs!.setInt(_kVideoFreedBytes, getVideoFreedBytes() + extra);
  Future<void> saveVideoSizeMap(Map<String, int> map) =>
      _prefs!.setString(_kVideoSizeMap, jsonEncode(map));

  Future<void> clearVideoData() async {
    await _prefs!.remove(_kVideoKeptIds);
    await _prefs!.remove(_kVideoTrashIds);
  }

  Future<void> resetVideoStats() async {
    await clearVideoData();
    await _prefs!.setInt(_kVideoFreedBytes, 0);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static Map<String, int> _decodeMap(String? raw) {
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }
}