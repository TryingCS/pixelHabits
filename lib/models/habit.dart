import 'package:flutter/material.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class LevelConfig {
  String label;
  int colorValue;

  LevelConfig({required this.label, required this.colorValue});

  Map<String, dynamic> toJson() => {'label': label, 'color': colorValue};
  factory LevelConfig.fromJson(Map<String, dynamic> j) => LevelConfig(
        label: j['label'] as String,
        colorValue: (j['color'] as num).toInt(),
      );
}

class Habit {
  final String id;
  String name;
  final Map<String, int> entries; // 'yyyy-MM-dd' -> level index (1-based)
  List<LevelConfig> levels; 

  Habit({
    required this.id,
    required this.name,
    required this.levels,
    Map<String, int>? entries,
  }) : entries = entries ?? <String, int>{};

  int levelOn(DateTime d) => entries[dateKey(d)] ?? 0;

  void cycleLevel(DateTime d) {
    final current = levelOn(d);
    final next = current >= levels.length ? 0 : current + 1;
    setLevel(d, next);
  }

  void setLevel(DateTime d, int level) {
    final k = dateKey(d);
    if (level <= 0) {
      entries.remove(k);
    } else {
      entries[k] = level;
    }
  }

  // ---------- stats ----------
  int doneCount(int year) {
    final prefix = '$year-';
    return entries.entries.where((e) => e.key.startsWith(prefix) && e.value > 0).length;
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

  Habit copyWith({String? name, List<LevelConfig>? levels}) => Habit(
        id: id,
        name: name ?? this.name,
        levels: levels ?? this.levels,
        entries: entries,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'levels': levels.map((l) => l.toJson()).toList(),
        'entries': entries,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        levels: (j['levels'] as List)
            .map((e) => LevelConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
        entries: (j['entries'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            <String, int>{},
      );
}