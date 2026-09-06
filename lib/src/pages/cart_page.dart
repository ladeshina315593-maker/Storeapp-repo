import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isUpdating = false;

  List<Map<String, dynamic>> _cartItems = [];

  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXMuted = Color(0xFF777777);
  static const Color pikkXBorder = Color(0xFFE8E8E8);

  User? get _currentUser => _auth.currentUser;

  String? get _userId => _currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _cartRef {
    final uid = _userId;

    if (uid == null) {
      throw StateError('User is not signed in.');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cart');
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ============================================================
  // FIREBASE CART
  // ============================================================

  Future<void> _loadCart() async {
    if (_userId == null) {
      if (!mounted) return;

      setState(() {
        _cartItems = [];
        _isLoading = false;
      });

      return;
    }

    try {
      final snapshot = await _cartRef.get();

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
      });
    } catch (e) {
      debugPrint('Cart loading error: $e');

      if (!mounted) return;

      setState(() {
        _cartItems = [];
        _isLoading = false;
      });

      _showMessage('Could not load your cart.');
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================

  Future<void> _updateQuantity(
    Map<String, dynamic> item,
    int newQuantity,
  ) async {
    if (_userId == null) {
      _showMessage('Please sign in first.');
      return;
    }

    if (newQuantity < 1) return;

    final id = item['id']?.toString();

    if (id == null || id.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _cartRef.doc(id).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadCart();
    } catch (e) {
      debugPrint('Quantity update error: $e');

      if (mounted) {
        _showMessage('Could not update quantity.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
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
  // ============================================================

  Future<void> _removeItem(
    Map<String, dynamic> item,
  ) async {
    if (_userId == null) {
      _showMessage('Please sign in first.');
      return;
    }

    final id = item['id']?.toString();

    if (id == null || id.isEmpty) return;

    try {
      await _cartRef.doc(id).delete();

      await _loadCart();

      if (mounted) {
        _showMessage('Item removed from cart.');
      }
    } catch (e) {
      debugPrint('Remove cart item error: $e');

      if (mounted) {
        _showMessage('Could not remove item.');
      }
    }
  }

  // ============================================================
  // HELPERS
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
    final name = item['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Product';
    }

    return name;
  }

  String _getImageUrl(
    Map<String, dynamic> item,
  ) {
    final imageUrl = item['imageUrl']?.toString().trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image = item['image']?.toString().trim();

    if (image != null && image.isNotEmpty) {
      return image;
    }

    return '';
  }

  String _getColor(
    Map<String, dynamic> item,
  ) {
    final color =
        item['selectedColor']?.toString().trim();

    if (color == null || color.isEmpty) {
      return '';
    }

    return color;
  }

  String _getSize(
    Map<String, dynamic> item,
  ) {
    final size = item['size']?.toString().trim();

    if (size == null || size.isEmpty) {
      return '';
    }

    return size;
  }

  bool _isAssetImage(String imageUrl) {
    return imageUrl.startsWith('assets/');
  }

  double get subtotal {
    return _cartItems.fold(
      0,
      (sum, item) {
        return sum +
            (_getPrice(item) *
                _getQuantity(item));
      },
    );
  }

  double get deliveryFee {
    if (_cartItems.isEmpty) {
      return 0;
    }

    return 500;
  }

  double get total {
    return subtotal + deliveryFee;
  }

  int get totalItems {
    return _cartItems.fold(
      0,
      (sum, item) {
        return sum + _getQuantity(item);
      },
    );
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
          content: Text(
            message,
            style: const TextStyle(
              color: pikkXWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: pikkXBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,

      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
        ),
        color: pikkXBlack,
      ),

      title: const Text(
        'My Cart',
        style: TextStyle(
          color: pikkXBlack,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
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
            onRefresh: _loadCart,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                16,
                5,
                16,
                20,
              ),
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Your Items'),
                    Text(
                      '$totalItems item${totalItems == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: pikkXMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                ..._cartItems.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _buildCartItem(item),
                  ),
                ),

                const SizedBox(height: 8),

                _sectionTitle('Order Summary'),

                const SizedBox(height: 5),

                _buildSummary(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

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
    final imageUrl = _getImageUrl(item);
    final color = _getColor(item);
    final size = _getSize(item);

    return _glass(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            _buildProductImage(imageUrl),

            const SizedBox(width: 13),

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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: pikkXBlack,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '₦${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: pikkXBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (color.isNotEmpty ||
                      size.isNotEmpty) ...[
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (color.isNotEmpty)
                          _smallDetail(
                            'Color: $color',
                          ),
                        if (size.isNotEmpty)
                          _smallDetail(
                            'Size: $size',
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _quantityButton(
                        icon:
                            Icons.remove_rounded,
                        onPressed: _isUpdating
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
                          horizontal: 13,
                        ),
                        child: Text(
                          '$quantity',
                          style:
                              const TextStyle(
                            color: pikkXBlack,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      _quantityButton(
                        icon:
                            Icons.add_rounded,
                        onPressed: _isUpdating
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

            const SizedBox(width: 5),

            _deleteButton(item),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL COLOR / SIZE DETAIL
  // ============================================================

  Widget _smallDetail(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.045),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pikkXBorder,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: pikkXMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    String imageUrl,
  ) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.60),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: pikkXBorder,
        ),
      ),
      child: imageUrl.isEmpty
          ? const Icon(
              Icons.shopping_bag_outlined,
              size: 31,
              color: pikkXBlack,
            )
          : ClipRRect(
              borderRadius:
                  BorderRadius.circular(19),
              child: _isAssetImage(imageUrl)
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (
                            context,
                            error,
                            stackTrace,
                          ) {
                        return const Icon(
                          Icons
                              .image_not_supported_outlined,
                          size: 30,
                          color: pikkXMuted,
                        );
                      },
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (
                            context,
                            child,
                            loadingProgress,
                          ) {
                        if (loadingProgress ==
                            null) {
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
                      errorBuilder:
                          (
                            context,
                            error,
                            stackTrace,
                          ) {
                        return const Icon(
                          Icons
                              .image_not_supported_outlined,
                          size: 30,
                          color: pikkXMuted,
                        );
                      },
                    ),
            ),
    );
  }

  // ============================================================
  // DELETE BUTTON
  // ============================================================

  Widget _deleteButton(
    Map<String, dynamic> item,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _removeItem(item),
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.62),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: pikkXBorder,
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: pikkXBlack,
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
            BorderRadius.circular(10),
        child: AnimatedOpacity(
          duration:
              const Duration(milliseconds: 150),
          opacity:
              onPressed == null ? 0.45 : 1,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: pikkXBlack,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
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
    return _glass(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _summaryRow(
              'Subtotal',
              '₦${subtotal.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 12),

            _summaryRow(
              'Delivery fee',
              '₦${deliveryFee.toStringAsFixed(2)}',
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
              child: Container(
                height: 1,
                color:
                    Colors.black.withOpacity(0.08),
              ),
            ),

            _summaryRow(
              'Total',
              '₦${total.toStringAsFixed(2)}',
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
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal
                ? FontWeight.w800
                : FontWeight.w500,
            color: pikkXBlack,
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: pikkXBlack,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  Widget _buildCheckoutButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          14,
        ),
        child: _primaryButton(
          text: 'Proceed to Checkout',
          icon: Icons.arrow_forward_rounded,
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
            BorderRadius.circular(21),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: pikkXBlack,
            borderRadius:
                BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 9),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(width: 9),

              Icon(
                icon,
                color: pikkXWhite,
                size: 21,
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
        padding: const EdgeInsets.all(28),
        child: _glass(
          radius: 30,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(
                          0.12,
                        ),
                        blurRadius: 20,
                        offset:
                            const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .shopping_cart_outlined,
                    size: 40,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(height: 19),

                const Text(
                  'Your cart is empty',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color: pikkXBlack,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Add products to your cart and they will appear here.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: pikkXMuted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 22),

                _smallActionButton(
                  text: 'Continue Shopping',
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
  // SIGN IN STATE
  // ============================================================

  Widget _buildSignInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _glass(
          radius: 30,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 38,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Sign in to view your cart',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                    color: pikkXBlack,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Your cart is saved securely to your account.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: pikkXMuted,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

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

  Widget _smallActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: pikkXBlack,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: pikkXWhite,
              fontSize: 14,
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 7,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: pikkXBlack,
        ),
      ),
    );
  }

  // ============================================================
  // GLASS
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}