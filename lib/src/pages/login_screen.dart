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

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

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
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  Future<void> _loginWithEmail() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Login error: $e');

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
  // GOOGLE LOGIN
  //
  // IMPORTANT:
  // For Android/iOS, the Google provider must be configured
  // correctly in Firebase. This uses FirebaseAuth directly.
  // ============================================================

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleAuthProvider provider =
          GoogleAuthProvider();

      provider.setCustomParameters({
        'prompt': 'select_account',
      });

      /*
       * This works for Firebase web.
       *
       * On Android/iOS, use the Google Sign-In package
       * and create a Firebase credential from the Google
       * account before calling signInWithCredential().
       *
       * Keeping this method separate makes that connection
       * easy to replace without changing the UI.
       */

      final UserCredential result =
          await _auth.signInWithPopup(provider);

      if (result.user != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Google login error: $e');

      _showError(
        'Google sign-in could not be completed.',
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
  // PHONE LOGIN
  // ============================================================

  void _openPhoneLogin() {
    if (_isLoading) return;

    Navigator.of(context).pushNamed(
      '/phone-login',
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  void _openForgotPassword() {
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

    Navigator.of(context).pushNamed(
      '/signup',
    );
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
        return 'This sign-in method is not enabled in Firebase.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';

      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';

      default:
        return e.message ??
            'Unable to sign in. Please try again.';
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: pikkXWhite.withOpacity(0.78),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: pikkXWhite.withOpacity(0.95),
          width: 1.2,
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
        validator: validator,
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
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
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
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.035),
                blurRadius: 17,
                offset: const Offset(0, 7),
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
                  fontWeight: FontWeight.w700,
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
            // ==================================================
            // SUBTLE GLASS BACKGROUND SHAPES
            // ==================================================

            Positioned(
              top: -90,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXNavy.withOpacity(0.035),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.025),
                ),
              ),
            ),

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
                          Container(
                            height: 82,
                            width: 82,
                            padding:
                                const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: pikkXWhite.withOpacity(0.82),
                              borderRadius:
                                  BorderRadius.circular(24),
                              border: Border.all(
                                color: pikkXWhite,
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
                              'assets/images/pikkx_icon(1).png',
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) {
                                return const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: pikkXNavy,
                                  size: 38,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 13),

                          const Text(
                            'pikkX',
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
                      'Sign in to continue shopping with pikkX.',
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
                      hint: 'Email address',
                      icon: Icons.email_outlined,
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

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    _glassField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon:
                          Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: pikkXNavy,
                          size: 20,
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
                          return 'Enter your password.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 5),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _openForgotPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: pikkXNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _loginWithEmail,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: pikkXBlack,
                          disabledBackgroundColor:
                              pikkXBlack.withOpacity(0.45),
                          foregroundColor: pikkXWhite,
                          elevation: 7,
                          shadowColor:
                              pikkXBlack.withOpacity(0.20),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                    pikkXWhite,
                                  ),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: pikkXWhite,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // DIVIDER
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                pikkXBlack.withOpacity(0.10),
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
                              color: pikkXGrey,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color:
                                pikkXBlack.withOpacity(0.10),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 19),

                    // ==================================================
                    // GOOGLE
                    // ==================================================

                    _socialButton(
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      text: 'Continue with Google',
                      onTap: _loginWithGoogle,
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PHONE
                    // ==================================================

                    _socialButton(
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: pikkXNavy,
                        size: 20,
                      ),
                      text: 'Continue with Phone',
                      onTap: _openPhoneLogin,
                    ),

                    const SizedBox(height: 26),

                    // ==================================================
                    // SIGN UP
                    // ==================================================

                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
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

                    const SizedBox(height: 12),

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
            ),
          ],
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
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: pikkXWhite.withOpacity(0.76),
        shape: BoxShape.circle,
        border: Border.all(
          color: pikkXWhite,
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
        icon: Icon(
          icon,
          size: 17,
          color: pikkXNavy,
        ),
      ),
    );
  }
}