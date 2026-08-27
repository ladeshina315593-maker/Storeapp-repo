import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  // ------------------------------------------------------------
  // Grape Go theme
  // ------------------------------------------------------------

  static const Color purple =
      Color(0xFF9B6DDB);

  static const Color lightPurple =
      Color(0xFFF0E7FA);

  static const Color softPurple =
      Color(0xFFD8C2F2);

  static const Color darkText =
      Color(0xFF30243D);

  static const Color mutedText =
      Color(0xFF81768C);

  // ------------------------------------------------------------
  // Controllers
  // ------------------------------------------------------------

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final FocusNode _nameFocus =
      FocusNode();

  final FocusNode _usernameFocus =
      FocusNode();

  final FocusNode _emailFocus =
      FocusNode();

  String? _selectedCountry;

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();

    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------

  void _continue() {
    if (_nameController.text.trim().isEmpty) {
      _showMessage(
        'Please enter your name.',
      );
      _nameFocus.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
    });

    // This is where Firebase/Firestore profile
    // saving will be connected.
    //
    // For now, after the profile information
    // has been entered, continue to Home.

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;

        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      },
    );
  }

  void _skip() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  // ------------------------------------------------------------
  // Message
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor: purple,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Floating glass field
  // ------------------------------------------------------------

  Widget _glassField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.62),
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.92),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: darkText,
          fontSize: 14,
          fontWeight:
              FontWeight.w600,
        ),
        decoration:
            InputDecoration(
          border: InputBorder.none,
          prefixIcon: Container(
            margin:
                const EdgeInsets.all(9),
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  lightPurple,
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: purple,
              size: 19,
            ),
          ),
          hintText: hint,
          hintStyle:
              const TextStyle(
            color: mutedText,
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Country selector
  // ------------------------------------------------------------

  Widget _countrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        height: 58,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color:
              Colors.white.withOpacity(0.62),
          borderRadius:
              BorderRadius.circular(19),
          border: Border.all(
            color:
                Colors.white.withOpacity(0.92),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.045),
              blurRadius: 18,
              offset:
                  const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  const BoxDecoration(
                color: lightPurple,
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.public_rounded,
                color: purple,
                size: 19,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Country',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCountry ??
                        'Select your country',
                    style:
                        const TextStyle(
                      color: darkText,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color: purple,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Country picker
  // ------------------------------------------------------------

  void _showCountryPicker() {
    final List<String> countries = [
      'Nigeria',
      'Ghana',
      'Kenya',
      'South Africa',
      'United Kingdom',
      'United States',
      'Canada',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.only(
              topLeft:
                  Radius.circular(30),
              topRight:
                  Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color: softPurple,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Choose your country',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                ...countries.map(
                  (country) {
                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading:
                          Container(
                        width: 38,
                        height: 38,
                        decoration:
                            const BoxDecoration(
                          color:
                              lightPurple,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons
                              .public_rounded,
                          color: purple,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        country,
                        style:
                            const TextStyle(
                          color:
                              darkText,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      trailing:
                          _selectedCountry ==
                                  country
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color:
                                      purple,
                                )
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedCountry =
                              country;
                        });

                        Navigator.pop(
                          context,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Profile illustration
  // ------------------------------------------------------------

  Widget _profileIcon() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.68),
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Colors.white.withOpacity(0.92),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                purple.withOpacity(0.16),
            blurRadius: 22,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: purple,
        size: 39,
      ),
    );
  }

  // ------------------------------------------------------------
  // Main floating card
  // ------------------------------------------------------------

  Widget _profileCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.66),
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.94),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.055),
            blurRadius: 28,
            offset:
                const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about you',
            style: TextStyle(
              color: darkText,
              fontSize: 19,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'A few details will help us personalize your Grape Go experience.',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          _glassField(
            controller:
                _nameController,
            focusNode:
                _nameFocus,
            hint: 'Full name',
            icon:
                Icons.person_outline_rounded,
          ),

          const SizedBox(height: 13),

          _glassField(
            controller:
                _usernameController,
            focusNode:
                _usernameFocus,
            hint: 'Username',
            icon:
                Icons.alternate_email_rounded,
          ),

          const SizedBox(height: 13),

          _glassField(
            controller:
                _emailController,
            focusNode:
                _emailFocus,
            hint: 'Email address',
            icon:
                Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
          ),

          const SizedBox(height: 13),

          _countrySelector(),

          const SizedBox(height: 22),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed:
                  _loading
                      ? null
                      : _continue,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    purple,
                disabledBackgroundColor:
                    purple.withOpacity(
                  0.55,
                ),
                elevation: 7,
                shadowColor:
                    purple.withOpacity(
                  0.25,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
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
                      'Continue',
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

          const SizedBox(height: 8),

          // Skip
          SizedBox(
            width: double.infinity,
            height: 45,
            child: TextButton(
              onPressed:
                  _loading
                      ? null
                      : _skip,
              child:
                  const Text(
                'Skip for now',
                style:
                    TextStyle(
                  color:
                      mutedText,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
          const Color(0xFFF8F5FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Background floating glow
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 230,
                height: 230,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      softPurple.withOpacity(
                    0.24,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      purple.withOpacity(
                    0.08,
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                25,
                22,
                35,
              ),
              child: Column(
                children: [
                  _profileIcon(),

                  const SizedBox(
                    height: 15,
                  ),

                  const Text(
                    'Complete your profile',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          darkText,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  const Text(
                    'Welcome to Grape Go 🍇',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          purple,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  _profileCard(),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'You can update your profile later in Settings.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          mutedText,
                      fontSize: 10,
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