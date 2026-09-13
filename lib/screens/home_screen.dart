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
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two habits side-by-side
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85, // Adjust this to make cards taller/shorter
                  ),
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
    
    // Use the first level's color as the accent color for the card
    final accentColor = habit.levels.isNotEmpty 
        ? Color(habit.levels.first.colorValue) 
        : theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero, // Grid handles the spacing
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habitId: habit.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Color dot + Title)
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // The mini heatmap
              // WeekStripGrid automatically scales to fit the available width
              WeekStripGrid(habit: habit, year: year),
              
              const Spacer(),
              
              // Footer (Streak + Percentage)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: accentColor),
                      const SizedBox(width: 2),
                      Text('$streak', style: theme.textTheme.labelSmall),
                    ],
                  ),
                  Text(
                    '$pct%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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