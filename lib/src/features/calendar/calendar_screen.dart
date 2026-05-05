import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/shared/layout/zen_studio_page_shell.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:kiyoshi/src/shared/widgets/zen_editorial_header.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return ZenStudioPageShell(
      child: eventsAsync.when(
        data: (blocks) => _buildCalendarContent(blocks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCalendarContent(List<ZenBlock> blocks) {
    final eventMap = <DateTime, List<ZenBlock>>{};
    for (var b in blocks) {
      final dateStr = b.metadata['dueDate'];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        final normalized = _normalizeDate(date);
        eventMap.putIfAbsent(normalized, () => []).add(b);
      }
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.frameMargin,
              right: AppTheme.frameMargin,
              bottom: AppTheme.frameMargin,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildTableCalendar(eventMap),
                ),
                const SizedBox(width: AppTheme.spaceXLarge),
                Expanded(
                  flex: 4,
                  child: _buildDayAgenda(eventMap[_normalizeDate(_selectedDay ?? DateTime.now())] ?? []),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return ZenEditorialHeader(
      label: 'SCHEDULE',
      title: DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
      actions: [
        _AnimatedIconButton(
          icon: LucideIcons.chevronLeft,
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
        ),
        const SizedBox(width: 8),
        _AnimatedIconButton(
          icon: LucideIcons.chevronRight,
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
        ),
      ],
    );
  }

  Widget _buildTableCalendar(Map<DateTime, List<ZenBlock>> eventMap) {
    return ZenGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // daysOfWeekRow (40) + padding (spaceMedium*2) + some breathing room
          final availableHeight = constraints.maxHeight - 40 - AppTheme.spaceMedium * 2;
          final rowHeight = (availableHeight / 6).clamp(36.0, 80.0);
          return TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            headerVisible: false,
            daysOfWeekHeight: 40,
            rowHeight: rowHeight,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => eventMap[_normalizeDate(day)] ?? [],
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              weekendStyle: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(
                color: AppTheme.onBackground.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              weekendTextStyle: TextStyle(
                color: AppTheme.onBackground.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              todayTextStyle: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              markerSize: 6,
              markersAlignment: Alignment.bottomCenter,
              markersMaxCount: 3,
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildDayAgenda(List<ZenBlock> dayBlocks) {
    return ZenGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendarDays, size: 18, color: AppTheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, MMMM d').format(_selectedDay ?? DateTime.now()).toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: dayBlocks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: dayBlocks.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final b = dayBlocks[index];
                      return _buildAgendaItem(b, index);
                    },
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.wind,
              size: 32,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A day of open space',
            style: TextStyle(
              color: AppTheme.onBackground.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks scheduled for this day.',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildAgendaItem(ZenBlock b, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              b.metadata['checked'] == true
                  ? LucideIcons.checkCircle2
                  : LucideIcons.circle,
              color: b.metadata['checked'] == true 
                  ? AppTheme.primary.withValues(alpha: 0.5) 
                  : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.content,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: b.metadata['checked'] == true 
                        ? AppTheme.onBackground.withValues(alpha: 0.4) 
                        : AppTheme.onBackground,
                    decoration: b.metadata['checked'] == true 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.tag, size: 10, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      b.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (b.metadata['priority'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(LucideIcons.flag, size: 10, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'P${b.metadata['priority']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05);
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
