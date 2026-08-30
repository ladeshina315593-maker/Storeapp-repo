import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({Key? key}) : super(key: key);

  static const Color purple = Color(0xFF9B6FE8);
  static const Color lightPurple = Color(0xFFF4EEFF);
  static const Color darkText = Color(0xFF30243D);
  static const Color mutedText = Color(0xFF8D8498);

  Widget _glassButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.90),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _socialButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return _glassButton(
      context: context,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: darkText,
            size: 21,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: darkText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFA77AEF),
                Color(0xFF8C5DD8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      height: 78,
      width: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDCC8FA),
            Color(0xFFA77AEF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍇',
          style: TextStyle(fontSize: 38),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider authentication will be connected to the backend next.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: purple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: Stack(
          children: [
            // TOP SOFT GLOW
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: purple.withOpacity(0.10),
                ),
              ),
            ),

            // BOTTOM SOFT GLOW
            Positioned(
              bottom: -100,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD8C0FA)
                      .withOpacity(0.16),
                ),
              ),
            ),

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
                    'Welcome to Grape Go',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkText,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
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

                  // GLASS AUTH PANEL
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      22,
                      18,
                      22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.52),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.85),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
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
                          context: context,
                          text: 'Sign In',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/sign-in',
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // CREATE ACCOUNT
                        _glassButton(
                          context: context,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/sign-up',
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: purple,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // GOOGLE
                        _socialButton(
                          context: context,
                          icon: Icons.g_mobiledata_rounded,
                          text: 'Continue with Google',
                          onTap: () {
                            _comingSoon(
                              context,
                              'Google',
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // PHONE
                        _socialButton(
                          context: context,
                          icon: Icons.phone_rounded,
                          text: 'Continue with Phone',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/phone-auth',
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // FACEBOOK
                        _socialButton(
                          context: context,
                          icon: Icons.facebook_rounded,
                          text: 'Continue with Facebook',
                          onTap: () {
                            _comingSoon(
                              context,
                              'Facebook',
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // APPLE
                        _socialButton(
                          context: context,
                          icon: Icons.apple,
                          text: 'Continue with Apple',
                          onTap: () {
                            _comingSoon(
                              context,
                              'Apple',
                            );
                          },
                        ),
                      ],
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