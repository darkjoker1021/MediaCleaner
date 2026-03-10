import 'package:get/get.dart';
import 'package:media_cleaner/app/data/service/photo_service.dart';
import 'package:media_cleaner/app/modules/shared/photo_item.dart';

/// Contratto minimo che HomeController e VideoController devono rispettare.
/// StatsBar, SortSheet, KeptController e TrashController dipendono
/// SOLO da questa interfaccia — zero accoppiamento concreto.
abstract class IMediaController {
  RxList<PhotoItem> get allItems;
  RxList<PhotoItem> get trashItems;
  RxList<PhotoItem> get keptItems;
  RxInt    get keptCount;
  RxInt    get trashCount;
  RxBool   get canUndo;
  Rx<SortMode> get currentSort;

  int    get totalCount;
  int    get pendingCount;
  int    get trashBytes;
  int    get keptBytes;
  double get progress;
  int    get totalFreedBytes;

  Future<void>  setSortMode(SortMode mode);
  void          keepItem(String id,    {bool trackHistory = true});
  void          moveToTrash(String id, {bool trackHistory = true});
  bool          undoLastAction();
  void          restoreFromTrash(String id);
  void          restoreAllFromTrash();
  Future<int>   deleteFromTrash(List<String> ids);
  Future<int>   emptyTrash();
  void          unkeepItem(String id);
  Future<PhotoItem> resolveFullThumb(PhotoItem item);
}