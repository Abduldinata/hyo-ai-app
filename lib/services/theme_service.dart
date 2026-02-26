import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  vibrantKawaii,
  softCandy,
  galaxy,
  genZ,
  sunset,
  forest,
}

class AppTheme {
  final AppThemeMode mode;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color textColor;
  final Color backgroundColor;

  AppTheme({
    required this.mode,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.textColor,
    required this.backgroundColor,
  });

  ThemeData toMaterialTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onSurface: textColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'system',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: '-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif',
        ),
      ),
    );
  }
}

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static final ThemeService _instance = ThemeService._internal();

  late SharedPreferences _prefs;
  AppThemeMode _currentTheme = AppThemeMode.vibrantKawaii;
  final ValueNotifier<AppThemeMode> _themeNotifier = ValueNotifier<AppThemeMode>(AppThemeMode.vibrantKawaii);

  ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _currentTheme = AppThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => AppThemeMode.vibrantKawaii,
      );
    }
    _themeNotifier.value = _currentTheme;
  }

  AppThemeMode get currentTheme => _currentTheme;
  ValueNotifier<AppThemeMode> get themeNotifier => _themeNotifier;

  Future<void> setTheme(AppThemeMode theme) async {
    _currentTheme = theme;
    _themeNotifier.value = theme;
    await _prefs.setString(_themeKey, theme.toString());
  }

  static final Map<AppThemeMode, AppTheme> themes = {
    AppThemeMode.vibrantKawaii: AppTheme(
      mode: AppThemeMode.vibrantKawaii,
      name: 'Vibrant Kawaii',
      primaryColor: const Color(0xFFFF69B4),
      secondaryColor: const Color(0xFFD946EF),
      accentColor: const Color(0xFFF5007F),
      surfaceColor: const Color(0xFFFFF5F7),
      textColor: const Color(0xFF3A3A3A),
      backgroundColor: const Color(0xFFFFF5F7),
    ),
    AppThemeMode.softCandy: AppTheme(
      mode: AppThemeMode.softCandy,
      name: 'Soft Candy',
      primaryColor: const Color(0xFFFFCDD2),
      secondaryColor: const Color(0xFFE1BEE7),
      accentColor: const Color(0xFFF48FB1),
      surfaceColor: const Color(0xFFFFF9FA),
      textColor: const Color(0xFF5A5A5A),
      backgroundColor: const Color(0xFFFFF9FA),
    ),
    AppThemeMode.galaxy: AppTheme(
      mode: AppThemeMode.galaxy,
      name: 'Galaxy',
      primaryColor: const Color(0xFF5E35B1),
      secondaryColor: const Color(0xFF3949AB),
      accentColor: const Color(0xFF7E57C2),
      surfaceColor: const Color(0xFFEDE7F6),
      textColor: const Color(0xFF2C2C2C),
      backgroundColor: const Color(0xFFEDE7F6),
    ),
    AppThemeMode.genZ: AppTheme(
      mode: AppThemeMode.genZ,
      name: 'Gen-Z',
      primaryColor: const Color(0xFFFF6F61),
      secondaryColor: const Color(0xFF00BFA6),
      accentColor: const Color(0xFF00E5FF),
      surfaceColor: const Color(0xFFE6FFF7),
      textColor: const Color(0xFF1F2A24),
      backgroundColor: const Color(0xFFF0FFFA),
    ),
    AppThemeMode.sunset: AppTheme(
      mode: AppThemeMode.sunset,
      name: 'Sunset',
      primaryColor: const Color(0xFFFF6B35),
      secondaryColor: const Color(0xFFFFB300),
      accentColor: const Color(0xFFFF8C42),
      surfaceColor: const Color(0xFFFFF5E6),
      textColor: const Color(0xFF3D3D3D),
      backgroundColor: const Color(0xFFFFF5E6),
    ),
    AppThemeMode.forest: AppTheme(
      mode: AppThemeMode.forest,
      name: 'Forest',
      primaryColor: const Color(0xFF2D6A4F),
      secondaryColor: const Color(0xFF40916C),
      accentColor: const Color(0xFF52B788),
      surfaceColor: const Color(0xFFE8F5E9),
      textColor: const Color(0xFF1B3A1B),
      backgroundColor: const Color(0xFFE8F5E9),
    ),
  };

  static AppTheme getTheme(AppThemeMode mode) {
    return themes[mode] ?? themes[AppThemeMode.vibrantKawaii]!;
  }
}
