import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../store/habit_store.dart';
import '../widgets/pixel_grids.dart';
import 'edit_habit_screen.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: habitStore,
      builder: (context, _) {
        final habits = habitStore.habits;
        return Scaffold(
          appBar: AppBar(title: const Text('Pixel Habits')),
          body: habits.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: habits.length,
                  itemBuilder: (_, i) => _HabitCard(habit: habits[i]),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditHabitScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New habit'),
          ),
        );
      },
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = DateTime.now().year;
    final done = habit.doneCount(year);
    final daysInYear =
        DateTime(year, 12, 31).difference(DateTime(year, 1, 1)).inDays + 1;
    final pct = (done / daysInYear * 100).round();
    final streak = habit.currentStreak();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habitId: habit.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: habit.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              WeekStripGrid(habit: habit, year: year),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.local_fire_department, size: 16, color: habit.color),
                  const SizedBox(width: 4),
                  Text('$streak day streak', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle_outline,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('$done / $daysInYear days',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_on, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No habits yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first habit and start painting your year, '
              'one pixel at a time.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
