import 'package:flutter/material.dart';

import 'package:pikkx/src/pages/mainPage.dart';
import 'package:pikkx/src/pages/shopping_cart_page.dart';
import 'package:pikkx/src/pages/checkout_page.dart';
import 'package:pikkx/src/pages/delivery_address_page.dart';
import 'package:pikkx/src/pages/orders_page.dart';
import 'package:pikkx/src/pages/order_details_page.dart';
import 'package:pikkx/src/pages/notifications_page.dart';
import 'package:pikkx/src/pages/chat_page.dart';
import 'package:pikkx/src/pages/settings_page.dart';

// Add this when your Favorites page exists:
// import 'package:pikkx/src/pages/favorites_page.dart';

class Routes {
  static Map<String, WidgetBuilder> getRoute() {
    return <String, WidgetBuilder>{

      // ==============================
      // MAIN
      // ==============================

      '/': (_) => MainPage(),

      'MainPage': (_) => MainPage(),

      // ==============================
      // SHOPPING
      // ==============================

      '/cart': (_) => ShoppingCartPage(),

      '/checkout': (_) => CheckoutPage(),

      '/delivery-address': (_) =>
          DeliveryAddressPage(),

      // ==============================
      // ORDERS
      // ==============================

      '/orders': (_) => OrdersPage(),

      '/order-details': (context) {
        final orderId =
            ModalRoute.of(context)!.settings.arguments as String;
        return OrderDetailsPage(orderId: orderId);
      },

      // ==============================
      // COMMUNICATION
      // ==============================

      '/notifications': (_) =>
          NotificationsPage(),

      '/chat': (context) {
        final chatId =
            ModalRoute.of(context)!.settings.arguments as String;
        return ChatPage(chatId: chatId);
      },

      // ==============================
      // SETTINGS
      // ==============================

      '/settings': (_) => SettingsPage(),

      // ==============================
      // PRODUCT DETAILS
      // ==============================
      //
      // /detail is handled by
      // onGenerateRoute() in main.dart
      // because it receives the Product
      // through RouteSettings.arguments.
      //
    };
  }
}