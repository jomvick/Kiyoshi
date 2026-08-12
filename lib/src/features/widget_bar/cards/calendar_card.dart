import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Third swipeable card: compact mini-calendar of the current month.
///
/// Days with at least one event carry a small dot; tapping a day lists its
/// events below. Events come from blocks carrying a `dueDate` metadata.
class CalendarCard extends ConsumerStatefulWidget {
  const CalendarCard({super.key});

  @override
  ConsumerState<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends ConsumerState<CalendarCard> {
  DateTime _selected = DateTime.now();
  DateTime _focused = DateTime.now();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocks = ref.watch(projectBlocksProvider('global')).value ?? const <ZenBlock>[];

    final events = <ZenBlock>[
      for (final b in blocks)
        if (b.metadata['dueDate'] is String &&
            (b.metadata['dueDate'] as String).isNotEmpty)
          b,
    ];

    final eventsByDay = <DateTime, List<ZenBlock>>{};
    for (final b in events) {
      try {
        final day = _normalize(DateTime.parse(b.metadata['dueDate'] as String));
        eventsByDay.putIfAbsent(day, () => []).add(b);
      } catch (_) {}
    }

    final selectedEvents = eventsByDay[_normalize(_selected)] ?? const <ZenBlock>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CALENDAR · ${DateFormat('MMMM yyyy').format(_focused).toUpperCase()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
              ),
              Row(
                children: [
                  _IconButton(
                    icon: LucideIcons.chevronLeft,
                    onTap: () => setState(() =>
                        _focused = DateTime(_focused.year, _focused.month - 1)),
                  ),
                  const SizedBox(width: 4),
                  _IconButton(
                    icon: LucideIcons.chevronRight,
                    onTap: () => setState(() =>
                        _focused = DateTime(_focused.year, _focused.month + 1)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGrid(scheme, eventsByDay),
          const SizedBox(height: 12),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendarDays,
                          size: 38,
                          color: scheme.primary.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nothing scheduled for this day',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: selectedEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final b = selectedEvents[i];
                      final raw = b.metadata['dueDate'] as String;
                      final time = DateTime.tryParse(raw);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                b.type == 'todo'
                                    ? LucideIcons.circle
                                    : LucideIcons.calendarClock,
                                size: 13,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (time != null)
                              Text(
                                DateFormat('HH:mm').format(time),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    ColorScheme scheme,
    Map<DateTime, List<ZenBlock>> eventsByDay,
  ) {
    final first = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final leading = first.weekday - 1;

    final cells = <Widget>[
      for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(
          child: Text(
            w,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _buildDayCell(
          scheme,
          DateTime(_focused.year, _focused.month, d),
          eventsByDay.containsKey(DateTime(_focused.year, _focused.month, d)),
          isToday: _normalize(DateTime.now()) ==
              _normalize(DateTime(_focused.year, _focused.month, d)),
          isSelected:
              _normalize(_selected) == _normalize(DateTime(_focused.year, _focused.month, d)),
          onTap: () => setState(() {
            _selected = DateTime(_focused.year, _focused.month, d);
          }),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: cells,
      ),
    );
  }

  Widget _buildDayCell(
    ColorScheme scheme,
    DateTime day,
    bool hasEvents, {
    required bool isToday,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary
                : isToday
                    ? scheme.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onSurface.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight:
                        isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (hasEvents)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.onPrimary.withValues(alpha: 0.85)
                          : scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 13, color: scheme.primary),
      ),
    );
  }
}