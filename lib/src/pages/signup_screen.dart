import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/pages/profile_setup_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _recoveryEmailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _recoveryEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<void> _signUpWithEmail() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final recoveryEmail =
        _recoveryEmailController.text.trim();
    final password = _passwordController.text;

    if (email.toLowerCase() ==
        recoveryEmail.toLowerCase()) {
      _showError(
        'Recovery email must be different from your main email.',
      );
      return;
    }

    if (password !=
        _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // CREATE FIREBASE ACCOUNT
      // ----------------------------------------------------------

      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception(
          'Firebase did not return a user.',
        );
      }

      // ----------------------------------------------------------
      // SAVE DISPLAY NAME
      // ----------------------------------------------------------

      await user.updateDisplayName(name);

      // ----------------------------------------------------------
      // SAVE USER PROFILE + RECOVERY EMAIL
      // ----------------------------------------------------------
      //
      // IMPORTANT:
      // Firebase Auth's standard password-reset system
      // still uses the main account email.
      //
      // This recovery email is securely stored in the
      // user's Firestore profile so PikkX can use it for
      // a future verified recovery system.
      //
      // ----------------------------------------------------------

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name': name,
          'email': email,
          'recoveryEmail': recoveryEmail,
          'recoveryEmailVerified': false,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ----------------------------------------------------------
      // CONTINUE TO PROFILE SETUP
      // ----------------------------------------------------------

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const ProfileSetupScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      debugPrint(
        'PikkX signup error: $e',
      );

      _showError(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  void _openLogin() {
    if (_isLoading) return;

    Navigator.of(context).pushReplacementNamed(
      '/login',
    );
  }

  // ============================================================
  // TERMS
  // ============================================================

  void _openTerms() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed('/terms');
  }

  // ============================================================
  // PRIVACY
  // ============================================================

  void _openPrivacy() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed('/privacy');
  }

  // ============================================================
  // FIREBASE ERROR MESSAGES
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Your password is too weak. Use a stronger password.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email and password sign-up is not enabled in Firebase.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return e.message ??
            'Unable to create your account.';
    }
  }

  // ============================================================
  // ERROR SNACKBAR
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
    FormFieldValidator<String>? validator,
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
            color: pikkXWhite.withOpacity(0.60),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.88),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            enabled: !_isLoading,
            cursorColor: pikkXNavy,
            style: const TextStyle(
              color: pikkXBlack,
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
                  color:
                      pikkXNavy.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: pikkXNavy,
                  size: 19,
                ),
              ),
              suffixIcon: suffix,
              hintText: hint,
              hintStyle: const TextStyle(
                color: pikkXGrey,
                fontSize: 13,
              ),
              errorStyle: const TextStyle(
                color: pikkXNavy,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
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

  Widget _glassButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pikkXNavy.withOpacity(0.94),
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color: pikkXNavy.withOpacity(0.98),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : _signUpWithEmail,
              borderRadius:
                  BorderRadius.circular(19),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: pikkXWhite,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .person_add_alt_1_rounded,
                            color: pikkXWhite,
                            size: 19,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: pikkXWhite,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
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

  // ============================================================
  // PREMIUM RECOVERY CARD
  // ============================================================

  Widget _recoveryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.48),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.78),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      pikkXNavy.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: pikkXNavy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure account recovery',
                      style: TextStyle(
                        color: pikkXBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add a separate recovery email to help protect your PikkX account.',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget _glassBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            borderRadius:
                BorderRadius.circular(15),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color:
                    pikkXWhite.withOpacity(0.58),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      pikkXWhite.withOpacity(0.88),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        pikkXBlack.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: pikkXBlack,
              ),
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
            // ----------------------------------------------------
            // BACKGROUND GLOW
            // ----------------------------------------------------

            Positioned(
              top: -100,
              right: -75,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      pikkXNavy.withOpacity(0.055),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -90,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      pikkXBlack.withOpacity(0.035),
                ),
              ),
            ),

            // ----------------------------------------------------
            // CONTENT
            // ----------------------------------------------------

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                35,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // BACK
                    // ------------------------------------------------

                    _glassBackButton(),

                    const SizedBox(height: 27),

                    // ------------------------------------------------
                    // LOGO
                    // ------------------------------------------------

                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(
                                sigmaX: 16,
                                sigmaY: 16,
                              ),
                              child: Container(
                                height: 82,
                                width: 82,
                                padding:
                                    const EdgeInsets.all(
                                  10,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: pikkXWhite
                                      .withOpacity(0.58),
                                  borderRadius:
                                      BorderRadius.circular(
                                    24,
                                  ),
                                  border: Border.all(
                                    color: pikkXWhite
                                        .withOpacity(0.9),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: pikkXBlack
                                          .withOpacity(
                                        0.055,
                                      ),
                                      blurRadius: 24,
                                      offset:
                                          const Offset(
                                        0,
                                        9,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/pikkx_icon (1).png',
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (_, __, ___) {
                                    return const Icon(
                                      Icons
                                          .storefront_rounded,
                                      color: pikkXNavy,
                                      size: 38,
                                    );
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
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ------------------------------------------------
                    // TITLE
                    // ------------------------------------------------

                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: pikkXBlack,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Join PikkX and build a secure shopping account.',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------------------------------------------
                    // NAME
                    // ------------------------------------------------

                    _glassField(
                      controller:
                          _nameController,
                      hint: 'Full name',
                      icon: Icons
                          .person_outline_rounded,
                      keyboardType:
                          TextInputType.name,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your name.';
                        }

                        if (value.trim().length <
                            2) {
                          return 'Enter your full name.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 13),

                    // ------------------------------------------------
                    // MAIN EMAIL
                    // ------------------------------------------------

                    _glassField(
                      controller:
                          _emailController,
                      hint: 'Email or Gmail',
                      icon:
                          Icons.email_outlined,
                      keyboardType:
                          TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your email.';
                        }

                        final email =
                            value.trim();

                        if (!email.contains('@') ||
                            !email.contains('.')) {
                          return 'Enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 13),

                    // ------------------------------------------------
                    // RECOVERY EMAIL
                    // ------------------------------------------------

                    _glassField(
                      controller:
                          _recoveryEmailController,
                      hint: 'Recovery email',
                      icon:
                          Icons.mark_email_read_outlined,
                      keyboardType:
                          TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter a recovery email.';
                        }

                        final recovery =
                            value.trim();

                        if (!recovery.contains('@') ||
                            !recovery.contains('.')) {
                          return 'Enter a valid recovery email.';
                        }

                        if (recovery.toLowerCase() ==
                            _emailController.text
                                .trim()
                                .toLowerCase()) {
                          return 'Use a different email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 9),

                    const Padding(
                      padding:
                          EdgeInsets.only(left: 4),
                      child: Text(
                        'Use an email you can access if you ever need account recovery.',
                        style: TextStyle(
                          color: pikkXGrey,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // RECOVERY CARD
                    // ------------------------------------------------

                    _recoveryCard(),

                    const SizedBox(height: 17),

                    // ------------------------------------------------
                    // PASSWORD
                    // ------------------------------------------------

                    _glassField(
                      controller:
                          _passwordController,
                      hint: 'Password',
                      icon:
                          Icons.lock_outline_rounded,
                      obscureText:
                          _obscurePassword,
                      suffix: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          color: pikkXNavy,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Create a password.';
                        }

                        if (value.length < 8) {
                          return 'Use at least 8 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 13),

                    // ------------------------------------------------
                    // CONFIRM PASSWORD
                    // ------------------------------------------------

                    _glassField(
                      controller:
                          _confirmPasswordController,
                      hint: 'Confirm password',
                      icon:
                          Icons.lock_outline_rounded,
                      obscureText:
                          _obscureConfirmPassword,
                      suffix: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          color: pikkXNavy,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Confirm your password.';
                        }

                        if (value !=
                            _passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    const Padding(
                      padding:
                          EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: pikkXNavy,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Your password is protected by Firebase Authentication.',
                              style: TextStyle(
                                color: pikkXGrey,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 21),

                    // ------------------------------------------------
                    // CREATE ACCOUNT
                    // ------------------------------------------------

                    _glassButton(),

                    const SizedBox(height: 25),

                    // ------------------------------------------------
                    // LOGIN
                    // ------------------------------------------------

                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: pikkXGrey,
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: _openLogin,
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: pikkXNavy,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 21),

                    // ------------------------------------------------
                    // TERMS
                    // ------------------------------------------------

                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
                        children: [
                          const Text(
                            'By creating an account, you agree to our ',
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
                                fontWeight:
                                    FontWeight.w800,
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
                                fontWeight:
                                    FontWeight.w800,
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

                    // ------------------------------------------------
                    // SECURITY FOOTER
                    // ------------------------------------------------

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
            ),
          ],
        ),
      ),
    );
  }
}