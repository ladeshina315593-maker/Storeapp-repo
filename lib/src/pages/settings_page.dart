import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool notificationsEnabled = true;
  bool orderUpdates = true;
  bool promotionalNotifications = true;

  bool isLoading = true;
  bool isSaving = false;

  String? get userId =>
      _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>
      get userRef {
    return _firestore
        .collection('users')
        .doc(userId);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot =
          await userRef.get();

      final data = snapshot.data();

      final settings =
          data?['settings'] is Map
              ? Map<String, dynamic>.from(
                  data!['settings'],
                )
              : <String, dynamic>{};

      setState(() {
        notificationsEnabled =
            settings[
                    'notificationsEnabled'] ??
                true;

        orderUpdates =
            settings['orderUpdates'] ??
                true;

        promotionalNotifications =
            settings[
                    'promotionalNotifications'] ??
                true;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Settings error: $e',
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (userId == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await userRef.set(
        {
          'settings': {
            'notificationsEnabled':
                notificationsEnabled,
            'orderUpdates':
                orderUpdates,
            'promotionalNotifications':
                promotionalNotifications,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Save settings error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _changeNotifications(
    bool value,
  ) async {
    setState(() {
      notificationsEnabled = value;

      if (!value) {
        orderUpdates = false;
        promotionalNotifications = false;
      }
    });

    await _saveSettings();
  }

  Future<void> _changeOrderUpdates(
    bool value,
  ) async {
    setState(() {
      orderUpdates = value;
    });

    await _saveSettings();
  }

  Future<void>
      _changePromotionalNotifications(
    bool value,
  ) async {
    setState(() {
      promotionalNotifications =
          value;
    });

    await _saveSettings();
  }

  Future<void> _signOut() async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your account.',
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
                'Sign out',
                style: TextStyle(
                  color: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color:
                Color(0xFF1D2635),
            fontSize: 21,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color:
              Color(0xFF1D2635),
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFB98BEF),
              ),
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                30,
              ),
              children: [
                _sectionTitle(
                  'Notifications',
                ),

                _glass(
                  child: Column(
                    children: [
                      _switchTile(
                        icon: Icons
                            .notifications_none_rounded,
                        title:
                            'Notifications',
                        subtitle:
                            'Receive app notifications',
                        value:
                            notificationsEnabled,
                        onChanged:
                            _changeNotifications,
                      ),
                      const Divider(
                        height: 1,
                        color:
                            Color(0xFFE1E2E4),
                      ),
                      _switchTile(
                        icon: Icons
                            .local_shipping_outlined,
                        title:
                            'Order updates',
                        subtitle:
                            'Get updates about your orders',
                        value:
                            orderUpdates,
                        enabled:
                            notificationsEnabled,
                        onChanged:
                            _changeOrderUpdates,
                      ),
                      const Divider(
                        height: 1,
                        color:
                            Color(0xFFE1E2E4),
                      ),
                      _switchTile(
                        icon: Icons
                            .local_offer_outlined,
                        title:
                            'Promotions',
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

                const SizedBox(
                  height: 24,
                ),

                _sectionTitle(
                  'Account',
                ),

                _glass(
                  child: Column(
                    children: [
                      _actionTile(
                        icon: Icons
                            .location_on_outlined,
                        title:
                            'Delivery Addresses',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/delivery-address',
                          );
                        },
                      ),
                      const Divider(
                        height: 1,
                        color:
                            Color(0xFFE1E2E4),
                      ),
                      _actionTile(
                        icon: Icons
                            .shopping_bag_outlined,
                        title:
                            'My Orders',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/orders',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                _sectionTitle(
                  'Support',
                ),

                _glass(
                  child: Column(
                    children: [
                      _actionTile(
                        icon: Icons
                            .help_outline_rounded,
                        title:
                            'Help & Support',
                        onTap: () {
                          // Connect to support
                          // screen when created.
                        },
                      ),
                      const Divider(
                        height: 1,
                        color:
                            Color(0xFFE1E2E4),
                      ),
                      _actionTile(
                        icon: Icons
                            .info_outline_rounded,
                        title:
                            'About GrapeGo',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName:
                                'GrapeGo',
                            applicationVersion:
                                '1.0.0',
                            applicationLegalese:
                                'GrapeGo marketplace',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                SizedBox(
                  height: 53,
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                    ),
                    label: const Text(
                      'Sign Out',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          const Color(
                              0xFFE65829),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                        side:
                            const BorderSide(
                          color:
                              Color(0xFFE1E2E4),
                        ),
                      ),
                    ),
                  ),
                ),

                if (isSaving)
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 14,
                    ),
                    child: Center(
                      child:
                          SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Color(
                                  0xFFB98BEF),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool>
        onChanged,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color:
              const Color(0xFFF8F5FF),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color:
              const Color(0xFFB98BEF),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              const Color(0xFF1D2635),
          fontWeight:
              FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color:
              Color(0xFF797878),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged:
            enabled ? onChanged : null,
        activeColor:
            const Color(0xFFB98BEF),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color:
              const Color(0xFFF8F5FF),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color:
              const Color(0xFFB98BEF),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color:
              Color(0xFF1D2635),
          fontWeight:
              FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
        color:
            Color(0xFFA1A3A6),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight:
              FontWeight.w700,
          color:
              Color(0xFF1D2635),
        ),
      ),
    );
  }

  Widget _glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          decoration:
              BoxDecoration(
            color: Colors.white
                .withOpacity(0.76),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white
                  .withOpacity(0.88),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.04),
                blurRadius: 18,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}