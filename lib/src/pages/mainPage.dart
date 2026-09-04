import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/pages/home_page.dart';
import 'package:flutter_ecommerce_app/src/pages/cart_page.dart';
import 'package:flutter_ecommerce_app/src/pages/chat_page.dart';
import 'package:flutter_ecommerce_app/src/pages/orders_page.dart';
import 'package:flutter_ecommerce_app/src/pages/delivery_address_page.dart';
import 'package:flutter_ecommerce_app/src/pages/notifications_page.dart';
import 'package:flutter_ecommerce_app/src/pages/settings_page.dart';

import 'package:flutter_ecommerce_app/src/widgets/BottomNavigationBar/bottom_navigation_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    this.title,
  });

  final String? title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ============================================================
  // PIKKX THEME
  // ============================================================
  //
  // NEW PikkX identity:
  // Black + White + Light Grey + Glass
  // NO BLUE
  // NO NAVY
  // NO PURPLE
  //

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color pikkXLightGrey = Color(0xFFE8E8E8);
  static const Color pikkXGlassGrey = Color(0xFFEFEFEF);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // NAVIGATION
  // ============================================================

  int _selectedIndex = 0;

  // 0 = Home
  // 1 = Cart
  // 2 = Chat
  // 3 = Favourite
  // 4 = Profile

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const MyHomePage();

      case 1:
        return CartPage(
          onContinueShopping: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );

      case 2:
        return const ChatPage();

      case 3:
        return const FavouritePage();

      case 4:
        return const ProfilePage();

      default:
        return const MyHomePage();
    }
  }

  void _onBottomIconPressed(int index) {
    if (index < 0 || index > 4) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // GLASS ICON
  // ============================================================

  Widget _glassIcon(
    IconData icon, {
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: pikkXWhite.withOpacity(0.68),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: pikkXWhite.withOpacity(0.92),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pikkXBlack.withOpacity(0.055),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor ?? pikkXBlack,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        10,
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // PIKKX LOGO
          // ------------------------------------------------------

          GestureDetector(
            onTap: _openMenu,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12,
                  sigmaY: 12,
                ),
                child: Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: pikkXWhite.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: pikkXWhite.withOpacity(0.92),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pikkXBlack.withOpacity(0.045),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/pikkx_icon (1).png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.shopping_bag_rounded,
                        color: pikkXBlack,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------------------------------
          // BRAND
          // ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'pikkX',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // NOTIFICATION
          // ------------------------------------------------------

          _notificationButton(),

          const SizedBox(width: 9),

          // ------------------------------------------------------
          // PROFILE
          // ------------------------------------------------------

          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 4;
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12,
                  sigmaY: 12,
                ),
                child: Container(
                  height: 46,
                  width: 46,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: pikkXWhite.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: pikkXWhite.withOpacity(0.92),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pikkXBlack.withOpacity(0.045),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _buildProfileImage(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION BUTTON
  // ============================================================

  Widget _notificationButton() {
    final user = currentUser;

    if (user == null) {
      return _glassIcon(
        Icons.notifications_none_rounded,
        onPressed: _openNotifications,
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        int unread = 0;

        if (snapshot.hasData) {
          unread = snapshot.data!.docs.where((doc) {
            return doc.data()['read'] != true;
          }).length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _glassIcon(
              Icons.notifications_none_rounded,
              onPressed: _openNotifications,
            ),

            if (unread > 0)
              Positioned(
                right: -3,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                  ),
                  height: 17,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: pikkXBlack,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: pikkXWhite,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    final String? photoUrl = currentUser?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _defaultProfileIcon();
        },
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: pikkXBackground,
      child: const Icon(
        Icons.person_outline_rounded,
        color: pikkXBlack,
        size: 25,
      ),
    );
  }

  // ============================================================
  // PAGE TITLE
  // ============================================================

  Widget _title() {
    String first;
    String second;

    switch (_selectedIndex) {
      case 0:
        first = 'Our';
        second = 'Products';
        break;

      case 1:
        first = 'Shopping';
        second = 'Cart';
        break;

      case 2:
        first = 'Chat';
        second = '';
        break;

      case 3:
        first = 'My';
        second = 'Favourites';
        break;

      case 4:
        first = 'My';
        second = 'Profile';
        break;

      default:
        first = 'Our';
        second = 'Products';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        5,
        20,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first,
                style: const TextStyle(
                  color: pikkXBlack,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (second.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  second,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          if (_selectedIndex == 1)
            _glassIcon(
              Icons.delete_outline_rounded,
              iconColor: pikkXBlack,
              onPressed: _clearCart,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildGlassMenu(),
    );
  }

  Widget _buildGlassMenu() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 22,
              sigmaY: 22,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: pikkXWhite.withOpacity(0.88),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: pikkXWhite.withOpacity(0.95),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pikkXBlack.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  15,
                  20,
                  18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HANDLE
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: pikkXLightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BRAND
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            width: 42,
                            height: 42,
                            padding: const EdgeInsets.all(6),
                            color: pikkXBackground,
                            child: Image.asset(
                              'assets/images/pikkx_icon (1).png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: pikkXBlack,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Text(
                          'pikkX Menu',
                          style: TextStyle(
                            color: pikkXBlack,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _menuItem(
                      Icons.person_outline_rounded,
                      'My Profile',
                      () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 4;
                        });
                      },
                    ),

                    _menuItem(
                      Icons.shopping_bag_outlined,
                      'My Orders',
                      () {
                        Navigator.pop(context);
                        _pushPage(
                          const OrdersPage(),
                        );
                      },
                    ),

                    _menuItem(
                      Icons.location_on_outlined,
                      'Delivery Addresses',
                      () {
                        Navigator.pop(context);
                        _pushPage(
                          const DeliveryAddressPage(),
                        );
                      },
                    ),

                    _menuItem(
                      Icons.favorite_outline_rounded,
                      'My Favourites',
                      () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                    ),

                    _menuItem(
                      Icons.notifications_none_rounded,
                      'Notifications',
                      () {
                        Navigator.pop(context);
                        _openNotifications();
                      },
                    ),

                    _menuItem(
                      Icons.settings_outlined,
                      'Settings',
                      () {
                        Navigator.pop(context);
                        _pushPage(
                          const SettingsPage(),
                        );
                      },
                    ),

                    const Divider(
                      height: 22,
                      color: pikkXLightGrey,
                    ),

                    _menuItem(
                      Icons.logout_rounded,
                      'Log Out',
                      _logout,
                      iconColor: pikkXBlack,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 5,
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: pikkXBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: pikkXBlack.withOpacity(0.05),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? pikkXBlack,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: pikkXGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PUSH PAGE
  // ============================================================

  void _pushPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // ============================================================
  // CLEAR FIREBASE CART
  // ============================================================

  Future<void> _clearCart() async {
    final user = currentUser;

    if (user == null) {
      _showMessage('Please sign in first.');
      return;
    }

    final bool? shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Clear cart?',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This will remove all items from your cart.',
            style: TextStyle(
              color: pikkXGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: pikkXBlack,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: pikkXBlack,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      final batch = _firestore.batch();

      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage('Cart cleared.');
    } catch (e) {
      debugPrint('Clear cart error: $e');

      if (!mounted) return;

      _showMessage(
        'Could not clear cart.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final bool? shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: pikkXGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: pikkXBlack,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: pikkXBlack,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      _showMessage(
        'Could not log out.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: pikkXWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: pikkXBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ----------------------------------------------------
            // MAIN BACKGROUND
            // ----------------------------------------------------

            Container(
              color: pikkXBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Only show this navigation-shell header
                  // on non-home pages.
                  if (_selectedIndex != 0) _appBar(),

                  _title(),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 260,
                      ),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_selectedIndex),
                        child: _buildCurrentPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // FLOATING GLASS NAVIGATION
            // ----------------------------------------------------

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavigationBar(
                selectedIndex: _selectedIndex,
                onIconPressedCallback:
                    _onBottomIconPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// FAVOURITE PAGE
// ==================================================================

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _SimpleEmptyState(
        icon: Icons.favorite_outline_rounded,
        title: 'Sign in to view favourites',
        subtitle: 'Your saved products will appear here.',
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: pikkXBlack,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _SimpleEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load favourites',
            subtitle: 'Please try again.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _SimpleEmptyState(
            icon: Icons.favorite_outline_rounded,
            title: 'No favourites yet',
            subtitle:
                'Products you save will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            5,
            16,
            90,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final name =
                data['name']?.toString() ?? 'Product';

            final price =
                data['price']?.toString() ?? '0';

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _GlassListTile(
                icon: Icons.favorite_rounded,
                title: name,
                subtitle: price,
              ),
            );
          },
        );
      },
    );
  }
}

// ==================================================================
// PROFILE PAGE
// ==================================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _SimpleEmptyState(
        icon: Icons.person_outline_rounded,
        title: 'You are not signed in',
        subtitle: 'Sign in to view your profile.',
      );
    }

    final name = user.displayName?.trim();
    final email = user.email ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        90,
      ),
      children: [
        // --------------------------------------------------------
        // PROFILE GLASS CARD
        // --------------------------------------------------------

        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 16,
              sigmaY: 16,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: pikkXWhite.withOpacity(0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: pikkXWhite.withOpacity(0.92),
                ),
                boxShadow: [
                  BoxShadow(
                    color: pikkXBlack.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: pikkXBackground,
                    backgroundImage:
                        user.photoURL != null &&
                                user.photoURL!.isNotEmpty
                            ? NetworkImage(user.photoURL!)
                            : null,
                    child:
                        user.photoURL == null ||
                                user.photoURL!.isEmpty
                            ? const Icon(
                                Icons.person_outline_rounded,
                                size: 42,
                                color: pikkXBlack,
                              )
                            : null,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    (name == null || name.isEmpty)
                        ? 'pikkX User'
                        : name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: pikkXBlack,
                    ),
                  ),

                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(
                        color: pikkXGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        _GlassListTile(
          icon: Icons.shopping_bag_outlined,
          title: 'My Orders',
          subtitle: 'View your orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrdersPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        _GlassListTile(
          icon: Icons.location_on_outlined,
          title: 'Delivery Addresses',
          subtitle: 'Manage your addresses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const DeliveryAddressPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        _GlassListTile(
          icon: Icons.favorite_outline_rounded,
          title: 'My Favourites',
          subtitle: 'View saved products',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FavouritePage(),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        _GlassListTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Manage your account',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ==================================================================
// GLASS LIST TILE
// ==================================================================

class _GlassListTile extends StatelessWidget {
  const _GlassListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: pikkXWhite.withOpacity(0.70),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(
                  color: pikkXWhite.withOpacity(0.90),
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: pikkXBlack.withOpacity(0.025),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: pikkXBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: pikkXBlack,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: pikkXBlack,
                          ),
                        ),

                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: pikkXGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: pikkXGrey,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// EMPTY STATE
// ==================================================================

class _SimpleEmptyState extends StatelessWidget {
  const _SimpleEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 14,
                  sigmaY: 14,
                ),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: pikkXWhite.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: pikkXWhite.withOpacity(0.92),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pikkXBlack.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: pikkXBlack,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: pikkXBlack,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: pikkXGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}