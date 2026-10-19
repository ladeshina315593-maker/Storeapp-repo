import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pikkx/src/themes/theme.dart';
import 'package:pikkx/src/themes/app_theme_controller.dart';

class SettingsPage extends StatefulWidget {
const SettingsPage({super.key});

@override
State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
final AppThemeController _themeController =
AppThemeController.instance;

bool notificationsEnabled = true;
bool orderUpdates = true;
bool promotionalNotifications = true;

bool isLoading = true;
bool isSaving = false;

String? get userId => _auth.currentUser?.uid;

DocumentReference<Map<String, dynamic>> get userRef =>
_firestore.collection('users').doc(userId);

bool get isDark =>
_themeController.isDarkMode;

Color get pageBackground => isDark
? AppTheme.darkBackground
: AppTheme.lightBackground;

Color get cardColor => isDark
? AppTheme.darkCard
: AppTheme.lightCard;

Color get primaryText =>
isDark ? Colors.white : const Color(0xFF050505);

Color get secondaryText => isDark
? Colors.white70
: const Color(0xFF777777);

Color get accent => _themeController.accentColor;

Color get borderColor => isDark
? Colors.white.withOpacity(0.12)
: Colors.black.withOpacity(0.07);

@override
void initState() {
super.initState();
_loadSettings();
}

// ------------------------------------------------------------
// LOAD FIRESTORE SETTINGS
// ------------------------------------------------------------

Future<void> _loadSettings() async {
if (userId == null) {
if (mounted) {
setState(() => isLoading = false);
}
return;
}

try {
  final snapshot = await userRef.get();
  final data = snapshot.data();

  final rawSettings = data?['settings'];
  final settings = rawSettings is Map
      ? Map<String, dynamic>.from(rawSettings)
      : <String, dynamic>{};

  if (!mounted) return;

  setState(() {
    notificationsEnabled =
        settings['notificationsEnabled'] is bool
            ? settings['notificationsEnabled'] as bool
            : true;

    orderUpdates =
        settings['orderUpdates'] is bool
            ? settings['orderUpdates'] as bool
            : true;

    promotionalNotifications =
        settings['promotionalNotifications'] is bool
            ? settings['promotionalNotifications'] as bool
            : true;

    if (!notificationsEnabled) {
      orderUpdates = false;
      promotionalNotifications = false;
    }

    isLoading = false;
  });
} catch (error) {
  debugPrint('Could not load PikkX settings: $error');

  if (!mounted) return;

  setState(() => isLoading = false);
  _showMessage('Could not load your saved settings.');
}

}

// ------------------------------------------------------------
// SAVE FIRESTORE SETTINGS
// ------------------------------------------------------------

Future<void> _saveSettings() async {
if (userId == null) {
_showMessage('Please sign in to save your settings.');
return;
}

if (mounted) {
  setState(() => isSaving = true);
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
} catch (error) {
  debugPrint('Could not save PikkX settings: $error');
  _showMessage('Could not save your settings. Please try again.');
} finally {
  if (mounted) {
    setState(() => isSaving = false);
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
setState(() => orderUpdates = value);
await _saveSettings();
}

Future<void> _changePromotionalNotifications(
bool value,
) async {
setState(() => promotionalNotifications = value);
await _saveSettings();
}

// ------------------------------------------------------------
// MESSAGE FEEDBACK
// ------------------------------------------------------------

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );

}

// ------------------------------------------------------------
// SIGN OUT
// ------------------------------------------------------------

Future<void> _signOut() async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
backgroundColor: cardColor,
title: Text(
'Sign out?',
style: TextStyle(
color: primaryText,
fontWeight: FontWeight.w800,
),
),
content: Text(
'You will need to sign in again to access your account.',
style: TextStyle(color: secondaryText),
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(dialogContext, false),
child: Text(
'Cancel',
style: TextStyle(color: primaryText),
),
),
TextButton(
onPressed: () =>
Navigator.pop(dialogContext, true),
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

if (confirmed != true) return;

try {
  await _auth.signOut();

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/login',
    (route) => false,
  );
} catch (error) {
  debugPrint('Sign-out error: $error');
  _showMessage('Could not sign out. Please try again.');
}

}

// ------------------------------------------------------------
// OPEN WHATSAPP SUPPORT
// ------------------------------------------------------------

Future<void> _openSupport() async {
final uri = Uri.parse('https://wa.me/2349132315593');

try {
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched && mounted) {
    _showMessage('Could not open WhatsApp. Please try again.');
  }
} catch (error) {
  debugPrint('Support link error: $error');
  _showMessage('Could not open WhatsApp. Please try again.');
}

}

// ------------------------------------------------------------
// GLASS CARD
// ------------------------------------------------------------

Widget _glass({
required Widget child,
EdgeInsetsGeometry padding = EdgeInsets.zero,
}) {
return ClipRRect(
borderRadius: BorderRadius.circular(24),
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
child: Container(
padding: padding,
decoration: BoxDecoration(
color: cardColor.withOpacity(isDark ? 0.88 : 0.80),
borderRadius: BorderRadius.circular(24),
border: Border.all(color: borderColor),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: child,
),
),
);
}

// ------------------------------------------------------------
// HEADER
// ------------------------------------------------------------

Widget _header() {
return Padding(
padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
child: Row(
children: [
_iconButton(
icon: Icons.arrow_back_ios_new_rounded,
onTap: () => Navigator.maybePop(context),
),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Settings',
style: TextStyle(
color: primaryText,
fontSize: 25,
fontWeight: FontWeight.w900,
letterSpacing: -0.6,
),
),
const SizedBox(height: 4),
Text(
'Manage your PikkX experience',
style: TextStyle(
color: secondaryText,
fontSize: 12,
),
),
],
),
),
if (isSaving)
SizedBox(
height: 20,
width: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
color: accent,
),
),
],
),
);
}

Widget _iconButton({
required IconData icon,
required VoidCallback onTap,
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
color: cardColor,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: borderColor),
),
child: Icon(icon, color: primaryText, size: 19),
),
),
);
}

// ------------------------------------------------------------
// SECTION HEADING
// ------------------------------------------------------------

Widget _sectionTitle(String title, {String? subtitle}) {
return Padding(
padding: const EdgeInsets.only(left: 4, bottom: 10),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
color: primaryText,
fontSize: 15,
fontWeight: FontWeight.w900,
),
),
if (subtitle != null) ...[
const SizedBox(height: 3),
Text(
subtitle,
style: TextStyle(
color: secondaryText,
fontSize: 11,
),
),
],
],
),
);
}

Widget _section({
required String title,
String? subtitle,
required Widget child,
}) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_sectionTitle(title, subtitle: subtitle),
_glass(child: child),
],
);
}

Widget _separator() {
return Divider(
height: 1,
thickness: 1,
indent: 72,
color: borderColor,
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
Widget? trailing,
}) {
return ListTile(
onTap: onTap,
contentPadding: const EdgeInsets.symmetric(
horizontal: 15,
vertical: 5,
),
leading: Container(
height: 44,
width: 44,
decoration: BoxDecoration(
color: accent.withOpacity(isDark ? 0.18 : 0.08),
borderRadius: BorderRadius.circular(15),
),
child: Icon(icon, color: accent, size: 21),
),
title: Text(
title,
style: TextStyle(
color: primaryText,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
subtitle: Padding(
padding: const EdgeInsets.only(top: 4),
child: Text(
subtitle,
style: TextStyle(
color: secondaryText,
fontSize: 11,
),
),
),
trailing: trailing ??
Icon(
Icons.arrow_forward_ios_rounded,
color: secondaryText,
size: 14,
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
vertical: 5,
),
leading: Container(
height: 44,
width: 44,
decoration: BoxDecoration(
color: accent.withOpacity(isDark ? 0.18 : 0.08),
borderRadius: BorderRadius.circular(15),
),
child: Icon(icon, color: accent, size: 21),
),
title: Text(
title,
style: TextStyle(
color: primaryText,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
subtitle: Padding(
padding: const EdgeInsets.only(top: 4),
child: Text(
subtitle,
style: TextStyle(
color: secondaryText,
fontSize: 11,
),
),
),
trailing: Switch.adaptive(
value: value,
onChanged: enabled ? onChanged : null,
activeTrackColor: accent,
),
);
}

// ------------------------------------------------------------
// APPEARANCE
// ------------------------------------------------------------

Widget _appearanceSection() {
return _section(
title: 'Appearance',
subtitle: 'Choose how PikkX looks on your device',
child: Column(
children: [
_actionTile(
icon: isDark
? Icons.dark_mode_rounded
: Icons.light_mode_rounded,
title: 'Dark mode',
subtitle: isDark
? 'Dark appearance is enabled'
: 'Use a darker appearance',
trailing: Switch.adaptive(
value: isDark,
activeTrackColor: accent,
onChanged: (value) async {
await _themeController.setDarkMode(value);
},
),
onTap: () async {
await _themeController.setDarkMode(!isDark);
},
),
_separator(),
Padding(
padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Accent colour',
style: TextStyle(
color: primaryText,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 5),
Text(
'Choose a coordinated colour for supported app controls.',
style: TextStyle(
color: secondaryText,
fontSize: 11,
),
),
const SizedBox(height: 16),
Wrap(
spacing: 10,
runSpacing: 14,
children: AppThemeController.accentColors.entries.map(
(entry) {
final selected =
_themeController.accentTheme == entry.key;

                  return SizedBox(
                    width: 88,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () async {
                        await _themeController.setAccentTheme(entry.key);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? primaryText
                                      : borderColor,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 23,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              AppThemeController.accentNames[entry.key] ??
                                  entry.key,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    ],
  ),
);

}

// ------------------------------------------------------------
// BUILD
// ------------------------------------------------------------

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: _themeController,
builder: (context, _) {
return Scaffold(
backgroundColor: pageBackground,
body: SafeArea(
child: Stack(
children: [
Positioned(
top: -110,
right: -90,
child: IgnorePointer(
child: Container(
height: 250,
width: 250,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: accent.withOpacity(0.045),
),
),
),
),
Column(
children: [
_header(),
Expanded(
child: isLoading
? Center(
child: CircularProgressIndicator(
color: accent,
),
)
: RefreshIndicator(
color: accent,
onRefresh: _loadSettings,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
padding: const EdgeInsets.fromLTRB(
20, 0, 20, 35,
),
children: [
// APPEARANCE
_appearanceSection(),
const SizedBox(height: 25),

                              // NOTIFICATIONS
                              _section(
                                title: 'Notifications',
                                subtitle:
                                    'Choose the updates you want to receive',
                                child: Column(
                                  children: [
                                    _switchTile(
                                      icon: Icons.notifications_none_rounded,
                                      title: 'Notifications',
                                      subtitle:
                                          'Enable or disable notification preferences',
                                      value: notificationsEnabled,
                                      onChanged: _changeNotifications,
                                    ),
                                    _separator(),
                                    _switchTile(
                                      icon: Icons.local_shipping_outlined,
                                      title: 'Order updates',
                                      subtitle:
                                          'Preferences for order-related alerts',
                                      value: orderUpdates,
                                      enabled: notificationsEnabled,
                                      onChanged: _changeOrderUpdates,
                                    ),
                                    _separator(),
                                    _switchTile(
                                      icon: Icons.local_offer_outlined,
                                      title: 'Promotions',
                                      subtitle:
                                          'Preferences for offers and promotions',
                                      value: promotionalNotifications,
                                      enabled: notificationsEnabled,
                                      onChanged:
                                          _changePromotionalNotifications,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 25),

                              // ACCOUNT
                              _section(
                                title: 'Account',
                                subtitle:
                                    'Manage your profile and purchases',
                                child: Column(
                                  children: [
                                    _actionTile(
                                      icon: Icons.person_outline_rounded,
                                      title: 'Profile',
                                      subtitle:
                                          'Manage your PikkX profile',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context, '/profile',
                                        );
                                      },
                                    ),
                                    _separator(),
                                    _actionTile(
                                      icon: Icons.location_on_outlined,
                                      title: 'Delivery Addresses',
                                      subtitle:
                                          'Manage your saved addresses',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context, '/delivery-address',
                                        );
                                      },
                                    ),
                                    _separator(),
                                    _actionTile(
                                      icon: Icons.shopping_bag_outlined,
                                      title: 'My Orders',
                                      subtitle:
                                          'View active and previous orders',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context, '/orders',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 25),

                              // SUPPORT — ABOUT AND LICENSES REMOVED
                              _section(
                                title: 'Support',
                                subtitle:
                                    'We are here if you need assistance',
                                child: _actionTile(
                                  icon: Icons.support_agent_rounded,
                                  title: 'Help & Support',
                                  subtitle:
                                      'Contact PikkX support on WhatsApp',
                                  onTap: _openSupport,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // SIGN OUT
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryText,
                                    side: BorderSide(
                                      color: borderColor,
                                    ),
                                    backgroundColor: cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Text(
                                  'PikkX • 1.0.0',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
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
  },
);

}
}