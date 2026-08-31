import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // ============================================================
  // pikkX IDENTITY
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFF7F7F7);
  static const Color card = Color(0xFFFFFFFF);

  static const Color darkText = Color(0xFF050505);
  static const Color mutedText = Color(0xFF777777);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;

  // ============================================================
  // CHECK FIREBASE AUTH STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final User? user = _auth.currentUser;

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      });
    }
  }

  // ============================================================
  // GLASS BUTTON
  // ============================================================

  Widget _glassButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.black.withOpacity(0.05),
        highlightColor: Colors.black.withOpacity(0.025),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.055),
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

  // ============================================================
  // SOCIAL / SECONDARY BUTTON
  // ============================================================

  Widget _socialButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return _glassButton(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: pikkXBlack,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pikkXBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pikkXBlack,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: pikkXWhite,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: pikkXWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _logo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          height: 82,
          width: 82,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.72),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'p',
              style: TextStyle(
                color: pikkXBlack,
                fontSize: 43,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIREBASE MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

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
  // GOOGLE
  // ============================================================

  Future<void> _googleSignIn() async {
    _showMessage(
      'Google Sign-In will use Firebase Authentication once the Google provider is configured.',
    );
  }

  // ============================================================
  // FACEBOOK
  // ============================================================

  Future<void> _facebookSignIn() async {
    _showMessage(
      'Facebook Sign-In will use Firebase Authentication once the Facebook provider is configured.',
    );
  }

  // ============================================================
  // APPLE
  // ============================================================

  Future<void> _appleSignIn() async {
    _showMessage(
      'Apple Sign-In will use Firebase Authentication once the Apple provider is configured.',
    );
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  void _openSignIn() {
    Navigator.pushNamed(
      context,
      '/sign-in',
    );
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  void _openSignUp() {
    Navigator.pushNamed(
      context,
      '/sign-up',
    );
  }

  // ============================================================
  // PHONE AUTH
  // ============================================================

  void _openPhoneAuth() {
    Navigator.pushNamed(
      context,
      '/phone-auth',
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
            // ==================================================
            // SOFT GLASS BACKGROUND
            // ==================================================

            Positioned(
              top: -100,
              right: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.035),
                ),
              ),
            ),

            Positioned(
              bottom: -110,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.025),
                ),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                24,
                35,
                24,
                30,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  _logo(),

                  const SizedBox(height: 20),

                  const Text(
                    'Welcome to pikkX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkText,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Shop what you love, discover something new.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // GLASS AUTH PANEL
                  // ==================================================

                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18,
                        sigmaY: 18,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          22,
                          18,
                          22,
                        ),
                        decoration: BoxDecoration(
                          color: pikkXWhite.withOpacity(0.64),
                          borderRadius:
                              BorderRadius.circular(30),
                          border: Border.all(
                            color:
                                pikkXWhite.withOpacity(0.92),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  pikkXBlack.withOpacity(0.055),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Get started',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Choose how you want to continue',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // SIGN IN
                            _primaryButton(
                              text: 'Sign In',
                              onTap: _openSignIn,
                            ),

                            const SizedBox(height: 12),

                            // CREATE ACCOUNT
                            _glassButton(
                              onTap: _openSignUp,
                              child: const Center(
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: pikkXBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // DIVIDER
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: pikkXBlack
                                        .withOpacity(0.08),
                                  ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      color: mutedText,
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: pikkXBlack
                                        .withOpacity(0.08),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // GOOGLE
                            _socialButton(
                              icon: Icons.g_mobiledata_rounded,
                              text: 'Continue with Google',
                              onTap: _googleSignIn,
                            ),

                            const SizedBox(height: 10),

                            // PHONE
                            _socialButton(
                              icon: Icons.phone_rounded,
                              text: 'Continue with Phone',
                              onTap: _openPhoneAuth,
                            ),

                            const SizedBox(height: 10),

                            // FACEBOOK
                            _socialButton(
                              icon: Icons.facebook_rounded,
                              text: 'Continue with Facebook',
                              onTap: _facebookSignIn,
                            ),

                            const SizedBox(height: 10),

                            // APPLE
                            _socialButton(
                              icon: Icons.apple,
                              text: 'Continue with Apple',
                              onTap: _appleSignIn,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'By continuing, you agree to our Terms of Service\n'
                    'and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 10,
                      height: 1.5,
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