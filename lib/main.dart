import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pikkx/src/pages/mainPage.dart';
import 'package:pikkx/src/pages/login_screen.dart';
import 'package:pikkx/src/pages/signup_screen.dart';
import 'package:pikkx/src/pages/phone_auth_screen.dart';
import 'package:pikkx/src/pages/forgot_password_screen.dart';
import 'package:pikkx/src/pages/product_detail.dart';
import 'package:pikkx/src/pages/shopping_cart_page.dart';
import 'package:pikkx/src/pages/favourite_page.dart';
import 'package:pikkx/src/pages/checkout_page.dart';
import 'package:pikkx/src/pages/delivery_address_page.dart';
import 'package:pikkx/src/pages/orders_page.dart';
import 'package:pikkx/src/pages/order_details_page.dart';
import 'package:pikkx/src/pages/notifications_page.dart';
import 'package:pikkx/src/pages/chat_page.dart';
import 'package:pikkx/src/pages/settings_page.dart';
import 'package:pikkx/src/pages/dispatch_tracking_page.dart';

import 'package:pikkx/src/pages/terms_conditions_page.dart';
import 'package:pikkx/src/pages/privacy_policy_page.dart';

import 'package:pikkx/src/widgets/customRoute.dart';
import 'package:pikkx/src/themes/theme.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PikkXApp());
}

// ==========================================================
// PIKKX APP
// ==========================================================

class PikkXApp extends StatelessWidget {
  const PikkXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = AppTheme.lightTheme;

    return MaterialApp(
      title: 'PikkX',
      debugShowCheckedModeBanner: false,

      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: AppTheme.lightBackground,
        primaryColor: AppTheme.pikkXBlack,

        colorScheme: baseTheme.colorScheme.copyWith(
          primary: AppTheme.pikkXBlack,
          secondary: AppTheme.pikkXBlack,
        ),

        textTheme: GoogleFonts.mulishTextTheme(
          baseTheme.textTheme,
        ).apply(
          bodyColor: AppTheme.pikkXBlack,
          displayColor: AppTheme.pikkXBlack,
        ),

        // IMPORTANT:
        // No const here because AppTheme.pikkXBlack
        // is not a compile-time constant in this project.
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: AppTheme.pikkXBlack,
          ),
        ),
      ),

      // ======================================================
      // ROUTES
      // ======================================================

      routes: {
        // ----------------------------------------------------
        // AUTH
        // ----------------------------------------------------

        '/login': (context) => const LoginScreen(),

        '/signup': (context) => const SignUpScreen(),

        '/forgot-password': (context) =>
            const ForgotPasswordScreen(),

        // Kept so existing references do not break.
        '/phone-login': (context) =>
            const PhoneAuthScreen(),

        '/phone-signup': (context) =>
            const PhoneAuthScreen(),

        // ----------------------------------------------------
        // LEGAL
        // ----------------------------------------------------

        '/terms': (context) =>
            const TermsConditionsPage(),

        '/privacy': (context) =>
            const PrivacyPolicyPage(),

        // ----------------------------------------------------
        // MAIN APP
        // ----------------------------------------------------

        '/': (context) => const AuthGate(),

        '/home': (context) => const MainPage(),

        '/MainPage': (context) => const MainPage(),

        // ----------------------------------------------------
        // CART
        // ----------------------------------------------------

        '/cart': (context) => ShoppingCartPage(),

        // ----------------------------------------------------
        // FAVOURITES
        // ----------------------------------------------------

        '/favourites': (context) =>
            const FavouritePage(),

        // ----------------------------------------------------
        // CHECKOUT
        // ----------------------------------------------------

        '/checkout': (context) => CheckoutPage(),

        '/delivery-address': (context) =>
            DeliveryAddressPage(),

        // ----------------------------------------------------
        // ORDERS
        // ----------------------------------------------------

        '/orders': (context) => OrdersPage(),

        // ----------------------------------------------------
        // NOTIFICATIONS
        // ----------------------------------------------------

        '/notifications': (context) =>
            NotificationsPage(),

        // ----------------------------------------------------
        // SETTINGS
        // ----------------------------------------------------

        '/settings': (context) => SettingsPage(),
      },

      // ======================================================
      // GENERATED ROUTES
      // ======================================================

      onGenerateRoute: (RouteSettings settings) {
        // ====================================================
        // PRODUCT DETAIL
        // ====================================================

        if (settings.name == '/detail') {
          final arguments = settings.arguments;

          if (arguments is! Map) {
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

          final productMap =
              Map<String, dynamic>.from(arguments);

          final productId =
              productMap['productId']?.toString() ??
                  productMap['id']?.toString() ??
                  '';

          if (productId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text(
                    'Product ID is missing.',
                  ),
                ),
              ),
            );
          }

          return CustomRoute<bool>(
            builder: (context) => ProductDetailPage(
              productId: productId,
              product: productMap,
            ),
            settings: settings,
          );
        }

        // ====================================================
        // ORDER DETAILS
        // ====================================================

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
            builder: (context) => OrderDetailsPage(
              orderId: orderId,
            ),
            settings: settings,
          );
        }

        // ====================================================
        // DISPATCH TRACKING
        // ====================================================

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
            builder: (context) => DispatchTrackingPage(
              orderId: orderId,
            ),
            settings: settings,
          );
        }

        // ====================================================
        // CHAT
        // ====================================================

        if (settings.name == '/chat') {
          final arguments = settings.arguments;

          String? chatId;
          String? otherUserName;

          if (arguments is Map) {
            chatId = arguments['chatId']?.toString();
            otherUserName =
                arguments['otherUserName']?.toString();
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
            builder: (context) => ChatPage(
              chatId: chatId!,
              otherUserName: otherUserName,
            ),
            settings: settings,
          );
        }

        // ====================================================
        // FALLBACK
        // ====================================================

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

      initialRoute: '/',
    );
  }
}

// ==========================================================
// AUTH GATE
// ==========================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // ----------------------------------------------------
        // CHECKING
        // ----------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            backgroundColor:
                AppTheme.lightBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.pikkXBlack,
              ),
            ),
          );
        }

        // ----------------------------------------------------
        // SIGNED IN
        // ----------------------------------------------------

        if (snapshot.hasData) {
          return const MainPage();
        }

        // ----------------------------------------------------
        // SIGNED OUT
        // ----------------------------------------------------

        return const LoginScreen();
      },
    );
  }
}