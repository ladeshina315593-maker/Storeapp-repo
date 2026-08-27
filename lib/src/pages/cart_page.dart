import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool isLoading = true;

  List<Map<String, dynamic>> cartItems = [];

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get cartRef {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart');
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // --------------------------------------------------
  // LOAD CART
  // --------------------------------------------------

  Future<void> _loadCart() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await cartRef.get();

      final items = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      setState(() {
        cartItems = items;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Cart loading error: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  // --------------------------------------------------
  // QUANTITY
  // --------------------------------------------------

  Future<void> _increaseQuantity(
    Map<String, dynamic> item,
  ) async {
    if (userId == null) return;

    final id = item['id'].toString();

    final currentQuantity =
        _getQuantity(item);

    try {
      await cartRef.doc(id).update({
        'quantity': currentQuantity + 1,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      await _loadCart();
    } catch (e) {
      debugPrint(
        'Increase quantity error: $e',
      );
    }
  }

  Future<void> _decreaseQuantity(
    Map<String, dynamic> item,
  ) async {
    if (userId == null) return;

    final id = item['id'].toString();

    final currentQuantity =
        _getQuantity(item);

    if (currentQuantity <= 1) {
      return;
    }

    try {
      await cartRef.doc(id).update({
        'quantity': currentQuantity - 1,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      await _loadCart();
    } catch (e) {
      debugPrint(
        'Decrease quantity error: $e',
      );
    }
  }

  // --------------------------------------------------
  // REMOVE ITEM
  // --------------------------------------------------

  Future<void> _removeItem(
    Map<String, dynamic> item,
  ) async {
    if (userId == null) return;

    final id = item['id'].toString();

    try {
      await cartRef.doc(id).delete();

      await _loadCart();
    } catch (e) {
      debugPrint(
        'Remove cart item error: $e',
      );
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

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

  double get subtotal {
    return cartItems.fold(
      0,
      (sum, item) {
        return sum +
            (_getPrice(item) *
                _getQuantity(item));
      },
    );
  }

  double get deliveryFee {
    if (cartItems.isEmpty) {
      return 0;
    }

    return 500;
  }

  double get total {
    return subtotal + deliveryFee;
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5FF),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'My Cart',
          style: TextStyle(
            color:
                Color(0xFF1D2635),
            fontSize: 21,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color:
              Color(0xFF1D2635),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFB98BEF),
              ),
            )
          : cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCart(),
    );
  }

  // --------------------------------------------------
  // CART
  // --------------------------------------------------

  Widget _buildCart() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color:
                const Color(0xFFB98BEF),

            onRefresh: _loadCart,

            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                20,
              ),

              children: [
                _sectionTitle(
                  'Your Items',
                ),

                ...cartItems.map(
                  (item) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child:
                          _buildCartItem(item),
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _sectionTitle(
                  'Order Summary',
                ),

                _buildSummary(),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),

        _buildCheckoutButton(),
      ],
    );
  }

  // --------------------------------------------------
  // CART ITEM
  // --------------------------------------------------

  Widget _buildCartItem(
    Map<String, dynamic> item,
  ) {
    final name =
        item['name']?.toString() ??
            'Product';

    final price =
        _getPrice(item);

    final quantity =
        _getQuantity(item);

    final imageUrl =
        item['imageUrl']?.toString() ??
            '';

    return _glass(
      child: Padding(
        padding:
            const EdgeInsets.all(14),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,

          children: [
            _buildProductImage(
              imageUrl,
            ),

            const SizedBox(
              width: 13,
            ),

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
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF1D2635),
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    '₦${price.toStringAsFixed(2)}',

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF8F62D9),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      _quantityButton(
                        Icons.remove,
                        () =>
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
                            color:
                                Color(0xFF1D2635),
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),

                      _quantityButton(
                        Icons.add,
                        () =>
                            _increaseQuantity(
                          item,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            IconButton(
              onPressed: () =>
                  _removeItem(item),

              icon: const Icon(
                Icons.delete_outline_rounded,
                color:
                    Color(0xFFE65829),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PRODUCT IMAGE
  // --------------------------------------------------

  Widget _buildProductImage(
    String imageUrl,
  ) {
    return Container(
      width: 78,
      height: 78,

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8F5FF),
        borderRadius:
            BorderRadius.circular(19),
      ),

      child: imageUrl.isEmpty
          ? const Icon(
              Icons.shopping_bag_outlined,
              size: 32,
              color:
                  Color(0xFFB98BEF),
            )
          : ClipRRect(
              borderRadius:
                  BorderRadius.circular(19),

              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,

                errorBuilder:
                    (context, error, stack) {
                  return const Icon(
                    Icons
                        .shopping_bag_outlined,
                    size: 32,
                    color:
                        Color(0xFFB98BEF),
                  );
                },
              ),
            ),
    );
  }

  // --------------------------------------------------
  // QUANTITY BUTTON
  // --------------------------------------------------

  Widget _quantityButton(
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,

      child: Container(
        width: 30,
        height: 30,

        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF8F5FF),
          borderRadius:
              BorderRadius.circular(10),
        ),

        child: Icon(
          icon,
          size: 17,
          color:
              const Color(0xFF8F62D9),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ORDER SUMMARY
  // --------------------------------------------------

  Widget _buildSummary() {
    return _glass(
      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          children: [
            _summaryRow(
              'Subtotal',
              '₦${subtotal.toStringAsFixed(2)}',
            ),

            const SizedBox(
              height: 12,
            ),

            _summaryRow(
              'Delivery fee',
              '₦${deliveryFee.toStringAsFixed(2)}',
            ),

            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 15,
              ),

              child: Divider(
                color:
                    Color(0xFFE1E2E4),
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
                isTotal ? 17 : 14,

            fontWeight:
                isTotal
                    ? FontWeight.w700
                    : FontWeight.w500,

            color:
                const Color(0xFF1D2635),
          ),
        ),

        Text(
          value,

          style: TextStyle(
            fontSize:
                isTotal ? 18 : 14,

            fontWeight:
                FontWeight.w700,

            color:
                isTotal
                    ? const Color(
                        0xFF8F62D9,
                      )
                    : const Color(
                        0xFF1D2635,
                      ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CHECKOUT BUTTON
  // --------------------------------------------------

  Widget _buildCheckoutButton() {
    return SafeArea(
      top: false,

      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          14,
        ),

        child: SizedBox(
          width: double.infinity,
          height: 58,

          child: DecoratedBox(
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),

              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFB98BEF),
                  Color(0xFF8F62D9),
                ],
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Color(0x33B98BEF),
                  blurRadius: 18,
                  offset:
                      Offset(0, 8),
                ),
              ],
            ),

            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/checkout',
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.transparent,
                shadowColor:
                    Colors.transparent,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  const Text(
                    'Proceed to Checkout',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                        Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY CART
  // --------------------------------------------------

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: _glass(
          child: Padding(
            padding:
                const EdgeInsets.all(30),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Container(
                  width: 80,
                  height: 80,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                            0xFFF8F5FF),
                    borderRadius:
                        BorderRadius.circular(
                      25,
                    ),
                  ),

                  child: const Icon(
                    Icons
                        .shopping_cart_outlined,
                    size: 42,
                    color:
                        Color(0xFFB98BEF),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'Your cart is empty',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF1D2635),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Add products to your cart and they will appear here.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Color(0xFF797878),
                    height: 1.4,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFFB98BEF),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Continue Shopping',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),

      child: Text(
        title,

        style:
            const TextStyle(
          fontSize: 17,
          fontWeight:
              FontWeight.w700,
          color:
              Color(0xFF1D2635),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // GLASS CONTAINER
  // --------------------------------------------------

  Widget _glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),

        child: Container(
          decoration:
              BoxDecoration(
            color:
                Colors.white
                    .withOpacity(0.76),

            borderRadius:
                BorderRadius.circular(24),

            border: Border.all(
              color:
                  Colors.white
                      .withOpacity(0.88),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(0.04),
                blurRadius: 18,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),

          child: child,
        ),
      ),
    );
  }
}