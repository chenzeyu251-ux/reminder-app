import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/models/reminder_item.dart';

void main() {
  group('ReminderItem Model Tests', () {
    test('should correctly serialize and deserialize to/from JSON map', () {
      final now = DateTime.now();
      final item = ReminderItem(
        id: 'test-uuid-123',
        title: '测试买牛奶',
        notes: '新鲜低脂',
        reminderTime: now,
        isCompleted: false,
        isStrongAlert: true,
        snoozeMinutes: 15,
      );

      final map = item.toMap();
      final fromMapItem = ReminderItem.fromMap(map);

      expect(fromMapItem.id, 'test-uuid-123');
      expect(fromMapItem.title, '测试买牛奶');
      expect(fromMapItem.notes, '新鲜低脂');
      expect(fromMapItem.isCompleted, false);
      expect(fromMapItem.isStrongAlert, true);
      expect(fromMapItem.snoozeMinutes, 15);
    });

    test('copyWith should update fields correctly', () {
      final item = ReminderItem(
        id: '1',
        title: '原始标题',
        reminderTime: DateTime.now(),
      );

      final updated = item.copyWith(title: '修改后标题', isCompleted: true);
      expect(updated.title, '修改后标题');
      expect(updated.isCompleted, true);
      expect(updated.id, '1');
    });

    test('isToday and isOverdue check', () {
      final today = DateTime.now();
      final itemToday = ReminderItem(
        id: '2',
        title: '今日事项',
        reminderTime: today,
      );
      expect(itemToday.isToday, isTrue);

      final pastItem = ReminderItem(
        id: '3',
        title: '已过期事项',
        reminderTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(pastItem.isOverdue, isTrue);
    });
  });
}
