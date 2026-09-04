import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  String _name = 'Your Name';
  String _email = '';
  String _phone = '';
  String _photoUrl = '';

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
  // GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
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
              color: Colors.white.withOpacity(0.95),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _profileImage(),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.pikkXBlack,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],

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

          const SizedBox(width: 10),

          _editProfileButton(),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE + PENCIL BADGE
  // ============================================================

  Widget _profileImage() {
    return GestureDetector(
      onTap: _changeProfilePicture,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 76,
            width: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.82),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _defaultProfileIcon();
                      },
                    )
                  : _defaultProfileIcon(),
            ),
          ),

          // CLEAR PENCIL
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              height: 29,
              width: 29,
              decoration: BoxDecoration(
                color: AppTheme.pikkXBlack,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),

          if (_isUploadingPhoto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.42),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Icon(
        Icons.person_rounded,
        color: AppTheme.pikkXBlack,
        size: 38,
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE BUTTON
  // ============================================================

  Widget _editProfileButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openEditProfile,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_rounded,
                color: AppTheme.pikkXBlack,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: AppTheme.pikkXBlack,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE PROFILE PICTURE
  // ============================================================

  Future<void> _changeProfilePicture() async {
    final user = _auth.currentUser;

    if (user == null || _isUploadingPhoto) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final file = File(pickedFile.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      await storageRef.putFile(file);

      final downloadUrl =
          await storageRef.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'photoUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _photoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      _showMessage(
        'Profile picture updated successfully.',
      );
    } catch (e) {
      debugPrint('Profile picture upload error: $e');

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _showMessage(
        'Unable to update profile picture. Please try again.',
      );
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 9,
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
      padding: const EdgeInsets.only(bottom: 9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: _glassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.055),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.pikkXBlack,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    size: 14,
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
      builder: (sheetContext) {
        return _EditProfileSheet(
          currentName: _name,
          currentPhotoUrl: _photoUrl,
          onSave: _saveProfile,
          onChangePhoto: _changeProfilePicture,
          isUploadingPhoto: _isUploadingPhoto,
        );
      },
    );
  }

  Future<void> _saveProfile(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user.');
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Name cannot be empty.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'name': cleanName,
        'email': user.email ?? _email,
        'phone': user.phoneNumber ?? _phone,
        'photoUrl': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await user.updateDisplayName(cleanName);

    if (!mounted) return;

    setState(() {
      _name = cleanName;
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

  void _openFavourites() {
    Navigator.pushNamed(
      context,
      '/favourites',
    );
  }

  void _openSettings() {
    Navigator.pushNamed(
      context,
      '/settings',
    );
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
                  color: AppTheme.pikkXBlack,
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
          color: AppTheme.pikkXBlack,
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.pikkXBlack,
      onRefresh: _loadProfile,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          110,
        ),
        children: [
          _profileHeader(),

          const SizedBox(height: 18),

          _sectionTitle('Account'),

          _profileOption(
            icon: Icons.receipt_long_rounded,
            title: 'My Orders',
            subtitle: 'View your active and previous orders',
            onTap: _openOrders,
          ),

          _profileOption(
            icon: Icons.location_on_outlined,
            title: 'Delivery Addresses',
            subtitle: 'Manage your saved delivery addresses',
            onTap: _openAddresses,
          ),

          _profileOption(
            icon: Icons.favorite_outline_rounded,
            title: 'Favourites',
            subtitle: 'View your saved favourite products',
            onTap: _openFavourites,
          ),

          _profileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Manage your PikkX preferences',
            onTap: _openSettings,
          ),

          const SizedBox(height: 7),

          _sectionTitle('Security'),

          _profileOption(
            icon: Icons.lock_outline_rounded,
            title: 'Password & Security',
            subtitle: 'Manage your account security',
            onTap: _openSecurity,
          ),

          _profileOption(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle: 'Sign out of your PikkX account',
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
  final String currentPhotoUrl;
  final Future<void> Function(String name) onSave;
  final Future<void> Function() onChangePhoto;
  final bool isUploadingPhoto;

  const _EditProfileSheet({
    required this.currentName,
    required this.currentPhotoUrl,
    required this.onSave,
    required this.onChangePhoto,
    required this.isUploadingPhoto,
  });

  @override
  State<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState
    extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter your name.',
          ),
          backgroundColor: AppTheme.pikkXBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
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
      debugPrint('Save profile error: $e');

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to update profile. Please try again.',
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

  Widget _sheetProfileImage() {
    return GestureDetector(
      onTap: widget.isUploadingPhoto
          ? null
          : widget.onChangePhoto,
      child: Stack(
        children: [
          Container(
            height: 84,
            width: 84,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: widget.currentPhotoUrl.isNotEmpty
                  ? Image.network(
                      widget.currentPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color: const Color(0xFFF0F0F0),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppTheme.pikkXBlack,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFF0F0F0),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.pikkXBlack,
                        size: 40,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: AppTheme.pikkXBlack,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              14,
              20,
              24,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(
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
                      color: Colors.black.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppTheme.pikkXBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_rounded,
                      color: AppTheme.pikkXBlack,
                      size: 19,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Center(
                  child: Column(
                    children: [
                      _sheetProfileImage(),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the pencil to change your photo',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
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
                      color: AppTheme.pikkXBlack,
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

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.pikkXBlack,
                      disabledBackgroundColor:
                          const Color(0xFF777777),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
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
                        : const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 19,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
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