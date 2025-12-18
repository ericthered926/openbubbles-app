# Changelog - OpenBubbles Sync Optimization

All notable changes for the sync performance optimization work.

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

## [Unreleased] - 2024-12-18

### Added (Performance Work - Later Identified as Unused)

#### Time-Based Sync (BlueBubbles path - UNUSED)
- Added `startTimestamp` parameter to `FullSyncManager`
- Added timestamp validation in constructor
- Added `syncStartDate` field to `SyncService` 
- Added `SyncDateRangeDropdown` widget (never shown in UI)

#### Parallel Chat Sync (BlueBubbles path - UNUSED)
- Added `parallelChats` parameter to `FullSyncManager` (default: 5)
- Added `_syncSingleChat` helper method for parallel execution
- Refactored sync loop to use `Future.wait`

#### Handle Caching (BlueBubbles path - UNUSED)
- Added `HandleCache` service with LRU eviction
- Added cache warmup before sync

#### Unit Tests
- Added `test/services/backend/sync/handle_cache_test.dart`
- Added `test/services/backend/sync/full_sync_manager_test.dart`

### Changed

#### Dependencies (USED)
- Replaced `chipweinberger/flutter_isolate` with `rmawatson/flutter_isolate`

#### Performance Optimizations (USED)
- **chats_service.dart**: Moved `sort()` outside batch loop - O(n²) → O(n log n)

#### Code Cleanup (USED)
- Applied 583 auto-fixes via `dart fix --apply`
- ColorScheme API updates (`background` → `surface`, etc.)
- Removed unused imports

### Removed
- Unused imports in multiple files

---

## Planned: BlueBubbles Code Removal

### Files to DELETE
```
lib/services/backend/sync/full_sync_manager.dart
lib/services/backend/sync/incremental_sync_manager.dart
lib/services/backend/sync/handle_cache.dart
lib/app/layouts/setup/pages/sync/server_credentials.dart
lib/app/layouts/setup/pages/sync/sync_settings.dart
lib/app/layouts/setup/pages/sync/sync_progress.dart
lib/app/layouts/setup/pages/sync/mac_setup_check.dart
lib/app/layouts/settings/dialogs/sync_dialog.dart
test/services/backend/sync/handle_cache_test.dart
test/services/backend/sync/full_sync_manager_test.dart
```

### Rationale
- OpenBubbles only uses RustPush mode
- BlueBubbles code is dead code from fork origin
- Reduces codebase complexity

---

### Changed

#### Dependencies
- Replaced `chipweinberger/flutter_isolate` with `rmawatson/flutter_isolate` (original repo was deleted)

#### Performance Optimizations
- **full_sync_manager.dart**: Sequential chat sync → Parallel batches (5 at a time)
- **message.dart**: `Database.handles.getAll()` → `handleCache.getByRowIds()` (cache with DB fallback)
- **chats_service.dart**: Moved `sort()` call outside batch loop (was O(n²), now O(n log n))
- **sync_service.dart**: Added cache warm-up call before starting full sync

### Removed
- Unused import: `package:dlibphonenumber/generated/metadata/phone_number/CH.dart`
- Unused import: `package:telephony_plus/src/models/attachment.dart`
- Unused import: `package:bluebubbles/src/rust/api/api.dart` (in chats_service.dart)

### Fixed
- `flutter pub get` now works (was failing due to deleted flutter_isolate fork)

---

## Files Modified

| File | Type | Summary |
|------|------|---------|
| `pubspec.yaml` | Modified | Fixed flutter_isolate dependency |
| `lib/services/backend/sync/full_sync_manager.dart` | Modified | Parallel sync, time filtering |
| `lib/services/backend/sync/sync_service.dart` | Modified | Added parallelChats, syncStartDate, cache warmup |
| `lib/services/backend/sync/handle_cache.dart` | **New** | LRU handle cache |
| `lib/services/backend/setup/setup_service.dart` | Modified | Accept syncStartDate parameter |
| `lib/app/layouts/setup/setup_view.dart` | Modified | Added syncStartDate property |
| `lib/app/layouts/setup/pages/sync/sync_settings.dart` | Modified | Added date range dropdown |
| `lib/services/ui/chat/chats_service.dart` | Modified | Sort optimization |
| `lib/database/io/message.dart` | Modified | Use handle cache |

---

## Migration Notes

These changes are **backward compatible**. No database migrations or user actions required.

Default behavior:
- `startTimestamp = 0` means sync all messages (same as before)
- `parallelChats = 5` is a reasonable default
- Handle cache auto-warms before sync

---

## Testing Recommendations

1. Test full sync with new user account
2. Test incremental sync after initial setup
3. Verify "Manually Sync Messages" in settings still works
4. Test cancelling sync mid-progress
5. Test with different date range selections
