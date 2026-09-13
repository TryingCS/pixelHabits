import 'package:flutter/material.dart';
import '../models/habit.dart';

const _monthLetters = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

bool _dayExists(int year, int month, int day) =>
    day <= DateTime(year, month + 1, 0).day;

/// Blends the habit colour with the "empty" colour based on level.
Color pixelColor(Habit habit, int level, ThemeData theme) {
  final empty = theme.brightness == Brightness.dark
      ? const Color(0xFF2B2B30)
      : const Color(0xFFE6E6EC);
  if (level <= 0) return empty;
  final t = habit.maxLevel <= 1
      ? 1.0
      : (0.35 + 0.65 * (level / habit.maxLevel)).clamp(0.0, 1.0);
  return Color.lerp(empty, habit.color, t)!;
}

// ─────────────────────────────────────────────────────────────
//  Classic Year-in-Pixels: 12 columns (months) × 31 rows (days)
// ─────────────────────────────────────────────────────────────
class MonthPixelGrid extends StatelessWidget {
  final Habit habit;
  final int year;
  final void Function(DateTime) onTapDay;

  const MonthPixelGrid({
    super.key,
    required this.habit,
    required this.year,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 2.0;
        final cell =
            ((constraints.maxWidth - gap * 11) / 12).floorToDouble();
        if (cell < 2) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month initials
            Row(
              children: List.generate(12, (m) {
                return Padding(
                  padding: EdgeInsets.only(right: m == 11 ? 0 : gap),
                  child: SizedBox(
                    width: cell,
                    child: Text(
                      _monthLetters[m],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
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

                  if (!_dayExists(year, month, day)) {
                    return Padding(
                      padding: pad,
                      child: SizedBox(width: cell, height: cell),
                    );
                  }

                  final date = DateTime(year, month, day);
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

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
                          border: isToday
                              ? Border.all(
                                  color: theme.colorScheme.onSurface,
                                  width: 1.5,
                                )
                              : null,
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
//  Compact heatmap: 53 columns (weeks) × 7 rows (days)
// ─────────────────────────────────────────────────────────────
class WeekStripGrid extends StatelessWidget {
  final Habit habit;
  final int year;
  final double cell;
  final double gap;

  const WeekStripGrid({
    super.key,
    required this.habit,
    required this.year,
    this.cell = 5,
    this.gap = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jan1 = DateTime(year, 1, 1);
    // Back up to the Sunday on/before Jan 1.
    final start = DateTime(jan1.year, jan1.month, jan1.day - (jan1.weekday % 7));

    return LayoutBuilder(
      builder: (context, constraints) {
        final natural = 53 * cell + 52 * gap;
        final scale =
            natural > constraints.maxWidth ? constraints.maxWidth / natural : 1.0;
        final c = cell * scale;
        final g = gap * scale;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(53, (w) {
            return Padding(
              padding: EdgeInsets.only(right: w == 52 ? 0 : g),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (d) {
                  final date =
                      DateTime(start.year, start.month, start.day + w * 7 + d);
                  final pad = EdgeInsets.only(bottom: d == 6 ? 0 : g);

                  if (date.year != year) {
                    return Padding(
                      padding: pad,
                      child: SizedBox(width: c, height: c),
                    );
                  }

                  return Padding(
                    padding: pad,
                    child: Container(
                      width: c,
                      height: c,
                      decoration: BoxDecoration(
                        color: pixelColor(habit, habit.levelOn(date), theme),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}
