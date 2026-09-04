import 'dart:ui';
import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalPage(
      title: 'Terms & Conditions',
      sections: const [
        _LegalSection(
          title: '1. Acceptance of Terms',
          text:
              'By using PikkX, you agree to these Terms & Conditions. '
              'If you do not agree with these terms, please do not use the app.',
        ),
        _LegalSection(
          title: '2. Using PikkX',
          text:
              'PikkX provides a platform where users can discover products, '
              'communicate with sellers, add products to favourites or cart, '
              'and place orders where available.',
        ),
        _LegalSection(
          title: '3. User Accounts',
          text:
              'You are responsible for keeping your account information '
              'accurate and for protecting your login credentials. '
              'Do not use another person’s account without permission.',
        ),
        _LegalSection(
          title: '4. Products and Sellers',
          text:
              'Product information, prices, images, availability and seller '
              'details may be provided by sellers. Users should review '
              'product information before making a purchase.',
        ),
        _LegalSection(
          title: '5. Orders and Payments',
          text:
              'Orders are subject to availability and any applicable '
              'purchase conditions shown in the app. Additional payment, '
              'delivery or cancellation terms may apply.',
        ),
        _LegalSection(
          title: '6. Prohibited Use',
          text:
              'You must not use PikkX to misuse the service, interfere with '
              'its operation, impersonate another person, or violate '
              'applicable laws.',
        ),
        _LegalSection(
          title: '7. Changes to These Terms',
          text:
              'We may update these Terms & Conditions from time to time. '
              'Updated terms will be made available through the app.',
        ),
        _LegalSection(
          title: '8. Contact',
          text:
              'If you have questions about these Terms & Conditions, '
              'please contact PikkX through the available support channels.',
        ),
      ],
    );
  }
}

class _LegalSection {
  final String title;
  final String text;

  const _LegalSection({
    required this.title,
    required this.text,
  });
}

class _LegalPage extends StatelessWidget {
  final String title;
  final List<_LegalSection> sections;

  const _LegalPage({
    required this.title,
    required this.sections,
  });

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: pikkXBlack,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: pikkXNavy.withOpacity(0.10),
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
                          Text(
                            'PikkX',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: pikkXBlack,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: pikkXNavy,
                            ),
                          ),
                          const SizedBox(height: 24),

                          ...sections.map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: pikkXBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    section.text,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.6,
                                      color: pikkXBlack.withOpacity(0.70),
                                    ),
                                  ),
                                ],
                              ),
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
}