import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/model/data.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() =>
      _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  bool isLiked = false;
  int selectedSize = 1;
  int selectedColor = 0;
  int selectedImage = 0;

  final List<String> sizes = [
    'US 6',
    'US 7',
    'US 8',
    'US 9',
  ];

  // pikkX palette:
  // Black / White identity with a small navy accent.
  final List<Color> colors = const [
    Color(0xFF050505),
    Color(0xFFFFFFFF),
    Color(0xFF10233F),
    Color(0xFF5A6472),
    Color(0xFFD9DDE3),
  ];

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXMuted = Color(0xFF747F8F);
  static const Color pikkXBorder = Color(0xFFE1E2E4);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // GLASS BUTTON
  // ============================================================

  Widget _glassButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _glassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: pikkXBlack,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          _glassButton(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: isLiked ? pikkXNavy : pikkXBlack,
            onPressed: () {
              setState(() {
                isLiked = !isLiked;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage() {
    if (AppData.showThumbnailList.isEmpty) {
      return const Expanded(
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: pikkXMuted,
          ),
        ),
      );
    }

    final int safeIndex = selectedImage.clamp(
      0,
      AppData.showThumbnailList.length - 1,
    );

    final String image =
        AppData.showThumbnailList[safeIndex];

    return Expanded(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.92,
                end: 1.0,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: pikkXWhite,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.95),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Small navy decorative glow.
                Positioned(
                  top: -35,
                  left: -35,
                  child: Container(
                    width: 135,
                    height: 135,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pikkXNavy.withOpacity(0.06),
                    ),
                  ),
                ),

                // Small accent badge.
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: pikkXNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: pikkXNavy.withOpacity(0.12),
                      ),
                    ),
                    child: const Text(
                      'TRENDING',
                      style: TextStyle(
                        color: pikkXNavy,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(35),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // THUMBNAILS
  // ============================================================

  Widget _thumbnail(String image, int index) {
    final bool selected = selectedImage == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImage = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        height: 58,
        width: 58,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? pikkXNavy
                : Colors.white.withOpacity(0.85),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: pikkXNavy.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Image.asset(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _thumbnailRow() {
    if (AppData.showThumbnailList.isEmpty) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: AppData.showThumbnailList
            .asMap()
            .entries
            .map(
              (entry) => _thumbnail(
                entry.value,
                entry.key,
              ),
            )
            .toList(),
      ),
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  Widget _rating() {
    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: pikkXNavy,
          size: 19,
        ),
        const SizedBox(width: 4),
        const Text(
          '4.8',
          style: TextStyle(
            color: pikkXBlack,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          '(120 reviews)',
          style: TextStyle(
            color: pikkXMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS SHEET
  // ============================================================

  Widget _detailWidget() {
    return DraggableScrollableSheet(
      maxChildSize: 0.82,
      initialChildSize: 0.56,
      minChildSize: 0.56,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
            ),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle.
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: pikkXNavy,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // PRODUCT TITLE + PRICE
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NIKE AIR MAX 200',
                            style: TextStyle(
                              color: pikkXBlack,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Trending Now',
                            style: TextStyle(
                              color: pikkXNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _rating(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '\$240',
                          style: TextStyle(
                            color: pikkXBlack,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'In stock',
                          style: TextStyle(
                            color: pikkXNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // SIZE
                _sectionTitle('Available Size'),

                const SizedBox(height: 12),

                Row(
                  children: List.generate(
                    sizes.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == sizes.length - 1
                              ? 0
                              : 8,
                        ),
                        child: _sizeWidget(
                          sizes[index],
                          index,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // COLOR
                _sectionTitle('Available Color'),

                const SizedBox(height: 14),

                Row(
                  children: List.generate(
                    colors.length,
                    (index) => Padding(
                      padding:
                          const EdgeInsets.only(right: 18),
                      child: _colorWidget(
                        colors[index],
                        index,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // DESCRIPTION
                _sectionTitle('Description'),

                const SizedBox(height: 10),

                const Text(
                  'Quality product from a trusted seller.',
                  style: TextStyle(
                    color: pikkXMuted,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),

                const SizedBox(height: 25),

                _infoRow(
                  Icons.local_shipping_outlined,
                  'Fast delivery',
                  'Get your order delivered quickly',
                ),

                const SizedBox(height: 12),

                _infoRow(
                  Icons.verified_outlined,
                  'pikkX verified',
                  'Quality product from a trusted seller',
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: pikkXBlack,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // SIZE SELECTOR
  // ============================================================

  Widget _sizeWidget(String text, int index) {
    final bool selected = selectedSize == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? pikkXNavy
              : pikkXBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? pikkXNavy
                : pikkXBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: pikkXNavy.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Colors.white
                : pikkXBlack,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COLOR SELECTOR
  // ============================================================

  Widget _colorWidget(Color color, int index) {
    final bool selected = selectedColor == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        width: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? pikkXNavy
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  color: color == Colors.white
                      ? pikkXBlack
                      : Colors.white,
                  size: 17,
                )
              : null,
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pikkXBackground,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: pikkXBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: pikkXNavy.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: pikkXNavy,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: pikkXMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Widget _floatingCartButton() {
    return Container(
      margin: const EdgeInsets.only(
        right: 5,
        bottom: 8,
      ),
      child: FloatingActionButton.extended(
        elevation: 8,
        backgroundColor: pikkXBlack,
        onPressed: () {
          if (AppData.productList.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Product is currently unavailable.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          if (AppData.cartList.isEmpty ||
              !AppData.cartList.any(
                (item) => item.name == 'Nike Air Max 200',
              )) {
            AppData.cartList.add(
              AppData.productList.first,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Nike Air Max 200 added to cart',
              ),
              backgroundColor: pikkXNavy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white,
        ),
        label: const Text(
          'Add to Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
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
      backgroundColor: pikkXBackground,
      floatingActionButton: _floatingCartButton(),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                pikkXBackground,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _appBar(),
                  _productImage(),
                  _thumbnailRow(),
                ],
              ),
              _detailWidget(),
            ],
          ),
        ),
      ),
    );
  }
}