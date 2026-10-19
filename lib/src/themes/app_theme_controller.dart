
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance =
      AppThemeController._();

  static const String _brightnessKey = 'pikkx_theme_mode';
  static const String _accentKey = 'pikkx_accent_theme';

  ThemeMode _themeMode = ThemeMode.light;
  String _accentTheme = 'classic';
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;

  String get accentTheme => _accentTheme;

  bool get isLoaded => _isLoaded;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static const Map<String, Color> accentColors = {
    'classic': AppTheme.pikkXBlack,
    'blue': Color(0xFF2563EB),
    'pink': Color(0xFFDB2777),
    'purple': Color(0xFF7C3AED),
    'green': Color(0xFF15803D),
    'orange': Color(0xFFEA580C),
  };

  static const Map<String, String> accentNames = {
    'classic': 'Classic Black',
    'blue': 'Ocean Blue',
    'pink': 'Rose Pink',
    'purple': 'Royal Purple',
    'green': 'Forest Green',
    'orange': 'Sunset Orange',
  };

  Color get accentColor =>
      accentColors[_accentTheme] ?? AppTheme.pikkXBlack;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final preferences = await SharedPreferences.getInstance();

      final savedMode = preferences.getString(_brightnessKey);
      final savedAccent = preferences.getString(_accentKey);

      _themeMode = savedMode == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;

      _accentTheme = accentColors.containsKey(savedAccent)
          ? savedAccent!
          : 'classic';
    } catch (error, stackTrace) {
      debugPrint('Could not load PikkX theme preferences: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(
        _brightnessKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (error) {
      debugPrint('Could not save PikkX theme mode: $error');
    }
  }

  Future<void> setDarkMode(bool enabled) {
    return setThemeMode(
      enabled ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> setAccentTheme(String theme) async {
    if (!accentColors.containsKey(theme)) return;
    if (_accentTheme == theme) return;

    _accentTheme = theme;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_accentKey, theme);
    } catch (error) {
      debugPrint('Could not save PikkX accent theme: $error');
    }
  }

  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = isDark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;

    final accent = accentColor;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: accent,
      surface: isDark
          ? AppTheme.darkCard
          : AppTheme.lightCard,
    );

    return baseTheme.copyWith(
      brightness: brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      colorScheme: scheme,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : accent,
        ),
      ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? Colors.black : Colors.white;
            }
            return null;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? Colors.white : accent;
            }
            return null;
          },
        ),
      ),
      navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
        indicatorColor: accent.withValues(alpha: 0.18),
      ),
    );
  }
}
