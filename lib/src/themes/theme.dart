import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme();

  // ============================================================
  // pikkX BRAND COLORS
  // ============================================================

  // Main identity
  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);

  // Soft backgrounds
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color darkBackground = Color(0xFF050505);

  // Cards
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF111111);

  // Navy = accent only
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXLightNavy = Color(0xFF1A3152);

  // Text
  static const Color lightText = Color(0xFF111111);
  static const Color lightMutedText = Color(0xFF777777);

  // Compatibility name used by older pages.
  static const Color mutedText = lightMutedText;

  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkMutedText = Color(0xFF9A9A9A);

  // Compatibility names
  // These keep older GrapeGo widgets from breaking while
  // we gradually rename their references to pikkX.
  static const Color grapePurple = pikkXBlack;
  static const Color grapeLightPurple = lightBackground;
  static const Color grapeSoftPurple = Color(0xFFE5E5E5);
  static const Color glassWhite = Color(0xCCFFFFFF);

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: lightBackground,

    primaryColor: pikkXBlack,

    colorScheme: const ColorScheme.light(
      primary: pikkXBlack,
      secondary: pikkXNavy,
      surface: lightCard,
    ),

    cardTheme: const CardThemeData(
      color: lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),

    // ------------------------------------------------------------
    // APP BAR
    // ------------------------------------------------------------

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: lightText,
      ),
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),

    // ------------------------------------------------------------
    // TEXT
    // ------------------------------------------------------------

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: lightText,
        fontSize: 14,
      ),
      bodyMedium: TextStyle(
        color: lightMutedText,
        fontSize: 13,
      ),
      headlineLarge: TextStyle(
        color: lightText,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: lightText,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: TextStyle(
        color: lightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    primaryTextTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: lightText,
      ),
    ),

    // ------------------------------------------------------------
    // ICONS
    // ------------------------------------------------------------

    iconTheme: const IconThemeData(
      color: pikkXBlack,
    ),

    dividerColor: Color(0xFFE3E3E3),

    // ------------------------------------------------------------
    // INPUTS
    // ------------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: Color(0xFFE5E5E5),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: Color(0xFFE5E5E5),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: pikkXBlack,
          width: 1.5,
        ),
      ),

      hintStyle: TextStyle(
        color: lightMutedText,
      ),
    ),

    // ------------------------------------------------------------
    // BUTTONS
    // ------------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: pikkXBlack,
        foregroundColor: Colors.white,
        elevation: 3,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ------------------------------------------------------------
    // BOTTOM NAVIGATION
    // ------------------------------------------------------------

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: pikkXBlack,
      indicatorColor: Color(0xFF2A2A2A),

      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Colors.white,
            );
          }

          return const IconThemeData(
            color: Color(0xFF888888),
          );
        },
      ),

      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            );
          }

          return const TextStyle(
            color: Color(0xFF888888),
          );
        },
      ),
    ),
  );

  // ============================================================
  // DARK THEME
  // ============================================================

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: darkBackground,

    primaryColor: Colors.white,

    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: pikkXNavy,
      surface: darkCard,
    ),

    cardTheme: const CardThemeData(
      color: darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),

    // ------------------------------------------------------------
    // APP BAR
    // ------------------------------------------------------------

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),

    // ------------------------------------------------------------
    // TEXT
    // ------------------------------------------------------------

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: darkText,
        fontSize: 14,
      ),
      bodyMedium: TextStyle(
        color: darkMutedText,
        fontSize: 13,
      ),
      headlineLarge: TextStyle(
        color: darkText,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: darkText,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: TextStyle(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    primaryTextTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
      ),
    ),

    // ------------------------------------------------------------
    // ICONS
    // ------------------------------------------------------------

    iconTheme: const IconThemeData(
      color: Colors.white,
    ),

    dividerColor: Color(0xFF242424),

    // ------------------------------------------------------------
    // INPUTS
    // ------------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF111111),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: Color(0xFF252525),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: Color(0xFF252525),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: Colors.white,
          width: 1.5,
        ),
      ),

      hintStyle: TextStyle(
        color: darkMutedText,
      ),
    ),

    // ------------------------------------------------------------
    // BUTTONS
    // ------------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 3,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),

        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ------------------------------------------------------------
    // BOTTOM NAVIGATION
    // ------------------------------------------------------------

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      indicatorColor: Color(0xFF242424),

      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Colors.white,
            );
          }

          return const IconThemeData(
            color: Color(0xFF777777),
          );
        },
      ),

      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            );
          }

          return const TextStyle(
            color: Color(0xFF777777),
          );
        },
      ),
    ),
  );

  // ============================================================
  // REUSABLE TEXT STYLES
  // ============================================================

  static TextStyle titleStyle = const TextStyle(
    color: lightText,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static TextStyle subTitleStyle = const TextStyle(
    color: lightMutedText,
    fontSize: 12,
  );

  static TextStyle h1Style = const TextStyle(
    color: lightText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle h2Style = const TextStyle(
    color: lightText,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle h3Style = const TextStyle(
    color: lightText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle h4Style = const TextStyle(
    color: lightText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle h5Style = const TextStyle(
    color: lightText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle h6Style = const TextStyle(
    color: lightText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // ============================================================
  // SHADOW
  // ============================================================

  static List<BoxShadow> shadow = const <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================================
  // SPACING
  // ============================================================

  static EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  );

  static EdgeInsets hPadding = const EdgeInsets.symmetric(
    horizontal: 10,
  );

  // ============================================================
  // SCREEN SIZE
  // ============================================================

  static double fullWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double fullHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // ============================================================
  // SUBTLE GLASS
  // ============================================================

  static BoxDecoration glassDecoration({
    double radius = 22,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.82),

      borderRadius: BorderRadius.circular(radius),

      border: Border.all(
        color: Colors.white.withValues(alpha: 0.95),
        width: 1.2,
      ),

      boxShadow: shadow,
    );
  }
}
