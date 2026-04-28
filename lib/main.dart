import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const PingNetCVEApp());
}

class PingNetCVEApp extends StatelessWidget {
  const PingNetCVEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping & Net + CVE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF006B7A);       // teal gelap
  static const Color accent = Color(0xFFFF6B35);        // oranye CVE
  static const Color surface = Color(0xFFF5F5F5);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: Colors.white,
      background: surface,
    ),
    fontFamily: 'SpaceMono',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: const Color(0xFF4DB6C8),
      secondary: accent,
      surface: darkCard,
      background: darkBg,
    ),
    fontFamily: 'SpaceMono',
    scaffoldBackgroundColor: darkBg,
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: const Color(0xFF4DB6C8),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4DB6C8),
      ),
    ),
  );
}
