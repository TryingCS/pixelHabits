import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'store/habit_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await habitStore.load();
  runApp(const PixelHabitsApp());
}

class PixelHabitsApp extends StatelessWidget {
  const PixelHabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Habits',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5E35B1),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5E35B1),
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
