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
  State<ProductDetailPage> createState() =>
      _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  late AnimationController controller;
  late Animation<double> animation;

  bool isLiked = false;
  bool isAddingToCart = false;

  int selectedSize = 1;
  int selectedColor = 0;

  final List<String> sizes = [
    'US 6',
    'US 7',
    'US 8',
    'US 9',
  ];

  final List<Color> colors = const [
    Color(0xFF050505),
    Color(0xFFFFFFFF),
    Color(0xFF10233F),
    Color(0xFF5A6472),
    Color(0xFFD9DDE3),
  ];

  static const Color pikkXBlack =
      Color(0xFF050505);

  static const Color pikkXWhite =
      Color(0xFFFFFFFF);

  static const Color pikkXBackground =
      Color(0xFFF7F7F7);

  static const Color pikkXNavy =
      Color(0xFF10233F);

  static const Color pikkXMuted =
      Color(0xFF747F8F);

  static const Color pikkXBorder =
      Color(0xFFE1E2E4);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ),
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
    return widget.product['name']
            ?.toString()
            .trim()
            .isNotEmpty ==
        true
        ? widget.product['name'].toString()
        : 'Product';
  }

  String get productDescription {
    return widget.product['description']
            ?.toString()
            .trim()
            .isNotEmpty ==
        true
        ? widget.product['description'].toString()
        : 'Quality product from a trusted seller.';
  }

  String get productCategory {
    return widget.product['category']
            ?.toString() ??
        '';
  }

  String get sellerName {
    return widget.product['sellerName']
            ?.toString() ??
        '';
  }

  String get imageUrl {
    return widget.product['imageUrl']
            ?.toString()
            .trim()
            .isNotEmpty ==
        true
        ? widget.product['imageUrl'].toString()
        : widget.product['image']
                ?.toString() ??
            '';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  String get formattedPrice {
    return '₦${_toDouble(widget.product['price']).toStringAsFixed(2)}';
  }

  // ============================================================
  // FIREBASE USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // FAVOURITE STATUS
  // ============================================================

  Future<void> _loadFavouriteStatus() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productId);

      final snapshot =
          await reference.get();

      if (!mounted) {
        return;
      }

      setState(() {
        isLiked = snapshot.exists;
      });
    } catch (e) {
      debugPrint(
        'Load favourite error: $e',
      );
    }
  }

  // ============================================================
  // TOGGLE FAVOURITE
  // ============================================================

  Future<void> _toggleFavourite() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to save favourites.',
      );
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

        if (!mounted) {
          return;
        }

        setState(() {
          isLiked = false;
        });

        _showMessage(
          'Removed from favourites.',
        );
      } else {
        await reference.set({
          'productId':
              widget.productId,
          'name':
              productName,
          'price':
              _toDouble(
                widget.product['price'],
              ),
          'imageUrl':
              imageUrl,
          'image':
              imageUrl,
          'category':
              productCategory,
          'sellerId':
              widget.product['sellerId']
                      ?.toString() ??
                  '',
          'sellerName':
              sellerName,
          'description':
              productDescription,
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        if (!mounted) {
          return;
        }

        setState(() {
          isLiked = true;
        });

        _showMessage(
          'Added to favourites.',
        );
      }
    } catch (e) {
      debugPrint(
        'Favourite error: $e',
      );

      _showMessage(
        'Could not update favourite.',
      );
    }
  }

  // ============================================================
  // ADD TO CART - FIREBASE
  // ============================================================

  Future<void> _addToCart() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to add items to your cart.',
      );
      return;
    }

    if (isAddingToCart) {
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      final cartReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(widget.productId);

      final existing =
          await cartReference.get();

      final price = _toDouble(
        widget.product['price'],
      );

      if (existing.exists) {
        final data = existing.data();

        int quantity = 1;

        final existingQuantity =
            data?['quantity'];

        if (existingQuantity is num) {
          quantity =
              existingQuantity.toInt();
        } else {
          quantity = int.tryParse(
                existingQuantity
                        ?.toString() ??
                    '',
              ) ??
              1;
        }

        await cartReference.update({
          'quantity': quantity + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await cartReference.set({
          'productId':
              widget.productId,
          'name':
              productName,
          'price':
              price,
          'imageUrl':
              imageUrl,
          'image':
              imageUrl,
          'quantity':
              1,
          'sellerId':
              widget.product['sellerId']
                      ?.toString() ??
                  '',
          'sellerName':
              sellerName,
          'category':
              productCategory,
          'description':
              productDescription,
          'size':
              sizes[selectedSize],
          'colorIndex':
              selectedColor,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Added to cart.',
      );
    } catch (e) {
      debugPrint(
        'Add to cart error: $e',
      );

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
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(
                  0.78,
                ),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(
                    0.9,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(
                      0.06,
                    ),
                    blurRadius: 16,
                    offset:
                        const Offset(0, 7),
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
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          _glassButton(
            icon:
                Icons.arrow_back_ios_new_rounded,
            iconColor: pikkXBlack,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          _glassButton(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor:
                isLiked ? pikkXNavy : pikkXBlack,
            onPressed:
                _toggleFavourite,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage() {
    if (imageUrl.isEmpty) {
      return Expanded(
        child: Center(
          child: Container(
            margin:
                const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: pikkXWhite,
              borderRadius:
                  BorderRadius.circular(32),
              border: Border.all(
                color:
                    Colors.white.withOpacity(
                  0.95,
                ),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons
                    .image_not_supported_outlined,
                size: 60,
                color: pikkXMuted,
              ),
            ),
          ),
        ),
      );
    }

    final Widget imageWidget =
        imageUrl.startsWith('assets/')
            ? Image.asset(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons
                        .image_not_supported_outlined,
                    size: 60,
                    color: pikkXMuted,
                  );
                },
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons
                        .image_not_supported_outlined,
                    size: 60,
                    color: pikkXMuted,
                  );
                },
              );

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
            margin:
                const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: pikkXWhite,
              borderRadius:
                  BorderRadius.circular(32),
              border: Border.all(
                color:
                    Colors.white.withOpacity(
                  0.95,
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(
                    0.07,
                  ),
                  blurRadius: 25,
                  offset:
                      const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -35,
                  left: -35,
                  child: Container(
                    width: 135,
                    height: 135,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          pikkXNavy.withOpacity(
                        0.06,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          pikkXNavy.withOpacity(
                        0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color:
                            pikkXNavy.withOpacity(
                          0.12,
                        ),
                      ),
                    ),
                    child: const Text(
                      'PIKKX',
                      style: TextStyle(
                        color: pikkXNavy,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.all(35),
                  child: imageWidget,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT SUMMARY
  // ============================================================

  Widget _productSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                if (productCategory
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Text(
                      productCategory,
                      style:
                          const TextStyle(
                        color: pikkXNavy,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(
            formattedPrice,
            style: const TextStyle(
              color: pikkXNavy,
              fontSize: 20,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // THUMBNAIL / IMAGE INDICATOR
  // ============================================================

  Widget _thumbnailRow() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                const BoxDecoration(
              color: pikkXNavy,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color:
                  pikkXNavy.withOpacity(.18),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color:
                  pikkXNavy.withOpacity(.18),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  Widget _rating() {
    final rating =
        widget.product['rating'];

    final reviews =
        widget.product['reviews'];

    final ratingText =
        rating?.toString() ?? '4.8';

    final reviewsText =
        reviews?.toString() ?? '120';

    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: pikkXNavy,
          size: 19,
        ),
        const SizedBox(width: 4),
        Text(
          ratingText,
          style: const TextStyle(
            color: pikkXBlack,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '($reviewsText reviews)',
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
      maxChildSize: 0.82,
      initialChildSize: 0.53,
      minChildSize: 0.53,
      builder:
          (context, scrollController) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(.97),
            borderRadius:
                const BorderRadius.only(
              topLeft:
                  Radius.circular(34),
              topRight:
                  Radius.circular(34),
            ),
            border: Border.all(
              color: Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  .08,
                ),
                blurRadius: 25,
                offset:
                    const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller:
                scrollController,
            physics:
                const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration:
                        BoxDecoration(
                      color: pikkXNavy,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                _productSummary(),

                const SizedBox(height: 5),

                if (sellerName.isNotEmpty)
                  Text(
                    'Seller: $sellerName',
                    style:
                        const TextStyle(
                      color: pikkXMuted,
                      fontSize: 11,
                    ),
                  ),

                const SizedBox(height: 10),

                _rating(),

                const SizedBox(height: 25),

                _sectionTitle(
                  'Available Size',
                ),

                const SizedBox(height: 12),

                Row(
                  children:
                      List.generate(
                    sizes.length,
                    (index) =>
                        Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(
                          right: index ==
                                  sizes.length -
                                      1
                              ? 0
                              : 8,
                        ),
                        child:
                            _sizeWidget(
                          sizes[index],
                          index,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _sectionTitle(
                  'Available Color',
                ),

                const SizedBox(height: 14),

                Row(
                  children:
                      List.generate(
                    colors.length,
                    (index) => Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        right: 18,
                      ),
                      child:
                          _colorWidget(
                        colors[index],
                        index,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                _sectionTitle(
                  'Description',
                ),

                const SizedBox(height: 10),

                Text(
                  productDescription,
                  style:
                      const TextStyle(
                    color: pikkXMuted,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),

                const SizedBox(height: 25),

                _infoRow(
                  Icons
                      .local_shipping_outlined,
                  'Fast delivery',
                  'Get your order delivered quickly',
                ),

                const SizedBox(height: 12),

                _infoRow(
                  Icons
                      .verified_outlined,
                  'pikkX verified',
                  'Quality product from a trusted seller',
                ),

                const SizedBox(height: 30),

                _firebaseAddButton(),

                const SizedBox(height: 40),
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

  Widget _sectionTitle(
    String title,
  ) {
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

  Widget _sizeWidget(
    String text,
    int index,
  ) {
    final bool selected =
        selectedSize == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 220,
        ),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? pikkXNavy
              : pikkXBackground,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? pikkXNavy
                : pikkXBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        pikkXNavy.withOpacity(
                      .18,
                    ),
                    blurRadius: 10,
                    offset:
                        const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? pikkXWhite
                : pikkXBlack,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COLOR SELECTOR
  // ============================================================

  Widget _colorWidget(
    Color color,
    int index,
  ) {
    final bool selected =
        selectedColor == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),
        height: 38,
        width: 38,
        padding:
            const EdgeInsets.all(3),
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
                  color:
                      color == Colors.white
                          ? pikkXBlack
                          : pikkXWhite,
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
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pikkXBackground,
        borderRadius:
            BorderRadius.circular(17),
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
              color:
                  pikkXNavy.withOpacity(.09),
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
                  style:
                      const TextStyle(
                    color: pikkXBlack,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
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
  // FIREBASE ADD BUTTON
  // ============================================================

  Widget _firebaseAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            isAddingToCart
                ? null
                : _addToCart,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              pikkXBlack,
          disabledBackgroundColor:
              pikkXBlack.withOpacity(.65),
          foregroundColor:
              pikkXWhite,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
        child: isAddingToCart
            ? const SizedBox(
                height: 22,
                width: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: pikkXWhite,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  const Icon(
                    Icons
                        .shopping_bag_outlined,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
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

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: pikkXNavy,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          pikkXBackground,
      body: SafeArea(
        child: Container(
          decoration:
              const BoxDecoration(
            gradient:
                LinearGradient(
              colors: [
                pikkXBackground,
                Colors.white,
              ],
              begin:
                  Alignment.topCenter,
              end:
                  Alignment.bottomCenter,
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