import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isLoading = true;

  String _name = 'Your Name';
  String _email = '';
  String _phone = '';
  String _photoUrl = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _name = 'Guest';
        _email = '';
        _phone = '';
        _photoUrl = '';
      });

      return;
    }

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      if (!mounted) return;

      setState(() {
        _name = data?['name']?.toString() ??
            user.displayName ??
            'Your Name';

        _email = data?['email']?.toString() ??
            user.email ??
            '';

        _phone = data?['phone']?.toString() ??
            user.phoneNumber ??
            '';

        _photoUrl = data?['photoUrl']?.toString() ??
            user.photoURL ??
            '';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile loading error: $e');

      if (!mounted) return;

      setState(() {
        _name = user.displayName ?? 'Your Name';
        _email = user.email ?? '';
        _phone = user.phoneNumber ?? '';
        _photoUrl = user.photoURL ?? '';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // GLASS FIXTURE
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
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
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
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

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _profileHeader() {
    return _glassContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _profileImage(),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.pikkXBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                if (_email.isNotEmpty)
                  Text(
                    _email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),

                if (_phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          _editButton(),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _profileImage() {
    return Container(
      height: 72,
      width: 72,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.78),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.pikkXNavy.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: _photoUrl.isNotEmpty
            ? Image.network(
                _photoUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return _defaultProfileIcon();
                },
              )
            : _defaultProfileIcon(),
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: const Color(0xFFF0F2F5),
      child: Icon(
        Icons.person_rounded,
        color: AppTheme.pikkXNavy,
        size: 38,
      ),
    );
  }

  // ============================================================
  // EDIT BUTTON
  // ============================================================

  Widget _editButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openEditProfile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          child: Icon(
            Icons.edit_rounded,
            color: AppTheme.pikkXNavy,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.pikkXBlack,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE OPTION
  // ============================================================

  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: _glassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.pikkXNavy.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.pikkXNavy,
                      size: 20,
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
                          style: TextStyle(
                            color: AppTheme.pikkXBlack,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.mutedText,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _EditProfileSheet(
          currentName: _name,
          onSave: _saveProfileName,
        );
      },
    );
  }

  Future<void> _saveProfileName(String name) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'name': name,
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await user.updateDisplayName(name);

    if (!mounted) return;

    setState(() {
      _name = name;
    });

    _showMessage('Profile updated successfully.');
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openOrders() {
    Navigator.pushNamed(
      context,
      '/orders',
    );
  }

  void _openAddresses() {
    Navigator.pushNamed(
      context,
      '/delivery-address',
    );
  }

  void _openSettings() {
    Navigator.pushNamed(
      context,
      '/settings',
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Log Out',
            style: TextStyle(
              color: AppTheme.pikkXBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: AppTheme.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.pikkXNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pikkXBlack,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      _showMessage(
        'Unable to log out. Please try again.',
      );
    }
  }

  // ============================================================
  // SECURITY
  // ============================================================

  void _openSecurity() {
    _showMessage(
      'Security settings will be connected here.',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.pikkXBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _content() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.pikkXNavy,
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.pikkXNavy,
      onRefresh: _loadProfile,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          120,
        ),
        children: [
          _profileHeader(),

          const SizedBox(height: 24),

          _sectionTitle('Account'),

          _profileOption(
            icon: Icons.receipt_long_rounded,
            title: 'My Orders',
            subtitle:
                'View your active and previous orders',
            onTap: _openOrders,
          ),

          _profileOption(
            icon: Icons.location_on_outlined,
            title: 'Delivery Addresses',
            subtitle:
                'Manage your saved delivery addresses',
            onTap: _openAddresses,
          ),

          _profileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle:
                'Manage your pikkX preferences',
            onTap: _openSettings,
          ),

          const SizedBox(height: 10),

          _sectionTitle('Security'),

          _profileOption(
            icon: Icons.lock_outline_rounded,
            title: 'Password & Security',
            subtitle:
                'Manage your account security',
            onTap: _openSecurity,
          ),

          _profileOption(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle:
                'Sign out of your pikkX account',
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7F7F7),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _content(),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// EDIT PROFILE SHEET
// ================================================================

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final Future<void> Function(String name) onSave;

  const _EditProfileSheet({
    required this.currentName,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState
    extends State<_EditProfileSheet> {
  late TextEditingController _nameController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.currentName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(name);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to update profile.',
          ),
          backgroundColor: AppTheme.pikkXBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              15,
              20,
              25,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(
                color: Colors.white,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.pikkXNavy
                          .withOpacity(0.20),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: AppTheme.pikkXBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _nameController,
                  textInputAction:
                      TextInputAction.done,
                  style: TextStyle(
                    color: AppTheme.pikkXBlack,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: AppTheme.mutedText,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.pikkXNavy,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.pikkXBlack,
                      disabledBackgroundColor:
                          const Color(0xFF777777),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}