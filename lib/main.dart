import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_ecommerce_app/src/pages/mainPage.dart';
import 'package:flutter_ecommerce_app/src/pages/login_screen.dart';
import 'package:flutter_ecommerce_app/src/pages/signup_screen.dart';
import 'package:flutter_ecommerce_app/src/pages/phone_auth_screen.dart';
import 'package:flutter_ecommerce_app/src/pages/product_detail.dart';
import 'package:flutter_ecommerce_app/src/pages/shopping_cart_page.dart';
import 'package:flutter_ecommerce_app/src/pages/checkout_page.dart';
import 'package:flutter_ecommerce_app/src/pages/delivery_address_page.dart';
import 'package:flutter_ecommerce_app/src/pages/orders_page.dart';
import 'package:flutter_ecommerce_app/src/pages/order_details_page.dart';
import 'package:flutter_ecommerce_app/src/pages/notifications_page.dart';
import 'package:flutter_ecommerce_app/src/pages/chat_page.dart';
import 'package:flutter_ecommerce_app/src/pages/settings_page.dart';
import 'package:flutter_ecommerce_app/src/pages/dispatch_tracking_page.dart';

import 'package:flutter_ecommerce_app/src/widgets/customRoute.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // FIREBASE
  // ==========================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==========================================================
  // GOOGLE SIGN-IN
  // ==========================================================

  await GoogleSignIn.instance.initialize();

  runApp(const PikkXApp());
}

// ==========================================================
// PIKKX APP
// ==========================================================

class PikkXApp extends StatelessWidget {
  const PikkXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pikkX',
      debugShowCheckedModeBanner: false,

      // ========================================================
      // PIKKX THEME
      // ========================================================

      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor:
            AppTheme.lightBackground,

        primaryColor:
            AppTheme.pikkXNavy,

        colorScheme:
            AppTheme.lightTheme.colorScheme.copyWith(
          primary: AppTheme.pikkXNavy,
          secondary: AppTheme.pikkXNavy,
        ),

        textTheme:
            GoogleFonts.mulishTextTheme(
          AppTheme.lightTheme.textTheme,
        ).apply(
          bodyColor: AppTheme.pikkXBlack,
          displayColor: AppTheme.pikkXBlack,
        ),

        appBarTheme:
            const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: AppTheme.pikkXBlack,
          ),
        ),
      ),

      // ========================================================
      // NORMAL ROUTES
      // ========================================================

      routes: {
        // ------------------------------------------------------
        // AUTH
        // ------------------------------------------------------

        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/phone-login': (context) => const PhoneAuthScreen(),

        // ------------------------------------------------------
        // HOME
        // ------------------------------------------------------

        '/': (context) => const AuthGate(),

        '/home': (context) => MainPage(),

        '/MainPage': (context) => MainPage(),

        // ------------------------------------------------------
        // SHOPPING
        // ------------------------------------------------------

        '/cart': (context) => ShoppingCartPage(),

        '/checkout': (context) => CheckoutPage(),

        '/delivery-address': (context) =>
            DeliveryAddressPage(),

        // ------------------------------------------------------
        // ORDERS
        // ------------------------------------------------------

        '/orders': (context) => OrdersPage(),

        // ------------------------------------------------------
        // NOTIFICATIONS
        // ------------------------------------------------------

        '/notifications': (context) =>
            NotificationsPage(),

        // ------------------------------------------------------
        // SETTINGS
        // ------------------------------------------------------

        '/settings': (context) => SettingsPage(),
      },

      // ========================================================
      // ROUTES THAT REQUIRE ARGUMENTS
      // ========================================================

      onGenerateRoute: (RouteSettings settings) {

        // ======================================================
        // PRODUCT DETAILS
        // ======================================================

        if (settings.name == '/detail') {
          final product = settings.arguments;

          if (product == null) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
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

        // ======================================================
        // ORDER DETAILS
        // ======================================================

        if (settings.name == '/order-details') {
          final orderId =
              settings.arguments?.toString();

          if (orderId == null || orderId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
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

        // ======================================================
        // DISPATCH TRACKING
        // ======================================================

        if (settings.name == '/dispatch-tracking') {
          final orderId =
              settings.arguments?.toString();

          if (orderId == null || orderId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
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
                DispatchTrackingPage(
              orderId: orderId,
            ),
            settings: settings,
          );
        }

        // ======================================================
        // CHAT
        // ======================================================

        if (settings.name == '/chat') {
          final arguments = settings.arguments;

          String? chatId;
          String? otherUserName;

          if (arguments is Map) {
            chatId =
                arguments['chatId']?.toString();

            otherUserName =
                arguments['otherUserName']
                    ?.toString();
          } else if (arguments != null) {
            chatId = arguments.toString();
          }

          if (chatId == null || chatId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
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

        // ======================================================
        // UNKNOWN ROUTE
        // ======================================================

        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text(
                'Page not found.',
              ),
            ),
          ),
        );
      },

      // ========================================================
      // START APP
      // ========================================================

      initialRoute: '/',
    );
  }
}

// ==========================================================
// AUTH GATE
// ==========================================================
//
// Firebase checks whether the user is already signed in.
//
// Signed in:
//     → MainPage
//
// Not signed in:
//     → LoginScreen
//
// ==========================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // ------------------------------------------------------
        // CHECKING AUTH STATE
        // ------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                AppTheme.lightBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.pikkXNavy,
              ),
            ),
          );
        }

        // ------------------------------------------------------
        // USER SIGNED IN
        // ------------------------------------------------------

        if (snapshot.hasData) {
          return MainPage();
        }

        // ------------------------------------------------------
        // USER NOT SIGNED IN
        // ------------------------------------------------------

        return const LoginScreen();
      },
    );
  }
}