import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pikkx/src/themes/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color pikkXLightGrey = Color(0xFFE8E8E8);

  bool notificationsEnabled = true;
  bool orderUpdates = true;
  bool promotionalNotifications = true;

  bool isLoading = true;
  bool isSaving = false;

  String? get userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get userRef {
    return _firestore.collection('users').doc(userId);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ------------------------------------------------------------
  // LOAD SETTINGS
  // ------------------------------------------------------------

  Future<void> _loadSettings() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await userRef.get();
      final data = snapshot.data();

      final settings = data?['settings'] is Map
          ? Map<String, dynamic>.from(data!['settings'])
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        notificationsEnabled =
            settings['notificationsEnabled'] ?? true;

        orderUpdates =
            settings['orderUpdates'] ?? true;

        promotionalNotifications =
            settings['promotionalNotifications'] ?? true;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Settings error: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // SAVE SETTINGS
  // ------------------------------------------------------------

  Future<void> _saveSettings() async {
    if (userId == null) return;

    if (mounted) {
      setState(() {
        isSaving = true;
      });
    }

    try {
      await userRef.set(
        {
          'settings': {
            'notificationsEnabled': notificationsEnabled,
            'orderUpdates': orderUpdates,
            'promotionalNotifications':
                promotionalNotifications,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Save settings error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _changeNotifications(bool value) async {
    setState(() {
      notificationsEnabled = value;

      if (!value) {
        orderUpdates = false;
        promotionalNotifications = false;
      }
    });

    await _saveSettings();
  }

  Future<void> _changeOrderUpdates(bool value) async {
    setState(() {
      orderUpdates = value;
    });

    await _saveSettings();
  }

  Future<void> _changePromotionalNotifications(
    bool value,
  ) async {
    setState(() {
      promotionalNotifications = value;
    });

    await _saveSettings();
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: pikkXWhite,
          surfaceTintColor: pikkXWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Sign out?',
            style: TextStyle(
              color: pikkXBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'You will need to sign in again to access your account.',
            style: TextStyle(
              color: AppTheme.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: pikkXBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  // ------------------------------------------------------------
  // GLASS CONTAINER
  // ------------------------------------------------------------

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.92),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.055),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP HEADER
  // ------------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20,
      ),
      child: Row(
        children: [
          _glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Manage your pikkX experience',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _glassIconButton(
            icon: Icons.tune_rounded,
            iconColor: pikkXBlack,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor ?? pikkXBlack,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: pikkXBlack,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SWITCH TILE
  // ------------------------------------------------------------

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 6,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: pikkXBlack.withOpacity(0.055),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: pikkXBlack,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: pikkXBlack,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 10,
          ),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: pikkXWhite,
        activeTrackColor: pikkXBlack,
        inactiveThumbColor: pikkXWhite,
        inactiveTrackColor: Colors.black12,
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTION TILE
  // ------------------------------------------------------------

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 6,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pikkXBlack.withOpacity(0.055),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: pikkXBlack,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 10,
              ),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.mutedText,
            size: 14,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ABOUT PIKKX
  // ------------------------------------------------------------

  void _showAboutPikkX() {
    showAboutDialog(
      context: context,
      applicationName: 'pikkX',
      applicationVersion: '1.0.0',
      applicationLegalese: 'pikkX marketplace',
      showLicenseButton: false,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: pikkXBlack,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: pikkXWhite,
          size: 25,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle neutral glass glow.
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                height: 230,
                width: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.025),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -90,
              child: Container(
                height: 230,
                width: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.018),
                ),
              ),
            ),

            Column(
              children: [
                _header(),

                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: pikkXBlack,
                          ),
                        )
                      : RefreshIndicator(
                          color: pikkXBlack,
                          onRefresh: _loadSettings,
                          child: ListView(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              35,
                            ),
                            children: [
                              // ------------------------------------------------
                              // NOTIFICATIONS
                              // ------------------------------------------------

                              _sectionTitle(
                                'Notifications',
                              ),

                              _glass(
                                child: Column(
                                  children: [
                                    _switchTile(
                                      icon: Icons
                                          .notifications_none_rounded,
                                      title: 'Notifications',
                                      subtitle:
                                          'Receive pikkX notifications',
                                      value:
                                          notificationsEnabled,
                                      onChanged:
                                          _changeNotifications,
                                    ),

                                    Divider(
                                      height: 1,
                                      color: pikkXBlack
                                          .withOpacity(0.06),
                                    ),

                                    _switchTile(
                                      icon: Icons
                                          .local_shipping_outlined,
                                      title:
                                          'Order updates',
                                      subtitle:
                                          'Get updates about your orders',
                                      value: orderUpdates,
                                      enabled:
                                          notificationsEnabled,
                                      onChanged:
                                          _changeOrderUpdates,
                                    ),

                                    Divider(
                                      height: 1,
                                      color: pikkXBlack
                                          .withOpacity(0.06),
                                    ),

                                    _switchTile(
                                      icon: Icons
                                          .local_offer_outlined,
                                      title: 'Promotions',
                                      subtitle:
                                          'Receive offers and promotions',
                                      value:
                                          promotionalNotifications,
                                      enabled:
                                          notificationsEnabled,
                                      onChanged:
                                          _changePromotionalNotifications,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // ------------------------------------------------
                              // ACCOUNT
                              // ------------------------------------------------

                              _sectionTitle('Account'),

                              _glass(
                                child: Column(
                                  children: [
                                    _actionTile(
                                      icon: Icons
                                          .location_on_outlined,
                                      title:
                                          'Delivery Addresses',
                                      subtitle:
                                          'Manage your saved addresses',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/delivery-address',
                                        );
                                      },
                                    ),

                                    Divider(
                                      height: 1,
                                      color: pikkXBlack
                                          .withOpacity(0.06),
                                    ),

                                    _actionTile(
                                      icon: Icons
                                          .shopping_bag_outlined,
                                      title: 'My Orders',
                                      subtitle:
                                          'View previous and active orders',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/orders',
                                        );
                                      },
                                    ),

                                    Divider(
                                      height: 1,
                                      color: pikkXBlack
                                          .withOpacity(0.06),
                                    ),

                                    _actionTile(
                                      icon: Icons
                                          .person_outline_rounded,
                                      title: 'Profile',
                                      subtitle:
                                          'Manage your pikkX profile',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/profile',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // ------------------------------------------------
                              // SUPPORT
                              // ------------------------------------------------

                              _sectionTitle('Support'),

                              _glass(
                                child: Column(
                                  children: [
                                    _actionTile(
                                      icon: Icons
                                          .help_outline_rounded,
                                      title:
                                          'Help & Support',
                                      subtitle:
                                          'Get help with pikkX',
                                      onTap: () {},
                                    ),

                                    Divider(
                                      height: 1,
                                      color: pikkXBlack
                                          .withOpacity(0.06),
                                    ),

                                    _actionTile(
                                      icon: Icons
                                          .info_outline_rounded,
                                      title: 'About pikkX',
                                      subtitle:
                                          'Learn more about pikkX',
                                      onTap: _showAboutPikkX,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ------------------------------------------------
                              // SIGN OUT
                              // ------------------------------------------------

                              SizedBox(
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: _signOut,
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'Sign Out',
                                  ),
                                  style:
                                      OutlinedButton.styleFrom(
                                    foregroundColor:
                                        pikkXBlack,
                                    side: BorderSide(
                                      color: pikkXBlack
                                          .withOpacity(0.10),
                                    ),
                                    backgroundColor:
                                        pikkXWhite
                                            .withOpacity(0.65),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (isSaving)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    top: 14,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: pikkXBlack,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 15),

                              const Center(
                                child: Text(
                                  'pikkX • 1.0.0',
                                  style: TextStyle(
                                    color: pikkXGrey,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}