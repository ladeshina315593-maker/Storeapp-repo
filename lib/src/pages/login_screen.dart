import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // EMAIL / PASSWORD LOGIN
  // ============================================================

  Future<void> _loginWithEmail() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Email login error: $e');
      _showError('Unable to sign in. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================
  //
  // Opens the custom PikkX recovery screen.
  // The actual recovery flow is handled there.
  //

  void _forgotPassword() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed(
      '/forgot-password',
    );
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  void _openSignUp() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed('/signup');
  }

  // ============================================================
  // TERMS & PRIVACY
  // ============================================================

  void _openTerms() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed('/terms');
  }

  void _openPrivacy() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed('/privacy');
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled in Firebase.';

      default:
        return e.message ??
            'Unable to sign in. Please try again.';
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: pikkXWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: pikkXBlack,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
  }

  // ============================================================
  // GLASS FIELD
  // ============================================================

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.58),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.85),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: pikkXNavy,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                icon,
                color: pikkXNavy,
                size: 21,
              ),
              suffixIcon: suffix,
              hintText: hint,
              hintStyle: const TextStyle(
                color: pikkXGrey,
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS BUTTON
  // ============================================================

  Widget _glassButton({
    required String text,
    required VoidCallback? onTap,
    bool primary = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            color: primary
                ? pikkXNavy.withOpacity(0.92)
                : pikkXWhite.withOpacity(0.58),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primary
                  ? pikkXNavy.withOpacity(0.95)
                  : pikkXWhite.withOpacity(0.85),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : onTap,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: _isLoading && primary
                    ? const SizedBox(
                        height: 21,
                        width: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: pikkXWhite,
                        ),
                      )
                    : Text(
                        text,
                        style: TextStyle(
                          color: primary
                              ? pikkXWhite
                              : pikkXBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS CIRCLE BUTTON
  // ============================================================

  Widget _glassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.58),
            shape: BoxShape.circle,
            border: Border.all(
              color: pikkXWhite.withOpacity(0.9),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onTap,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: pikkXNavy,
            ),
          ),
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
          children: [
            // ==================================================
            // GLASS BACKGROUND
            // ==================================================

            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXNavy.withOpacity(0.055),
                ),
              ),
            ),

            Positioned(
              bottom: -110,
              left: -90,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.035),
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
                22,
                24,
                35,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // BACK BUTTON
                  // ==================================================

                  _glassCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (!_isLoading) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // PIKKX LOGO
                  // ==================================================

                  Center(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 16,
                              sigmaY: 16,
                            ),
                            child: Container(
                              height: 82,
                              width: 82,
                              padding:
                                  const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    pikkXWhite.withOpacity(0.58),
                                borderRadius:
                                    BorderRadius.circular(24),
                                border: Border.all(
                                  color:
                                      pikkXWhite.withOpacity(0.9),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: pikkXBlack
                                        .withOpacity(0.055),
                                    blurRadius: 24,
                                    offset:
                                        const Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/pikkx_icon (1).png',
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (_, __, ___) {
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        const Text(
                          'PikkX',
                          style: TextStyle(
                            color: pikkXBlack,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 34),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: pikkXBlack,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Sign in to continue shopping with PikkX.',
                    style: TextStyle(
                      color: pikkXGrey,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 27),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  _glassField(
                    controller: _emailController,
                    hint: 'Email or Gmail',
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 13),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  _glassField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: pikkXGrey,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // FORGOT PASSWORD
                  // ==================================================

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: pikkXNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SIGN IN BUTTON
                  // ==================================================

                  _glassButton(
                    text: 'Sign In',
                    onTap: _loginWithEmail,
                    primary: true,
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // SIGN UP
                  // ==================================================

                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSignUp,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: pikkXNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // TERMS & PRIVACY
                  // ==================================================

                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'By continuing, you agree to our ',
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 9.5,
                          ),
                        ),

                        GestureDetector(
                          onTap: _openTerms,
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: pikkXNavy,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const Text(
                          ' and ',
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 9.5,
                          ),
                        ),

                        GestureDetector(
                          onTap: _openPrivacy,
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: pikkXNavy,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const Text(
                          '.',
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // FIREBASE NOTE
                  // ==================================================

                  const Center(
                    child: Text(
                      'Secure authentication powered by Firebase',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 9,
                      ),
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