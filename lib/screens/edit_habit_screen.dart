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
  late List<LevelConfig> _levels;

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = habitStore.habits.firstWhere((x) => x.id == widget.habitId);
      _name = TextEditingController(text: h.name);
      _levels = List.from(h.levels); // Copy the list
    } else {
      _name = TextEditingController();
      _levels = [
        LevelConfig(label: 'Done', colorValue: 0xFF43A047), // Default
      ];
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
      habitStore.updateHabit(widget.habitId!, name: name, levels: _levels);
    } else {
      habitStore.addHabit(Habit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        levels: _levels,
      ));
    }
    Navigator.of(context).pop();
  }

  void _addLevel() {
    setState(() {
      _levels.add(LevelConfig(label: 'New Level', colorValue: kHabitPalette[_levels.length % kHabitPalette.length]));
    });
  }

  void _editLevel(int index) async {
    final result = await showDialog<LevelConfig>(
      context: context,
      builder: (ctx) => _LevelEditorDialog(level: _levels[index]),
    );
    if (result != null) {
      setState(() {
        _levels[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Habit name', hintText: 'e.g. Health Log', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Levels', style: theme.textTheme.titleSmall),
              TextButton.icon(
                onPressed: _addLevel,
                icon: const Icon(Icons.add),
                label: const Text('Add Level'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._levels.asMap().entries.map((entry) {
            final i = entry.key;
            final level = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(width: 24, height: 24, decoration: BoxDecoration(color: Color(level.colorValue), shape: BoxShape.circle)),
                title: Text(level.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editLevel(i)),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        if (_levels.length > 1) {
                          setState(() => _levels.removeAt(i));
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_isEditing) ...[
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () async {
                 // ... (Delete logic from previous version)
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

class _LevelEditorDialog extends StatefulWidget {
  final LevelConfig level;
  const _LevelEditorDialog({required this.level});

  @override
  State<_LevelEditorDialog> createState() => _LevelEditorDialogState();
}

class _LevelEditorDialogState extends State<_LevelEditorDialog> {
  late TextEditingController _label;
  late int _color;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.level.label);
    _color = widget.level.colorValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Level'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            decoration: const InputDecoration(labelText: 'Label (e.g., Happy, Cold)'),
          ),
          const SizedBox(height: 16),
          ColorPalettePicker(selected: _color, onSelected: (c) => setState(() => _color = c)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, LevelConfig(label: _label.text.trim(), colorValue: _color));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}