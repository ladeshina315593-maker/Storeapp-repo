import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key key}) : super(key: key);

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
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

            _showMessage('Phone number verified.');

            Navigator.pushReplacementNamed(
              context,
              '/MainPage',
            );
          } catch (e) {
            if (!mounted) return;
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
            (String verificationId, int resendToken) {
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
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
      );
    }
  }

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
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Verification failed. Please try again.',
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_resending) return;

    setState(() {
      _resending = true;
    });

    await _sendOtp();

    if (!mounted) return;

    setState(() {
      _resending = false;
    });
  }

  void _changeNumber() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
      _verificationId = '';
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _floatingGlass({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.90),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F42C1)
                .withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.80),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _phoneField() {
    return _floatingGlass(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1E9FF),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Text(
              _selectedCountryCode,
              style: const TextStyle(
                color: Color(0xFF6F42C1),
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
              style: const TextStyle(
                color: Color(0xFF30243D),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Phone number',
                hintStyle: TextStyle(
                  color: Color(0xFF9B91A8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpField() {
    return _floatingGlass(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF30243D),
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: '••••••',
          hintStyle: TextStyle(
            color: Color(0xFFC8B9DA),
            fontSize: 24,
            letterSpacing: 7,
          ),
        ),
      ),
    );
  }

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
          backgroundColor:
              const Color(0xFF8E5BD9),
          disabledBackgroundColor:
              const Color(0xFFBFA5E6),
          elevation: 10,
          shadowColor: const Color(0xFF8E5BD9)
              .withOpacity(0.30),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    Colors.white,
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
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Icon(
                    verifying
                        ? Icons.verified_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

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
            color: Color(0xFF30243D),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'We sent a 6-digit code to $_selectedCountryCode${_phoneController.text.trim()}',
          style: const TextStyle(
            color: Color(0xFF9B91A8),
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
                  color: Color(0xFF8E5BD9),
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
                  color: Color(0xFF8E5BD9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5FF),

      body: SafeArea(
        child: Stack(
          children: [
            // Soft floating purple glow.
            Positioned(
              top: -90,
              right: -80,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDCC8FF)
                      .withOpacity(0.35),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -90,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE9DDFF)
                      .withOpacity(0.45),
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
                  // Back button.
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Colors.white.withOpacity(0.9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.05),
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
                            Color(0xFF30243D),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logo / branding.
                  Center(
                    child: _floatingGlass(
                      padding:
                          const EdgeInsets.all(14),
                      child: const Text(
                        '🍇',
                        style:
                            TextStyle(fontSize: 35),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Center(
                    child: Text(
                      'Phone verification',
                      style: TextStyle(
                        color:
                            Color(0xFF30243D),
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
                            Color(0xFF9B91A8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _floatingGlass(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone number',
                          style: TextStyle(
                            color:
                                Color(0xFF30243D),
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

                  Center(
                    child: Text(
                      'By continuing, you agree to Grape Go’s terms and privacy policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            const Color(0xFF9B91A8),
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