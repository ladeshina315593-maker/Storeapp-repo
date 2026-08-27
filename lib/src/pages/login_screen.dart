import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color purple = Color(0xFF9B6FE8);
  static const Color purpleDark = Color(0xFF8052C9);
  static const Color lightPurple = Color(0xFFF7F2FF);
  static const Color darkText = Color(0xFF30243D);
  static const Color mutedText = Color(0xFF8B8296);

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // REAL FIREBASE LOGIN
  // ---------------------------------------------------------

  Future<void> _login() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final String email =
          emailController.text.trim();

      final String password =
          passwordController.text;

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Firebase has authenticated the user.
      // Continue to the actual app.
      Navigator.pushNamedAndRemoveUntil(
        context,
        'MainPage',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          'Unable to log in. Please try again.';

      switch (e.code) {
        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message =
              'No account was found with this email.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message =
              'The email or password is incorrect.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Check your internet connection and try again.';
          break;
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // FORGOT PASSWORD
  // ---------------------------------------------------------

  Future<void> _forgotPassword() async {
    final String email =
        emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Enter your email first.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showMessage(
        'Password reset email sent.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          'Could not send the reset email.';

      if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      } else if (e.code == 'user-not-found') {
        message =
            'No account was found with this email.';
      }

      _showMessage(message);
    }
  }

  // ---------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: purpleDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ---------------------------------------------------------
  // FLOATING GLASS FIELD
  // ---------------------------------------------------------

  Widget _glassField({
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
    TextInputType keyboardType,
    bool obscureText = false,
    Widget suffixIcon,
    String Function(String) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          color: darkText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: mutedText,
            fontSize: 12,
          ),
          hintStyle: const TextStyle(
            color: mutedText,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: purple,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // LOGIN BUTTON
  // ---------------------------------------------------------

  Widget _loginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : _login,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 57,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFA97BEF),
                Color(0xFF8758D1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 23,
                    width: 23,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // SOCIAL BUTTON
  // ---------------------------------------------------------

  Widget _socialButton({
    IconData icon,
    String text,
    VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: darkText,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: darkText,
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

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      body: SafeArea(
        child: Stack(
          children: [
            // FLOATING BACKGROUND GLOWS
            Positioned(
              top: -100,
              right: -90,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      purple.withOpacity(0.10),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -100,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDCC7FA)
                      .withOpacity(0.20),
                ),
              ),
            ),

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                16,
                22,
                35,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // BACK
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.72),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Colors.white.withOpacity(0.95),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.035),
                          blurRadius: 14,
                          offset:
                              const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons
                            .arrow_back_ios_new_rounded,
                        size: 18,
                        color: darkText,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // HEADER
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Login to continue to Grape Go.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // FLOATING GLASS LOGIN CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.50),
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color:
                            Colors.white.withOpacity(0.90),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              purple.withOpacity(0.07),
                          blurRadius: 30,
                          offset:
                              const Offset(0, 14),
                        ),
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.025),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _glassField(
                            label: 'Email',
                            hint: 'Enter your email',
                            icon:
                                Icons.email_outlined,
                            controller:
                                emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Enter your email';
                              }

                              if (!value
                                  .contains('@')) {
                                return 'Enter a valid email';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          _glassField(
                            label: 'Password',
                            hint: 'Enter your password',
                            icon:
                                Icons.lock_outline_rounded,
                            controller:
                                passwordController,
                            obscureText:
                                obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword =
                                      !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                                color: purple,
                                size: 20,
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Enter your password';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _forgotPassword,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: purpleDark,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          _loginButton(),

                          const SizedBox(height: 22),

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
                                  'OR',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 10,
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

                          _socialButton(
                            icon: Icons.g_mobiledata_rounded,
                            text: 'Continue with Google',
                            onTap: () {
                              _showMessage(
                                'Google Sign-In will be connected next.',
                              );
                            },
                          ),

                          const SizedBox(height: 11),

                          _socialButton(
                            icon:
                                Icons.phone_outlined,
                            text:
                                'Continue with Phone',
                            onTap: () {
                              _showMessage(
                                'Phone authentication will be connected next.',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SIGN UP
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          'SignUp',
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text:
                              "Don't have an account? ",
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                color: purpleDark,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
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