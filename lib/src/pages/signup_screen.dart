import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ============================================================
  // pikkX THEME
  // ============================================================

  static const Color pikkXBlack =
      Color(0xFF050505);

  static const Color pikkXWhite =
      Color(0xFFFFFFFF);

  static const Color pikkXNavy =
      Color(0xFF10233F);

  static const Color background =
      Color(0xFFF7F7F7);

  static const Color mutedText =
      Color(0xFF777777);

  static const Color lightGrey =
      Color(0xFFE9E9E9);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // EMAIL SIGN UP
  // ============================================================

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      _showError(
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save name to Firebase Authentication.
      if (credential.user != null) {
        await credential.user!.updateDisplayName(
          _nameController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
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
  // GOOGLE
  // ============================================================

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleAuthProvider provider =
          GoogleAuthProvider();

      final UserCredential credential =
          await _auth.signInWithPopup(
        provider,
      );

      if (credential.user != null &&
          mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      _showError(
        'Google sign-up could not be completed.',
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
  // PHONE
  // ============================================================

  void _openPhoneSignUp() {
    Navigator.of(context).pushNamed(
      '/phone-signup',
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  void _openLogin() {
    Navigator.of(context).pushReplacementNamed(
      '/login',
    );
  }

  // ============================================================
  // FIREBASE ERRORS
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
        return 'Your password is too weak.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'This sign-up method is not enabled in Firebase.';

      default:
        return e.message ??
            'Unable to create your account.';
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: pikkXBlack,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
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
      borderRadius:
          BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.95),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.045),
                blurRadius: 20,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Container(
                margin:
                    const EdgeInsets.all(9),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pikkXNavy
                      .withOpacity(0.08),
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
                color: mutedText,
                fontSize: 13,
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
  // SOCIAL BUTTON
  // ============================================================

  Widget _socialButton({
    required Widget icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            _isLoading ? null : onTap,
        borderRadius:
            BorderRadius.circular(19),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(19),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(0.68),
                borderRadius:
                    BorderRadius.circular(19),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.92),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.035),
                    blurRadius: 18,
                    offset:
                        const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: pikkXBlack,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // ----------------------------------------------------
            // SUBTLE NAVY BACKGROUND GLOW
            // ----------------------------------------------------

            Positioned(
              top: -110,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXNavy
                      .withOpacity(0.055),
                ),
              ),
            ),

            Positioned(
              bottom: -110,
              left: -90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXNavy
                      .withOpacity(0.035),
                ),
              ),
            ),

            // ----------------------------------------------------
            // CONTENT
            // ----------------------------------------------------

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
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
                    // BACK BUTTON
                    // ------------------------------------------------

                    _glassBackButton(),

                    const SizedBox(height: 28),

                    // ------------------------------------------------
                    // pikkX BRAND
                    // ------------------------------------------------

                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withOpacity(0.72),
                              shape:
                                  BoxShape.circle,
                              border:
                                  Border.all(
                                color: Colors.white
                                    .withOpacity(0.95),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: pikkXNavy
                                      .withOpacity(
                                          0.10),
                                  blurRadius: 24,
                                  offset:
                                      const Offset(
                                    0,
                                    9,
                                  ),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'p',
                                style: TextStyle(
                                  color:
                                      pikkXBlack,
                                  fontSize: 34,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 11,
                          ),

                          RichText(
                            text:
                                const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'pikk',
                                  style:
                                      TextStyle(
                                    color:
                                        pikkXBlack,
                                    fontSize: 25,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: 'X',
                                  style:
                                      TextStyle(
                                    color:
                                        pikkXNavy,
                                    fontSize: 25,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ------------------------------------------------
                    // TITLE
                    // ------------------------------------------------

                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: pikkXBlack,
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Join pikkX and discover products from stores and sellers you can trust.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 25),

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
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // ------------------------------------------------
                    // EMAIL
                    // ------------------------------------------------

                    _glassField(
                      controller:
                          _emailController,
                      hint: 'Email address',
                      icon:
                          Icons.email_outlined,
                      keyboardType:
                          TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter your email.';
                        }

                        if (!value.contains('@')) {
                          return 'Enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

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
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          color: pikkXNavy,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Enter a password.';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

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
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          color: pikkXNavy,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
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

                    const SizedBox(height: 22),

                    // ------------------------------------------------
                    // CREATE ACCOUNT
                    // ------------------------------------------------

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _signUpWithEmail,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              pikkXBlack,
                          disabledBackgroundColor:
                              Colors.black
                                  .withOpacity(0.45),
                          elevation: 7,
                          shadowColor:
                              Colors.black
                                  .withOpacity(0.20),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              19,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
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
                            : const Text(
                                'Create Account',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 23),

                    // ------------------------------------------------
                    // DIVIDER
                    // ------------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.black
                                .withOpacity(0.08),
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            'OR SIGN UP WITH',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black
                                .withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // GOOGLE
                    // ------------------------------------------------

                    _socialButton(
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color:
                              Color(0xFF4285F4),
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      text:
                          'Continue with Google',
                      onTap:
                          _signUpWithGoogle,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // PHONE
                    // ------------------------------------------------

                    _socialButton(
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: pikkXNavy,
                        size: 20,
                      ),
                      text:
                          'Continue with Phone',
                      onTap:
                          _openPhoneSignUp,
                    ),

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
                              color: mutedText,
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: _openLogin,
                            child: const Text(
                              'Login',
                              style:
                                  TextStyle(
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

                    const SizedBox(height: 10),

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

  // ============================================================
  // GLASS BACK BUTTON
  // ============================================================

  Widget _glassBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
        },
        borderRadius:
            BorderRadius.circular(15),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(0.68),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.92),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset:
                        const Offset(0, 6),
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
}