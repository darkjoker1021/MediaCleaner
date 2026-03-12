import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper su SharedPreferences con cache in memoria per tutti i valori letti
/// frequentemente. Ogni getter ricrea Set/Map solo al primo accesso (lazy) e
/// li tiene in memoria finché non vengono invalidati da una save().
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

  // ── Cache in memoria ──────────────────────────────────────────────────────
  // FIX: Set e Map sono creati una sola volta e invalidati solo dopo una save().
  // Prima ogni chiamata a getKeptIds() allocava un nuovo Set<String> copiando
  // tutta la lista — ora è un semplice return del campo cached.
  Set<String>?     _keptCache;
  Set<String>?     _trashCache;
  Map<String, int>? _sizeMapCache;

  Set<String>?     _videoKeptCache;
  Set<String>?     _videoTrashCache;
  Map<String, int>? _videoSizeMapCache;

  Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  // ── Photos: read ──────────────────────────────────────────────────────────

  Set<String> getKeptIds() =>
      _keptCache  ??= Set<String>.from(_prefs?.getStringList(_kKeptIds)  ?? const []);

  Set<String> getTrashIds() =>
      _trashCache ??= Set<String>.from(_prefs?.getStringList(_kTrashIds) ?? const []);

  int getFreedBytes() => _prefs?.getInt(_kFreedBytes) ?? 0;

  Map<String, int> getSizeMap() =>
      _sizeMapCache ??= _decodeMap(_prefs?.getString(_kSizeMap));

  // ── Photos: write ─────────────────────────────────────────────────────────

  Future<void> saveKeptIds(Set<String> ids) {
    _keptCache = ids; // aggiorna cache in memoria
    return _prefs!.setStringList(_kKeptIds, ids.toList());
  }

  Future<void> saveTrashIds(Set<String> ids) {
    _trashCache = ids;
    return _prefs!.setStringList(_kTrashIds, ids.toList());
  }

  Future<void> addFreedBytes(int extra) =>
      _prefs!.setInt(_kFreedBytes, getFreedBytes() + extra);

  Future<void> saveSizeMap(Map<String, int> map) {
    _sizeMapCache = map;
    return _prefs!.setString(_kSizeMap, jsonEncode(map));
  }

  Future<void> clearAll() async {
    _keptCache  = null;
    _trashCache = null;
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

  Set<String> getVideoKeptIds() =>
      _videoKeptCache  ??= Set<String>.from(_prefs?.getStringList(_kVideoKeptIds)  ?? const []);

  Set<String> getVideoTrashIds() =>
      _videoTrashCache ??= Set<String>.from(_prefs?.getStringList(_kVideoTrashIds) ?? const []);

  int getVideoFreedBytes() => _prefs?.getInt(_kVideoFreedBytes) ?? 0;

  Map<String, int> getVideoSizeMap() =>
      _videoSizeMapCache ??= _decodeMap(_prefs?.getString(_kVideoSizeMap));

  // ── Videos: write ────────────────────────────────────────────────────────

  Future<void> saveVideoKeptIds(Set<String> ids) {
    _videoKeptCache = ids;
    return _prefs!.setStringList(_kVideoKeptIds, ids.toList());
  }

  Future<void> saveVideoTrashIds(Set<String> ids) {
    _videoTrashCache = ids;
    return _prefs!.setStringList(_kVideoTrashIds, ids.toList());
  }

  Future<void> addVideoFreedBytes(int extra) =>
      _prefs!.setInt(_kVideoFreedBytes, getVideoFreedBytes() + extra);

  Future<void> saveVideoSizeMap(Map<String, int> map) {
    _videoSizeMapCache = map;
    return _prefs!.setString(_kVideoSizeMap, jsonEncode(map));
  }

  Future<void> clearVideoData() async {
    _videoKeptCache  = null;
    _videoTrashCache = null;
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