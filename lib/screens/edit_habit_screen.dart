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
      _levels = List.from(h.levels); // local copy while editing
    } else {
      _name = TextEditingController();
      _levels = [
        LevelConfig(label: 'Done', colorValue: 0xFF43A047),
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
    if (result != null) {
      setState(() {
        _levels[index] = result;
      });
    }
  }

  /// Removes a level, and — if we're editing an existing habit — also
  /// remaps that habit's entries so its history stays consistent.
  Future<void> _deleteLevel(int index) async {
    if (_levels.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A habit needs at least one level.')),
      );
      return;
    }

    final level = _levels[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${level.label}"?'),
        content: const Text(
          'Any days you logged at this level will be cleared. '
          'Levels above it will shift down. This cannot be undone.',
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

    if (_isEditing) {
      // Persist immediately so entries get remapped correctly.
      habitStore.removeHabitLevel(widget.habitId!, index);
    }
    setState(() {
      _levels.removeAt(index);
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

    habitStore.clearHabitData(widget.habitId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared.')),
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
              hintText: 'e.g. Health Log',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),

          // ── Levels section ────────────────────────────────────────────
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
          const SizedBox(height: 4),
          Text(
            'Each level is a colour + label. Tap a level in the tracker '
            'to cycle through them.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          ..._levels.asMap().entries.map((entry) {
            final i = entry.key;
            final level = entry.value;
            return Card(
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
                  ],
                ),
              ),
            );
          }),

          // ── Danger zone ───────────────────────────────────────────────
          if (_isEditing) ...[
            const SizedBox(height: 40),
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