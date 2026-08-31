import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _otpController =
      TextEditingController();

  String _verificationId = '';

  bool _otpSent = false;
  bool _loading = false;
  bool _resending = false;

  String _selectedCountryCode = '+234';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    final String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showMessage('Please enter your phone number.');
      return;
    }

    if (phone.length < 7) {
      _showMessage('Please enter a valid phone number.');
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    final String fullPhoneNumber =
        '$_selectedCountryCode$phone';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);

            if (!mounted) return;

            setState(() {
              _loading = false;
            });

            _showMessage('Phone number verified.');

            Navigator.pushReplacementNamed(
              context,
              '/MainPage',
            );
          } catch (e) {
            debugPrint(
              'Automatic phone verification error: $e',
            );

            if (!mounted) return;

            setState(() {
              _loading = false;
            });

            _showMessage(
              'Automatic verification failed. Please enter the OTP.',
            );
          }
        },

        verificationFailed:
            (FirebaseAuthException error) {
          if (!mounted) return;

          setState(() {
            _loading = false;
          });

          _showMessage(
            error.message ??
                'Could not send OTP. Please check your number.',
          );
        },

        codeSent:
            (String verificationId, int? resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });

          _showMessage('OTP sent successfully.');
        },

        codeAutoRetrievalTimeout:
            (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint(
        'Send OTP error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit OTP.');
      return;
    }

    if (_verificationId.isEmpty) {
      _showMessage('Please request a new OTP.');
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage('Login successful.');

      Navigator.pushReplacementNamed(
        context,
        '/MainPage',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      String message =
          'Invalid OTP. Please try again.';

      if (error.code == 'invalid-verification-code') {
        message = 'The OTP is incorrect.';
      } else if (error.code == 'session-expired') {
        message =
            'The OTP has expired. Please request another one.';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint(
        'OTP verification error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Verification failed. Please try again.',
      );
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_resending || _loading) return;

    setState(() {
      _resending = true;
    });

    try {
      await _sendOtp();
    } finally {
      if (!mounted) return;

      setState(() {
        _resending = false;
      });
    }
  }

  // ============================================================
  // CHANGE NUMBER
  // ============================================================

  void _changeNumber() {
    if (_loading) return;

    setState(() {
      _otpSent = false;
      _otpController.clear();
      _verificationId = '';
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.pikkXBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(18),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.pikkXBlack.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.pikkXBlack.withOpacity(0.06),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // PHONE FIELD
  // ============================================================

  Widget _phoneField() {
    return _glass(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.pikkXNavy,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _selectedCountryCode,
              style: const TextStyle(
                color: AppTheme.pikkXWhite,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _phoneController,
              enabled: !_otpSent && !_loading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: AppTheme.pikkXBlack,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Phone number',
                hintStyle: TextStyle(
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OTP FIELD
  // ============================================================

  Widget _otpField() {
    return _glass(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      child: TextField(
        controller: _otpController,
        enabled: !_loading,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.pikkXBlack,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: '••••••',
          hintStyle: TextStyle(
            color: Color(0xFFB8BDC5),
            fontSize: 24,
            letterSpacing: 7,
          ),
        ),
        onSubmitted: (_) {
          if (!_loading) {
            _verifyOtp();
          }
        },
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton() {
    final bool verifying = _otpSent;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _loading
            ? null
            : verifying
                ? _verifyOtp
                : _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.pikkXBlack,
          disabledBackgroundColor:
              AppTheme.pikkXBlack.withOpacity(0.45),
          elevation: 6,
          shadowColor:
              AppTheme.pikkXBlack.withOpacity(0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    AppTheme.pikkXWhite,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    verifying
                        ? 'Verify OTP'
                        : 'Send OTP',
                    style: const TextStyle(
                      color: AppTheme.pikkXWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Icon(
                    verifying
                        ? Icons.verified_rounded
                        : Icons.arrow_forward_rounded,
                    color: AppTheme.pikkXWhite,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // OTP SECTION
  // ============================================================

  Widget _otpSection() {
    if (!_otpSent) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        const Text(
          'Enter verification code',
          style: TextStyle(
            color: AppTheme.pikkXBlack,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'We sent a 6-digit code to '
          '$_selectedCountryCode${_phoneController.text.trim()}',
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 13),

        _otpField(),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _loading
                  ? null
                  : _changeNumber,
              child: const Text(
                'Change number',
                style: TextStyle(
                  color: AppTheme.pikkXNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            TextButton(
              onPressed: _loading || _resending
                  ? null
                  : _resendOtp,
              child: Text(
                _resending
                    ? 'Sending...'
                    : 'Resend OTP',
                style: const TextStyle(
                  color: AppTheme.pikkXNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ----------------------------------------------------
            // SUBTLE NAVY BACKGROUND GLOW
            // ----------------------------------------------------

            Positioned(
              top: -100,
              right: -90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppTheme.pikkXNavy.withOpacity(0.06),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -100,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppTheme.pikkXNavy.withOpacity(0.04),
                ),
              ),
            ),

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                25,
                22,
                35,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // BACK BUTTON
                  // ------------------------------------------------

                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            AppTheme.pikkXBlack
                                .withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.pikkXBlack
                                  .withOpacity(0.05),
                          blurRadius: 15,
                          offset:
                              const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color:
                            AppTheme.pikkXBlack,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // APP MARK
                  // ------------------------------------------------

                  Center(
                    child: _glass(
                      padding:
                          const EdgeInsets.all(15),
                      child: const Icon(
                        Icons.phone_rounded,
                        color:
                            AppTheme.pikkXNavy,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Center(
                    child: Text(
                      'Phone verification',
                      style: TextStyle(
                        color:
                            AppTheme.pikkXBlack,
                        fontSize: 27,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      _otpSent
                          ? 'Enter the code we sent to your phone.'
                          : 'Enter your phone number to continue.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:
                            AppTheme.mutedText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // MAIN FORM
                  // ------------------------------------------------

                  _glass(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone number',
                          style: TextStyle(
                            color:
                                AppTheme.pikkXBlack,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        _phoneField(),

                        _otpSection(),

                        const SizedBox(height: 22),

                        _primaryButton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'By continuing, you agree to the app’s '
                      'terms and privacy policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            AppTheme.mutedText,
                        fontSize: 10,
                        height: 1.5,
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