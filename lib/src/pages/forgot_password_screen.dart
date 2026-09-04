import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _recoveryEmailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _newPasswordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _recoveryEmailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // RECOVERY
  // ============================================================

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    final recoveryEmail =
        _recoveryEmailController.text.trim();

    final currentPassword =
        _passwordController.text;

    final newPassword =
        _newPasswordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    if (recoveryEmail.isEmpty) {
      _showError('Enter your recovery email.');
      return;
    }

    if (!recoveryEmail.contains('@') ||
        !recoveryEmail.contains('.')) {
      _showError('Enter a valid recovery email.');
      return;
    }

    if (currentPassword.isEmpty) {
      _showError('Enter your current password.');
      return;
    }

    if (newPassword.length < 8) {
      _showError(
        'Your new password must contain at least 8 characters.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('New passwords do not match.');
      return;
    }

    if (newPassword == currentPassword) {
      _showError(
        'Your new password must be different from your current password.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // FIND ACCOUNT USING THE STORED RECOVERY EMAIL
      // ----------------------------------------------------------

      final QuerySnapshot<Map<String, dynamic>> users =
          await _firestore
              .collection('users')
              .where(
                'recoveryEmail',
                isEqualTo: recoveryEmail,
              )
              .limit(1)
              .get();

      if (users.docs.isEmpty) {
        _showError(
          'No account was found with this recovery email.',
        );
        return;
      }

      final userData = users.docs.first.data();

      final String? accountEmail =
          userData['email']?.toString();

      if (accountEmail == null ||
          accountEmail.isEmpty) {
        _showError(
          'This account is missing its login email.',
        );
        return;
      }

      // ----------------------------------------------------------
      // SIGN IN USING THE ACCOUNT EMAIL + CURRENT PASSWORD
      // ----------------------------------------------------------

      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: accountEmail,
        password: currentPassword,
      );

      final User? user = credential.user;

      if (user == null) {
        _showError(
          'Unable to verify your account.',
        );
        return;
      }

      // ----------------------------------------------------------
      // CHANGE PASSWORD
      // ----------------------------------------------------------

      await user.updatePassword(newPassword);

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      if (!mounted) return;

      _showSuccess(
        'Your password has been changed successfully.',
      );

      await Future.delayed(
        const Duration(milliseconds: 900),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      debugPrint(
        'PikkX password recovery error: $e',
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
  // FIREBASE ERRORS
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'The account email is invalid.';

      case 'user-not-found':
        return 'The account could not be found.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The current password is incorrect.';

      case 'weak-password':
        return 'Your new password is too weak.';

      case 'requires-recent-login':
        return 'Please sign in again before changing your password.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      default:
        return e.message ??
            'Unable to change your password.';
    }
  }

  // ============================================================
  // BACK TO LOGIN
  // ============================================================

  void _backToLogin() {
    if (_isLoading) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
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
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccess(String message) {
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
          backgroundColor: pikkXNavy,
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
            color: pikkXWhite.withOpacity(0.60),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.88),
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
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: !_isLoading,
            keyboardType: keyboardType,
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
                  color: pikkXNavy.withOpacity(0.08),
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
  // RESET BUTTON
  // ============================================================

  Widget _resetButton() {
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
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: pikkXNavy.withOpacity(0.98),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.12),
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
                  : _resetPassword,
              borderRadius: BorderRadius.circular(19),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: pikkXWhite,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_reset_rounded,
                            color: pikkXWhite,
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              color: pikkXWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
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
  // SECURITY CARD
  // ============================================================

  Widget _securityCard() {
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
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.78),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: pikkXNavy,
                size: 22,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure password recovery',
                      style: TextStyle(
                        color: pikkXBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your current password is required before PikkX allows a new password to be created.',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 10.5,
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -75,
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
              bottom: -120,
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
                  // ------------------------------------------------
                  // BACK BUTTON
                  // ------------------------------------------------

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 12,
                        sigmaY: 12,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _backToLogin,
                          borderRadius:
                              BorderRadius.circular(15),
                          child: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: pikkXWhite
                                  .withOpacity(0.58),
                              borderRadius:
                                  BorderRadius.circular(15),
                              border: Border.all(
                                color: pikkXWhite
                                    .withOpacity(0.88),
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .arrow_back_ios_new_rounded,
                              size: 18,
                              color: pikkXBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

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
                                color: pikkXWhite
                                    .withOpacity(0.58),
                                borderRadius:
                                    BorderRadius.circular(24),
                                border: Border.all(
                                  color: pikkXWhite
                                      .withOpacity(0.9),
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

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      color: pikkXBlack,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Recover your PikkX account and create a new password.',
                    style: TextStyle(
                      color: pikkXGrey,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 25),

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
                  ),

                  const SizedBox(height: 13),

                  // ------------------------------------------------
                  // CURRENT PASSWORD
                  // ------------------------------------------------

                  _glassField(
                    controller: _passwordController,
                    hint: 'Current password',
                    icon:
                        Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
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
                        color: pikkXGrey,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // ------------------------------------------------
                  // SECURITY CARD
                  // ------------------------------------------------

                  _securityCard(),

                  const SizedBox(height: 17),

                  // ------------------------------------------------
                  // NEW PASSWORD
                  // ------------------------------------------------

                  _glassField(
                    controller:
                        _newPasswordController,
                    hint: 'New password',
                    icon:
                        Icons.lock_reset_rounded,
                    obscureText:
                        _obscureNewPassword,
                    suffix: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscureNewPassword =
                                    !_obscureNewPassword;
                              });
                            },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color: pikkXGrey,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // ------------------------------------------------
                  // CONFIRM NEW PASSWORD
                  // ------------------------------------------------

                  _glassField(
                    controller:
                        _confirmPasswordController,
                    hint: 'Confirm new password',
                    icon:
                        Icons.lock_reset_rounded,
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
                        color: pikkXGrey,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Padding(
                    padding:
                        EdgeInsets.only(left: 4),
                    child: Text(
                      'Use at least 8 characters for your new password.',
                      style: TextStyle(
                        color: pikkXGrey,
                        fontSize: 10.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 21),

                  // ------------------------------------------------
                  // RESET
                  // ------------------------------------------------

                  _resetButton(),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // BACK TO LOGIN
                  // ------------------------------------------------

                  Center(
                    child: GestureDetector(
                      onTap: _backToLogin,
                      child: const Text(
                        'Back to Log In',
                        style: TextStyle(
                          color: pikkXNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

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