import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

/// Single global store — no state-management package needed.
final habitStore = HabitStore();

class HabitStore extends ChangeNotifier {
  static const _key = 'pixel_habits_v1';
  final List<Habit> habits = <Habit>[];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      habits
        ..clear()
        ..addAll(list.map((e) => Habit.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Failed to load habits: $e');
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(habits.map((h) => h.toJson()).toList()),
    );
  }

  void addHabit(Habit h) {
    habits.add(h);
    _persist();
    notifyListeners();
  }

  void updateHabit(String id,
      {String? name, int? colorValue, int? maxLevel}) {
    final i = habits.indexWhere((h) => h.id == id);
    if (i == -1) return;
    habits[i] = habits[i]
        .copyWith(name: name, colorValue: colorValue, maxLevel: maxLevel);
    _persist();
    notifyListeners();
  }

  void deleteHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    _persist();
    notifyListeners();
  }

  void toggleDay(Habit h, DateTime d) {
    h.cycleLevel(d);
    _persist();
    notifyListeners();
  }
}
