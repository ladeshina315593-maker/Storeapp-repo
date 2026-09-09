import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pikkx/src/pages/chat_page.dart';

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
  bool isFollowing = false;
  bool isFollowLoading = false;

  int selectedSize = 1;
  int selectedColor = 0;

  // ============================================================
  // NIKE DEMO PRODUCT
  // ============================================================

  static const Map<String, dynamic> nikeDemoProduct = {
    'name': 'Nike Air Sneakers',
    'title': 'Nike Air Sneakers',
    'category': 'Fashion',
    'price': 45000.0,
    'originalPrice': 55000.0,
    'currency': 'NGN',
    'rating': 4.8,
    'reviews': 124,
    'sellerId': 'pikkx_demo_seller',
    'sellerName': 'PikkX Fashion',
    'description':
        'Classic Nike sneakers with a clean everyday design. '
            'Comfortable, stylish and available in multiple colours and sizes.',
    'deliveryEstimate': 'Arrives in 2–4 days',
  };

  // These assets already exist in your project.
  static const List<String> nikeImages = [
    'assets/images/blue_nike.jpg',
    'assets/images/grey_nike.jpg',
    'assets/images/purple_nike.jpg',
  ];

  static const List<String> colorNames = [
    'Blue',
    'Grey',
    'Purple',
  ];

  static const List<String> sizes = [
    'US 6',
    'US 7',
    'US 8',
    'US 9',
  ];

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXMuted = Color(0xFF777777);
  static const Color pikkXBorder = Color(0xFFE8E8E8);

  static const Color ratingYellow = Color(0xFFFFC107);
  static const Color favouriteRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
    _loadFollowStatus();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // PRODUCT DATA
  // ============================================================

  Map<String, dynamic> get productData {
    if (widget.product.isEmpty) {
      return Map<String, dynamic>.from(nikeDemoProduct);
    }

    final data = Map<String, dynamic>.from(nikeDemoProduct);
    data.addAll(widget.product);

    return data;
  }

  String get productName {
    final name = productData['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final title = productData['title']?.toString().trim();

    if (title != null && title.isNotEmpty) {
      return title;
    }

    return 'Nike Air Sneakers';
  }

  String get productDescription {
    final value = productData['description']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return nikeDemoProduct['description'].toString();
  }

  String get productCategory {
    final value = productData['category']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Fashion';
  }

  String get sellerName {
    final value = productData['sellerName']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'PikkX Fashion';
  }

  String get sellerId {
    final value = productData['sellerId']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'pikkx_demo_seller';
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

  double get productPrice {
    final price = _toDouble(productData['price']);

    if (price > 0) {
      return price;
    }

    return 45000;
  }

  double get originalPrice {
    final value = _toDouble(
      productData['originalPrice'],
    );

    if (value > productPrice) {
      return value;
    }

    return 0;
  }

  int get discountPercent {
    if (originalPrice <= productPrice ||
        originalPrice <= 0) {
      return 0;
    }

    return (((originalPrice - productPrice) /
                originalPrice) *
            100)
        .round();
  }

  double get savings {
    if (originalPrice <= productPrice) {
      return 0;
    }

    return originalPrice - productPrice;
  }

  // ------------------------------------------------------------
  // Currency
  // ------------------------------------------------------------

  String get currencyCode {
    final value = productData['currency']
        ?.toString()
        .trim()
        .toUpperCase();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'NGN';
  }

  String get currencySymbol {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'GHS':
        return 'GH₵';
      case 'KES':
        return 'KSh';
      case 'ZAR':
        return 'R';
      case 'NGN':
      default:
        return '₦';
    }
  }

  String _formatMoney(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  String get formattedPrice {
    return _formatMoney(productPrice);
  }

  String get formattedOriginalPrice {
    return _formatMoney(originalPrice);
  }

  String get formattedSavings {
    return _formatMoney(savings);
  }

  // ============================================================
  // IMAGE DATA
  // ============================================================

  List<String> get productImages {
    final rawImages = productData['images'];

    if (rawImages is List) {
      final firebaseImages = rawImages
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();

      if (firebaseImages.isNotEmpty) {
        return firebaseImages;
      }
    }

    final imageUrl = productData['imageUrl']
        ?.toString()
        .trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return [imageUrl];
    }

    final image = productData['image']
        ?.toString()
        .trim();

    if (image != null && image.isNotEmpty) {
      return [image];
    }

    // No Firebase product yet:
    // use the Nike demo images.
    return nikeImages;
  }

  String get selectedImage {
    final images = productImages;

    if (selectedColor >= images.length) {
      selectedColor = 0;
    }

    return images[selectedColor];
  }

  String get selectedColorName {
    if (selectedColor >= colorNames.length) {
      return colorNames.first;
    }

    return colorNames[selectedColor];
  }

  String get deliveryEstimate {
    final value = productData['deliveryEstimate']
        ?.toString()
        .trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Arrives in 2–4 days';
  }

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: pikkXWhite,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: pikkXWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: pikkXBlack,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // FAVOURITE STATUS
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

  // ============================================================
  // TOGGLE FAVOURITE
  // ============================================================

  Future<void> _toggleFavourite() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to save favourites.',
        error: true,
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

        if (!mounted) return;

        setState(() {
          isLiked = false;
        });

        _showMessage('Removed from favourites');
        return;
      }

      final favoriteData = <String, dynamic>{
        'productId': widget.productId,
        'name': productName,
        'title': productName,
        'price': productPrice,
        'currency': currencyCode,
        'imageUrl': selectedImage,
        'image': selectedImage,
        'images': productImages,
        'category': productCategory,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'description': productDescription,
        'selectedColor': selectedColorName,
        'colorIndex': selectedColor,
        'size': sizes[selectedSize],
        'rating': productData['rating'],
        'reviews': productData['reviews'],
        'originalPrice': productData['originalPrice'],
        'deliveryEstimate': deliveryEstimate,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      favoriteData.removeWhere(
        (key, value) => value == null,
      );

      await reference.set(favoriteData);

      if (!mounted) return;

      setState(() {
        isLiked = true;
      });

      _showMessage('Added to favourites ❤️');
    } catch (e, stackTrace) {
      debugPrint('PikkX Favourite ERROR: $e');
      debugPrint('Favourite stackTrace: $stackTrace');

      _showMessage(
        'Could not update favourite. Please try again.',
        error: true,
      );
    }
  }

  // ============================================================
  // FOLLOW STATUS
  // ============================================================

  Future<void> _loadFollowStatus() async {
    final user = currentUser;

    if (user == null || sellerId.isEmpty) {
      return;
    }

    try {
      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(sellerId);

      final snapshot = await reference.get();

      if (!mounted) return;

      setState(() {
        isFollowing = snapshot.exists;
      });
    } catch (e) {
      debugPrint('Load follow status error: $e');
    }
  }

  // ============================================================
  // FOLLOW MERCHANT
  // ============================================================

  Future<void> _toggleFollow() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to follow sellers.',
        error: true,
      );
      return;
    }

    if (sellerId.isEmpty || isFollowLoading) {
      return;
    }

    setState(() {
      isFollowLoading = true;
    });

    try {
      final followReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(sellerId);

      if (isFollowing) {
        await followReference.delete();

        if (!mounted) return;

        setState(() {
          isFollowing = false;
        });

        _showMessage('Unfollowed $sellerName');
      } else {
        await followReference.set({
          'merchantId': sellerId,
          'sellerId': sellerId,
          'merchantName': sellerName,
          'sellerName': sellerName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Keep the existing notification behaviour.
        final notificationReference = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc();

        await notificationReference.set({
          'type': 'merchant_follow',
          'title': 'Merchant followed',
          'message': 'You followed $sellerName.',
          'merchantId': sellerId,
          'sellerId': sellerId,
          'sellerName': sellerName,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        setState(() {
          isFollowing = true;
        });

        _showMessage('Now following $sellerName');
      }
    } catch (e, stackTrace) {
      debugPrint('PikkX Follow ERROR: $e');
      debugPrint('Follow stackTrace: $stackTrace');

      _showMessage(
        'Could not update follow status.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isFollowLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CHAT
  // ============================================================

  Future<void> _openMerchantChat() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to chat with the seller.',
        error: true,
      );
      return;
    }

    if (sellerId.isEmpty) {
      _showMessage(
        'Seller chat is unavailable.',
        error: true,
      );
      return;
    }

    final ids = [
      user.uid,
      sellerId,
    ]..sort();

    final chatId = ids.join('_');

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(
        {
          'participants': FieldValue.arrayUnion([
            user.uid,
            sellerId,
          ]),
          'otherUserName': sellerName,
          'sellerId': sellerId,
          'sellerName': sellerName,
          'productId': widget.productId,
          'productName': productName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ChatPageLauncher(
            chatId: chatId,
            otherUserName: sellerName,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('PikkX Chat ERROR: $e');
      debugPrint('Chat stackTrace: $stackTrace');

      _showMessage(
        'Could not open seller chat.',
        error: true,
      );
    }
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart() async {
    final user = currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to add products to your cart.',
        error: true,
      );
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

      // Transaction avoids a separate read before writing.
      // This is safer and faster for quantity updates.
      await _firestore.runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(cartReference);

          int quantity = 1;

          if (snapshot.exists) {
            final data = snapshot.data();

            final existingQuantity =
                data?['quantity'];

            if (existingQuantity is num) {
              quantity =
                  existingQuantity.toInt() + 1;
            } else {
              quantity =
                  (int.tryParse(
                            existingQuantity
                                    ?.toString() ??
                                '',
                          ) ??
                          1) +
                      1;
            }
          }

          final cartData = <String, dynamic>{
            'productId': widget.productId,
            'name': productName,
            'title': productName,
            'price': productPrice,
            'currency': currencyCode,
            'imageUrl': selectedImage,
            'image': selectedImage,
            'images': productImages,
            'quantity': quantity,
            'sellerId': sellerId,
            'sellerName': sellerName,
            'category': productCategory,
            'description': productDescription,
            'size': sizes[selectedSize],
            'color': selectedColorName,
            'colorIndex': selectedColor,
            'selectedColor': selectedColorName,
            'rating': productData['rating'],
            'reviews': productData['reviews'],
            'originalPrice':
                productData['originalPrice'],
            'updatedAt':
                FieldValue.serverTimestamp(),
          };

          cartData.removeWhere(
            (key, value) => value == null,
          );

          if (snapshot.exists) {
            transaction.update(
              cartReference,
              cartData,
            );
          } else {
            cartData['createdAt'] =
                FieldValue.serverTimestamp();

            transaction.set(
              cartReference,
              cartData,
            );
          }
        },
      );

      debugPrint(
        'PikkX cart write successful: '
        'product=${widget.productId}, '
        'name=$productName, '
        'price=$productPrice, '
        'image=$selectedImage, '
        'size=${sizes[selectedSize]}, '
        'color=$selectedColorName',
      );

      if (!mounted) return;

      _showMessage(
        'Product added successfully 🛒',
      );
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('PIKKX ADD TO CART ERROR');
      debugPrint('productId: ${widget.productId}');
      debugPrint('productName: $productName');
      debugPrint('price: $productPrice');
      debugPrint('image: $selectedImage');
      debugPrint('size: ${sizes[selectedSize]}');
      debugPrint('color: $selectedColorName');
      debugPrint('sellerId: $sellerId');
      debugPrint('error: $e');
      debugPrint('stackTrace: $stackTrace');
      debugPrint('================================');

      if (mounted) {
        _showMessage(
          'Could not add product to cart. Please try again.',
          error: true,
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
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        10,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          _glassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleFavourite,
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
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: 180),
                      child: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isLiked),
                        color: isLiked
                            ? favouriteRed
                            : pikkXBlack,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(String path) {
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.image_not_supported_outlined,
            size: 55,
            color: pikkXMuted,
          );
        },
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.image_not_supported_outlined,
          size: 55,
          color: pikkXMuted,
        );
      },
    );
  }

  Widget _productImageCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            height: 330,
            width: double.infinity,
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
                      color:
                          Colors.black.withOpacity(0.035),
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
                      color:
                          Colors.black.withOpacity(0.025),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    final velocity =
                        details.primaryVelocity ?? 0;

                    final images = productImages;

                    if (images.length <= 1) {
                      return;
                    }

                    if (velocity < 0) {
                      setState(() {
                        selectedColor =
                            (selectedColor + 1) %
                                images.length;
                      });
                    } else if (velocity > 0) {
                      setState(() {
                        selectedColor =
                            (selectedColor -
                                    1 +
                                    images.length) %
                                images.length;
                      });
                    }
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        15,
                        18,
                        42,
                      ),
                      child: AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 280),
                        child: SizedBox(
                          key: ValueKey(selectedImage),
                          width: double.infinity,
                          height: 255,
                          child: _buildProductImage(
                            selectedImage,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
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
    );
  }

  // ============================================================
  // THUMBNAILS
  // ============================================================

  Widget _thumbnailRow() {
    final images = productImages;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          images.length,
          (index) {
            final selected =
                selectedColor == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = index;
                });
              },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 180),
                margin:
                    const EdgeInsets.symmetric(horizontal: 4),
                height: selected ? 8 : 6,
                width: selected ? 22 : 6,
                decoration: BoxDecoration(
                  color: selected
                      ? pikkXBlack
                      : pikkXBlack.withOpacity(0.18),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
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
              const SizedBox(height: 4),
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
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Text(
              formattedPrice,
              style: const TextStyle(
                color: pikkXBlack,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (originalPrice > productPrice) ...[
              const SizedBox(height: 2),
              Text(
                formattedOriginalPrice,
                style: const TextStyle(
                  color: pikkXMuted,
                  fontSize: 11,
                  decoration:
                      TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DISCOUNT
  // ============================================================

  Widget _discountCard() {
    if (discountPercent <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pikkXBlack.withOpacity(0.045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: pikkXBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: pikkXBlack,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$discountPercent% OFF',
              style: const TextStyle(
                color: pikkXWhite,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You save $formattedSavings',
              style: const TextStyle(
                color: pikkXBlack,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
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
        _toDouble(productData['rating']) > 0
            ? _toDouble(productData['rating'])
            : 4.8;

    final reviewsValue =
        productData['reviews'];

    final reviews =
        reviewsValue is num
            ? reviewsValue.toInt()
            : int.tryParse(
                  reviewsValue?.toString() ?? '',
                ) ??
                124;

    return Row(
      children: [
        Row(
          children: List.generate(
            5,
            (index) {
              final filled =
                  index < rating.round();

              return Icon(
                filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: ratingYellow,
                size: 18,
              );
            },
          ),
        ),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1),
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
  // SELLER
  // ============================================================

  Widget _sellerSection() {
    if (sellerName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: pikkXBlack.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: pikkXBlack,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seller',
                  style: TextStyle(
                    color: pikkXMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sellerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // CHAT
          _sellerActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: _openMerchantChat,
          ),

          const SizedBox(width: 7),

          // FOLLOW
          _sellerActionButton(
            icon: isFollowing
                ? Icons.check_rounded
                : Icons.add_rounded,
            onTap: _toggleFollow,
            loading: isFollowLoading,
          ),
        ],
      ),
    );
  }

  Widget _sellerActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: pikkXBlack.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: pikkXBorder,
            ),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: pikkXBlack,
                  ),
                )
              : Icon(
                  icon,
                  color: pikkXBlack,
                  size: 20,
                ),
        ),
      ),
    );
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Widget _reviewsSection() {
    final reviewCount =
        productData['reviews'];

    final count = reviewCount is num
        ? reviewCount.toInt()
        : int.tryParse(
              reviewCount?.toString() ?? '',
            ) ??
            124;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Reviews'),
            Text(
              '$count reviews',
              style: const TextStyle(
                color: pikkXMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Demo reviews for the Nike test product.
        // These can later come from Firestore.
        _reviewCard(
          name: 'Amina',
          rating: 5,
          text:
              'The sneakers look great and the fit is really comfortable.',
        ),

        const SizedBox(height: 8),

        _reviewCard(
          name: 'Daniel',
          rating: 4,
          text:
              'Nice quality and the colour looks just like the product.',
        ),
      ],
    );
  }

  Widget _reviewCard({
    required String name,
    required int rating,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pikkXBlack.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: ratingYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: pikkXMuted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL SHEET
  // ============================================================

  Widget _detailWidget() {
    return DraggableScrollableSheet(
      maxChildSize: 0.86,
      initialChildSize: 0.56,
      minChildSize: 0.56,
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
                18,
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
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 115,
                ),
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

                    const SizedBox(height: 16),

                    _productSummary(),

                    const SizedBox(height: 10),

                    _discountCard(),

                    const SizedBox(height: 10),

                    _rating(),

                    const SizedBox(height: 14),

                    _sellerSection(),

                    const SizedBox(height: 20),

                    _sectionTitle('Available Size'),

                    const SizedBox(height: 10),

                    Row(
                      children: List.generate(
                        sizes.length,
                        (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index ==
                                        sizes.length - 1
                                    ? 0
                                    : 7,
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

                    const SizedBox(height: 19),

                    _sectionTitle('Available Color'),

                    const SizedBox(height: 10),

                    _colorSelector(),

                    const SizedBox(height: 20),

                    _sectionTitle('Description'),

                    const SizedBox(height: 8),

                    Text(
                      productDescription,
                      style: const TextStyle(
                        color: pikkXMuted,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _infoRow(
                      Icons.local_shipping_outlined,
                      'Fast delivery',
                      'Get your order delivered quickly',
                    ),

                    const SizedBox(height: 9),

                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Delivery estimate',
                      deliveryEstimate,
                    ),

                    const SizedBox(height: 9),

                    _infoRow(
                      Icons.verified_outlined,
                      'PikkX verified',
                      'Quality product from a trusted seller',
                    ),

                    const SizedBox(height: 22),

                    _reviewsSection(),

                    const SizedBox(height: 22),

                    _firebaseAddButton(),

                    const SizedBox(height: 25),
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
    final selected =
        selectedSize == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 220),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? pikkXBlack
              : Colors.white.withOpacity(0.55),
          borderRadius:
              BorderRadius.circular(14),
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
    final images = productImages;

    return Row(
      children: List.generate(
        images.length,
        (index) {
          final selected =
              selectedColor == index;

          final colorName =
              index < colorNames.length
                  ? colorNames[index]
                  : 'Option ${index + 1}';

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
                  right: index == images.length - 1
                      ? 0
                      : 8,
                ),
                padding:
                    const EdgeInsets.all(6),
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
                      child: _buildProductImage(
                        images[index],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      colorName,
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
      padding: const EdgeInsets.all(12),
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
          const SizedBox(width: 11),
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
                const SizedBox(height: 2),
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
  // NORMAL ADD TO CART BUTTON
  // ============================================================

  Widget _firebaseAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
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
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: isAddingToCart
            ? const SizedBox(
                height: 21,
                width: 21,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: pikkXWhite,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_rounded,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
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
  // STICKY CART
  // ============================================================

  Widget _stickyCartBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color:
                    Colors.white.withOpacity(0.95),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          formattedPrice,
                          style: const TextStyle(
                            color: pikkXBlack,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$selectedColorName • '
                          '${sizes[selectedSize]}',
                          style: const TextStyle(
                            color: pikkXMuted,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        isAddingToCart
                            ? null
                            : _addToCart,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          pikkXBlack,
                      foregroundColor:
                          pikkXWhite,
                      disabledBackgroundColor:
                          pikkXBlack
                              .withOpacity(0.65),
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 21,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: isAddingToCart
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: pikkXWhite,
                            ),
                          )
                        : const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .shopping_cart_rounded,
                                size: 18,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w800,
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

              _stickyCartBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CHAT LAUNCHER
// ================================================================

class _ChatPageLauncher
    extends StatelessWidget {
  const _ChatPageLauncher({
    required this.chatId,
    required this.otherUserName,
  });

  final String chatId;
  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    return ChatPage(
      chatId: chatId,
      otherUserName: otherUserName,
    );
  }
}