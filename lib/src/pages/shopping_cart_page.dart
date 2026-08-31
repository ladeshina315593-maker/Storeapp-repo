import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/model/data.dart';
import 'package:flutter_ecommerce_app/src/model/product.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() =>
      _ShoppingCartPageState();
}

class _ShoppingCartPageState
    extends State<ShoppingCartPage> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = true;
  bool _saving = false;

  List<Product> _cartItems = [];

  String? get _userId =>
      _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>
      get _cartRef {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc('items');
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ------------------------------------------------------------
  // FIREBASE CART
  // ------------------------------------------------------------

  Future<void> _loadCart() async {
    if (_userId == null) {
      setState(() {
        _cartItems =
            List<Product>.from(
          AppData.cartList,
        );
        _loading = false;
      });
      return;
    }

    try {
      final snapshot =
          await _cartRef.get();

      final data = snapshot.data();

      if (data != null &&
          data['products'] is List) {
        final List<dynamic> products =
            data['products'];

        final List<Product> loaded = [];

        for (final item in products) {
          if (item is Map) {
            final productId =
                item['productId'];

            final product =
                _findProduct(productId);

            if (product != null) {
              loaded.add(product);
            }
          }
        }

        setState(() {
          _cartItems = loaded;
        });

        // Keep local cart synchronized.
        AppData.cartList
          ..clear()
          ..addAll(loaded);
      } else {
        // If Firebase cart does not exist yet,
        // use the current local cart and upload it.
        setState(() {
          _cartItems =
              List<Product>.from(
            AppData.cartList,
          );
        });

        await _saveCart();
      }
    } catch (e) {
      debugPrint(
        'Load cart error: $e',
      );

      setState(() {
        _cartItems =
            List<Product>.from(
          AppData.cartList,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Product? _findProduct(dynamic id) {
    if (id == null) return null;

    try {
      return AppData.productList.firstWhere(
        (product) =>
            product.id.toString() ==
            id.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCart() async {
    if (_userId == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await _cartRef.set(
        {
          'products': _cartItems
              .map(
                (product) => {
                  'productId':
                      product.id,
                  'name':
                      product.name,
                  'price':
                      product.price,
                  'image':
                      product.image,
                  'category':
                      product.category,
                },
              )
              .toList(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Save cart error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // CART ACTIONS
  // ------------------------------------------------------------

  Future<void> _removeItem(
    Product product,
  ) async {
    setState(() {
      _cartItems.remove(product);
      AppData.cartList
        ..clear()
        ..addAll(_cartItems);
    });

    await _saveCart();
  }

  Future<void> _clearCart() async {
    if (_cartItems.isEmpty) return;

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Clear cart?',
            style: TextStyle(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Remove all products from your cart?',
            style: TextStyle(
              color: AppTheme.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.darkText,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: AppTheme.pikkXNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _cartItems.clear();
      AppData.cartList.clear();
    });

    await _saveCart();
  }

  // ------------------------------------------------------------
  // GLASS CONTAINER
  // ------------------------------------------------------------

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(14),
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.72,
            ),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(
                0.92,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.045,
                ),
                blurRadius: 20,
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

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        4,
        8,
        4,
        18,
      ),
      child: Row(
        children: [
          _circleButton(
            icon: Icons
                .arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopping Cart',
                  style: TextStyle(
                    color:
                        AppTheme.darkText,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Review your selected items',
                  style: TextStyle(
                    color:
                        AppTheme.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (_cartItems.isNotEmpty)
            _circleButton(
              icon:
                  Icons.delete_outline_rounded,
              iconColor:
                  AppTheme.pikkXNavy,
              onTap: _clearCart,
            ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor =
        AppTheme.darkText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.68,
            ),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white
                  .withOpacity(0.9),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.04,
                ),
                blurRadius: 14,
                offset:
                    const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CART ITEM
  // ------------------------------------------------------------

  Widget _item(Product product) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: _glass(
        padding:
            const EdgeInsets.all(9),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color:
                    AppTheme.lightBackground,
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
                border: Border.all(
                  color: Colors.white,
                ),
              ),
              padding:
                  const EdgeInsets.all(8),
              child: Image.asset(
                product.image,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.darkText,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    product.category,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.mutedText,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    '\$${product.price}',
                    style:
                        const TextStyle(
                      color:
                          AppTheme.pikkXNavy,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        _removeItem(product),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.all(5),
                      child: Icon(
                        Icons
                            .close_rounded,
                        color:
                            AppTheme.mutedText,
                        size: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.65),
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(0.9),
                    ),
                  ),
                  child: Text(
                    'x1',
                    style:
                        const TextStyle(
                      color:
                          AppTheme.darkText,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
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
  // EMPTY CART
  // ------------------------------------------------------------

  Widget _emptyCart() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 70,
        ),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(
                  0.75,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(
                      0.04,
                    ),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons
                    .shopping_bag_outlined,
                color:
                    AppTheme.pikkXNavy,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Your cart is empty',
              style: TextStyle(
                color:
                    AppTheme.darkText,
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Add some products and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.mutedText,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.pikkXNavy,
                  foregroundColor:
                      Colors.white,
                  elevation: 5,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------

  double get _total {
    double total = 0;

    for (final product in _cartItems) {
      total += product.price;
    }

    return total;
  }

  Widget _summary() {
    return _glass(
      padding:
          const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  color:
                      AppTheme.mutedText,
                  fontSize: 12,
                ),
              ),
              Text(
                '${_cartItems.length}',
                style:
                    const TextStyle(
                  color:
                      AppTheme.darkText,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  color:
                      AppTheme.mutedText,
                  fontSize: 12,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style:
                    const TextStyle(
                  color:
                      AppTheme.darkText,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 13,
            ),
            child: Divider(
              height: 1,
              color:
                  Color(0xFFE5E7EB),
            ),
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color:
                      AppTheme.darkText,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style:
                    const TextStyle(
                  color:
                      AppTheme.pikkXNavy,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CHECKOUT
  // ------------------------------------------------------------

  Widget _checkoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _cartItems.isEmpty
            ? null
            : () {
                Navigator.pushNamed(
                  context,
                  '/checkout',
                );
              },
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppTheme.pikkXNavy,
          disabledBackgroundColor:
              Colors.grey.shade300,
          foregroundColor:
              Colors.white,
          elevation: 7,
          shadowColor:
              AppTheme.pikkXNavy
                  .withOpacity(0.20),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              'Continue to Checkout',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            SizedBox(width: 9),
            Icon(
              Icons
                  .arrow_forward_rounded,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.lightBackground,
      body: Container(
        decoration:
            const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.lightBackground,
              Colors.white,
            ],
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        AppTheme.pikkXNavy,
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child: _header(),
                    ),

                    Expanded(
                      child:
                          _cartItems.isEmpty
                              ? _emptyCart()
                              : ListView(
                                  physics:
                                      const BouncingScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    25,
                                  ),
                                  children: [
                                    Text(
                                      '${_cartItems.length} ${_cartItems.length == 1 ? 'item' : 'items'} in your cart',
                                      style:
                                          const TextStyle(
                                        color:
                                            AppTheme.mutedText,
                                        fontSize:
                                            11,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    ..._cartItems.map(
                                      _item,
                                    ),

                                    const SizedBox(
                                      height: 8,
                                    ),

                                    _summary(),

                                    const SizedBox(
                                      height: 16,
                                    ),

                                    _checkoutButton(),

                                    if (_saving)
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(
                                          top: 12,
                                        ),
                                        child:
                                            Center(
                                          child:
                                              SizedBox(
                                            width:
                                                17,
                                            height:
                                                17,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                              color:
                                                  AppTheme.pikkXNavy,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}