import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'alarm_reminder_channel';
  static const String channelName = '即使提要 - 强提醒闹钟';
  static const String channelDescription = '用于重要待办事项的准时响铃、震动与锁屏强提醒';

  static const String iosCategoryId = 'alarm_reminder_category';
  static const String actionSnooze = 'ACTION_SNOOZE';
  static const String actionComplete = 'ACTION_COMPLETE';

  Function(String reminderId, String actionId)? onNotificationAction;

  Future<void> init() async {
    // 1. 初始化时区信息
    tz.initializeTimeZones();
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      if (kDebugMode) {
        print('Timezone fallback: $e');
      }
      tz.setLocalLocation(tz.local);
    }

    // 2. 初始化平台配置与 iOS 通知操作按钮
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final List<DarwinNotificationCategory> darwinNotificationCategories = [
      DarwinNotificationCategory(
        iosCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            actionComplete,
            '✓ 标为完成',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
          DarwinNotificationAction.plain(
            actionSnooze,
            '💤 稍后提醒',
          ),
        ],
      ),
    ];

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      notificationCategories: darwinNotificationCategories,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && response.actionId != null) {
          onNotificationAction?.call(payload, response.actionId!);
        }
      },
    );

    // 3. 创建高优先级 Android 通知渠道
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  int _generateNotificationId(String id) {
    return id.hashCode & 0x7FFFFFFF;
  }

  Future<void> scheduleReminder(ReminderItem item) async {
    if (item.isCompleted || item.reminderTime.isBefore(DateTime.now())) {
      return;
    }

    final int notificationId = _generateNotificationId(item.id);
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(item.reminderTime, tz.local);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: '待办事项提醒：${item.title}',
      fullScreenIntent: item.isStrongAlert,
      ongoing: item.isStrongAlert,
      autoCancel: !item.isStrongAlert,
      styleInformation: BigTextStyleInformation(
        item.notes.isNotEmpty ? item.notes : '点击进入应用查看详情',
        contentTitle: '⏰ ${item.title}',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          actionComplete,
          '✓ 标为完成',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          '💤 稍后提醒 (${item.snoozeMinutes}分钟)',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: iosCategoryId,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: '⏰ ${item.title}',
      body: item.notes.isNotEmpty ? item.notes : '设定时间已到，请尽快处理',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: item.id,
    );
  }

  Future<void> cancelReminder(String id) async {
    final int notificationId = _generateNotificationId(id);
    await _notificationsPlugin.cancel(id: notificationId);
  }
}
