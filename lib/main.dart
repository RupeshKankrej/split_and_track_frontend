import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SplitTrackerApp());
}

class SplitTrackerApp extends StatefulWidget {
  const SplitTrackerApp({super.key});

  @override
  State<SplitTrackerApp> createState() => _SplitTrackerAppState();
}

class _SplitTrackerAppState extends State<SplitTrackerApp> {
  final String baseUrl = "http://192.168.31.55:8080/api";

  // final String baseUrl = "http://localhost:8080/api";

  bool _isLoading = true;
  int? _savedUserId;
  String? _savedUserName;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final userName = prefs.getString('userName');

    if (userId != null && userName != null) {
      setState(() {
        _savedUserId = userId;
        _savedUserName = userName;
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // 1. The Seed Color drives the entire UI (Light & Dark)
    const seedColor = Colors.indigo;

    return MaterialApp(
      title: 'SplitWise Clone',
      debugShowCheckedModeBanner: false,

      // LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        // Modern Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 2),
          ),
        ),
      ),

      // DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // Surface Variant is standard for inputs in Dark Mode
          fillColor: const Color(0xFF303030),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      themeMode: ThemeMode.system, // Respects phone settings

      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _savedUserId != null
          ? HomeScreen(
              baseUrl: baseUrl,
              userId: _savedUserId!,
              userName: _savedUserName!,
            )
          : LoginScreen(baseUrl: baseUrl),
    );
  }
}
