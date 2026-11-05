import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/reminder_item.dart';

class WidgetService {
  static const String appGroupId = 'group.com.reminder.app';
  static const String androidWidgetName = 'ReminderAppWidget';
  static const String iOSWidgetName = 'ReminderAppWidget';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      if (kDebugMode) {
        print('Widget init error: $e');
      }
    }
  }

  static Future<void> updateWidgetData(List<ReminderItem> allItems) async {
    try {
      final todayPending =
          allItems.where((item) => item.isToday && !item.isCompleted).toList();

      // 保存今日待办总数
      await HomeWidget.saveWidgetData<int>(
        'today_pending_count',
        todayPending.length,
      );

      // 保存前三条待办标题与时间摘要
      final topTasks = todayPending.take(3).map((item) {
        final timeStr =
            '${item.reminderTime.hour.toString().padLeft(2, '0')}:${item.reminderTime.minute.toString().padLeft(2, '0')}';
        return {
          'id': item.id,
          'title': item.title,
          'time': timeStr,
          'isStrongAlert': item.isStrongAlert,
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'today_tasks_json',
        json.encode(topTasks),
      );

      // 通知系统小组件刷新视图
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Update widget data error: $e');
      }
    }
  }
}
