import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

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
    if (!_formKey.currentState.validate()) {
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save the user's name in their Firebase profile.
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
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      _showError(
        'Something went wrong. Please try again.',
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
      GoogleAuthProvider provider =
          GoogleAuthProvider();

      UserCredential credential =
          await _auth.signInWithPopup(provider);

      if (credential.user != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      _showError(
        'Google sign-up could not be completed.',
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
        return 'Your password is too weak.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'This sign-up method has not been enabled in Firebase.';

      default:
        return e.message ??
            'Unable to create your account.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF30243D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // FLOATING GLASS FIELD
  // ============================================================

  Widget _glassField({
    TextEditingController controller,
    String hint,
    IconData icon,
    bool obscureText = false,
    Widget suffix,
    TextInputType keyboardType,
    String Function(String) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D61C5)
                .withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF8D61C5),
          ),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9B91A5),
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
    Widget icon,
    String text,
    VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.68),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.035),
                blurRadius: 18,
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
                  color: Color(0xFF30243D),
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
      backgroundColor:
          const Color(0xFFF7F2FF),
      body: SafeArea(
        child: Stack(
          children: [

            // Background floating glow
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB98BEF)
                      .withOpacity(0.13),
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
                  color: const Color(0xFFD8BFFF)
                      .withOpacity(0.18),
                ),
              ),
            ),

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                24,
                25,
                24,
                35,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    // BACK
                    _glassBackButton(),

                    const SizedBox(height: 30),

                    // BRAND
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withOpacity(0.72),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.95),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(
                                    0xFF8D61C5,
                                  ).withOpacity(0.12),
                                  blurRadius: 24,
                                  offset:
                                      const Offset(0, 9),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🍇',
                                style: TextStyle(
                                  fontSize: 33,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Grape',
                                  style: TextStyle(
                                    color:
                                        Color(0xFF30243D),
                                    fontSize: 24,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Go',
                                  style: TextStyle(
                                    color:
                                        Color(0xFF8D61C5),
                                    fontSize: 24,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: Color(0xFF30243D),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Join Grape Go and start discovering products you love.',
                      style: TextStyle(
                        color: Color(0xFF8F8499),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // NAME
                    _glassField(
                      controller:
                          _nameController,
                      hint: 'Full name',
                      icon:
                          Icons.person_outline_rounded,
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

                    // EMAIL
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

                    // PASSWORD
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
                          color:
                              const Color(0xFF8D61C5),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                      ),
                      keyboardType:
                          TextInputType.text,
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

                    // CONFIRM PASSWORD
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
                          color:
                              const Color(0xFF8D61C5),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      keyboardType:
                          TextInputType.text,
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

                    // CREATE ACCOUNT
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
                              const Color(0xFF8D61C5),
                          disabledBackgroundColor:
                              const Color(0xFFBFA4DC),
                          elevation: 8,
                          shadowColor:
                              const Color(0xFF8D61C5)
                                  .withOpacity(0.25),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    19),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 23),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white
                                .withOpacity(0.9),
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
                              color:
                                  Color(0xFF9B91A5),
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white
                                .withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // GOOGLE
                    _socialButton(
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
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

                    // PHONE
                    _socialButton(
                      icon: const Icon(
                        Icons.phone_rounded,
                        color:
                            Color(0xFF8D61C5),
                        size: 20,
                      ),
                      text:
                          'Continue with Phone',
                      onTap:
                          _openPhoneSignUp,
                    ),

                    const SizedBox(height: 25),

                    // LOGIN
                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color:
                                  Color(0xFF8F8499),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: _openLogin,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color:
                                    Color(0xFF8D61C5),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w800,
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
                          color:
                              Color(0xFFA79DAF),
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
  // BACK BUTTON
  // ============================================================

  Widget _glassBackButton() {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
        ),
        color: const Color(0xFF30243D),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}