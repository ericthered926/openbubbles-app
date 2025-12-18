import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:get/get.dart' hide Condition;

/// A cache for Handle objects to avoid repeated database queries during sync
/// Uses LRU-style eviction when cache is full
HandleCache handleCache = Get.isRegistered<HandleCache>()
    ? Get.find<HandleCache>()
    : Get.put(HandleCache());

class HandleCache extends GetxService {
  /// Maximum number of handles to keep in cache
  static const int maxCacheSize = 500;

  /// Cache: originalROWID -> Handle
  final Map<int, Handle> _cacheByRowId = {};

  /// Cache: address -> Handle (for address-based lookups)
  final Map<String, Handle> _cacheByAddress = {};

  /// Access order for LRU eviction (most recent at end)
  final List<int> _accessOrder = [];

  /// Get a handle by its originalROWID, using cache if available
  Handle? getByRowId(int rowId) {
    if (_cacheByRowId.containsKey(rowId)) {
      // Move to end of access order (most recently used)
      _accessOrder.remove(rowId);
      _accessOrder.add(rowId);
      return _cacheByRowId[rowId];
    }
    return null;
  }

  /// Get a handle by address, using cache if available
  Handle? getByAddress(String address) {
    return _cacheByAddress[address];
  }

  /// Add a handle to the cache
  void put(Handle handle) {
    if (handle.originalROWID != null && handle.originalROWID! > 0) {
      _evictIfNeeded();
      _cacheByRowId[handle.originalROWID!] = handle;
      _accessOrder.remove(handle.originalROWID!);
      _accessOrder.add(handle.originalROWID!);
    }
    if (handle.address.isNotEmpty) {
      _cacheByAddress[handle.address] = handle;
    }
  }

  /// Add multiple handles to the cache
  void putAll(List<Handle> handles) {
    for (final handle in handles) {
      put(handle);
    }
  }

  /// Get handles by a list of ROWIDs, querying DB only for misses
  /// Returns a map of rowId -> Handle
  Map<int, Handle> getByRowIds(List<int> rowIds) {
    final result = <int, Handle>{};
    final missing = <int>[];

    for (final rowId in rowIds) {
      final cached = getByRowId(rowId);
      if (cached != null) {
        result[rowId] = cached;
      } else {
        missing.add(rowId);
      }
    }

    // Query database for missing handles
    if (missing.isNotEmpty) {
      final handles = Database.runInTransaction(TxMode.read, () {
        QueryBuilder<Handle> query =
            Database.handles.query(Handle_.originalROWID.oneOf(missing));
        return query.build().find();
      });

      for (final handle in handles) {
        result[handle.originalROWID!] = handle;
        put(handle);
      }
    }

    return result;
  }

  /// Evict oldest entries if cache is full
  void _evictIfNeeded() {
    while (_cacheByRowId.length >= maxCacheSize && _accessOrder.isNotEmpty) {
      final oldest = _accessOrder.removeAt(0);
      final handle = _cacheByRowId.remove(oldest);
      if (handle != null && handle.address.isNotEmpty) {
        _cacheByAddress.remove(handle.address);
      }
    }
  }

  /// Clear the entire cache
  void clear() {
    _cacheByRowId.clear();
    _cacheByAddress.clear();
    _accessOrder.clear();
  }

  /// Pre-warm the cache with all handles (useful before a large sync)
  Future<void> warmUp() async {
    final handles = Database.handles.getAll();
    putAll(handles);
  }

  /// Get cache statistics
  Map<String, int> get stats => {
        'cacheByRowId': _cacheByRowId.length,
        'cacheByAddress': _cacheByAddress.length,
        'maxSize': maxCacheSize,
      };
}
