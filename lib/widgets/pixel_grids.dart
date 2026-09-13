import 'package:flutter/material.dart';
import '../models/habit.dart';

const _monthLetters = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

bool _dayExists(int year, int month, int day) =>
    day <= DateTime(year, month + 1, 0).day;

Color pixelColor(Habit habit, int level, ThemeData theme) {
  final empty = theme.brightness == Brightness.dark
      ? const Color(0xFF2B2B30)
      : const Color(0xFFE6E6EC);
  if (level <= 0 || level > habit.levels.length) return empty;
  return Color(habit.levels[level - 1].colorValue);
}

// ─────────────────────────────────────────────────────────────
//  Classic Year-in-Pixels: 12 columns (months) × 31 rows (days)
// ─────────────────────────────────────────────────────────────
class MonthPixelGrid extends StatelessWidget {
  final Habit habit;
  final int year;
  final void Function(DateTime) onTapDay;

  const MonthPixelGrid({super.key, required this.habit, required this.year, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 2.0;
        final cell = ((constraints.maxWidth - gap * 11) / 12).floorToDouble();
        if (cell < 2) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(12, (m) {
                return Padding(
                  padding: EdgeInsets.only(right: m == 11 ? 0 : gap),
                  child: SizedBox(width: cell, child: Text(_monthLetters[m], textAlign: TextAlign.center, style: theme.textTheme.labelSmall)),
                );
              }),
            ),
            const SizedBox(height: 6),
            for (int day = 1; day <= 31; day++) ...[
              if (day > 1) const SizedBox(height: gap),
              Row(
                children: List.generate(12, (m) {
                  final month = m + 1;
                  final pad = EdgeInsets.only(right: m == 11 ? 0 : gap);
                  if (!_dayExists(year, month, day)) return Padding(padding: pad, child: SizedBox(width: cell, height: cell));
                  
                  final date = DateTime(year, month, day);
                  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                  
                  return Padding(
                    padding: pad,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTapDay(date),
                      child: Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: pixelColor(habit, habit.levelOn(date), theme),
                          borderRadius: BorderRadius.circular(2.5),
                          border: isToday ? Border.all(color: theme.colorScheme.onSurface, width: 1.5) : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NEW: Month Calendar View (M T W T F S S)
// ─────────────────────────────────────────────────────────────
class CalendarMonthView extends StatelessWidget {
  final Habit habit;
  final int year;
  final int month;
  final void Function(DateTime) onTapDay;

  const CalendarMonthView({super.key, required this.habit, required this.year, required this.month, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday, 1 = Monday...
    
    // Weekday headers
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final adjustedStart = firstDay.weekday - 1; // 0 = Monday, 6 = Sunday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_monthNames[month - 1]} $year', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: weekdays.map((d) => Expanded(child: Center(child: Text(d, style: theme.textTheme.labelSmall)))).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: adjustedStart + daysInMonth,
          itemBuilder: (context, index) {
            if (index < adjustedStart) return const SizedBox.shrink();
            final day = index - adjustedStart + 1;
            final date = DateTime(year, month, day);
            final level = habit.levelOn(date);
            
            return GestureDetector(
              onTap: () => onTapDay(date),
              child: Container(
                decoration: BoxDecoration(
                  color: pixelColor(habit, level, theme),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: level > 0 ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];