import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/services/backend/sync/full_sync_manager.dart';

/// Unit tests for FullSyncManager
///
/// Note: These tests focus on the timestamp validation logic.
/// Full sync behavior requires mocking HTTP and database dependencies.

void main() {
  group('FullSyncManager', () {
    group('timestamp validation', () {
      test('should accept valid startTimestamp < endTimestamp', () {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        final oneYearAgo = now - (365 * 24 * 60 * 60 * 1000);

        final manager = FullSyncManager(
          startTimestamp: oneYearAgo,
          messageCount: 25,
        );

        // startTimestamp should remain as set
        expect(manager.startTimestamp, equals(oneYearAgo));
        expect(manager.startTimestamp < manager.endTimestamp, isTrue);
      });

      test('should accept startTimestamp = 0 (sync all)', () {
        final manager = FullSyncManager(
          startTimestamp: 0,
          messageCount: 25,
        );

        expect(manager.startTimestamp, equals(0));
      });

      test('should reset startTimestamp if greater than endTimestamp', () {
        // Create a timestamp in the future (should trigger validation)
        final futureTimestamp = DateTime.now()
            .add(const Duration(days: 365))
            .toUtc()
            .millisecondsSinceEpoch;

        final manager = FullSyncManager(
          startTimestamp: futureTimestamp,
          messageCount: 25,
        );

        // startTimestamp should be reset to 0
        expect(manager.startTimestamp, equals(0));
      });

      test('should accept startTimestamp = endTimestamp (edge case)', () {
        // This is technically valid - would return no messages
        // but shouldn't cause an error
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;

        final manager = FullSyncManager(
          startTimestamp: now,
          messageCount: 25,
        );

        // Should be valid since endTimestamp is also ~now
        // Note: there's a tiny race condition here, but in practice
        // the endTimestamp is set slightly after startTimestamp
        expect(manager.startTimestamp <= manager.endTimestamp, isTrue);
      });
    });

    group('default values', () {
      test('should use correct defaults', () {
        final manager = FullSyncManager();

        expect(manager.startTimestamp, equals(0));
        expect(manager.messageCount, equals(25));
        expect(manager.skipEmptyChats, isTrue);
        expect(manager.parallelChats, equals(5));
      });

      test('should allow custom parallelChats', () {
        final manager = FullSyncManager(parallelChats: 10);
        expect(manager.parallelChats, equals(10));
      });

      test('should allow parallelChats = 1 (sequential mode)', () {
        final manager = FullSyncManager(parallelChats: 1);
        expect(manager.parallelChats, equals(1));
      });
    });

    group('message count', () {
      test('should accept custom messageCount', () {
        final manager = FullSyncManager(messageCount: 100);
        expect(manager.messageCount, equals(100));
      });

      test('should accept small messageCount', () {
        final manager = FullSyncManager(messageCount: 1);
        expect(manager.messageCount, equals(1));
      });
    });
  });
}
