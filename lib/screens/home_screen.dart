import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reminder_item.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_theme.dart';
import 'add_reminder_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddSheet(BuildContext context, [ReminderItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddReminderSheet(initialItem: item),
    );
  }

  ({String text, IconData icon, Color color}) _getGreetingInfo() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return (text: '夜深了', icon: Icons.nights_stay_rounded, color: Colors.indigoAccent);
    }
    if (hour < 11) {
      return (text: '早上好', icon: Icons.wb_sunny_rounded, color: Colors.amber);
    }
    if (hour < 14) {
      return (text: '中午好', icon: Icons.light_mode_rounded, color: Colors.orange);
    }
    if (hour < 18) {
      return (text: '下午好', icon: Icons.local_cafe_rounded, color: Colors.brown);
    }
    return (text: '晚上好', icon: Icons.bedtime_rounded, color: Colors.deepPurpleAccent);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              '即使提要',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => provider.init(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    _buildGreetingHeader(context, provider),
                    _buildHeaderStats(context, provider),
                    _buildFilterSegments(context, provider),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: provider.filteredItems.isEmpty
                            ? _buildEmptyState(context, provider.filter)
                            : ListView.separated(
                                key: ValueKey(provider.filter),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: provider.filteredItems.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = provider.filteredItems[index];
                                  return RepaintBoundary(
                                    child: _ReminderCard(
                                      item: item,
                                      onToggle: () => provider.toggleComplete(item.id),
                                      onDelete: () => provider.deleteReminder(item.id),
                                      onEdit: () => _openAddSheet(context, item),
                                      onSnooze: () => provider.snoozeReminder(item.id, extraMinutes: 10),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGradientStart.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openAddSheet(context),
          elevation: 0,
          backgroundColor: Colors.transparent,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            '记提要',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, ReminderProvider provider) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('M月d日 EEEE', 'zh_CN').format(now);
    final pending = provider.todayPendingCount;
    final greeting = _getGreetingInfo();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      greeting.text,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(greeting.icon, color: greeting.color, size: 24),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr · ${pending > 0 ? "今天还有 $pending 件事要处理" : "今日事已毕，享受时光"}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context, ReminderProvider provider) {
    final todayPending = provider.todayPendingCount;
    final totalCompleted = provider.totalCompletedCount;
    final todayItems = provider.items.where((e) => e.isToday).toList();
    final todayTotal = todayItems.length;
    final todayDone = todayItems.where((e) => e.isCompleted).length;

    final double progress = todayTotal > 0 ? (todayDone / todayTotal) : (todayPending == 0 ? 1.0 : 0.0);
    final int percent = (progress * 100).toInt();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGradientStart.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned(
              right: -10,
              bottom: -15,
              child: Icon(
                Icons.bolt,
                size: 110,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      todayTotal == 0
                          ? const Icon(Icons.auto_awesome, color: Colors.white, size: 22)
                          : Text(
                              '$percent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '今日达成进度',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          todayTotal > 0 ? '已完成 $todayDone / $todayTotal 件事' : '今日暂无日程安排',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '累计完成',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '$totalCompleted',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSegments(BuildContext context, ReminderProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<ReminderFilter>(
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          segments: [
            ButtonSegment(
              value: ReminderFilter.today,
              label: Text('今日 · ${provider.todayPendingCount}'),
            ),
            ButtonSegment(
              value: ReminderFilter.all,
              label: Text('全部 · ${provider.items.length}'),
            ),
            ButtonSegment(
              value: ReminderFilter.completed,
              label: Text('已完成 · ${provider.totalCompletedCount}'),
            ),
          ],
          selected: {provider.filter},
          onSelectionChanged: (set) => provider.setFilter(set.first),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ReminderFilter filter) {
    final theme = Theme.of(context);
    String title = '今日很轻松';
    String subtitle = '目前没有待办提要，享受轻松时光！';
    IconData icon = Icons.wb_sunny_outlined;

    if (filter == ReminderFilter.completed) {
      title = '暂无已完成的事要';
      subtitle = '完成的事情会保存在这里，见证你的足迹。';
      icon = Icons.emoji_events_outlined;
    } else if (filter == ReminderFilter.all) {
      title = '还没有任何提要';
      subtitle = '随手记录，清空大脑负荷。点击下方按钮开始！';
      icon = Icons.edit_calendar_outlined;
    }

    return Center(
      key: ValueKey('empty_$filter'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: AppTheme.primaryGradientStart.withValues(alpha: 0.12),
              child: Icon(icon, size: 46, color: AppTheme.primaryGradientStart),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (filter != ReminderFilter.completed) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () => _openAddSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加一个提醒'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onSnooze;

  const _ReminderCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onSnooze,
  });

  String _formatFriendlyTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (item.isCompleted) {
      return DateFormat('MM-dd HH:mm').format(time);
    }

    if (difference.isNegative) {
      final passedMinutes = difference.inMinutes.abs();
      if (passedMinutes < 60) {
        return '已逾期 $passedMinutes 分钟';
      }
      final passedHours = difference.inHours.abs();
      if (passedHours < 24) {
        return '已逾期 $passedHours 小时';
      }
      return '已逾期 ${difference.inDays.abs()} 天';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟后';
    }

    if (item.isToday) {
      return '今天 ${DateFormat('HH:mm').format(time)}';
    }

    final tomorrow = now.add(const Duration(days: 1));
    if (time.year == tomorrow.year && time.month == tomorrow.month && time.day == tomorrow.day) {
      return '明天 ${DateFormat('HH:mm').format(time)}';
    }

    return DateFormat('MM-dd HH:mm (E)', 'zh_CN').format(time);
  }

  Color _getStatusColor() {
    if (item.isCompleted) return Colors.grey;
    if (item.isOverdue) return AppTheme.overdueRed;
    if (item.isStrongAlert) return AppTheme.alertOrange;
    return AppTheme.primaryGradientStart;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor();

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.overdueRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF242833) : const Color(0xFFE5E9F2),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: statusColor, width: 4.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    shape: const CircleBorder(),
                    activeColor: AppTheme.successGreen,
                    onChanged: (_) => onToggle(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted
                                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (item.notes.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: item.isOverdue && !item.isCompleted
                                  ? AppTheme.overdueRed
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatFriendlyTime(item.reminderTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: item.isOverdue && !item.isCompleted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: item.isOverdue && !item.isCompleted
                                    ? AppTheme.overdueRed
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (item.isStrongAlert && !item.isCompleted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.alertOrange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.alarm, size: 11, color: AppTheme.alertOrange),
                                    SizedBox(width: 3),
                                    Text(
                                      '强提醒',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.alertOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!item.isCompleted)
                    IconButton(
                      icon: const Icon(Icons.snooze, size: 20),
                      tooltip: '延后10分钟',
                      onPressed: onSnooze,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
