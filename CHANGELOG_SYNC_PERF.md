# Changelog - OpenBubbles Sync Optimization

All notable changes for the sync performance optimization work.

---

## [2024-12-18] - BlueBubbles Code Removal

### Removed (Legacy BlueBubbles Code)

#### Deleted Files
- `lib/services/backend/sync/full_sync_manager.dart` - Full sync manager
- `lib/services/backend/sync/incremental_sync_manager.dart` - Incremental sync manager  
- `lib/services/backend/sync/handle_cache.dart` - Handle cache we added
- `lib/app/layouts/setup/pages/sync/server_credentials.dart` - Server credentials page
- `lib/app/layouts/setup/pages/sync/sync_settings.dart` - Sync settings page we modified
- `lib/app/layouts/setup/pages/sync/sync_progress.dart` - Sync progress page
- `lib/app/layouts/settings/dialogs/sync_dialog.dart` - Sync dialog
- `test/services/backend/sync/handle_cache_test.dart` - Our tests
- `test/services/backend/sync/full_sync_manager_test.dart` - Our tests

#### Modified Files
- `lib/services/services.dart` - Removed exports for deleted files
- `lib/services/backend/sync/sync_service.dart` - Simplified to RustPush-only
- `lib/services/backend/setup/setup_service.dart` - Simplified to RustPush-only
- `lib/app/layouts/setup/setup_view.dart` - Removed BlueBubbles setup pages
- `lib/app/layouts/settings/pages/server/server_management_panel.dart` - Removed sync dialog
- `lib/database/io/message.dart` - Removed handle cache, use direct DB queries

### Rationale
- OpenBubbles uses RustPush mode exclusively (`const usingRustPush = true`)
- BlueBubbles server-based sync code was never executed
- Reduces codebase size and complexity

---

## Architecture Discovery - 2024-12-18

### Key Findings

1. **OpenBubbles uses RustPush, not BlueBubbles server mode**
   - `const usingRustPush = true;` in main.dart
   - All BlueBubbles sync code is never executed
   - Our Full Sync optimizations were applied to the wrong code path

2. **RustPush is a separate submodule**
   - Git: https://github.com/OpenBubbles/rustpush.git
   - Dart wrapper in this repo: `lib/services/rustpush/rustpush_service.dart`
   - CloudKit sync happens in Dart layer, not Rust

3. **Message sync in RustPush**
   - Real-time: Apple Push → `api.recvWait()` → one at a time
   - History: CloudKit → `doCloudKitSync()` → batched sync

---

## [2024-12-18] - Initial Performance Work (SUPERSEDED)

### Added (Performance Work - Later Removed as Unused)

#### Time-Based Sync (BlueBubbles path - REMOVED)
- Added `startTimestamp` parameter to `FullSyncManager`
- Added timestamp validation in constructor
- Added `syncStartDate` field to `SyncService` 
- Added `SyncDateRangeDropdown` widget (never shown in UI)

#### Parallel Chat Sync (BlueBubbles path - REMOVED)
- Added `parallelChats` parameter to `FullSyncManager` (default: 5)
- Added `_syncSingleChat` helper method for parallel execution
- Refactored sync loop to use `Future.wait`

#### Handle Caching (BlueBubbles path - REMOVED)
- Added `HandleCache` service with LRU eviction
- Added cache warmup before sync

### Changed (STILL ACTIVE)

#### Dependencies
- Replaced `chipweinberger/flutter_isolate` with `rmawatson/flutter_isolate`

#### Performance Optimizations
- **chats_service.dart**: Moved `sort()` outside batch loop - O(n²) → O(n log n)

#### Code Cleanup
- Applied 583 auto-fixes via `dart fix --apply`
- ColorScheme API updates (`background` → `surface`, etc.)
- Removed unused imports

---

## Future Work: RustPush Optimization

The sync optimization patterns (parallel processing, caching) could be ported to:
- `lib/services/rustpush/rustpush_service.dart` → `doCloudKitSyncPrivate()`
- Apply handle caching to message processing
- Parallelize chat item processing in CloudKit sync
