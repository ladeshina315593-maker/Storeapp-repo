import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/pages/mainPage.dart';
import 'package:flutter_ecommerce_app/src/pages/product_detail.dart';
import 'package:flutter_ecommerce_app/src/pages/checkout_page.dart';
import 'package:flutter_ecommerce_app/src/pages/delivery_address_page.dart';
import 'package:flutter_ecommerce_app/src/pages/orders_page.dart';
import 'package:flutter_ecommerce_app/src/pages/order_details_page.dart';
import 'package:flutter_ecommerce_app/src/pages/notifications_page.dart';
import 'package:flutter_ecommerce_app/src/pages/chat_page.dart';
import 'package:flutter_ecommerce_app/src/pages/settings_page.dart';
import 'package:flutter_ecommerce_app/src/widgets/customRoute.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/themes/theme.dart';

void main() {
  runApp(const GrapeGoApp());
}

class GrapeGoApp extends StatelessWidget {
  const GrapeGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grape Go',
      debugShowCheckedModeBanner: false,

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

      // ------------------------------------------------
      // GrapeGo APP ROUTES
      // ------------------------------------------------
      routes: {
        // Main app
        'MainPage': (context) =>
            const MainPage(),

        // Shopping
        '/checkout': (context) =>
            const CheckoutPage(),

        '/delivery-address': (context) =>
            const DeliveryAddressPage(),

        '/orders': (context) =>
            const OrdersPage(),

        // Notifications
        '/notifications': (context) =>
            const NotificationsPage(),

        // Settings
        '/settings': (context) =>
            const SettingsPage(),
      },

      // ------------------------------------------------
      // ROUTES THAT REQUIRE ARGUMENTS
      // ------------------------------------------------
      onGenerateRoute:
          (RouteSettings settings) {
        // Product details
        if (settings.name != null &&
            settings.name!.contains('detail')) {
          return CustomRoute<bool>(
            builder: (BuildContext context) =>
                ProductDetailPage(),
          );
        }

        // Order details
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
          );
        }

        // Chat
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
              otherUserName:
                  otherUserName,
            ),
          );
        }

        // Unknown route
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

      // Start page
      initialRoute: 'MainPage',
    );
  }
}