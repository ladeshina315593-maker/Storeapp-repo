import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/pages/home_page.dart';
import 'package:flutter_ecommerce_app/src/pages/cart_page.dart';
import 'package:flutter_ecommerce_app/src/pages/orders_page.dart';
import 'package:flutter_ecommerce_app/src/pages/delivery_address_page.dart';
import 'package:flutter_ecommerce_app/src/pages/notifications_page.dart';
import 'package:flutter_ecommerce_app/src/pages/settings_page.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
import 'package:flutter_ecommerce_app/src/widgets/BottomNavigationBar/bottom_navigation_bar.dart';
import 'package:flutter_ecommerce_app/src/widgets/title_text.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.title});

  final String? title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // --------------------------------------------------
  // MAIN PAGES
  // --------------------------------------------------

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const MyHomePage();

      case 1:
        return const CartPage();

      case 2:
        return const FavouritePage();

      case 3:
        return const ProfilePage();

      default:
        return const MyHomePage();
    }
  }

  // --------------------------------------------------
  // TOP GLASS ICON
  // --------------------------------------------------

  Widget _glassIcon(
    IconData icon, {
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.85),
            ),
            boxShadow: AppTheme.shadow,
          ),
          child: Icon(
            icon,
            color:
                iconColor ??
                AppTheme.darkText,
            size: 21,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // APP BAR
  // --------------------------------------------------

  Widget _appBar() {
    return Padding(
      padding: AppTheme.padding,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          _glassIcon(
            Icons.menu_rounded,
            onPressed: _openMenu,
          ),

          Row(
            children: [
              _glassIcon(
                Icons.notifications_none_rounded,
                onPressed: _openNotifications,
              ),

              const SizedBox(width: 10),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
                child: Container(
                  height: 46,
                  width: 46,
                  padding:
                      const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.glassWhite,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(0.85),
                    ),
                    boxShadow:
                        AppTheme.shadow,
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(13),
                    child: _buildProfileImage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final photoUrl =
        currentUser?.photoURL;

    if (photoUrl != null &&
        photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return _defaultProfileIcon();
        },
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: const Color(0xFFF8F5FF),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFFB98BEF),
        size: 25,
      ),
    );
  }

  // --------------------------------------------------
  // TITLE
  // --------------------------------------------------

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
        first = 'My';
        second = 'Favourites';
        break;

      case 3:
        first = 'My';
        second = 'Profile';
        break;

      default:
        first = 'Our';
        second = 'Products';
    }

    return Container(
      margin: AppTheme.padding,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              TitleText(
                text: first,
                fontSize: 27,
                fontWeight:
                    FontWeight.w400,
                color:
                    AppTheme.darkText,
              ),
              TitleText(
                text: second,
                fontSize: 27,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppTheme.darkText,
              ),
            ],
          ),

          const Spacer(),

          if (_selectedIndex == 1)
            _glassIcon(
              Icons.delete_outline_rounded,
              iconColor:
                  AppTheme.grapePurple,
              onPressed:
                  _clearCart,
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------

  void onBottomIconPressed(int index) {
    if (index < 0 || index > 3) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // --------------------------------------------------
  // NOTIFICATIONS
  // --------------------------------------------------

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const NotificationsPage(),
      ),
    );
  }

  // --------------------------------------------------
  // MENU
  // --------------------------------------------------

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _buildGlassMenu();
      },
    );
  }

  Widget _buildGlassMenu() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20,
              sigmaY: 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.90),
                borderRadius:
                    BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.9),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  16,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFFDCC7FA,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'GrapeGo Menu',
                        style: TextStyle(
                          color:
                              Color(0xFF1D2635),
                          fontSize: 21,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    _menuItem(
                      Icons.person_outline_rounded,
                      'My Profile',
                      () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                    ),

                    _menuItem(
                      Icons.shopping_bag_outlined,
                      'My Orders',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const OrdersPage(),
                          ),
                        );
                      },
                    ),

                    _menuItem(
                      Icons.location_on_outlined,
                      'Delivery Addresses',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DeliveryAddressPage(),
                          ),
                        );
                      },
                    ),

                    _menuItem(
                      Icons.favorite_outline_rounded,
                      'My Favourites',
                      () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 2;
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SettingsPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(
                      height: 22,
                      color:
                          Color(0xFFE1E2E4),
                    ),

                    _menuItem(
                      Icons.logout_rounded,
                      'Log Out',
                      _logout,
                      iconColor:
                          const Color(
                        0xFFE65829,
                      ),
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
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 6,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF8F5FF),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color:
                      iconColor ??
                      AppTheme.grapePurple,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        Color(0xFF1D2635),
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color:
                    Color(0xFFA1A3A6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CLEAR CART
  // --------------------------------------------------

  Future<void> _clearCart() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in first.',
      );
      return;
    }

    final shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Clear cart?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'This will remove all items from your cart.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  color:
                      AppTheme.grapePurple,
                  fontWeight:
                      FontWeight.w700,
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
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .get();

      final batch =
          _firestore.batch();

      for (final doc
          in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage(
        'Cart cleared.',
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not clear cart.',
      );

      debugPrint(
        'Clear cart error: $e',
      );
    }
  }

  // --------------------------------------------------
  // LOG OUT
  // --------------------------------------------------

  Future<void> _logout() async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color:
                      Color(0xFFE65829),
                  fontWeight:
                      FontWeight.w700,
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

      // The authentication flow should
      // eventually handle this automatically
      // using FirebaseAuth.authStateChanges().
      _showMessage(
        'You have been logged out.',
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            AppTheme.grapePurple,
      ),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.grapeLightPurple,

      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  colors: [
                    AppTheme.grapeLightPurple,
                    Colors.white,
                  ],
                  begin:
                      Alignment.topCenter,
                  end:
                      Alignment.bottomCenter,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _appBar(),

                  _title(),

                  Expanded(
                    child:
                        AnimatedSwitcher(
                      duration:
                          const Duration(
                        milliseconds: 300,
                      ),
                      switchInCurve:
                          Curves.easeInToLinear,
                      switchOutCurve:
                          Curves.easeOutBack,
                      child: KeyedSubtree(
                        key: ValueKey(
                          _selectedIndex,
                        ),
                        child:
                            _buildCurrentPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child:
                  CustomBottomNavigationBar(
                onIconPresedCallback:
                    onBottomIconPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// FAVOURITE PAGE
// ======================================================

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _SimpleEmptyState(
        icon:
            Icons.favorite_outline_rounded,
        title:
            'Sign in to view favourites',
        subtitle:
            'Your saved products will appear here.',
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
            child:
                CircularProgressIndicator(
              color:
                  Color(0xFFB98BEF),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _SimpleEmptyState(
            icon:
                Icons.error_outline_rounded,
            title:
                'Could not load favourites',
            subtitle:
                'Please try again.',
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _SimpleEmptyState(
            icon:
                Icons.favorite_outline_rounded,
            title:
                'No favourites yet',
            subtitle:
                'Products you save will appear here.',
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            5,
            16,
            90,
          ),
          itemCount: docs.length,
          itemBuilder:
              (context, index) {
            final data =
                docs[index].data();

            final name =
                data['name']
                    ?.toString() ??
                    'Product';

            final price =
                data['price']?.toString() ??
                    '0';

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: _GlassListTile(
                icon:
                    Icons.favorite_rounded,
                title: name,
                subtitle:
                    '₦$price',
              ),
            );
          },
        );
      },
    );
  }
}

// ======================================================
// PROFILE PAGE
// ======================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _SimpleEmptyState(
        icon:
            Icons.person_outline_rounded,
        title:
            'You are not signed in',
        subtitle:
            'Sign in to view your profile.',
      );
    }

    final name =
        user.displayName?.trim();

    final email =
        user.email ?? '';

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        90,
      ),

      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(22),
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.72),
                borderRadius:
                    BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.85),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        const Color(
                      0xFFF8F5FF,
                    ),
                    backgroundImage:
                        user.photoURL !=
                                null
                            ? NetworkImage(
                                user.photoURL!,
                              )
                            : null,
                    child:
                        user.photoURL ==
                                null
                            ? const Icon(
                                Icons
                                    .person_rounded,
                                size: 42,
                                color:
                                    Color(
                                  0xFFB98BEF,
                                ),
                              )
                            : null,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Text(
                    (name == null ||
                            name.isEmpty)
                        ? 'GrapeGo User'
                        : name,

                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF1D2635),
                    ),
                  ),

                  if (email.isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      email,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF797878),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        _GlassListTile(
          icon:
              Icons.shopping_bag_outlined,
          title: 'My Orders',
          subtitle:
              'View your orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const OrdersPage(),
              ),
            );
          },
        ),

        const SizedBox(
          height: 10,
        ),

        _GlassListTile(
          icon:
              Icons.location_on_outlined,
          title:
              'Delivery Addresses',
          subtitle:
              'Manage your addresses',
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

        const SizedBox(
          height: 10,
        ),

        _GlassListTile(
          icon:
              Icons.settings_outlined,
          title: 'Settings',
          subtitle:
              'Manage your account',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ======================================================
// GLASS LIST TILE
// ======================================================

class _GlassListTile
    extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: Colors.white
              .withOpacity(0.72),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(22),
            child: Padding(
              padding:
                  const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF8F5FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          const Color(
                        0xFFB98BEF,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          title,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(
                              0xFF1D2635,
                            ),
                          ),
                        ),

                        if (subtitle !=
                            null) ...[
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            subtitle!,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  Color(
                                0xFF797878,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (onTap != null)
                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      size: 14,
                      color:
                          Color(0xFFA1A3A6),
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

// ======================================================
// EMPTY STATE
// ======================================================

class _SimpleEmptyState
    extends StatelessWidget {
  const _SimpleEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF8F5FF,
                ),
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color:
                    const Color(
                  0xFFB98BEF,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF1D2635),
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              subtitle,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(0xFF797878),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}