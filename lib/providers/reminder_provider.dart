import 'package:flutter/foundation.dart';
import '../models/reminder_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

enum ReminderFilter { all, today, completed }

class ReminderProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  List<ReminderItem> _items = [];
  bool _isLoading = true;
  ReminderFilter _filter = ReminderFilter.today;

  List<ReminderItem> get items => _items;
  bool get isLoading => _isLoading;
  ReminderFilter get filter => _filter;

  int get todayPendingCount =>
      _items.where((e) => e.isToday && !e.isCompleted).length;

  int get totalCompletedCount => _items.where((e) => e.isCompleted).length;

  List<ReminderItem> get filteredItems {
    switch (_filter) {
      case ReminderFilter.today:
        return _items.where((e) => e.isToday).toList()
          ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
      case ReminderFilter.completed:
        return _items.where((e) => e.isCompleted).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReminderFilter.all:
        return List.from(_items)
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }
            return a.reminderTime.compareTo(b.reminderTime);
          });
    }
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _items = await _storageService.loadReminders();
    _isLoading = false;
    notifyListeners();

    _notificationService.onNotificationAction = handleNotificationAction;
    await WidgetService.updateWidgetData(_items);
  }

  void setFilter(ReminderFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> addReminder(ReminderItem item) async {
    _items.add(item);
    notifyListeners();

    await _storageService.saveReminders(_items);
    await _notificationService.scheduleReminder(item);
    await WidgetService.updateWidgetData(_items);
  }

  Future<void> updateReminder(ReminderItem updatedItem) async {
    final index = _items.indexWhere((e) => e.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();

      await _storageService.saveReminders(_items);
      if (updatedItem.isCompleted) {
        await _notificationService.cancelReminder(updatedItem.id);
      } else {
        await _notificationService.scheduleReminder(updatedItem);
      }
      await WidgetService.updateWidgetData(_items);
    }
  }

  Future<void> toggleComplete(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _items[index];
      final newStatus = !item.isCompleted;
      final updated = item.copyWith(isCompleted: newStatus);
      _items[index] = updated;
      notifyListeners();

      await _storageService.saveReminders(_items);
      if (newStatus) {
        await _notificationService.cancelReminder(id);
      } else {
        await _notificationService.scheduleReminder(updated);
      }
      await WidgetService.updateWidgetData(_items);
    }
  }

  Future<void> deleteReminder(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();

    await _storageService.saveReminders(_items);
    await _notificationService.cancelReminder(id);
    await WidgetService.updateWidgetData(_items);
  }

  Future<void> snoozeReminder(String id, {int? extraMinutes}) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _items[index];
      final minutes = extraMinutes ?? item.snoozeMinutes;
      final newTime = DateTime.now().add(Duration(minutes: minutes));
      final updated = item.copyWith(
        reminderTime: newTime,
        isCompleted: false,
      );
      _items[index] = updated;
      notifyListeners();

      await _storageService.saveReminders(_items);
      await _notificationService.scheduleReminder(updated);
      await WidgetService.updateWidgetData(_items);
    }
  }

  void handleNotificationAction(String reminderId, String actionId) {
    if (actionId == NotificationService.actionComplete) {
      toggleComplete(reminderId);
    } else if (actionId == NotificationService.actionSnooze) {
      snoozeReminder(reminderId);
    }
  }
}
