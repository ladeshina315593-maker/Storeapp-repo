import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce_app/src/pages/mainPage.dart';
import 'package:flutter_ecommerce_app/src/pages/login_screen.dart';
import 'package:flutter_ecommerce_app/src/pages/product_detail.dart';
import 'package:flutter_ecommerce_app/src/pages/shopping_cart_page.dart';
import 'package:flutter_ecommerce_app/src/pages/checkout_page.dart';
import 'package:flutter_ecommerce_app/src/pages/delivery_address_page.dart';
import 'package:flutter_ecommerce_app/src/pages/orders_page.dart';
import 'package:flutter_ecommerce_app/src/pages/order_details_page.dart';
import 'package:flutter_ecommerce_app/src/pages/notifications_page.dart';
import 'package:flutter_ecommerce_app/src/pages/chat_page.dart';
import 'package:flutter_ecommerce_app/src/pages/settings_page.dart';
import 'package:flutter_ecommerce_app/src/widgets/customRoute.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'src/themes/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase ONCE before the app starts.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Sign-In.
  await GoogleSignIn.instance.initialize();

  runApp(const GrapeGoApp());
}

class GrapeGoApp extends StatelessWidget {
  const GrapeGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grape Go',
      debugShowCheckedModeBanner: false,

      // ==================================================
      // THEME
      // ==================================================

      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor:
            const Color(0xFFF8F5FF),

        primaryColor:
            const Color(0xFFB98BEF),

        colorScheme:
            AppTheme.lightTheme.colorScheme.copyWith(
          primary: const Color(0xFFB98BEF),
          secondary: const Color(0xFFD8BFFF),
        ),

        textTheme:
            GoogleFonts.mulishTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor:
              const Color(0xFF30243D),
          displayColor:
              const Color(0xFF30243D),
        ),

        appBarTheme:
            const AppBarTheme(
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          iconTheme:
              IconThemeData(
            color:
                Color(0xFF30243D),
          ),
        ),
      ),

      // ==================================================
      // NORMAL ROUTES
      // ==================================================

      routes: {
        // ------------------------------------------------
        // AUTH
        // ------------------------------------------------

        '/login': (context) =>
            LoginScreen(),

        // ------------------------------------------------
        // HOME
        // ------------------------------------------------

        '/': (context) =>
            const AuthGate(),

        '/home': (context) =>
            MainPage(),

        'MainPage': (context) =>
            MainPage(),

        // ------------------------------------------------
        // SHOPPING
        // ------------------------------------------------

        '/cart': (context) =>
            ShoppingCartPage(),

        '/checkout': (context) =>
            CheckoutPage(),

        '/delivery-address': (context) =>
            DeliveryAddressPage(),

        // ------------------------------------------------
        // ORDERS
        // ------------------------------------------------

        '/orders': (context) =>
            OrdersPage(),

        // ------------------------------------------------
        // NOTIFICATIONS
        // ------------------------------------------------

        '/notifications': (context) =>
            NotificationsPage(),

        // ------------------------------------------------
        // SETTINGS
        // ------------------------------------------------

        '/settings': (context) =>
            SettingsPage(),
      },

      // ==================================================
      // ROUTES THAT NEED ARGUMENTS
      // ==================================================

      onGenerateRoute:
          (RouteSettings settings) {

        // ------------------------------------------------
        // PRODUCT DETAILS
        // ------------------------------------------------

        if (settings.name == '/detail') {
          final product =
              settings.arguments;

          if (product == null) {
            return MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(
                body: Center(
                  child: Text(
                    'Product information is missing.',
                  ),
                ),
              ),
            );
          }

          return CustomRoute<bool>(
            builder: (BuildContext context) =>
                ProductDetailPage(),
            settings: settings,
          );
        }

        // ------------------------------------------------
        // ORDER DETAILS / TRACKING
        // ------------------------------------------------

        if (settings.name ==
            '/order-details') {

          final orderId =
              settings.arguments?.toString();

          if (orderId == null ||
              orderId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(
                body: Center(
                  child: Text(
                    'Order ID is missing.',
                  ),
                ),
              ),
            );
          }

          return CustomRoute<bool>(
            builder: (BuildContext context) =>
                OrderDetailsPage(
                  orderId: orderId,
                ),
            settings: settings,
          );
        }

        // ------------------------------------------------
        // CHAT
        // ------------------------------------------------

        if (settings.name == '/chat') {
          final arguments =
              settings.arguments;

          String? chatId;
          String? otherUserName;

          if (arguments is Map) {
            chatId =
                arguments['chatId']?.toString();

            otherUserName =
                arguments['otherUserName']
                    ?.toString();
          } else if (arguments != null) {
            chatId =
                arguments.toString();
          }

          if (chatId == null ||
              chatId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(
                body: Center(
                  child: Text(
                    'Chat ID is missing.',
                  ),
                ),
              ),
            );
          }

          return CustomRoute<bool>(
            builder: (BuildContext context) =>
                ChatPage(
                  chatId: chatId!,
                  otherUserName: otherUserName,
                ),
            settings: settings,
          );
        }

        // ==================================================
        // UNKNOWN ROUTE
        // ==================================================

        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(
            body: Center(
              child: Text(
                'Page not found.',
              ),
            ),
          ),
        );
      },

      // ==================================================
      // START APP
      // ==================================================

      initialRoute: '/',
    );
  }
}

// ==========================================================
// AUTH GATE
// ==========================================================
//
// This decides what the user sees when GrapeGo opens.
//
// No Firebase user:
//     → LoginScreen
//
// Existing Firebase user:
//     → MainPage
//
// Firebase remembers the authenticated user between
// app launches, so users don't have to log in every time.
// ==========================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(),
      builder: (context, snapshot) {

        // Firebase is still checking the session.
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is already signed in.
        if (snapshot.hasData) {
          return MainPage();
        }

        // No signed-in user.
        return LoginScreen();
      },
    );
  }
}