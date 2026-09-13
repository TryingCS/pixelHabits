import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../store/habit_store.dart';
import '../widgets/pixel_grids.dart';
import 'edit_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  bool _isYearView = true;

  void _pickLevel(BuildContext context, Habit habit, DateTime date) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            ...habit.levels.asMap().entries.map((entry) {
              final i = entry.key;
              final level = entry.value;
              final selected = habit.levelOn(date) == i + 1;
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(level.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(level.label),
                trailing: selected
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  habitStore.setDay(habit, date, i + 1);
                  Navigator.pop(ctx);
                },
              );
            }),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
              title: const Text('Clear'),
              onTap: () {
                habitStore.setDay(habit, date, 0);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: habitStore,
      builder: (context, _) {
        final matches =
            habitStore.habits.where((h) => h.id == widget.habitId).toList();
        if (matches.isEmpty) {
          return const Scaffold(body: Center(child: Text('Habit deleted')));
        }
        final habit = matches.first;
        final theme = Theme.of(context);

        final Map<int, int> levelCounts = {};
        for (var entry in habit.entries.entries) {
          if (entry.key.startsWith('$_year-')) {
            levelCounts[entry.value] =
                (levelCounts[entry.value] ?? 0) + 1;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditHabitScreen(habitId: habit.id),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Year')),
                    ButtonSegment(value: false, label: Text('Month')),
                  ],
                  selected: {_isYearView},
                  onSelectionChanged: (s) =>
                      setState(() => _isYearView = s.first),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      if (_isYearView) {
                        _year--;
                      } else {
                        _month--;
                        if (_month < 1) {
                          _month = 12;
                          _year--;
                        }
                      }
                    }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    _isYearView
                        ? '$_year'
                        : '${_monthNames[_month - 1]} $_year',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      if (_isYearView) {
                        _year++;
                      } else {
                        _month++;
                        if (_month > 12) {
                          _month = 1;
                          _year++;
                        }
                      }
                    }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isYearView
                      ? MonthPixelGrid(
                          habit: habit,
                          year: _year,
                          onTapDay: (d) => habitStore.toggleDay(habit, d),
                          onLongPressDay: (d) =>
                              _pickLevel(context, habit, d),
                        )
                      : CalendarMonthView(
                          habit: habit,
                          year: _year,
                          month: _month,
                          onTapDay: (d) => habitStore.toggleDay(habit, d),
                          onLongPressDay: (d) =>
                              _pickLevel(context, habit, d),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tap to cycle · Long-press to pick',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: habit.levels.asMap().entries.map((entry) {
                  final level = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(level.colorValue),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(level.label, style: theme.textTheme.bodySmall),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Year overview', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: habit.levels.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final count = levelCounts[i] ?? 0;
                      if (count == 0) return null;
                      return PieChartSectionData(
                        color: Color(entry.value.colorValue),
                        value: count.toDouble(),
                        title: '$count',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).whereType<PieChartSectionData>().toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
