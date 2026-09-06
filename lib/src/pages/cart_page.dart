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

  bool _isLoading = true;
  bool _isUpdating = false;

  List<Map<String, dynamic>> _cartItems = [];

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

      debugPrint(
        'PikkX cart loaded: ${items.length} item(s)',
      );

      if (!mounted) return;

      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'PikkX CART LOAD ERROR: $e',
      );
      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
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

    if (id == null || id.isEmpty) {
      debugPrint(
        'PikkX quantity update blocked: missing cart document ID.',
      );
      return;
    }

    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      debugPrint(
        'PikkX quantity update: '
        'cartId=$id, '
        'quantity=$newQuantity',
      );

      await _cartRef.doc(id).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadCart();
    } catch (e, stackTrace) {
      debugPrint(
        'PikkX QUANTITY UPDATE ERROR: $e',
      );
      debugPrint(
        stackTrace.toString(),
      );

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

    if (quantity <= 1) return;

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

    if (id == null || id.isEmpty) {
      debugPrint(
        'PikkX remove blocked: missing cart document ID.',
      );
      return;
    }

    try {
      debugPrint(
        'PikkX removing cart item: $id',
      );

      await _cartRef.doc(id).delete();

      await _loadCart();

      if (mounted) {
        _showMessage('Item removed from cart.');
      }
    } catch (e, stackTrace) {
      debugPrint(
        'PikkX REMOVE CART ERROR: $e',
      );
      debugPrint(
        stackTrace.toString(),
      );

      if (mounted) {
        _showMessage('Could not remove item.');
      }
    }
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
    final name = item['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Product';
    }

    return name;
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
      return images.first.toString();
    }

    return '';
  }

  String _getSize(
    Map<String, dynamic> item,
  ) {
    return item['size']?.toString().trim() ?? '';
  }

  String _getColor(
    Map<String, dynamic> item,
  ) {
    return item['selectedColor']?.toString().trim() ?? '';
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
            18,
          ),
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
          size: 19,
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
              physics:
                  const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                16,
                2,
                16,
                12,
              ),
              children: [
                _sectionTitle('Your Items'),

                const SizedBox(height: 3),

                ..._cartItems.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 9,
                    ),
                    child: _buildCartItem(item),
                  ),
                ),

                const SizedBox(height: 5),

                _sectionTitle('Order Summary'),

                const SizedBox(height: 3),

                _buildSummary(),

                const SizedBox(height: 12),
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
    final image = _getImage(item);
    final size = _getSize(item);
    final color = _getColor(item);

    return _glass(
      radius: 21,
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            _buildProductImage(image),

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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: pikkXBlack,
                    ),
                  ),

                  if (size.isNotEmpty ||
                      color.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      [
                        if (color.isNotEmpty) color,
                        if (size.isNotEmpty) size,
                      ].join(' • '),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: pikkXGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 5),

                  Text(
                    '₦${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: pikkXBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _quantityButton(
                        icon:
                            Icons.remove_rounded,
                        onPressed:
                            _isUpdating
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
                        child: Text(
                          '$quantity',
                          style:
                              const TextStyle(
                            color: pikkXBlack,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      _quantityButton(
                        icon:
                            Icons.add_rounded,
                        onPressed:
                            _isUpdating
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

            _deleteButton(item),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    String image,
  ) {
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
      child: image.isEmpty
          ? _imageFallback()
          : ClipRRect(
              borderRadius:
                  BorderRadius.circular(18),
              child: _imageWidget(image),
            ),
    );
  }

  Widget _imageWidget(
    String image,
  ) {
    // ----------------------------------------------------------
    // LOCAL ASSET
    // ----------------------------------------------------------

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.contain,
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

    // ----------------------------------------------------------
    // NETWORK / FIREBASE URL
    // ----------------------------------------------------------

    return Image.network(
      image,
      fit: BoxFit.contain,
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
            child: CircularProgressIndicator(
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
  // BRANDED IMAGE FALLBACK
  // ============================================================

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: pikkXBlack.withOpacity(0.035),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Center(
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: pikkXBlack,
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: pikkXWhite,
            size: 22,
          ),
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
            BorderRadius.circular(13),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.62),
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color:
                  pikkXBorder,
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 19,
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
    return _glass(
      radius: 21,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _summaryRow(
              'Subtotal',
              '₦${subtotal.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 9),

            _summaryRow(
              'Delivery fee',
              '₦${deliveryFee.toStringAsFixed(2)}',
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 11,
              ),
              child: Container(
                height: 1,
                color:
                    pikkXBorder,
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
            fontSize:
                isTotal ? 16 : 13,
            fontWeight:
                isTotal
                    ? FontWeight.w800
                    : FontWeight.w500,
            color: pikkXBlack,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:
                isTotal ? 17 : 13,
            fontWeight:
                FontWeight.w800,
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
        padding:
            const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          12,
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
              color: pikkXWhite.withOpacity(0.15),
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
                  fontWeight: FontWeight.w800,
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
            const EdgeInsets.all(22),
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
      child: Padding(
        padding:
            const EdgeInsets.all(22),
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