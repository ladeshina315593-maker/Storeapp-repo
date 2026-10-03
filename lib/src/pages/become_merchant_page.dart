import 'dart:ui';

import 'package:flutter/material.dart';

class BecomeMerchantPage extends StatelessWidget {
  const BecomeMerchantPage({super.key});

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ----------------------------------------------------------
            // BACKGROUND GLOW
            // ----------------------------------------------------------

            Positioned(
              top: -110,
              right: -80,
              child: Container(
                height: 260,
                width: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.035),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -90,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pikkXBlack.withOpacity(0.025),
                ),
              ),
            ),

            Column(
              children: [
                // ------------------------------------------------------
                // TOP BAR
                // ------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    10,
                  ),
                  child: Row(
                    children: [
                      _glassButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      const Spacer(),

                      const Text(
                        'Merchant',
                        style: TextStyle(
                          color: pikkXBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const Spacer(),

                      // Keeps the title centered.
                      const SizedBox(width: 46),
                    ],
                  ),
                ),

                // ------------------------------------------------------
                // CONTENT
                // ------------------------------------------------------

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      25,
                      24,
                      30,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 15),

                        // ------------------------------------------------
                        // MERCHANT ICON
                        // ------------------------------------------------

                        _merchantIcon(),

                        const SizedBox(height: 30),

                        const Text(
                          'Welcome Aboard!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pikkXBlack,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Turn your business into a PikkX store '
                          'and start reaching more customers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ------------------------------------------------
                        // BENEFITS
                        // ------------------------------------------------

                        _glassCard(
                          child: Column(
                            children: [
                              _benefitTile(
                                icon: Icons.storefront_outlined,
                                title: 'Create your store',
                                subtitle:
                                    'Build your own space on PikkX.',
                              ),

                              _divider(),

                              _benefitTile(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Sell your products',
                                subtitle:
                                    'Put your products in front of customers.',
                              ),

                              _divider(),

                              _benefitTile(
                                icon: Icons.local_shipping_outlined,
                                title: 'Manage your orders',
                                subtitle:
                                    'Keep track of customer orders easily.',
                              ),

                              _divider(),

                              _benefitTile(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'Connect with customers',
                                subtitle:
                                    'Chat with customers directly on PikkX.',
                              ),

                              _divider(),

                              _benefitTile(
                                icon: Icons.trending_up_rounded,
                                title: 'Grow your business',
                                subtitle:
                                    'Reach more people and grow your store.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ------------------------------------------------
                        // NOTE
                        // ------------------------------------------------

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: pikkXWhite.withOpacity(0.70),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: pikkXBlack.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  color: pikkXBlack.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: pikkXBlack,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your merchant application will be '
                                  'reviewed before your store becomes '
                                  'active.',
                                  style: TextStyle(
                                    color: pikkXGrey,
                                    fontSize: 11,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ------------------------------------------------
                        // GET STARTED
                        // ------------------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {
                              // The merchant application form
                              // will be connected here next.
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pikkXBlack,
                              foregroundColor: pikkXWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(19),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Let’s build your PikkX store.',
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MERCHANT ICON
  // ------------------------------------------------------------

  Widget _merchantIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          height: 118,
          width: 118,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.75),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: pikkXBlack,
            size: 54,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BENEFIT TILE
  // ------------------------------------------------------------

  Widget _benefitTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: pikkXBlack.withOpacity(0.055),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: pikkXBlack,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: pikkXGrey,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // GLASS CARD
  // ------------------------------------------------------------

  Widget _glassCard({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.76),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.055),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DIVIDER
  // ------------------------------------------------------------

  Widget _divider() {
    return Divider(
      height: 1,
      color: pikkXBlack.withOpacity(0.055),
    );
  }

  // ------------------------------------------------------------
  // GLASS BUTTON
  // ------------------------------------------------------------

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: pikkXBlack,
            size: 18,
          ),
        ),
      ),
    );
  }
}