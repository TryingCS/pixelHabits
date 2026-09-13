import 'package:flutter/material.dart';
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

        final daysInYear =
            DateTime(_year, 12, 31).difference(DateTime(_year, 1, 1)).inDays + 1;
        final done = habit.doneCount(_year);
        final pct = (done / daysInYear * 100).round();

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _year--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_year', style: theme.textTheme.titleLarge),
                  IconButton(
                    onPressed: () => setState(() => _year++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: MonthPixelGrid(
                    habit: habit,
                    year: _year,
                    onTapDay: (d) => habitStore.toggleDay(habit, d),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(label: 'Streak', value: '${habit.currentStreak()}'),
                  _Stat(label: 'Best', value: '${habit.longestStreak(_year)}'),
                  _Stat(label: 'Done', value: '$done'),
                  _Stat(label: 'Rate', value: '$pct%'),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Less', style: theme.textTheme.labelSmall),
                    const SizedBox(width: 6),
                    for (int l = 0; l <= habit.maxLevel; l++) ...[
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: pixelColor(habit, l, theme),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text('More', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap any square to cycle its level. Add as many habits as '
                'you like — nothing is capped.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
