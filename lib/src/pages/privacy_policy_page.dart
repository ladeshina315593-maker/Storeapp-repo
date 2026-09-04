import 'dart:ui';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXBackground = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: pikkXBlack,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Soft glass background decoration
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: pikkXNavy.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: pikkXBlack.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: pikkXWhite.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: pikkXWhite.withOpacity(0.85),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pikkXBlack.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PikkX',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: pikkXBlack,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: pikkXNavy,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _section(
                            '1. Information We Collect',
                            'PikkX may collect information that you provide when '
                                'creating or using your account. This may include '
                                'your name, email address, phone number, profile '
                                'information, and other information you choose '
                                'to provide.',
                          ),

                          _section(
                            '2. How We Use Your Information',
                            'We may use your information to create and manage '
                                'your account, provide PikkX services, process '
                                'orders, communicate with you, provide customer '
                                'support, and improve the app.',
                          ),

                          _section(
                            '3. Account Information',
                            'Your account information is used to help you '
                                'securely sign in and access your PikkX account. '
                                'Please keep your login information private.',
                          ),

                          _section(
                            '4. Products, Cart and Orders',
                            'Information about products you view, favourite, '
                                'add to your cart, or order may be stored so that '
                                'PikkX can provide these features to you.',
                          ),

                          _section(
                            '5. Location Information',
                            'If PikkX provides location-based features, we may '
                                'request permission to use your device location. '
                                'You can control location permissions through '
                                'your device settings.',
                          ),

                          _section(
                            '6. Sharing of Information',
                            'PikkX does not intend to sell your personal '
                                'information. Information may be shared with '
                                'service providers when necessary to provide '
                                'requested services or when required by law.',
                          ),

                          _section(
                            '7. Data Security',
                            'We take reasonable measures to protect information '
                                'associated with your account. However, no '
                                'internet-based service can guarantee complete '
                                'security of information.',
                          ),

                          _section(
                            '8. Your Choices',
                            'You may be able to update or change certain account '
                                'information through your PikkX account. You '
                                'may also contact PikkX regarding privacy-related '
                                'questions or requests.',
                          ),

                          _section(
                            '9. Children and Age Requirements',
                            'PikkX is intended to be used in accordance with '
                                'the applicable age requirements in the user’s '
                                'location. If an account is not permitted for '
                                'someone under the applicable age, it should not '
                                'be created or used without appropriate permission.',
                          ),

                          _section(
                            '10. Changes to This Privacy Policy',
                            'We may update this Privacy Policy from time to '
                                'time as PikkX develops or our privacy practices '
                                'change. Any updated version will be made '
                                'available through the app.',
                          ),

                          _section(
                            '11. Contact Us',
                            'If you have questions or concerns about this '
                                'Privacy Policy, please contact PikkX through '
                                'the support channels provided in the app.',
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Last updated: September 4, 2026',
                            style: TextStyle(
                              fontSize: 12,
                              color: pikkXBlack.withOpacity(0.50),
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
    );
  }

  static Widget _section(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: pikkXBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: pikkXBlack.withOpacity(0.70),
            ),
          ),
        ],
      ),
    );
  }
}