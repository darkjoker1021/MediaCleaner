import 'package:get/get.dart';
import 'package:media_cleaner/app/service/photo_service.dart';
import 'package:media_cleaner/app/modules/home/controllers/home_controller.dart';

/// Gruppo burst con campi derivati memoizzati nel costruttore.
/// best / extras / wasteBytes sono calcolati una sola volta — mai più getter ripetuti.
class BurstGroup {
  BurstGroup(this.items)
      : best = items.reduce((a, b) => a.sizeBytes >= b.sizeBytes ? a : b) {
    extras     = List.unmodifiable(items.where((i) => i.id != best.id));
    wasteBytes = extras.fold(0, (s, e) => s + e.sizeBytes);
  }

  final List<PhotoItem> items;
  final PhotoItem       best;
  late final List<PhotoItem> extras;
  late final int wasteBytes;
  int      get count => items.length;
  DateTime get time  => best.createdAt;
}

class BurstController extends GetxController {
  HomeController get _home => Get.find<HomeController>();

  static const initialScanLimit = 400;
  static const _windowSeconds   = 3;
  static const _minBurst        = 3;

  final isScanning  = true.obs;
  final hasMore     = false.obs;
  final groups      = <BurstGroup>[].obs;
  final isSelecting = false.obs;
  final selectedIds = <String>{}.obs;

  int get totalExtras     => groups.fold(0, (s, g) => s + g.extras.length);
  int get totalWasteBytes => groups.fold(0, (s, g) => s + g.wasteBytes);

  // FIX: indice size memoizzato — non ricostruisce la mappa ad ogni accesso
  Map<String, int>? _sizeIndex;
  Map<String, int> get _getSizeIndex =>
      _sizeIndex ??= {for (final p in _home.allItems) p.id: p.sizeBytes};
  void _invalidateSizeIndex() => _sizeIndex = null;

  int get selectedWasteBytes {
    final idx = _getSizeIndex;
    return selectedIds.fold(0, (s, id) => s + (idx[id] ?? 0));
  }

  @override
  void onReady() {
    super.onReady();
    scan();
  }

  @override
  void onClose() {
    _sizeIndex = null;
    super.onClose();
  }

  // FIX: scan e scanAll collassati in un unico metodo (come già fatto altrove)
  Future<void> scan({bool all = false}) async {
    isScanning.value = true;
    selectedIds.clear();
    _invalidateSizeIndex();
    await Future.delayed(Duration.zero);

    final trashSet = {for (final t in _home.trashItems) t.id};
    final keptSet  = {for (final k in _home.keptItems)  k.id};

    final allSource = _home.allItems
        .where((p) => !trashSet.contains(p.id) && !keptSet.contains(p.id))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final source = !all && allSource.length > initialScanLimit
        ? allSource.sublist(0, initialScanLimit)
        : allSource;

    final found = _detectBursts(source);
    groups.assignAll(found);

    // Auto-select extras
    for (final g in found) {
      for (final e in g.extras) {
        selectedIds.add(e.id);
      }
    }
    // FIX: RxSet notifica automaticamente — nessun refresh() necessario

    hasMore.value    = allSource.length > source.length;
    isScanning.value = false;
  }

  Future<void> scanAll() => scan(all: true);

  List<BurstGroup> _detectBursts(List<PhotoItem> source) {
    final found = <BurstGroup>[];
    int i = 0;
    while (i < source.length) {
      final group = [source[i]];
      int j = i + 1;
      while (j < source.length) {
        final diffSec = source[j].createdAt
            .difference(source[j - 1].createdAt)
            .inSeconds
            .abs();
        if (diffSec <= _windowSeconds) {
          group.add(source[j++]);
        } else {
          break;
        }
      }
      if (group.length >= _minBurst) found.add(BurstGroup(group));
      i = j > i ? j : i + 1;
    }
    return found;
  }

  // ── Selezione ─────────────────────────────────────────────────────────────

  void toggleSelect(String id) {
    // FIX: RxSet notifica da solo — rimosso selectedIds.refresh()
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
  }

  void clearSelection() => selectedIds.clear();

  void selectAllExtras() {
    for (final g in groups) {
      for (final e in g.extras) {
        selectedIds.add(e.id);
      }
    }
    // FIX: nessun refresh() ridondante
  }

  // ── Azioni ────────────────────────────────────────────────────────────────

  void moveSelectedToTrash() {
    // FIX: costruisci i set una sola volta e usa bulk moveToTrash
    final trashSet = {for (final t in _home.trashItems) t.id};
    final keptSet  = {for (final k in _home.keptItems)  k.id};
    for (final id in selectedIds.toList()) {
      if (trashSet.contains(id) || keptSet.contains(id)) continue;
      _home.moveToTrash(id);
    }
    _invalidateSizeIndex();
    scan();
  }

  Future<PhotoItem> resolveThumb(PhotoItem item) =>
      _home.resolveFullThumb(item);

  String fmt(int b) => PhotoService.formatBytes(b);
}