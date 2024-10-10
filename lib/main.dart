import 'package:flutter/material.dart';
import 'package:note_taking/ui/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NoteApp());
}

class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  State<NoteApp> createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  ThemeMode _themeMode = ThemeMode.light;

  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    bool isDarkMode = pref.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // Toggle theme and save preference
  Future<void> _toggleTheme(bool isDarkMode) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      pref.setBool('isDarkMode', isDarkMode);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Note App',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: Home(onThemeChanged: _toggleTheme),
    );
  }
}
