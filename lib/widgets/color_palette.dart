import 'package:flutter/material.dart';

const kHabitPalette = <int>[
  0xFFE53935, 0xFFD81B60, 0xFF8E24AA, 0xFF5E35B1,
  0xFF3949AB, 0xFF1E88E5, 0xFF039BE5, 0xFF00ACC1,
  0xFF00897B, 0xFF43A047, 0xFF7CB342, 0xFFC0CA33,
  0xFFFDD835, 0xFFFFB300, 0xFFFB8C00, 0xFFF4511E,
  0xFF6D4C41, 0xFF546E7A,
];

class ColorPalettePicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const ColorPalettePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kHabitPalette.map((c) {
        final isSel = c == selected;
        return GestureDetector(
          onTap: () => onSelected(c),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: isSel
                  ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                  : null,
            ),
            child: isSel
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
