import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_item.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_theme.dart';

class AddReminderSheet extends StatefulWidget {
  final ReminderItem? initialItem;

  const AddReminderSheet({super.key, this.initialItem});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  late DateTime _selectedDateTime;
  late bool _isStrongAlert;
  late int _snoozeMinutes;
  int? _activePresetIndex;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _selectedDateTime = item?.reminderTime ??
        DateTime.now().add(const Duration(hours: 1));
    _isStrongAlert = item?.isStrongAlert ?? true;
    _snoozeMinutes = item?.snoozeMinutes ?? 10;

    _hourController = TextEditingController(
      text: _selectedDateTime.hour.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: _selectedDateTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _syncControllersFromDateTime() {
    _hourController.text = _selectedDateTime.hour.toString().padLeft(2, '0');
    _minuteController.text = _selectedDateTime.minute.toString().padLeft(2, '0');
  }

  void _applyQuickPreset(int index, Duration offset, {int? setHour, int? setMinute}) {
    final base = DateTime.now();
    DateTime target = base.add(offset);
    if (setHour != null) {
      target = DateTime(
        target.year,
        target.month,
        target.day,
        setHour,
        setMinute ?? 0,
      );
    }
    setState(() {
      _selectedDateTime = target;
      _activePresetIndex = index;
      _syncControllersFromDateTime();
    });
  }

  void _onManualTimeInputChanged() {
    final hourText = _hourController.text.trim();
    final minuteText = _minuteController.text.trim();

    if (hourText.isEmpty && minuteText.isEmpty) return;

    int hour = int.tryParse(hourText) ?? _selectedDateTime.hour;
    int minute = int.tryParse(minuteText) ?? _selectedDateTime.minute;

    hour = hour.clamp(0, 23);
    minute = minute.clamp(0, 59);

    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        hour,
        minute,
      );
      _activePresetIndex = null;
    });
  }

  void _adjustMinutes(int offsetMinutes) {
    setState(() {
      _selectedDateTime = _selectedDateTime.add(Duration(minutes: offsetMinutes));
      _syncControllersFromDateTime();
      _activePresetIndex = null;
    });
  }

  Future<void> _pickCustomDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
        _activePresetIndex = null;
      });
    }
  }

  Future<void> _pickCustomTimeWithDial() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _syncControllersFromDateTime();
        _activePresetIndex = null;
      });
    }
  }

  void _save() {
    // 提交前格式化补齐输入框的 0
    _syncControllersFromDateTime();

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入提要标题')),
      );
      return;
    }

    final provider = context.read<ReminderProvider>();
    if (widget.initialItem != null) {
      final updated = widget.initialItem!.copyWith(
        title: title,
        notes: _notesController.text.trim(),
        reminderTime: _selectedDateTime,
        isStrongAlert: _isStrongAlert,
        snoozeMinutes: _snoozeMinutes,
      );
      provider.updateReminder(updated);
    } else {
      final newItem = ReminderItem(
        id: const Uuid().v4(),
        title: title,
        notes: _notesController.text.trim(),
        reminderTime: _selectedDateTime,
        isStrongAlert: _isStrongAlert,
        snoozeMinutes: _snoozeMinutes,
      );
      provider.addReminder(newItem);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('yyyy年M月d日 (E)', 'zh_CN');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialItem != null ? '编辑事要' : '新建极速提要',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: false,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '想提醒什么事？(例如：下班买水果、交水费)',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F232C) : const Color(0xFFF1F3F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primaryGradientStart),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '添加补充备注（可选）',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F232C) : const Color(0xFFF1F3F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.notes, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '快捷时间预设',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(
                    index: 0,
                    icon: Icons.hourglass_top,
                    iconColor: Colors.blueAccent,
                    label: '+1小时',
                    onTap: () => _applyQuickPreset(0, const Duration(hours: 1)),
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    index: 1,
                    icon: Icons.nightlight_round,
                    iconColor: Colors.deepPurpleAccent,
                    label: '今晚 20:00',
                    onTap: () => _applyQuickPreset(1, Duration.zero, setHour: 20, setMinute: 0),
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    index: 2,
                    icon: Icons.wb_sunny,
                    iconColor: Colors.orangeAccent,
                    label: '明天 09:00',
                    onTap: () => _applyQuickPreset(2, const Duration(days: 1), setHour: 9, setMinute: 0),
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    index: 3,
                    icon: Icons.weekend,
                    iconColor: Colors.green,
                    label: '周六 10:00',
                    onTap: () {
                      final now = DateTime.now();
                      final days = (DateTime.saturday - now.weekday + 7) % 7;
                      _applyQuickPreset(
                        3,
                        Duration(days: days == 0 ? 7 : days),
                        setHour: 10,
                        setMinute: 0,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 双模式并存：数字直输 + 表盘日历并存时间卡片
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryGradientStart.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.primaryGradientStart.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期行：显示当前日期 + 快捷选日期按钮
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18, color: AppTheme.primaryGradientStart),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(_selectedDateTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _pickCustomDate,
                        icon: const Icon(Icons.edit_calendar, size: 14),
                        label: const Text('选日期', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),

                  // 时间直输与表盘混合行
                  Row(
                    children: [
                      // 数字输入框：小时
                      _buildNumberTimeField(
                        controller: _hourController,
                        label: '时 (0-23)',
                        max: 23,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGradientStart,
                          ),
                        ),
                      ),
                      // 数字输入框：分钟 (任意 0-59 精确分)
                      _buildNumberTimeField(
                        controller: _minuteController,
                        label: '分 (0-59)',
                        max: 59,
                      ),
                      const SizedBox(width: 10),

                      // 微调步进按钮 (+1m, -1m, +5m)
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildAdjustStepButton(label: '-1分', onTap: () => _adjustMinutes(-1)),
                                const SizedBox(width: 4),
                                _buildAdjustStepButton(label: '+1分', onTap: () => _adjustMinutes(1)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildAdjustStepButton(label: '-5分', onTap: () => _adjustMinutes(-5)),
                                const SizedBox(width: 4),
                                _buildAdjustStepButton(label: '+5分', onTap: () => _adjustMinutes(5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 保留表盘弹窗选择入口
                      IconButton.filledTonal(
                        onPressed: _pickCustomTimeWithDial,
                        tooltip: '打开时钟表盘选择',
                        icon: const Icon(Icons.access_time_filled, color: AppTheme.primaryGradientStart),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 强提醒卡片
            Container(
              decoration: BoxDecoration(
                color: _isStrongAlert
                    ? AppTheme.alertOrange.withValues(alpha: 0.08)
                    : (isDark ? const Color(0xFF1F232C) : const Color(0xFFF1F3F7)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isStrongAlert
                      ? AppTheme.alertOrange.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.notification_important, color: AppTheme.alertOrange, size: 20),
                        SizedBox(width: 8),
                        Text('闹钟级强提醒', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    subtitle: Text(
                      '锁屏全屏、响铃震动，防止一划就忘',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    value: _isStrongAlert,
                    activeThumbColor: AppTheme.alertOrange,
                    onChanged: (val) => setState(() => _isStrongAlert = val),
                  ),
                  if (_isStrongAlert) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        Text(
                          '稍后提醒 (贪睡)：',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        for (final mins in [5, 10, 15, 30])
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              label: Text('${mins}m'),
                              selected: _snoozeMinutes == mins,
                              onSelected: (_) => setState(() => _snoozeMinutes = mins),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGradientStart.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  widget.initialItem != null ? '保存修改' : '立即添加提醒',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberTimeField({
    required TextEditingController controller,
    required String label,
    required int max,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 68,
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2024) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppTheme.primaryGradientStart.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGradientStart,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => _onManualTimeInputChanged(),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustStepButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryGradientStart.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGradientStart,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _activePresetIndex == index;
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : iconColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected
          ? AppTheme.primaryGradientStart
          : theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryGradientStart
            : theme.colorScheme.outlineVariant,
      ),
      onPressed: onTap,
    );
  }
}
