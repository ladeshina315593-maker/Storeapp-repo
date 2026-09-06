import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.product,
  });

  final String productId;
  final Map<String, dynamic> product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController controller;
  late Animation<double> animation;

  bool isLiked = false;
  bool isAddingToCart = false;

  int selectedSize = 1;
  int selectedColor = 0;

  final List<String> sizes = const [
    'US 6',
    'US 7',
    'US 8',
    'US 9',
  ];

  // ============================================================
  // REAL NIKE PRODUCT IMAGES
  // ============================================================

  final List<String> nikeImages = const [
    'assets/images/blue_nike.jpg',
    'assets/images/grey_nike.jpg',
    'assets/images/purple_nike.jpg',
  ];

  final List<String> colorNames = const [
    'Blue',
    'Grey',
    'Purple',
  ];

  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXMuted = Color(0xFF777777);
  static const Color pikkXBorder = Color(0xFFE8E8E8);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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

    _loadFavouriteStatus();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // PRODUCT DATA
  // ============================================================

  String get productName {
    final value = widget.product['name']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Nike';
  }

  String get productDescription {
    final value = widget.product['description']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Nike sneakers available in Blue, Grey and Purple. '
        'Choose your preferred colour and size.';
  }

  String get productCategory {
    final value = widget.product['category']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Fashion';
  }

  String get sellerName {
    return widget.product['sellerName']?.toString() ?? '';
  }

  String get sellerId {
    return widget.product['sellerId']?.toString() ?? '';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  double get productPrice {
    return _toDouble(widget.product['price']);
  }

  String get formattedPrice {
    return '₦${productPrice.toStringAsFixed(2)}';
  }

  String get selectedImage {
    return nikeImages[selectedColor];
  }

  String get selectedColorName {
    return colorNames[selectedColor];
  }

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // FAVOURITE
  // ============================================================

  Future<void> _loadFavouriteStatus() async {
    final user = currentUser;

    if (user == null) return;

    try {
      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productId);

      final snapshot = await reference.get();

      if (!mounted) return;

      setState(() {
        isLiked = snapshot.exists;
      });
    } catch (e) {
      debugPrint('Load favourite error: $e');
    }
  }

  Future<void> _toggleFavourite() async {
    final user = currentUser;

    if (user == null) {
      _showMessage('Please sign in to save favourites.');
      return;
    }

    try {
      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productId);

      if (isLiked) {
        await reference.delete();

        if (!mounted) return;

        setState(() {
          isLiked = false;
        });

        _showMessage('Removed from favourites.');
      } else {
        await reference.set({
          'productId': widget.productId,
          'name': productName,
          'price': productPrice,
          'imageUrl': selectedImage,
          'image': selectedImage,
          'category': productCategory,
          'sellerId': sellerId,
          'sellerName': sellerName,
          'description': productDescription,
          'selectedColor': selectedColorName,
          'colorIndex': selectedColor,
          'size': sizes[selectedSize],
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        setState(() {
          isLiked = true;
        });

        _showMessage('Added to favourites.');
      }
    } catch (e) {
      debugPrint('Favourite error: $e');
      _showMessage('Could not update favourite.');
    }
  }

  // ============================================================
  // ADD TO EXISTING FIREBASE CART
  // ============================================================

  Future<void> _addToCart() async {
    final user = currentUser;

    if (user == null) {
      _showMessage('Please sign in to add items to your cart.');
      return;
    }

    if (isAddingToCart) return;

    setState(() {
      isAddingToCart = true;
    });

    try {
      final cartReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(widget.productId);

      final existing = await cartReference.get();

      if (existing.exists) {
        final data = existing.data();

        int quantity = 1;
        final existingQuantity = data?['quantity'];

        if (existingQuantity is num) {
          quantity = existingQuantity.toInt();
        } else {
          quantity = int.tryParse(
                existingQuantity?.toString() ?? '',
              ) ??
              1;
        }

        // Update the existing Nike cart item with the
        // currently selected colour, image and size.
        await cartReference.update({
          'quantity': quantity + 1,
          'name': productName,
          'price': productPrice,
          'imageUrl': selectedImage,
          'image': selectedImage,
          'selectedColor': selectedColorName,
          'colorIndex': selectedColor,
          'size': sizes[selectedSize],
          'sellerId': sellerId,
          'sellerName': sellerName,
          'category': productCategory,
          'description': productDescription,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartReference.set({
          'productId': widget.productId,
          'name': productName,
          'price': productPrice,

          // Selected Nike image.
          'imageUrl': selectedImage,
          'image': selectedImage,

          'quantity': 1,

          'sellerId': sellerId,
          'sellerName': sellerName,
          'category': productCategory,
          'description': productDescription,

          'size': sizes[selectedSize],
          'colorIndex': selectedColor,
          'selectedColor': selectedColorName,

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _showMessage(
        '$selectedColorName Nike added to cart.',
      );
    } catch (e) {
      debugPrint('Add to cart error: $e');

      if (mounted) {
        _showMessage(
          'Could not add product to cart.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

  // ============================================================
  // GLASS BUTTON
  // ============================================================

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = pikkXBlack,
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
              sigmaX: 14,
              sigmaY: 14,
            ),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
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
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          _glassButton(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: pikkXBlack,
            onPressed: _toggleFavourite,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NIKE IMAGE CARD
  // ============================================================

  Widget _productImageCard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.68),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -55,
                    left: -45,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.035),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -70,
                    right: -50,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.025),
                      ),
                    ),
                  ),

                  // ==================================================
                  // SWIPE LEFT / RIGHT
                  // ==================================================

                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      final velocity =
                          details.primaryVelocity ?? 0;

                      if (velocity < 0) {
                        // LEFT → next colour
                        setState(() {
                          selectedColor =
                              (selectedColor + 1) %
                                  nikeImages.length;
                        });
                      } else if (velocity > 0) {
                        // RIGHT → previous colour
                        setState(() {
                          selectedColor =
                              (selectedColor -
                                      1 +
                                      nikeImages.length) %
                                  nikeImages.length;
                        });
                      }
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 280,
                          ),
                          transitionBuilder:
                              (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.94,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            selectedImage,
                            key: ValueKey(selectedImage),
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) {
                              return const Icon(
                                Icons
                                    .image_not_supported_outlined,
                                size: 65,
                                color: pikkXMuted,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // SWIPE HINT
                  // ==================================================

                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withOpacity(0.72),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Colors.white.withOpacity(0.9),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 16,
                              color: pikkXBlack,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Swipe',
                              style: TextStyle(
                                color: pikkXBlack,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: pikkXBlack,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COLOR INDICATOR
  // ============================================================

  Widget _thumbnailRow() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          nikeImages.length,
          (index) {
            final selected = selectedColor == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              height: selected ? 8 : 6,
              width: selected ? 22 : 6,
              decoration: BoxDecoration(
                color: selected
                    ? pikkXBlack
                    : pikkXBlack.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT SUMMARY
  // ============================================================

  Widget _productSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: pikkXBlack,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$productCategory • $selectedColorName',
                style: const TextStyle(
                  color: pikkXMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Text(
          formattedPrice,
          style: const TextStyle(
            color: pikkXBlack,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  Widget _rating() {
    final rating = widget.product['rating'] ?? 4.9;
    final reviews = widget.product['reviews'] ?? 128;

    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: pikkXBlack,
          size: 19,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: const TextStyle(
            color: pikkXBlack,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '($reviews reviews)',
          style: const TextStyle(
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
      maxChildSize: 0.84,
      initialChildSize: 0.53,
      minChildSize: 0.53,
      builder: (
        context,
        scrollController,
      ) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(34),
            topRight: Radius.circular(34),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(34),
                  topRight: Radius.circular(34),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 45,
                        decoration: BoxDecoration(
                          color:
                              pikkXBlack.withOpacity(0.18),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _productSummary(),

                    const SizedBox(height: 10),

                    if (sellerName.isNotEmpty)
                      Text(
                        'Seller: $sellerName',
                        style: const TextStyle(
                          color: pikkXMuted,
                          fontSize: 11,
                        ),
                      ),

                    const SizedBox(height: 10),

                    _rating(),

                    const SizedBox(height: 25),

                    _sectionTitle('Available Size'),

                    const SizedBox(height: 12),

                    Row(
                      children: List.generate(
                        sizes.length,
                        (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right:
                                    index ==
                                            sizes.length - 1
                                        ? 0
                                        : 8,
                              ),
                              child: _sizeWidget(
                                sizes[index],
                                index,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('Available Color'),

                    const SizedBox(height: 12),

                    _colorSelector(),

                    const SizedBox(height: 25),

                    _sectionTitle('Description'),

                    const SizedBox(height: 10),

                    Text(
                      productDescription,
                      style: const TextStyle(
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
                      'PikkX verified',
                      'Quality product from a trusted seller',
                    ),

                    const SizedBox(height: 30),

                    _firebaseAddButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
  // SIZE
  // ============================================================

  Widget _sizeWidget(
    String text,
    int index,
  ) {
    final selected = selectedSize == index;

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
              ? pikkXBlack
              : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? pikkXBlack
                : pikkXBorder,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? pikkXWhite
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

  Widget _colorSelector() {
    return Row(
      children: List.generate(
        nikeImages.length,
        (index) {
          final selected = selectedColor == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = index;
                });
              },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right:
                      index == nikeImages.length - 1
                          ? 0
                          : 10,
                ),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.black.withOpacity(0.07)
                      : Colors.white.withOpacity(0.55),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? pikkXBlack
                        : Colors.white.withOpacity(0.9),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 55,
                      child: Image.asset(
                        nikeImages[index],
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) {
                          return const Icon(
                            Icons
                                .image_not_supported_outlined,
                            color: pikkXMuted,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colorNames[index],
                      style: const TextStyle(
                        color: pikkXBlack,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: pikkXBlack.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: pikkXBlack,
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
  // ADD TO CART BUTTON
  // ============================================================

  Widget _firebaseAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            isAddingToCart ? null : _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: pikkXBlack,
          disabledBackgroundColor:
              pikkXBlack.withOpacity(0.65),
          foregroundColor: pikkXWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isAddingToCart
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: pikkXWhite,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: pikkXBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
                  _productImageCard(),
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