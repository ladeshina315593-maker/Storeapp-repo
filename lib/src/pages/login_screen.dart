import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // EMAIL + PASSWORD LOGIN
  // ------------------------------------------------------------

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

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

  // ------------------------------------------------------------
  // GOOGLE
  // ------------------------------------------------------------

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      GoogleAuthProvider provider =
          GoogleAuthProvider();

      provider.addScope(
        'https://www.googleapis.com/auth/userinfo.email',
      );

      UserCredential result =
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
      _showError(
        'Google sign-in could not be completed.',
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // PHONE NUMBER
  // ------------------------------------------------------------

  void _openPhoneLogin() {
    Navigator.of(context).pushNamed('/phone-login');
  }

  // ------------------------------------------------------------
  // FORGOT PASSWORD
  // ------------------------------------------------------------

  void _openForgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  // ------------------------------------------------------------
  // SIGN UP
  // ------------------------------------------------------------

  void _openSignUp() {
    Navigator.of(context).pushNamed('/signup');
  }

  // ------------------------------------------------------------
  // ERROR HANDLING
  // ------------------------------------------------------------

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

      default:
        return e.message ??
            'Unable to sign in. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF30243D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FLOATING GLASS INPUT
  // ------------------------------------------------------------

  Widget _glassField({
    TextEditingController controller,
    String hint,
    IconData icon,
    bool obscureText = false,
    Widget suffix,
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
            color: const Color(0xFF7C4DB5)
                .withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType:
            hint == 'Email address'
                ? TextInputType.emailAddress
                : TextInputType.text,
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

  // ------------------------------------------------------------
  // SOCIAL BUTTON
  // ------------------------------------------------------------

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
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
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

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F2FF),

      body: SafeArea(
        child: Stack(
          children: [

            // Soft background glow
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

                    // BACK BUTTON
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.68),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              Colors.white.withOpacity(0.9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.04),
                            blurRadius: 16,
                            offset:
                                const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                        ),
                        color:
                            const Color(0xFF30243D),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),

                    const SizedBox(height: 35),

                    // BRAND
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 66,
                            width: 66,
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
                                  color: const Color(
                                          0xFF9B6BD0)
                                      .withOpacity(0.12),
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
                                  fontSize: 34,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Grape',
                                  style: TextStyle(
                                    color:
                                        Color(0xFF30243D),
                                    fontSize: 25,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Go',
                                  style: TextStyle(
                                    color:
                                        Color(0xFF8D61C5),
                                    fontSize: 25,
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

                    const SizedBox(height: 35),

                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Color(0xFF30243D),
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Login to continue shopping with Grape Go.',
                      style: TextStyle(
                        color: Color(0xFF8F8499),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // EMAIL
                    _glassField(
                      controller:
                          _emailController,
                      hint: 'Email address',
                      icon: Icons.email_outlined,
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

                    const SizedBox(height: 15),

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
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Enter your password.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // FORGOT PASSWORD
                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            _openForgotPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color:
                                Color(0xFF8D61C5),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _loginWithEmail,
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
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

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
                            'OR CONTINUE WITH',
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

                    const SizedBox(height: 20),

                    // GOOGLE
                    _socialButton(
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      text: 'Continue with Google',
                      onTap: _loginWithGoogle,
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
                      onTap: _openPhoneLogin,
                    ),

                    const SizedBox(height: 25),

                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color:
                                  Color(0xFF8F8499),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: _openSignUp,
                            child: const Text(
                              'Sign Up',
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
}