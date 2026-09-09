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
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
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

  User? get currentUser => _auth.currentUser;

  String? get userId => currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get cartRef {
    final uid = userId;

    if (uid == null) {
      throw StateError('User is not signed in.');
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
  // LOAD EVERYTHING
  // ============================================================

  Future<void> _loadCheckoutData() async {
    if (userId == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      await Future.wait<void>([
        _loadCart(),
        _loadDefaultAddress(),
      ]);
    } catch (e, stackTrace) {
      debugPrint('PIKKX CHECKOUT LOAD ERROR: $e');
      debugPrint(stackTrace.toString());

      if (mounted) {
        _showMessage(
          'Could not load checkout information.',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // LOAD REAL CART
  // ============================================================

  Future<void> _loadCart() async {
    if (userId == null) return;

    final snapshot = await cartRef.get();

    final loadedItems =
        snapshot.docs.map((doc) {
      final data = doc.data();

      return <String, dynamic>{
        // REAL FIRESTORE CART DOCUMENT ID
        'id': doc.id,

        // REAL PRODUCT ID
        'productId':
            data['productId'] ?? doc.id,

        // PRODUCT INFORMATION
        'name':
            _stringValue(
          data['name'] ??
              data['title'],
        ),

        'price':
            _toDouble(
          data['price'],
        ),

        'quantity':
            _toInt(
          data['quantity'],
        ),

        // IMAGE DATA
        'imageUrl':
            _stringValue(
          data['imageUrl'],
        ),

        'image':
            _stringValue(
          data['image'],
        ),

        'images':
            data['images'],

        // SELLER
        'sellerId':
            _stringValue(
          data['sellerId'],
        ),

        'sellerName':
            _stringValue(
          data['sellerName'],
        ),

        // PRODUCT DETAILS
        'category':
            _stringValue(
          data['category'],
        ),

        'description':
            _stringValue(
          data['description'],
        ),

        'size':
            _stringValue(
          data['size'],
        ),

        'selectedColor':
            _stringValue(
          data['selectedColor'],
        ),

        'colorIndex':
            data['colorIndex'],

        'rating':
            data['rating'],

        'reviews':
            data['reviews'],

        'originalPrice':
            data['originalPrice'],

        'currency':
            _stringValue(
              data['currency'],
            ),
      };
    }).toList();

    if (!mounted) return;

    setState(() {
      cartItems = loadedItems;
    });

    debugPrint(
      'PIKKX CHECKOUT CART: '
      '${loadedItems.length} item(s) loaded.',
    );
  }

  // ============================================================
  // LOAD DEFAULT ADDRESS
  // ============================================================

  Future<void> _loadDefaultAddress() async {
    if (userId == null) return;

    final addressCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');

    final defaultSnapshot = await addressCollection
        .where(
          'isDefault',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (defaultSnapshot.docs.isNotEmpty) {
      final doc = defaultSnapshot.docs.first;

      if (!mounted) return;

      setState(() {
        selectedAddressId = doc.id;
        selectedAddress = {
          'id': doc.id,
          ...doc.data(),
        };
      });

      return;
    }

    final firstSnapshot =
        await addressCollection.limit(1).get();

    if (firstSnapshot.docs.isNotEmpty) {
      final doc = firstSnapshot.docs.first;

      if (!mounted) return;

      setState(() {
        selectedAddressId = doc.id;
        selectedAddress = {
          'id': doc.id,
          ...doc.data(),
        };
      });
    }
  }

  // ============================================================
  // PRICE
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
    if (cartItems.isEmpty) {
      return 0;
    }

    // Keep your current checkout delivery rule.
    return 500;
  }

  double get total {
    return subtotal + deliveryFee;
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String get currencySymbol {
    if (cartItems.isEmpty) {
      return '₦';
    }

    final currency =
        cartItems.first['currency']
            ?.toString()
            .toUpperCase();

    switch (currency) {
      case 'USD':
        return '\$';

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

  String _money(double value) {
    return '$currencySymbol${value.toStringAsFixed(2)}';
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Future<void> _increaseQuantity(int index) async {
    if (userId == null ||
        isPlacingOrder ||
        index < 0 ||
        index >= cartItems.length) {
      return;
    }

    final item = cartItems[index];

    final cartId =
        item['id']?.toString();

    if (cartId == null ||
        cartId.isEmpty) {
      _showMessage(
        'Cart item could not be updated.',
      );
      return;
    }

    final oldQuantity =
        _toInt(item['quantity']);

    final newQuantity =
        oldQuantity + 1;

    // OPTIMISTIC UI UPDATE
    setState(() {
      item['quantity'] = newQuantity;
    });

    try {
      await cartRef.doc(cartId).update({
        'quantity': newQuantity,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'PIKKX INCREASE QUANTITY ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        item['quantity'] =
            oldQuantity;
      });

      _showMessage(
        'Unable to update quantity.',
      );
    }
  }

  Future<void> _decreaseQuantity(int index) async {
    if (userId == null ||
        isPlacingOrder ||
        index < 0 ||
        index >= cartItems.length) {
      return;
    }

    final item = cartItems[index];

    final oldQuantity =
        _toInt(item['quantity']);

    if (oldQuantity <= 1) {
      return;
    }

    final cartId =
        item['id']?.toString();

    if (cartId == null ||
        cartId.isEmpty) {
      _showMessage(
        'Cart item could not be updated.',
      );
      return;
    }

    final newQuantity =
        oldQuantity - 1;

    // OPTIMISTIC UI UPDATE
    setState(() {
      item['quantity'] =
          newQuantity;
    });

    try {
      await cartRef.doc(cartId).update({
        'quantity': newQuantity,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'PIKKX DECREASE QUANTITY ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        item['quantity'] =
            oldQuantity;
      });

      _showMessage(
        'Unable to update quantity.',
      );
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
    }
  }

  // ============================================================
  // PLACE REAL ORDER
  // ============================================================

  Future<void> _placeOrder() async {
    if (userId == null) {
      _showMessage(
        'Please sign in before placing an order.',
      );
      return;
    }

    if (cartItems.isEmpty) {
      _showMessage(
        'Your cart is empty.',
      );
      return;
    }

    if (selectedAddress == null) {
      _showMessage(
        'Please select a delivery address.',
      );
      return;
    }

    if (isPlacingOrder) {
      return;
    }

    setState(() {
      isPlacingOrder = true;
    });

    try {
      // ========================================================
      // REAL UNIQUE ORDER ID
      // ========================================================

      final orderReference =
          _firestore
              .collection('orders')
              .doc();

      final orderId =
          orderReference.id;

      final userOrderReference =
          _firestore
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId);

      // ========================================================
      // COPY REAL CART PRODUCTS INTO ORDER
      // ========================================================

      final orderItems =
          cartItems.map((item) {
        return <String, dynamic>{
          'productId':
              item['productId'],

          'name':
              item['name'],

          'price':
              _toDouble(
                item['price'],
              ),

          'quantity':
              _toInt(
                item['quantity'],
              ),

          // IMPORTANT:
          // Preserve image fields so order history,
          // tracking and order details can display it.
          'imageUrl':
              item['imageUrl'] ?? '',

          'image':
              item['image'] ?? '',

          'images':
              item['images'],

          'sellerId':
              item['sellerId'] ?? '',

          'sellerName':
              item['sellerName'] ?? '',

          'category':
              item['category'] ?? '',

          'description':
              item['description'] ?? '',

          'size':
              item['size'] ?? '',

          'selectedColor':
              item['selectedColor'] ?? '',

          'colorIndex':
              item['colorIndex'],

          'rating':
              item['rating'],

          'reviews':
              item['reviews'],

          'originalPrice':
              item['originalPrice'],
        };
      }).toList();

      // ========================================================
      // DELIVERY ADDRESS
      // ========================================================

      final deliveryAddress =
          <String, dynamic>{
        'fullName':
            selectedAddress?['fullName'] ??
                '',

        'phone':
            selectedAddress?['phone'] ??
                '',

        'addressLine':
            selectedAddress?['addressLine'] ??
                '',

        'city':
            selectedAddress?['city'] ??
                '',

        'state':
            selectedAddress?['state'] ??
                '',

        'country':
            selectedAddress?['country'] ??
                '',

        'latitude':
            selectedAddress?['latitude'],

        'longitude':
            selectedAddress?['longitude'],
      };

      // ========================================================
      // REAL ORDER DATA
      // ========================================================

      final orderData =
          <String, dynamic>{
        'orderId':
            orderId,

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
            _currencyCode(),

        'paymentMethod':
            selectedPayment,

        'paymentStatus':
            'pending',

        // IMPORTANT:
        // These are the fields used by the tracking flow.
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

      // ========================================================
      // ATOMIC FIRESTORE BATCH
      // ========================================================

      final batch =
          _firestore.batch();

      // Main order.
      batch.set(
        orderReference,
        orderData,
      );

      // User order history.
      batch.set(
        userOrderReference,
        orderData,
      );

      // Remove ONLY the actual cart documents.
      for (final item in cartItems) {
        final cartId =
            item['id']?.toString();

        if (cartId != null &&
            cartId.isNotEmpty) {
          batch.delete(
            cartRef.doc(cartId),
          );
        }
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        cartItems = [];
      });

      _showOrderSuccess(orderId);
    } catch (e, stackTrace) {
      debugPrint(
        'PIKKX PLACE ORDER ERROR: $e',
      );
      debugPrint(
        stackTrace.toString(),
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
  // CURRENCY CODE
  // ============================================================

  String _currencyCode() {
    if (cartItems.isEmpty) {
      return 'NGN';
    }

    final currency =
        cartItems.first['currency']
            ?.toString()
            .toUpperCase();

    if (currency == null ||
        currency.isEmpty) {
      return 'NGN';
    }

    return currency;
  }

  // ============================================================
  // SUCCESS DIALOG
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
                        const BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color:
                          pikkXBlack,
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
                    height: 16,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXBlack
                              .withOpacity(
                        0.05,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Order ID',
                          style:
                              TextStyle(
                            color:
                                mutedText,
                            fontSize:
                                12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          orderId,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color:
                                darkText,
                            fontSize:
                                12,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
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
                        elevation:
                            0,
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
                                  FontWeight.w700,
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
        scrolledUnderElevation: 0,
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
                    pikkXBlack,
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
                        const EdgeInsets
                            .fromLTRB(
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

                      // Extra bottom clearance.
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard() {
    return _glass(
      radius: 24,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
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
                    selectedAddress == null
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
                                      FontWeight.w700,
                                ),
                              ),
                              SizedBox(
                                height: 5,
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
                                      FontWeight.w700,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
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
                    mutedText,
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
  // CHECKOUT PRODUCT
  // ============================================================

  Widget _buildCartItem(
    int index,
  ) {
    final item =
        cartItems[index];

    final name =
        _stringValue(
          item['name'],
        ).isEmpty
            ? 'Product'
            : _stringValue(
                item['name'],
              );

    final price =
        _toDouble(
          item['price'],
        );

    final quantity =
        _toInt(
          item['quantity'],
        );

    final image =
        _getImage(item);

    final selectedColor =
        _stringValue(
          item['selectedColor'],
        );

    final size =
        _stringValue(
          item['size'],
        );

    final details =
        <String>[];

    if (selectedColor.isNotEmpty) {
      details.add(
        selectedColor,
      );
    }

    if (size.isNotEmpty) {
      details.add(
        'Size $size',
      );
    }

    return _glass(
      radius: 24,
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            _buildProductImage(
              image,
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
                          FontWeight.w700,
                    ),
                  ),

                  if (details.isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      details.join(
                        ' • ',
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            mutedText,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    _money(price),
                    style:
                        const TextStyle(
                      color:
                          darkText,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      _quantityButton(
                        Icons
                            .remove_rounded,
                        () =>
                            _decreaseQuantity(
                          index,
                        ),
                      ),

                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          '$quantity',
                          style:
                              const TextStyle(
                            color:
                                darkText,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      _quantityButton(
                        Icons
                            .add_rounded,
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
  // GET REAL IMAGE
  // ============================================================

  String _getImage(
    Map<String, dynamic> item,
  ) {
    final imageUrl =
        _stringValue(
          item['imageUrl'],
        );

    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        _stringValue(
          item['image'],
        );

    if (image.isNotEmpty) {
      return image;
    }

    final images =
        item['images'];

    if (images is List &&
        images.isNotEmpty) {
      final first =
          images.first?.toString().trim();

      if (first != null &&
          first.isNotEmpty) {
        return first;
      }
    }

    return '';
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
      decoration:
          BoxDecoration(
        color:
            pikkXWhite.withOpacity(
          0.60,
        ),
        borderRadius:
            BorderRadius.circular(
          19,
        ),
        border:
            Border.all(
          color:
              pikkXWhite.withOpacity(
            0.80,
          ),
        ),
      ),
      child: image.isEmpty
          ? _imageFallback()
          : ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                19,
              ),
              child:
                  _imageWidget(image),
            ),
    );
  }

  Widget _imageWidget(
    String image,
  ) {
    if (image.startsWith(
      'assets/',
    )) {
      return Image.asset(
        image,
        fit: BoxFit.contain,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            'PIKKX CHECKOUT ASSET ERROR: '
            '$image',
          );

          return _imageFallback();
        },
      );
    }

    return Image.network(
      image,
      fit: BoxFit.contain,

      // Keep network images from
      // becoming a huge loading area.
      cacheWidth: 300,
      cacheHeight: 300,

      loadingBuilder:
          (
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
              color:
                  pikkXBlack,
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
        debugPrint(
          'PIKKX CHECKOUT NETWORK IMAGE ERROR: '
          '$image',
        );

        return _imageFallback();
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration:
          BoxDecoration(
        color:
            pikkXBlack.withOpacity(
          0.035,
        ),
        borderRadius:
            BorderRadius.circular(
          19,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_cart_outlined,
          size: 30,
          color:
              darkText,
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
                darkText,
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
        if (isPlacingOrder) return;

        setState(() {
          selectedPayment =
              value;
        });
      },
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  selected
                      ? darkText
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
                      FontWeight.w600,
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
                      ? darkText
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
              _money(subtotal),
            ),

            const SizedBox(
              height: 12,
            ),

            _summaryRow(
              'Delivery fee',
              _money(deliveryFee),
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
              _money(total),
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
                    ? FontWeight.w800
                    : FontWeight.w500,
          ),
        ),

        Text(
          value,
          style:
              TextStyle(
            color:
                darkText,
            fontSize:
                isTotal
                    ? 18
                    : 14,
            fontWeight:
                FontWeight.w800,
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
              boxShadow: [
                BoxShadow(
                  color:
                      pikkXBlack
                          .withOpacity(
                    0.16,
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
                            Icon(
                              Icons
                                  .shopping_cart_outlined,
                              color:
                                  pikkXWhite,
                              size: 20,
                            ),

                            SizedBox(
                              width: 9,
                            ),

                            Text(
                              'Place Order',
                              style:
                                  TextStyle(
                                color:
                                    pikkXWhite,
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.w800,
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
  // EMPTY CART
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: _glass(
          radius: 28,
          child: Padding(
            padding:
                const EdgeInsets.all(
              30,
            ),
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
                        FontWeight.w800,
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
                            FontWeight.w700,
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
  // GLASS
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
          child:
              child,
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
            pikkXBlack
                .withOpacity(
          0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          size * 0.32,
        ),
      ),
      child: Icon(
        icon,
        color:
            darkText,
        size:
            size * 0.48,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior
                  .floating,
          backgroundColor:
              pikkXBlack,
          elevation:
              0,
          margin:
              const EdgeInsets
                  .fromLTRB(
            16,
            0,
            16,
            18,
          ),
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