import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../store/habit_store.dart';
import '../widgets/color_palette.dart';

class EditHabitScreen extends StatefulWidget {
  final String? habitId;
  const EditHabitScreen({super.key, this.habitId});

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late final TextEditingController _name;
  late int _color;
  late int _maxLevel;

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = habitStore.habits.firstWhere((x) => x.id == widget.habitId);
      _name = TextEditingController(text: h.name);
      _color = h.colorValue;
      _maxLevel = h.maxLevel;
    } else {
      _name = TextEditingController();
      _color = kHabitPalette[3];
      _maxLevel = 1;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    if (_isEditing) {
      habitStore.updateHabit(
        widget.habitId!,
        name: name,
        colorValue: _color,
        maxLevel: _maxLevel,
      );
    } else {
      habitStore.addHabit(Habit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        colorValue: _color,
        maxLevel: _maxLevel,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Habit name',
              hintText: 'e.g. Read 20 pages',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 28),
          Text('Colour', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          ColorPalettePicker(
            selected: _color,
            onSelected: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: 28),
          Text('Levels per day', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            _maxLevel == 1
                ? 'Tap a day to toggle it done.'
                : 'Tap a day repeatedly to cycle through $_maxLevel levels.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Done')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
            ],
            selected: {_maxLevel},
            onSelectionChanged: (s) => setState(() => _maxLevel = s.first),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete habit?'),
                    content: Text(
                        'All history for "${_name.text}" will be lost.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  habitStore.deleteHabit(widget.habitId!);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete habit'),
            ),
          ],
        ],
      ),
    );
  }
}
