import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // ============================================================
  // pikkX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);

  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color darkText = Color(0xFF111111);
  static const Color mutedText = Color(0xFF707070);
  static const Color softGrey = Color(0xFFE8E8E8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get cartRef {
    final uid = userId;

    if (uid == null) {
      return _firestore.collection('_invalid_cart');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cart');
  }

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  bool isPlacingOrder = false;

  String selectedPayment = 'cash_on_delivery';

  List<Map<String, dynamic>> cartItems = [];

  Map<String, dynamic>? selectedAddress;
  String? selectedAddressId;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  // ============================================================
  // LOAD CHECKOUT DATA
  // ============================================================

  Future<void> _loadCheckoutData() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      await Future.wait([
        _loadCart(),
        _loadDefaultAddress(),
      ]);
    } catch (e) {
      debugPrint('Checkout loading error: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD CART
  //
  // users/{userId}/cart/{productId}
  // ============================================================

  Future<void> _loadCart() async {
    if (userId == null) return;

    final snapshot = await cartRef.get();

    final loadedItems =
        snapshot.docs.map((doc) {
      final data = doc.data();

      return <String, dynamic>{
        'id': doc.id,
        'productId': data['productId'] ?? doc.id,
        'name': data['name'] ?? 'Product',
        'price': _toDouble(data['price']),
        'quantity': _toInt(data['quantity']),
        'imageUrl': data['imageUrl'] ?? '',
        'sellerId': data['sellerId'] ?? '',
      };
    }).toList();

    cartItems = loadedItems;
  }

  // ============================================================
  // LOAD ADDRESS
  //
  // users/{userId}/addresses/{addressId}
  // ============================================================

  Future<void> _loadDefaultAddress() async {
    if (userId == null) return;

    final addressCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');

    final defaultSnapshot = await addressCollection
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (defaultSnapshot.docs.isNotEmpty) {
      final doc = defaultSnapshot.docs.first;

      selectedAddressId = doc.id;

      selectedAddress = {
        'id': doc.id,
        ...doc.data(),
      };

      return;
    }

    // No default address — use the first saved address.
    final firstSnapshot =
        await addressCollection.limit(1).get();

    if (firstSnapshot.docs.isNotEmpty) {
      final doc = firstSnapshot.docs.first;

      selectedAddressId = doc.id;

      selectedAddress = {
        'id': doc.id,
        ...doc.data(),
      };
    }
  }

  // ============================================================
  // PRICE CALCULATIONS
  // ============================================================

  double get subtotal {
    return cartItems.fold<double>(
      0,
      (sum, item) {
        return sum +
            (_toDouble(item['price']) *
                _toInt(item['quantity']));
      },
    );
  }

  double get deliveryFee {
    return cartItems.isEmpty ? 0 : 500;
  }

  double get total {
    return subtotal + deliveryFee;
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Future<void> _increaseQuantity(int index) async {
    if (userId == null || isPlacingOrder) return;

    final item = cartItems[index];

    final productId =
        item['productId'].toString();

    final newQuantity =
        _toInt(item['quantity']) + 1;

    setState(() {
      item['quantity'] = newQuantity;
    });

    try {
      await cartRef.doc(productId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Increase quantity error: $e');

      if (mounted) {
        setState(() {
          item['quantity'] = newQuantity - 1;
        });

        _showMessage(
          'Unable to update quantity.',
        );
      }
    }
  }

  Future<void> _decreaseQuantity(int index) async {
    if (userId == null || isPlacingOrder) return;

    final item = cartItems[index];

    final currentQuantity =
        _toInt(item['quantity']);

    if (currentQuantity <= 1) return;

    final productId =
        item['productId'].toString();

    final newQuantity =
        currentQuantity - 1;

    setState(() {
      item['quantity'] = newQuantity;
    });

    try {
      await cartRef.doc(productId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Decrease quantity error: $e');

      if (mounted) {
        setState(() {
          item['quantity'] = currentQuantity;
        });

        _showMessage(
          'Unable to update quantity.',
        );
      }
    }
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Future<void> _openAddressPage() async {
    final result = await Navigator.pushNamed(
      context,
      '/delivery-address',
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      setState(() {
        selectedAddress = result;
        selectedAddressId =
            result['id']?.toString();
      });
    } else {
      await _loadDefaultAddress();

      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // PLACE ORDER
  //
  // orders/{orderId}
  //
  // Also:
  // users/{userId}/orders/{orderId}
  //
  // This gives the main order system and the user's
  // personal order history access to the same order.
  // ============================================================

  Future<void> _placeOrder() async {
    if (userId == null) {
      _showMessage(
        'Please sign in before placing an order.',
      );
      return;
    }

    if (cartItems.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    if (selectedAddress == null) {
      _showMessage(
        'Please select a delivery address.',
      );
      return;
    }

    if (isPlacingOrder) return;

    setState(() {
      isPlacingOrder = true;
    });

    try {
      final orderReference =
          _firestore.collection('orders').doc();

      final userOrderReference = _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderReference.id);

      final orderItems =
          cartItems.map((item) {
        return <String, dynamic>{
          'productId':
              item['productId'],
          'name':
              item['name'],
          'price':
              _toDouble(item['price']),
          'quantity':
              _toInt(item['quantity']),
          'imageUrl':
              item['imageUrl'] ?? '',
          'sellerId':
              item['sellerId'] ?? '',
        };
      }).toList();

      final deliveryAddress =
          <String, dynamic>{
        'fullName':
            selectedAddress?['fullName'] ?? '',
        'phone':
            selectedAddress?['phone'] ?? '',
        'addressLine':
            selectedAddress?['addressLine'] ?? '',
        'city':
            selectedAddress?['city'] ?? '',
        'state':
            selectedAddress?['state'] ?? '',
        'country':
            selectedAddress?['country'] ?? '',
        'latitude':
            selectedAddress?['latitude'],
        'longitude':
            selectedAddress?['longitude'],
      };

      final orderData =
          <String, dynamic>{
        'orderId':
            orderReference.id,

        'userId':
            userId,

        'items':
            orderItems,

        'subtotal':
            subtotal,

        'deliveryFee':
            deliveryFee,

        'total':
            total,

        'currency':
            'NGN',

        'paymentMethod':
            selectedPayment,

        'paymentStatus':
            'pending',

        'orderStatus':
            'pending',

        'deliveryStatus':
            'pending',

        'addressId':
            selectedAddressId,

        'deliveryAddress':
            deliveryAddress,

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      // --------------------------------------------------------
      // ATOMIC FIRESTORE WRITE
      // --------------------------------------------------------

      final batch = _firestore.batch();

      // Main order.
      batch.set(
        orderReference,
        orderData,
      );

      // User's order history.
      batch.set(
        userOrderReference,
        orderData,
      );

      // Remove purchased cart products.
      for (final item in cartItems) {
        final productId =
            item['productId'].toString();

        batch.delete(
          cartRef.doc(productId),
        );
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        cartItems.clear();
      });

      _showOrderSuccess(
        orderReference.id,
      );
    } catch (e) {
      debugPrint(
        'Place order error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to place order. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPlacingOrder = false;
        });
      }
    }
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showOrderSuccess(
    String orderId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,

          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: _glass(
            radius: 28,
            child: Padding(
              padding:
                  const EdgeInsets.all(26),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color:
                          pikkXNavy,
                      boxShadow: [
                        BoxShadow(
                          color: pikkXNavy
                              .withOpacity(
                            0.22,
                          ),
                          blurRadius: 20,
                          offset:
                              const Offset(
                            0,
                            8,
                          ),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color:
                          pikkXWhite,
                      size: 36,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Order Placed!',
                    style: TextStyle(
                      color:
                          darkText,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Your order has been successfully created.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          mutedText,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                        );

                        Navigator.pushNamed(
                          context,
                          '/order-details',
                          arguments:
                              orderId,
                        );
                      },
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            pikkXBlack,
                        foregroundColor:
                            pikkXWhite,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            17,
                          ),
                        ),
                      ),
                      child:
                          const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Text(
                            'Track Order',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Icon(
                            Icons
                                .arrow_forward_rounded,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          lightBackground,

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Checkout',
          style: TextStyle(
            color:
                darkText,
            fontSize: 21,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color:
              darkText,
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    pikkXNavy,
              ),
            )
          : cartItems.isEmpty
              ? _buildEmptyCart()
              : SafeArea(
                  child:
                      ListView(
                    physics:
                        const BouncingScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      30,
                    ),

                    children: [
                      _sectionTitle(
                        'Delivery Address',
                      ),

                      _buildAddressCard(),

                      const SizedBox(
                        height: 24,
                      ),

                      _sectionTitle(
                        'Your Items',
                      ),

                      ...List.generate(
                        cartItems.length,
                        (index) {
                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _buildCartItem(
                              index,
                            ),
                          );
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _sectionTitle(
                        'Payment Method',
                      ),

                      _buildPaymentSection(),

                      const SizedBox(
                        height: 24,
                      ),

                      _sectionTitle(
                        'Order Summary',
                      ),

                      _buildOrderSummary(),

                      const SizedBox(
                        height: 26,
                      ),

                      _buildPlaceOrderButton(),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Widget _buildAddressCard() {
    return _glass(
      radius: 24,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(24),
        onTap:
            _openAddressPage,

        child: Padding(
          padding:
              const EdgeInsets.all(18),

          child: Row(
            children: [
              _iconBox(
                Icons.location_on_rounded,
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child:
                    selectedAddress ==
                            null
                        ? const Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Delivery Address',
                                style:
                                    TextStyle(
                                  color:
                                      darkText,
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              SizedBox(
                                height:
                                    5,
                              ),
                              Text(
                                'Select your delivery address',
                                style:
                                    TextStyle(
                                  color:
                                      mutedText,
                                  fontSize:
                                      13,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                selectedAddress?[
                                        'fullName'] ??
                                    'Delivery Address',
                                style:
                                    const TextStyle(
                                  color:
                                      darkText,
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              const SizedBox(
                                height:
                                    5,
                              ),
                              Text(
                                _addressText(),
                                maxLines:
                                    2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      mutedText,
                                  fontSize:
                                      13,
                                ),
                              ),
                            ],
                          ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 16,
                color:
                    Color(0xFF777777),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _addressText() {
    final address =
        selectedAddress;

    if (address == null) {
      return 'Select your delivery address';
    }

    final parts = [
      address['addressLine'],
      address['city'],
      address['state'],
    ]
        .where(
          (value) =>
              value != null &&
              value
                  .toString()
                  .trim()
                  .isNotEmpty,
        )
        .map(
          (value) =>
              value.toString(),
        )
        .toList();

    return parts.isEmpty
        ? 'Delivery address selected'
        : parts.join(', ');
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget _buildCartItem(
    int index,
  ) {
    final item =
        cartItems[index];

    final name =
        item['name']
                ?.toString() ??
            'Product';

    final price =
        _toDouble(
      item['price'],
    );

    final quantity =
        _toInt(
      item['quantity'],
    );

    final imageUrl =
        item['imageUrl']
                ?.toString() ??
            '';

    return _glass(
      radius: 24,
      child: Padding(
        padding:
            const EdgeInsets.all(14),

        child: Row(
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
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          darkText,
                      fontSize:
                          15,
                      fontWeight:
                          FontWeight
                              .w700,
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
                          pikkXNavy,
                      fontWeight:
                          FontWeight
                              .w800,
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
                          index,
                        ),
                      ),

                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              10,
                        ),
                        child: Text(
                          '$quantity',
                          style:
                              const TextStyle(
                            color:
                                darkText,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),

                      _quantityButton(
                        Icons.add,
                        () =>
                            _increaseQuantity(
                          index,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      width: 72,
      height: 72,

      decoration:
          BoxDecoration(
        color:
            pikkXWhite.withOpacity(
          0.55,
        ),
        borderRadius:
            BorderRadius.circular(
          19,
        ),
        border:
            Border.all(
          color:
              pikkXWhite.withOpacity(
            0.75,
          ),
        ),
      ),

      child: imageUrl.isEmpty
          ? const Icon(
              Icons
                  .shopping_bag_outlined,
              size: 30,
              color:
                  pikkXNavy,
            )
          : ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                19,
              ),
              child:
                  Image.network(
                imageUrl,
                fit:
                    BoxFit.cover,
                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .shopping_bag_outlined,
                    size: 30,
                    color:
                        pikkXNavy,
                  );
                },
              ),
            ),
    );
  }

  // ============================================================
  // QUANTITY BUTTON
  // ============================================================

  Widget _quantityButton(
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        onTap:
            onPressed,

        child: Container(
          width: 30,
          height: 30,

          decoration:
              BoxDecoration(
            color:
                pikkXBlack
                    .withOpacity(
              0.06,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),

          child: Icon(
            icon,
            size: 17,
            color:
                pikkXNavy,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentSection() {
    return _glass(
      radius: 24,
      child: Column(
        children: [
          _paymentOption(
            title:
                'Cash on Delivery',
            icon:
                Icons.payments_outlined,
            value:
                'cash_on_delivery',
          ),

          Divider(
            height: 1,
            color:
                softGrey.withOpacity(
              0.75,
            ),
          ),

          _paymentOption(
            title:
                'Card / Online Payment',
            icon:
                Icons.credit_card_outlined,
            value:
                'card',
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final selected =
        selectedPayment ==
            value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedPayment =
              value;
        });
      },

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        child: Row(
          children: [
            Icon(
              icon,
              color:
                  selected
                      ? pikkXNavy
                      : mutedText,
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(
                  color:
                      darkText,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),

            Icon(
              selected
                  ? Icons
                      .radio_button_checked
                  : Icons
                      .radio_button_off,
              color:
                  selected
                      ? pikkXNavy
                      : const Color(
                          0xFF999999,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================

  Widget _buildOrderSummary() {
    return _glass(
      radius: 24,
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
                    softGrey,
              ),
            ),

            _summaryRow(
              'Total',
              '₦${total.toStringAsFixed(2)}',
              isTotal:
                  true,
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
          MainAxisAlignment
              .spaceBetween,

      children: [
        Text(
          title,
          style:
              TextStyle(
            color:
                darkText,
            fontSize:
                isTotal
                    ? 17
                    : 14,
            fontWeight:
                isTotal
                    ? FontWeight
                        .w800
                    : FontWeight
                        .w500,
          ),
        ),

        Text(
          value,
          style:
              TextStyle(
            color:
                isTotal
                    ? pikkXNavy
                    : darkText,
            fontSize:
                isTotal
                    ? 18
                    : 14,
            fontWeight:
                FontWeight
                    .w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      height: 58,
      width:
          double.infinity,

      child: Material(
        color:
            Colors.transparent,

        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          onTap:
              isPlacingOrder
                  ? null
                  : _placeOrder,

          child: Ink(
            decoration:
                BoxDecoration(
              color:
                  pikkXBlack,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border:
                  Border.all(
                color:
                    pikkXNavy
                        .withOpacity(
                  0.45,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      pikkXNavy
                          .withOpacity(
                    0.18,
                  ),
                  blurRadius:
                      20,
                  offset:
                      const Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),

            child: Center(
              child:
                  isPlacingOrder
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2.5,
                            color:
                                pikkXWhite,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Text(
                              'Place Order',
                              style:
                                  TextStyle(
                                color:
                                    pikkXWhite,
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                            SizedBox(
                              width: 9,
                            ),
                            Icon(
                              Icons
                                  .arrow_forward_rounded,
                              color:
                                  pikkXWhite,
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
  // EMPTY CART
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: _glass(
          radius: 28,

          child: Padding(
            padding:
                const EdgeInsets.all(30),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                _iconBox(
                  Icons
                      .shopping_cart_outlined,
                  size: 70,
                ),

                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'Your cart is empty',
                  style:
                      TextStyle(
                    color:
                        darkText,
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Add products to your cart before checking out.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        mutedText,
                    height:
                        1.4,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 48,

                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          pikkXBlack,
                      foregroundColor:
                          pikkXWhite,
                      elevation:
                          0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                    ),

                    child:
                        const Text(
                      'Continue Shopping',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w700,
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
  // SECTION TITLE
  // ============================================================

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
          color:
              darkText,
          fontSize:
              17,
          fontWeight:
              FontWeight.w800,
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
          BorderRadius.circular(
        radius,
      ),

      child: BackdropFilter(
        filter:
            ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(
          decoration:
              BoxDecoration(
            color:
                pikkXWhite
                    .withOpacity(
              0.62,
            ),

            borderRadius:
                BorderRadius.circular(
              radius,
            ),

            border:
                Border.all(
              color:
                  pikkXWhite
                      .withOpacity(
                0.82,
              ),
              width: 1.1,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack
                        .withOpacity(
                  0.055,
                ),
                blurRadius:
                    24,
                offset:
                    const Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),

          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(
    IconData icon, {
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,

      decoration:
          BoxDecoration(
        color:
            pikkXNavy
                .withOpacity(
          0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          size * 0.32,
        ),
      ),

      child: Icon(
        icon,
        color:
            pikkXNavy,
        size:
            size * 0.48,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int _toInt(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        1;
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior
                .floating,
        backgroundColor:
            pikkXBlack,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }
}