import 'package:flutter/material.dart';


class AppTheme {
  const AppTheme();

  // Grape Go colors
  static const Color grapePurple = Color(0xFFB98BEF);
  static const Color grapeLightPurple = Color(0xFFF8F5FF);
  static const Color grapeSoftPurple = Color(0xFFDCC7FA);
  static const Color glassWhite = Color(0xCCFFFFFF);

  static const Color darkText = Color(0xFF30243D);
  static const Color mutedText = Color(0xFF7E718D);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: grapeLightPurple,

  
    primaryColor: grapePurple,

    colorScheme: const ColorScheme.light(
      primary: grapePurple,
      secondary: grapeSoftPurple,
      surface: Colors.white,
    ),

    cardTheme: const CardThemeData(
      color: glassWhite,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: darkText,
      ),
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: darkText,
        fontSize: 14,
      ),
      bodyMedium: TextStyle(
        color: mutedText,
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
        color: darkText,
      ),
    ),

    iconTheme: const IconThemeData(
      color: grapePurple,
    ),


    dividerColor: Color(0xFFE8DDF5),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
        borderSide: BorderSide(
          color: grapePurple,
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(
        color: mutedText,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: grapePurple,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  static TextStyle titleStyle = const TextStyle(
    color: darkText,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static TextStyle subTitleStyle = const TextStyle(
    color: mutedText,
    fontSize: 12,
  );

  static TextStyle h1Style = const TextStyle(
    color: darkText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle h2Style = const TextStyle(
    color: darkText,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static TextStyle h3Style = const TextStyle(
    color: darkText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle h4Style = const TextStyle(
    color: darkText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle h5Style = const TextStyle(
    color: darkText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle h6Style = const TextStyle(
    color: darkText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Soft glass-style shadow
  static List<BoxShadow> shadow = const <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  );

  static EdgeInsets hPadding = const EdgeInsets.symmetric(
    horizontal: 10,
  );

  static double fullWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double fullHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Reusable glass decoration for Grape Go cards.
  static BoxDecoration glassDecoration({
    double radius = 22,
  }) {
    return BoxDecoration(
      color: glassWhite,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.85),
        width: 1.2,
      ),
      boxShadow: shadow,
    );
  }
}