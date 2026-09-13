import 'package:flutter/material.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class Habit {
  final String id;
  String name;
  int colorValue;
  int maxLevel; // 1 = simple done/not-done; 2..5 = intensity levels
  final Map<String, int> entries; // 'yyyy-MM-dd' -> level

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    this.maxLevel = 1,
    Map<String, int>? entries,
  }) : entries = entries ?? <String, int>{};

  Color get color => Color(colorValue);

  int levelOn(DateTime d) => entries[dateKey(d)] ?? 0;

  /// 0 -> 1 -> ... -> maxLevel -> 0
  void cycleLevel(DateTime d) {
    final next = levelOn(d) >= maxLevel ? 0 : levelOn(d) + 1;
    setLevel(d, next);
  }

  void setLevel(DateTime d, int level) {
    final k = dateKey(d);
    if (level <= 0) {
      entries.remove(k);
    } else {
      entries[k] = level > maxLevel ? maxLevel : level;
    }
  }

  // ---------- stats ----------

  int doneCount(int year) {
    final prefix = '$year-';
    return entries.entries
        .where((e) => e.key.startsWith(prefix) && e.value > 0)
        .length;
  }

  int currentStreak() {
    var d = DateTime.now();
    if (levelOn(d) == 0) d = DateTime(d.year, d.month, d.day - 1);
    var n = 0;
    while (levelOn(d) > 0) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  int longestStreak(int year) {
    final days =
        DateTime(year, 12, 31).difference(DateTime(year, 1, 1)).inDays + 1;
    var best = 0, cur = 0;
    for (var i = 0; i < days; i++) {
      if (levelOn(DateTime(year, 1, 1 + i)) > 0) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
    }
    return best;
  }

  Habit copyWith({String? name, int? colorValue, int? maxLevel}) => Habit(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        maxLevel: maxLevel ?? this.maxLevel,
        entries: entries, // shared reference: history is preserved
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'maxLevel': maxLevel,
        'entries': entries,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        colorValue: (j['color'] as num).toInt(),
        maxLevel: (j['maxLevel'] as num?)?.toInt() ?? 1,
        entries: (j['entries'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            <String, int>{},
      );
}
