import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_item.dart';

class StorageService {
  static const String _keyReminders = 'saved_reminders';
  static const String _keyWidgetTodayCount = 'widget_today_count';
  static const String _keyWidgetTopTasks = 'widget_top_tasks';

  Future<List<ReminderItem>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyReminders);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => ReminderItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveReminders(List<ReminderItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((e) => e.toMap()).toList();
    await prefs.setString(_keyReminders, json.encode(data));

    // 同步刷新提供给桌面小组件 (Widget) 的精简数据
    final todayPending = list.where((e) => e.isToday && !e.isCompleted).toList();
    await prefs.setInt(_keyWidgetTodayCount, todayPending.length);
    final topThreeTitles = todayPending.take(3).map((e) => e.title).toList();
    await prefs.setStringList(_keyWidgetTopTasks, topThreeTitles);
  }
}
