import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/config/route.dart';
import 'package:flutter_ecommerce_app/src/pages/mainPage.dart';
import 'package:flutter_ecommerce_app/src/pages/product_detail.dart';
import 'package:flutter_ecommerce_app/src/widgets/customRoute.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/themes/theme.dart';

void main() {
  runApp(const GrapeGoApp());
}

class GrapeGoApp extends StatelessWidget {
  const GrapeGoApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grape Go',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),

        primaryColor: const Color(0xFFB98BEF),

        colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
          primary: const Color(0xFFB98BEF),
          secondary: const Color(0xFFD8BFFF),
        ),

        textTheme: GoogleFonts.mulishTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: const Color(0xFF30243D),
          displayColor: const Color(0xFF30243D),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Color(0xFF30243D),
          ),
        ),
      ),

      routes: Routes.getRoute(),

      onGenerateRoute: (RouteSettings settings) {
        if (settings.name != null &&
            settings.name.contains('detail')) {
          return CustomRoute<bool>(
            builder: (BuildContext context) =>
                ProductDetailPage(),
          );
        }

        return CustomRoute<bool>(
          builder: (BuildContext context) =>
              MainPage(),
        );
      },

      initialRoute: 'MainPage',
    );
  }
}