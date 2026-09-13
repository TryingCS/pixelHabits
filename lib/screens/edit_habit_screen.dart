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
  late Map<String, int> _entries;

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = habitStore.habits.firstWhere((x) => x.id == widget.habitId);
      _name = TextEditingController(text: h.name);
      _levels = List.from(h.levels);
      _entries = Map.from(h.entries);
    } else {
      _name = TextEditingController();
      _levels = [LevelConfig(label: 'Done', colorValue: 0xFF43A047)];
      _entries = <String, int>{};
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
        levels: _levels,
        entries: _entries,
      );
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
      _levels.add(LevelConfig(
        label: 'Level ${_levels.length + 1}',
        colorValue: kHabitPalette[_levels.length % kHabitPalette.length],
      ));
    });
  }

  Future<void> _editLevel(int index) async {
    final result = await showDialog<LevelConfig>(
      context: context,
      builder: (ctx) => _LevelEditorDialog(level: _levels[index]),
    );
    if (result != null) setState(() => _levels[index] = result);
  }

  Future<void> _deleteLevel(int index) async {
    if (_levels.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A habit needs at least one level.')),
      );
      return;
    }

    final level = _levels[index];
    final affected = _entries.values.where((v) => v == index + 1).length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${level.label}"?'),
        content: Text(
          affected == 0
              ? 'Levels above it will shift down.'
              : '$affected logged ${affected == 1 ? "day" : "days"} will be '
                  'cleared, and levels above it will shift down.',
        ),
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
    if (ok != true) return;

    // Build a throwaway Habit so we can reuse its remap helper.
    final temp = Habit(
      id: '_',
      name: '_',
      levels: _levels,
      entries: _entries,
    );
    setState(() {
      _entries = temp.remappedForDelete(index);
      _levels.removeAt(index);
    });
  }

  void _reorderLevel(int oldIndex, int newIndex) {
    // ReorderableListView convention: newIndex is "before removal".
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final temp = Habit(
      id: '_',
      name: '_',
      levels: _levels,
      entries: _entries,
    );
    setState(() {
      _entries = temp.remappedForReorder(oldIndex, newIndex);
      final moved = _levels.removeAt(oldIndex);
      _levels.insert(newIndex, moved);
    });
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all pixels?'),
        content: Text(
          'Every logged day for "${_name.text}" will be wiped. '
          'The habit and its levels will stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _entries = <String, int>{});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared. Tap Save to commit.')),
      );
    }
  }

  Future<void> _deleteHabit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
            'All history for "${_name.text}" will be lost. This cannot be undone.'),
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
    if (ok != true) return;
    habitStore.deleteHabit(widget.habitId!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(20),
        onReorder: _reorderLevel,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Health Log',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Levels', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _addLevel,
                  icon: const Icon(Icons.add),
                  label: const Text('Add level'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Drag a level to reorder it. Tap a level in the tracker to '
                'cycle, or long-press to pick directly.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        footer: _isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text('Danger zone',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.error)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Clear all pixel history'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _deleteHabit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete this habit'),
                  ),
                  const SizedBox(height: 24),
                ],
              )
            : const SizedBox(height: 24),
        children: _levels.asMap().entries.map((entry) {
          final i = entry.key;
          final level = entry.value;
          return Card(
            key: ValueKey(identityHashCode(level)),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(level.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(level.label),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editLevel(i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteLevel(i),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_handle, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit level'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Happy, Cold, Fever',
              ),
            ),
            const SizedBox(height: 16),
            ColorPalettePicker(
              selected: _color,
              onSelected: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            LevelConfig(label: _label.text.trim(), colorValue: _color),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
