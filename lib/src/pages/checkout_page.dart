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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedPayment = 'cash_on_delivery';

  bool isLoading = true;
  bool isPlacingOrder = false;

  List<Map<String, dynamic>> cartItems = [];

  Map<String, dynamic>? selectedAddress;
  String? selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  // ============================================================
  // FIREBASE USER
  // ============================================================

  String? get userId => _auth.currentUser?.uid;

  // ============================================================
  // LOAD CHECKOUT DATA
  // ============================================================

  Future<void> _loadCheckoutData() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
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
  // carts/{userId}/items/{productId}
  // ============================================================

  Future<void> _loadCart() async {
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('carts')
        .doc(userId)
        .collection('items')
        .get();

    final List<Map<String, dynamic>> loadedItems = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      loadedItems.add({
        'id': doc.id,
        'productId': data['productId'] ?? doc.id,
        'name': data['name'] ?? 'Product',
        'price': _toDouble(data['price']),
        'quantity': _toInt(data['quantity']),
        'imageUrl': data['imageUrl'] ?? '',
        'sellerId': data['sellerId'] ?? '',
      });
    }

    cartItems = loadedItems;
  }

  // ============================================================
  // LOAD DEFAULT ADDRESS
  //
  // users/{userId}/addresses/{addressId}
  // ============================================================

  Future<void> _loadDefaultAddress() async {
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;

      selectedAddressId = doc.id;
      selectedAddress = {
        'id': doc.id,
        ...doc.data(),
      };
      return;
    }

    // If there is no default address, load the first saved address.
    final allAddresses = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .limit(1)
        .get();

    if (allAddresses.docs.isNotEmpty) {
      final doc = allAddresses.docs.first;

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
    double result = 0;

    for (final item in cartItems) {
      final price = _toDouble(item['price']);
      final quantity = _toInt(item['quantity']);

      result += price * quantity;
    }

    return result;
  }

  double get deliveryFee {
    // Later this can be calculated dynamically using
    // the user's location, seller location and delivery system.
    return cartItems.isEmpty ? 0 : 500;
  }

  double get total {
    return subtotal + deliveryFee;
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Future<void> _increaseQuantity(int index) async {
    if (userId == null) return;

    final item = cartItems[index];

    final newQuantity = _toInt(item['quantity']) + 1;

    setState(() {
      cartItems[index]['quantity'] = newQuantity;
    });

    await _updateCartQuantity(
      item['productId'],
      newQuantity,
    );
  }

  Future<void> _decreaseQuantity(int index) async {
    if (userId == null) return;

    final item = cartItems[index];
    final currentQuantity = _toInt(item['quantity']);

    if (currentQuantity <= 1) {
      return;
    }

    final newQuantity = currentQuantity - 1;

    setState(() {
      cartItems[index]['quantity'] = newQuantity;
    });

    await _updateCartQuantity(
      item['productId'],
      newQuantity,
    );
  }

  Future<void> _updateCartQuantity(
    String productId,
    int quantity,
  ) async {
    if (userId == null) return;

    await _firestore
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(productId)
        .update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELIVERY ADDRESS
  // ============================================================

  Future<void> _openAddressPage() async {
    final result = await Navigator.pushNamed(
      context,
      '/delivery-address',
    );

    // Delivery Address page can return the selected address.
    if (result is Map<String, dynamic>) {
      setState(() {
        selectedAddress = result;
        selectedAddressId = result['id']?.toString();
      });
    } else {
      // Reload from Firebase in case the address was changed.
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
  // ============================================================

  Future<void> _placeOrder() async {
    if (userId == null) {
      _showMessage('Please sign in before placing an order.');
      return;
    }

    if (cartItems.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    if (selectedAddress == null) {
      _showMessage('Please select a delivery address.');
      return;
    }

    setState(() {
      isPlacingOrder = true;
    });

    try {
      final orderReference = _firestore.collection('orders').doc();

      final orderItems = cartItems.map((item) {
        return {
          'productId': item['productId'],
          'name': item['name'],
          'price': _toDouble(item['price']),
          'quantity': _toInt(item['quantity']),
          'imageUrl': item['imageUrl'],
          'sellerId': item['sellerId'],
        };
      }).toList();

      final orderData = {
        'orderId': orderReference.id,
        'userId': userId,

        'items': orderItems,

        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,

        'paymentMethod': selectedPayment,
        'paymentStatus': selectedPayment == 'cash_on_delivery'
            ? 'pending'
            : 'pending',

        'orderStatus': 'pending',

        'addressId': selectedAddressId,

        'deliveryAddress': {
          'fullName': selectedAddress?['fullName'] ?? '',
          'phone': selectedAddress?['phone'] ?? '',
          'addressLine': selectedAddress?['addressLine'] ?? '',
          'city': selectedAddress?['city'] ?? '',
          'state': selectedAddress?['state'] ?? '',
          'country': selectedAddress?['country'] ?? '',
          'latitude': selectedAddress?['latitude'],
          'longitude': selectedAddress?['longitude'],
        },

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create order.
      await orderReference.set(orderData);

      // Remove purchased products from cart.
      final batch = _firestore.batch();

      for (final item in cartItems) {
        final productId = item['productId'].toString();

        final cartReference = _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .doc(productId);

        batch.delete(cartReference);
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        cartItems.clear();
      });

      _showOrderSuccess(orderReference.id);
    } catch (e) {
      debugPrint('Place order error: $e');

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

  void _showOrderSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _glassContainer(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFF8F5FF),
                    child: Icon(
                      Icons.check_rounded,
                      size: 35,
                      color: Color(0xFF8F62D9),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Order Placed!',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2635),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order has been successfully created.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF797878),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        Navigator.pushNamed(
                          context,
                          '/order-details',
                          arguments: orderId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB98BEF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Text(
                        'Track Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF1D2635),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF1D2635),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB98BEF),
              ),
            )
          : cartItems.isEmpty
              ? _buildEmptyCart()
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      30,
                    ),
                    children: [
                      _sectionTitle('Delivery Address'),

                      _buildAddressCard(),

                      const SizedBox(height: 24),

                      _sectionTitle('Your Items'),

                      ...List.generate(
                        cartItems.length,
                        (index) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12),
                          child: _buildCartItem(index),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _sectionTitle('Payment Method'),

                      _buildPaymentSection(),

                      const SizedBox(height: 24),

                      _sectionTitle('Order Summary'),

                      _buildOrderSummary(),

                      const SizedBox(height: 26),

                      _buildPlaceOrderButton(),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard() {
    return _glassContainer(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openAddressPage,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xFFF8F5FF),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFB98BEF),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: selectedAddress == null
                    ? const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D2635),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Select your delivery address',
                            style: TextStyle(
                              color: Color(0xFF797878),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAddress?['fullName'] ??
                                'Delivery Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D2635),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _addressText(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF797878),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF747F8F),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _addressText() {
    final address = selectedAddress;

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
              value.toString().trim().isNotEmpty,
        )
        .map((value) => value.toString())
        .toList();

    return parts.isEmpty
        ? 'Delivery address selected'
        : parts.join(', ');
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget _buildCartItem(int index) {
    final item = cartItems[index];

    final name = item['name']?.toString() ?? 'Product';
    final price = _toDouble(item['price']);
    final quantity = _toInt(item['quantity']);
    final imageUrl = item['imageUrl']?.toString() ?? '';

    return _glassContainer(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFB98BEF),
                      size: 30,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFB98BEF),
                            size: 30,
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2635),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '₦${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF8F62D9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                _quantityButton(
                  Icons.remove,
                  () => _decreaseQuantity(index),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2635),
                    ),
                  ),
                ),

                _quantityButton(
                  Icons.add,
                  () => _increaseQuantity(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton(
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 17,
          color: const Color(0xFF8F62D9),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentSection() {
    return _glassContainer(
      child: Column(
        children: [
          _paymentOption(
            title: 'Cash on Delivery',
            icon: Icons.payments_outlined,
            value: 'cash_on_delivery',
          ),

          const Divider(
            height: 1,
            color: Color(0xFFE1E2E4),
          ),

          _paymentOption(
            title: 'Card / Online Payment',
            icon: Icons.credit_card_outlined,
            value: 'card',
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
    final isSelected = selectedPayment == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF8F62D9),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2635),
                ),
              ),
            ),

            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFFB98BEF)
                  : const Color(0xFFA1A3A6),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildOrderSummary() {
    return _glassContainer(
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

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(
              color: Color(0xFFE1E2E4),
            ),
          ),

          _summaryRow(
            'Total',
            '₦${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
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
            fontWeight:
                isTotal ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF1D2635),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: isTotal
                ? const Color(0xFF8F62D9)
                : const Color(0xFF1D2635),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLACE ORDER BUTTON
  // ============================================================

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB98BEF),
              Color(0xFF8F62D9),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33B98BEF),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
              isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor:
                Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: isPlacingOrder
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Place Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.all(30),
        child: _glassContainer(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 60,
                  color: Color(0xFFB98BEF),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2635),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add products to your cart before checking out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF797878),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D2635),
        ),
      ),
    );
  }

  // ============================================================
  // GRAPEGO GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}