import 'dart:convert';

class ReminderItem {
  final String id;
  final String title;
  final String notes;
  final DateTime reminderTime;
  final bool isCompleted;
  final bool isStrongAlert;
  final int snoozeMinutes;
  final DateTime createdAt;

  ReminderItem({
    required this.id,
    required this.title,
    this.notes = '',
    required this.reminderTime,
    this.isCompleted = false,
    this.isStrongAlert = true,
    this.snoozeMinutes = 10,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue =>
      !isCompleted && reminderTime.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return reminderTime.year == now.year &&
        reminderTime.month == now.month &&
        reminderTime.day == now.day;
  }

  ReminderItem copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? reminderTime,
    bool? isCompleted,
    bool? isStrongAlert,
    int? snoozeMinutes,
    DateTime? createdAt,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isStrongAlert: isStrongAlert ?? this.isStrongAlert,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'reminderTime': reminderTime.toIso8601String(),
      'isCompleted': isCompleted,
      'isStrongAlert': isStrongAlert,
      'snoozeMinutes': snoozeMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: (map['notes'] as String?) ?? '',
      reminderTime: DateTime.parse(map['reminderTime'] as String),
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      isStrongAlert: (map['isStrongAlert'] as bool?) ?? true,
      snoozeMinutes: (map['snoozeMinutes'] as int?) ?? 10,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReminderItem.fromJson(String source) =>
      ReminderItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
