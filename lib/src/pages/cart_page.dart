import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'product_detail_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    this.onContinueShopping,
  });

  final VoidCallback? onContinueShopping;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color pikkXBorder = Color(0xFFE8E8E8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _cartSubscription;

  bool _isLoading = true;
  String? _cartError;

  final Set<String> _updatingItems = <String>{};
  final Set<String> _removingItems = <String>{};

  List<Map<String, dynamic>> _cartItems = [];

  User? get _currentUser => _auth.currentUser;

  String? get _userId => _currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _cartRef {
    final uid = _userId;

    if (uid == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cart');
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _startCartListener();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // REAL-TIME CART LISTENER
  //
  // This replaces repeated:
  // Firebase write -> get() -> reload entire cart
  //
  // The UI stays synchronized with Firebase automatically.
  // ============================================================

  void _startCartListener() {
    final ref = _cartRef;

    if (ref == null) {
      if (!mounted) return;

      setState(() {
        _cartItems = [];
        _isLoading = false;
      });

      return;
    }

    _cartSubscription?.cancel();

    _cartSubscription = ref.snapshots().listen(
      (snapshot) {
        final items = snapshot.docs.map((doc) {
          return <String, dynamic>{
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          _cartItems = items;
          _isLoading = false;
          _cartError = null;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'PikkX CART STREAM ERROR: $error',
        );

        debugPrint(
          stackTrace.toString(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _cartError =
              'Could not load your cart.';
        });

        _showMessage(
          'Could not load your cart.',
        );
      },
    );
  }

  // ============================================================
  // MANUAL REFRESH
  // ============================================================

  Future<void> _refreshCart() async {
    final ref = _cartRef;

    if (ref == null) {
      return;
    }

    try {
      final snapshot = await ref.get();

      final items = snapshot.docs.map((doc) {
        return <String, dynamic>{
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _cartItems = items;
        _cartError = null;
      });
    } catch (e) {
      debugPrint(
        'PikkX CART REFRESH ERROR: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not refresh your cart.',
        );
      }
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  //
  // Optimistic UI:
  // 1. Update screen immediately.
  // 2. Write to Firebase.
  // 3. Real-time listener keeps everything synchronized.
  // ============================================================

  Future<void> _updateQuantity(
    Map<String, dynamic> item,
    int newQuantity,
  ) async {
    if (_userId == null) {
      _showMessage(
        'Please sign in first.',
      );
      return;
    }

    if (newQuantity < 1) {
      return;
    }

    final id = item['id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage(
        'This cart item is invalid.',
      );
      return;
    }

    if (_updatingItems.contains(id)) {
      return;
    }

    final ref = _cartRef;

    if (ref == null) {
      return;
    }

    final index = _cartItems.indexWhere(
      (cartItem) => cartItem['id']?.toString() == id,
    );

    if (index == -1) {
      return;
    }

    final oldQuantity =
        _getQuantity(_cartItems[index]);

    setState(() {
      _updatingItems.add(id);

      _cartItems[index] = {
        ..._cartItems[index],
        'quantity': newQuantity,
      };
    });

    try {
      await ref.doc(id).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      debugPrint(
        'PikkX QUANTITY UPDATE ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      // Restore old UI value if Firebase failed.
      final currentIndex = _cartItems.indexWhere(
        (cartItem) =>
            cartItem['id']?.toString() == id,
      );

      if (currentIndex != -1) {
        setState(() {
          _cartItems[currentIndex] = {
            ..._cartItems[currentIndex],
            'quantity': oldQuantity,
          };
        });
      }

      _showMessage(
        'Could not update quantity.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingItems.remove(id);
        });
      }
    }
  }

  Future<void> _increaseQuantity(
    Map<String, dynamic> item,
  ) async {
    final quantity = _getQuantity(item);

    await _updateQuantity(
      item,
      quantity + 1,
    );
  }

  Future<void> _decreaseQuantity(
    Map<String, dynamic> item,
  ) async {
    final quantity = _getQuantity(item);

    if (quantity <= 1) {
      return;
    }

    await _updateQuantity(
      item,
      quantity - 1,
    );
  }

  // ============================================================
  // REMOVE ITEM
  //
  // Optimistically removes it from the screen first.
  // Firebase remains the source of truth through the listener.
  // ============================================================

  Future<void> _removeItem(
    Map<String, dynamic> item,
  ) async {
    if (_userId == null) {
      _showMessage(
        'Please sign in first.',
      );
      return;
    }

    final id = item['id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage(
        'This cart item is invalid.',
      );
      return;
    }

    if (_removingItems.contains(id)) {
      return;
    }

    final ref = _cartRef;

    if (ref == null) {
      return;
    }

    final removedIndex = _cartItems.indexWhere(
      (cartItem) => cartItem['id']?.toString() == id,
    );

    if (removedIndex == -1) {
      return;
    }

    final removedItem = Map<String, dynamic>.from(
      _cartItems[removedIndex],
    );

    setState(() {
      _removingItems.add(id);
      _cartItems.removeAt(removedIndex);
    });

    try {
      await ref.doc(id).delete();

      if (mounted) {
        _showMessage(
          'Item removed from cart.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'PikkX REMOVE CART ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      // Restore item if Firebase deletion failed.
      setState(() {
        final alreadyExists = _cartItems.any(
          (cartItem) =>
              cartItem['id']?.toString() == id,
        );

        if (!alreadyExists) {
          final safeIndex =
              removedIndex.clamp(
            0,
            _cartItems.length,
          );

          _cartItems.insert(
            safeIndex,
            removedItem,
          );
        }
      });

      _showMessage(
        'Could not remove item.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _removingItems.remove(id);
        });
      }
    }
  }

  // ============================================================
  // OPEN PRODUCT DETAIL
  //
  // Clicking the product image OR product information takes
  // the user back to ProductDetailPage using the same product ID.
  // ============================================================

  void _openProductDetail(
    Map<String, dynamic> item,
  ) {
    final productId =
        item['productId']?.toString().trim().isNotEmpty == true
            ? item['productId'].toString()
            : item['id']?.toString();

    if (productId == null || productId.isEmpty) {
      _showMessage(
        'Product details are unavailable.',
      );
      return;
    }

    final product = _buildProductForDetail(
      item,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          productId: productId,
          product: product,
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT DETAIL DATA
  //
  // The Nike fallback means the cart can still reopen the Nike
  // Product Detail screen even while Firebase products is empty.
  // ============================================================

  Map<String, dynamic> _buildProductForDetail(
    Map<String, dynamic> item,
  ) {
    const nikeImages = [
      'assets/images/blue_nike.jpg',
      'assets/images/grey_nike.jpg',
      'assets/images/purple_nike.jpg',
    ];

    final productId =
        item['productId']?.toString() ??
            item['id']?.toString() ??
            '';

    final isNike =
        productId == 'pikkx-nike' ||
        _getName(item).toLowerCase() == 'nike';

    final storedImages = _readStringList(
      item['images'],
    );

    final primaryImage =
        _getImage(item);

    final images = storedImages.isNotEmpty
        ? storedImages
        : primaryImage.isNotEmpty
            ? <String>[
                primaryImage,
              ]
            : isNike
                ? nikeImages
                : <String>[];

    final name = _getName(item);

    return {
      if (isNike) ...{
        'id': 'pikkx-nike',
        'productId': 'pikkx-nike',
        'name': 'Nike',
        'title': 'Nike',
        'category': 'Fashion',
        'price': 45000.0,
        'originalPrice': 55000.0,
        'currency': 'NGN',
        'image': nikeImages.first,
        'imageUrl': nikeImages.first,
        'images': nikeImages,
        'colors': const [
          'Blue',
          'Grey',
          'Purple',
        ],
        'sizes': const [
          'US 6',
          'US 7',
          'US 8',
          'US 9',
        ],
        'rating': 4.8,
        'reviews': 124,
        'deliveryTime': '25 min',
        'deliveryEstimate':
            'Arrives Sep 14–16',
        'sellerId': 'pikkx_demo_seller',
        'sellerName': 'PikkX Fashion',
        'description':
            'Premium Nike sneakers with a clean everyday design.',
        'isFeatured': true,
      },

      // Real cart data overrides fallback values.
      ...item,

      // Ensure Product Detail has these useful fields.
      'id': productId,
      'productId': productId,
      'name': name,
      'title': item['title']?.toString() ?? name,
      'images': images,
      'image': primaryImage.isNotEmpty
          ? primaryImage
          : images.isNotEmpty
              ? images.first
              : '',
      'imageUrl': primaryImage.isNotEmpty
          ? primaryImage
          : images.isNotEmpty
              ? images.first
              : '',
      'quantity': _getQuantity(item),
      'size': _getSize(item),
      'selectedColor': _getColor(item),
    };
  }

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .map(
          (entry) => entry.toString().trim(),
        )
        .where(
          (entry) => entry.isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // DATA HELPERS
  // ============================================================

  double _getPrice(
    Map<String, dynamic> item,
  ) {
    final value = item['price'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int _getQuantity(
    Map<String, dynamic> item,
  ) {
    final value = item['quantity'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        1;
  }

  String _getName(
    Map<String, dynamic> item,
  ) {
    final name =
        item['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final title =
        item['title']?.toString().trim();

    if (title != null && title.isNotEmpty) {
      return title;
    }

    return 'Product';
  }

  String _getImage(
    Map<String, dynamic> item,
  ) {
    final imageUrl =
        item['imageUrl']?.toString().trim() ?? '';

    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        item['image']?.toString().trim() ?? '';

    if (image.isNotEmpty) {
      return image;
    }

    final images = item['images'];

    if (images is List && images.isNotEmpty) {
      final first =
          images.first?.toString().trim() ?? '';

      if (first.isNotEmpty) {
        return first;
      }
    }

    return '';
  }

  String _getSize(
    Map<String, dynamic> item,
  ) {
    final size =
        item['size']?.toString().trim() ?? '';

    return size;
  }

  String _getColor(
    Map<String, dynamic> item,
  ) {
    final selectedColor =
        item['selectedColor']?.toString().trim() ?? '';

    if (selectedColor.isNotEmpty) {
      return selectedColor;
    }

    return item['color']?.toString().trim() ?? '';
  }

  String _getCurrencySymbol(
    Map<String, dynamic> item,
  ) {
    final currency =
        item['currency']?.toString().trim().toUpperCase();

    switch (currency) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
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

  String _formatMoney(
    double amount,
    Map<String, dynamic> item,
  ) {
    return '${_getCurrencySymbol(item)}'
        '${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // TOTALS
  // ============================================================

  double get subtotal {
    return _cartItems.fold(
      0.0,
      (sum, item) {
        return sum +
            (_getPrice(item) *
                _getQuantity(item));
      },
    );
  }

  int get totalItemCount {
    return _cartItems.fold(
      0,
      (sum, item) {
        return sum + _getQuantity(item);
      },
    );
  }

  // Keep delivery at zero here until the actual delivery system
  // supplies a real fee. No fake ₦500 charge.
  double get deliveryFee => 0.0;

  double get total {
    return subtotal + deliveryFee;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: pikkXWhite,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: pikkXWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: pikkXBlack,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            92,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
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

      // IMPORTANT:
      // No AppBar here.
      //
      // Cart is a MainPage tab and therefore has NO back arrow.
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: pikkXBlack,
        ),
      );
    }

    if (_userId == null) {
      return _buildSignInState();
    }

    if (_cartError != null &&
        _cartItems.isEmpty) {
      return _buildErrorState();
    }

    if (_cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return _buildCart();
  }

  // ============================================================
  // CART
  // ============================================================

  Widget _buildCart() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: pikkXBlack,
            backgroundColor: pikkXWhite,
            onRefresh: _refreshCart,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(
                parent:
                    BouncingScrollPhysics(),
              ),

              // Extra bottom space is intentional.
              //
              // MainPage places the floating navigation
              // above this screen using Stack/Positioned.
              //
              // This prevents the final content and checkout
              // area from being hidden underneath it.
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                125,
              ),

              children: [
                _sectionTitle(
                  'Your Items',
                ),

                const SizedBox(height: 6),

                ..._cartItems.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 9,
                    ),
                    child:
                        _buildCartItem(item),
                  ),
                ),

                const SizedBox(height: 7),

                _sectionTitle(
                  'Order Summary',
                ),

                const SizedBox(height: 6),

                _buildSummary(),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),

        // Checkout is inside the page but has enough
        // clearance from MainPage's floating navigation.
        _buildCheckoutButton(),
      ],
    );
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget _buildCartItem(
    Map<String, dynamic> item,
  ) {
    final name = _getName(item);
    final price = _getPrice(item);
    final quantity = _getQuantity(item);
    final image = _getImage(item);
    final size = _getSize(item);
    final color = _getColor(item);
    final id = item['id']?.toString() ?? '';

    final isUpdating =
        _updatingItems.contains(id);

    final isRemoving =
        _removingItems.contains(id);

    return _glass(
      radius: 21,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRemoving
              ? null
              : () => _openProductDetail(
                    item,
                  ),
          borderRadius:
              BorderRadius.circular(21),
          child: Padding(
            padding:
                const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                // ------------------------------------------------
                // PRODUCT IMAGE
                //
                // CLICKING IMAGE OPENS PRODUCT DETAIL.
                // ------------------------------------------------

                GestureDetector(
                  onTap: isRemoving
                      ? null
                      : () =>
                          _openProductDetail(
                            item,
                          ),
                  child:
                      _buildProductImage(
                    image,
                    isLoading: isRemoving,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                          color: pikkXBlack,
                        ),
                      ),

                      if (size.isNotEmpty ||
                          color.isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Text(
                          [
                            if (color.isNotEmpty)
                              color,
                            if (size.isNotEmpty)
                              size,
                          ].join(' • '),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: pikkXGrey,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 5),

                      Text(
                        _formatMoney(
                          price,
                          item,
                        ),
                        style:
                            const TextStyle(
                          color: pikkXBlack,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _quantityButton(
                            icon:
                                Icons.remove_rounded,
                            onPressed:
                                isUpdating ||
                                        isRemoving
                                    ? null
                                    : () =>
                                        _decreaseQuantity(
                                          item,
                                        ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 11,
                            ),
                            child: AnimatedSwitcher(
                              duration:
                                  const Duration(
                                milliseconds: 150,
                              ),
                              child: Text(
                                '$quantity',
                                key: ValueKey(
                                  quantity,
                                ),
                                style:
                                    const TextStyle(
                                  color:
                                      pikkXBlack,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          _quantityButton(
                            icon:
                                Icons.add_rounded,
                            onPressed:
                                isUpdating ||
                                        isRemoving
                                    ? null
                                    : () =>
                                        _increaseQuantity(
                                          item,
                                        ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 3),

                _deleteButton(
                  item,
                  disabled:
                      isUpdating ||
                          isRemoving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    String image, {
    bool isLoading = false,
  }) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: pikkXBackground,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: pikkXBorder,
        ),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: pikkXBlack,
                ),
              ),
            )
          : image.isEmpty
              ? _imageFallback()
              : ClipRRect(
                  borderRadius:
                      BorderRadius.circular(18),
                  child:
                      _imageWidget(image),
                ),
    );
  }

  Widget _imageWidget(
    String image,
  ) {
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.contain,
        cacheWidth: 220,
        cacheHeight: 220,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            'PikkX asset image error: '
            '$image\n$error',
          );

          return _imageFallback();
        },
      );
    }

    return Image.network(
      image,
      fit: BoxFit.contain,

      // Keeps downloaded product images
      // reasonably sized for this small cart card.
      cacheWidth: 220,
      cacheHeight: 220,

      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color: pikkXBlack,
            ),
          ),
        );
      },

      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        debugPrint(
          'PikkX network image error: '
          '$image\n$error',
        );

        return _imageFallback();
      },
    );
  }

  // ============================================================
  // IMAGE FALLBACK
  // ============================================================

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color:
            pikkXBlack.withOpacity(0.035),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_cart_outlined,
          color: pikkXBlack,
          size: 28,
        ),
      ),
    );
  }

  // ============================================================
  // DELETE BUTTON
  // ============================================================

  Widget _deleteButton(
    Map<String, dynamic> item, {
    bool disabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled
            ? null
            : () => _removeItem(item),
        borderRadius:
            BorderRadius.circular(13),
        child: AnimatedOpacity(
          duration:
              const Duration(milliseconds: 150),
          opacity: disabled ? 0.45 : 1,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.62),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: pikkXBorder,
              ),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: pikkXBlack,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUANTITY BUTTON
  // ============================================================

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(9),
        child: AnimatedOpacity(
          duration:
              const Duration(milliseconds: 150),
          opacity:
              onPressed == null ? 0.45 : 1,
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: pikkXBlack,
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 16,
              color: pikkXWhite,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final firstItem =
        _cartItems.isNotEmpty
            ? _cartItems.first
            : <String, dynamic>{};

    return _glass(
      radius: 21,
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          children: [
            _summaryRow(
              'Items',
              '$totalItemCount',
            ),

            const SizedBox(height: 9),

            _summaryRow(
              'Subtotal',
              _formatMoney(
                subtotal,
                firstItem,
              ),
            ),

            const SizedBox(height: 9),

            _summaryRow(
              'Delivery fee',
              deliveryFee == 0
                  ? 'Calculated at checkout'
                  : _formatMoney(
                      deliveryFee,
                      firstItem,
                    ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 11,
              ),
              child: Container(
                height: 1,
                color: pikkXBorder,
              ),
            ),

            _summaryRow(
              'Total',
              _formatMoney(
                total,
                firstItem,
              ),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize:
                  isTotal ? 16 : 13,
              fontWeight:
                  isTotal
                      ? FontWeight.w800
                      : FontWeight.w500,
              color: pikkXBlack,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize:
                  isTotal ? 17 : 13,
              fontWeight:
                  FontWeight.w800,
              color: pikkXBlack,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHECKOUT
  //
  // Large bottom clearance is intentional because MainPage
  // overlays the floating navigation using Positioned.
  // ============================================================

  Widget _buildCheckoutButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          96,
        ),
        child: _primaryButton(
          text: 'Proceed to Checkout',
          icon:
              Icons.arrow_forward_rounded,
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/checkout',
            );
          },
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(19),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: pikkXBlack,
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: pikkXWhite,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                icon,
                color: pikkXWhite,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CART
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          22,
          22,
          22,
          120,
        ),
        child: _glass(
          radius: 27,
          child: Padding(
            padding:
                const EdgeInsets.all(25),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration:
                      BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 37,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Your cart is empty',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                    color: pikkXBlack,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Add products to your cart and they will appear here.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: pikkXGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                _smallActionButton(
                  text:
                      'Continue Shopping',
                  onPressed: () {
                    widget
                        .onContinueShopping
                        ?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Widget _buildSignInState() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          22,
          22,
          22,
          120,
        ),
        child: _glass(
          radius: 27,
          child: Padding(
            padding:
                const EdgeInsets.all(25),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration:
                      BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Sign in to view your cart',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                    color: pikkXBlack,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Your cart is saved securely to your account.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: pikkXGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                _smallActionButton(
                  text: 'Sign In',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/sign-in',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          22,
          22,
          22,
          120,
        ),
        child: _glass(
          radius: 27,
          child: Padding(
            padding:
                const EdgeInsets.all(25),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration:
                      BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 36,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Something went wrong',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                    color: pikkXBlack,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'We could not load your cart.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: pikkXGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                _smallActionButton(
                  text: 'Try Again',
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _cartError = null;
                    });

                    _startCartListener();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SMALL BUTTON
  // ============================================================

  Widget _smallActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: pikkXBlack,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: pikkXWhite,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 3,
        bottom: 5,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: pikkXBlack,
        ),
      ),
    );
  }

  // ============================================================
  // GLASS FIXTURE
  // ============================================================

  Widget _glass({
    required Widget child,
    double radius = 24,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.70),
            borderRadius:
                BorderRadius.circular(radius),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.90),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.055),
                blurRadius: 22,
                offset:
                    const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}