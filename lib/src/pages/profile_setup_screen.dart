import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce_app/src/pages/mainPage.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _profileImage;
  // ============================================================
  // pikkX THEME
  // ============================================================

  static const Color pikkXBlack =
      Color(0xFF050505);

  static const Color pikkXWhite =
      Color(0xFFFFFFFF);

  static const Color background =
      Color(0xFFF7F7F7);

  static const Color cardWhite =
      Color(0xFFFFFFFF);

  static const Color pikkXNavy =
      Color(0xFF10233F);

  static const Color darkText =
      Color(0xFF050505);

  static const Color mutedText =
      Color(0xFF737373);

  static const Color lightGrey =
      Color(0xFFE7E7E7);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final FocusNode _nameFocus =
      FocusNode();

  final FocusNode _usernameFocus =
      FocusNode();

  final FocusNode _emailFocus =
      FocusNode();

  String? _selectedCountry;

  bool _loading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();

    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();

    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');
    await ref.putData(await _profileImage!.readAsBytes());
    return ref.getDownloadURL();
  }

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your name.');
      _nameFocus.requestFocus();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in again.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'country': _selectedCountry ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(
        _nameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage(
        'Could not save your profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainPage(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: pikkXBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // GLASS FIELD
  // ============================================================

  Widget _glassField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.64),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: darkText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Container(
                margin: const EdgeInsets.all(9),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pikkXNavy.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: pikkXNavy,
                  size: 19,
                ),
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COUNTRY SELECTOR
  // ============================================================

  Widget _countrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.64),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: pikkXNavy.withOpacity(0.09),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: pikkXNavy,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Country',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _selectedCountry ??
                            'Select your country',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: pikkXNavy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COUNTRY PICKER
  // ============================================================

  void _showCountryPicker() {
    final List<String> countries = [
      'Nigeria',
      'Ghana',
      'Kenya',
      'South Africa',
      'United Kingdom',
      'United States',
      'Canada',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                25,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius:
                    const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.white,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: lightGrey,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose your country',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...countries.map(
                      (country) {
                        final bool selected =
                            _selectedCountry ==
                                country;

                        return ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: pikkXNavy
                                  .withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.public_rounded,
                              color: pikkXNavy,
                              size: 19,
                            ),
                          ),
                          title: Text(
                            country,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color: pikkXNavy,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCountry =
                                  country;
                            });

                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE ICON
  // ============================================================

  Widget _profileIcon() {
    return _glassContainer(
      padding: const EdgeInsets.all(15),
      child: const SizedBox(
        width: 58,
        height: 58,
        child: Icon(
          Icons.person_outline_rounded,
          color: pikkXNavy,
          size: 38,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _profileCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about you',
            style: TextStyle(
              color: darkText,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'A few details will help us personalize your pikkX experience.',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          _glassField(
            controller: _nameController,
            focusNode: _nameFocus,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 13),

          _glassField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            hint: 'Username',
            icon: Icons.alternate_email_rounded,
          ),

          const SizedBox(height: 13),

          _glassField(
            controller: _emailController,
            focusNode: _emailFocus,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
          ),

          const SizedBox(height: 13),

          _countrySelector(),

          const SizedBox(height: 22),

          // ----------------------------------------------------
          // CONTINUE
          // ----------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed:
                  _loading ? null : _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: pikkXBlack,
                disabledBackgroundColor:
                    pikkXBlack.withOpacity(0.45),
                elevation: 6,
                shadowColor:
                    Colors.black.withOpacity(0.20),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------
          // SKIP
          // ----------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 45,
            child: TextButton(
              onPressed:
                  _loading ? null : _skip,
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // --------------------------------------------------
            // SUBTLE NAVY BACKGROUND GLOW
            // --------------------------------------------------

            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXNavy.withOpacity(0.045),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXNavy.withOpacity(0.035),
                ),
              ),
            ),

            // --------------------------------------------------
            // CONTENT
            // --------------------------------------------------

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                25,
                22,
                35,
              ),
              child: Column(
                children: [
                  _profileIcon(),

                  const SizedBox(height: 17),

                  const Text(
                    'Complete your profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkText,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Welcome to pikkX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pikkXNavy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 25),

                  _profileCard(),

                  const SizedBox(height: 20),

                  const Text(
                    'You can update your profile later in Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}