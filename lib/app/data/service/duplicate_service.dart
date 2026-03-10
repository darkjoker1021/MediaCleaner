import 'package:media_cleaner/app/modules/shared/photo_item.dart';

/// Gruppo di foto considerate duplicate
class DuplicateGroup {
  final List<PhotoItem> items;
  DuplicateGroup(this.items);

  /// La foto "migliore" del gruppo (più pesante = qualità più alta)
  PhotoItem get best => items.reduce((a, b) => a.sizeBytes >= b.sizeBytes ? a : b);

  /// Le foto "peggiori" (tutte tranne la migliore)
  List<PhotoItem> get duplicates => items.where((i) => i.id != best.id).toList();

  int get wasteBytes => duplicates.fold(0, (s, e) => s + e.sizeBytes);
  int get totalBytes => items.fold(0, (s, e) => s + e.sizeBytes);
  int get count => items.length;
}

class DuplicateService {
  /// Trova gruppi di duplicati.
  /// Strategia: stesso sizeBytes E stessa data al minuto → quasi certamente duplicato
  /// (es. foto salvata in più album, burst shot, copia da WhatsApp)
  List<DuplicateGroup> findDuplicates(List<PhotoItem> items) {
    // Raggruppa per chiave: "sizeBytes_yyyy-MM-dd_HH:mm"
    final map = <String, List<PhotoItem>>{};

    for (final item in items) {
      if (item.sizeBytes <= 0) continue; // skip non-risolti
      final dt = item.createdAt;
      final key = '${item.sizeBytes}_'
          '${dt.year}-${_p(dt.month)}-${_p(dt.day)}_'
          '${_p(dt.hour)}:${_p(dt.minute)}';
      map.putIfAbsent(key, () => []).add(item);
    }

    final groups = map.values
        .where((g) => g.length > 1)
        .map((g) => DuplicateGroup(g))
        .toList();

    // Ordina per spreco decrescente (prima i gruppi che liberano più spazio)
    groups.sort((a, b) => b.wasteBytes.compareTo(a.wasteBytes));
    return groups;
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
