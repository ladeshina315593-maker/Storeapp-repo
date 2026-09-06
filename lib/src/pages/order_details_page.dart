import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  // ============================================================
  // PikkX Colors
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color lightGrey = Color(0xFFE8E8E8);

  // ============================================================
  // Firebase
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? order;
  bool isLoading = true;
  String? errorMessage;

  // ============================================================
  // Currency
  // ============================================================

  String selectedCurrency = 'NGN';

  final Map<String, double> currencyRates = {
    'NGN': 1.0,
    'USD': 0.00062,
    'GBP': 0.00046,
    'EUR': 0.00053,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _loadOrder();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        selectedCurrency =
            prefs.getString('selected_currency') ?? 'NGN';
      });
    } catch (_) {
      // Keep NGN if currency cannot be loaded.
    }
  }

  // ============================================================
  // Load Order
  // ============================================================

  Future<void> _loadOrder() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please sign in to view this order.';
        });
        return;
      }

      final doc = await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
          errorMessage = 'Order not found.';
        });
        return;
      }

      final data = doc.data();

      if (data == null || data['userId'] != user.uid) {
        setState(() {
          isLoading = false;
          errorMessage = 'You do not have access to this order.';
        });
        return;
      }

      setState(() {
        order = {
          'id': doc.id,
          ...data,
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load order details.';
      });
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  double _number(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatPrice(dynamic value) {
    final amount = _number(value);
    final rate = currencyRates[selectedCurrency] ?? 1.0;
    final converted = amount * rate;

    switch (selectedCurrency) {
      case 'USD':
        return '\$${converted.toStringAsFixed(2)}';

      case 'GBP':
        return '£${converted.toStringAsFixed(2)}';

      case 'EUR':
        return '€${converted.toStringAsFixed(2)}';

      default:
        return '₦${converted.toStringAsFixed(0)}';
    }
  }

  String _status() {
    final value =
        (order?['orderStatus'] ?? 'pending').toString().toLowerCase();

    return value;
  }

  String _prettyStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';

      case 'confirmed':
        return 'Confirmed';

      case 'preparing':
        return 'Preparing';

      case 'out_for_delivery':
        return 'Out for delivery';

      case 'delivered':
        return 'Delivered';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  // ============================================================
  // FIX:
  // Supports both local assets and Firebase/network images.
  // ============================================================

  Widget _buildProductImage(
    String imageUrl, {
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.isEmpty) {
      return Container(
        color: lightGrey,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: pikkXGrey,
          size: 28,
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: lightGrey,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: pikkXGrey,
              size: 28,
            ),
          );
        },
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: lightGrey,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            color: pikkXGrey,
            size: 28,
          ),
        );
      },
    );
  }

  // ============================================================
  // Glassmorphism
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
    double radius = 24,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.85),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // Status Badge
  // ============================================================

  Widget _statusBadge(String status) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: pikkXBlack.withOpacity(0.06),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: pikkXBlack.withOpacity(0.08),
            ),
          ),
          child: Text(
            _prettyStatus(status),
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Order Header
  // ============================================================

  Widget _buildOrderHeader() {
    final status = _status();

    return _glassContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: pikkXBlack.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: pikkXBlack,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order',
                  style: TextStyle(
                    color: pikkXGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${widget.orderId}',
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _statusBadge(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Order Items
  // ============================================================

  Widget _buildOrderItems() {
    final rawItems = order?['items'];

    if (rawItems is! List || rawItems.isEmpty) {
      return _glassContainer(
        child: const Text(
          'No items found for this order.',
          style: TextStyle(
            color: pikkXGrey,
            fontSize: 14,
          ),
        ),
      );
    }

    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            rawItems.length,
            (index) {
              final item =
                  Map<String, dynamic>.from(
                rawItems[index] as Map,
              );

              return _item(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _item(Map<String, dynamic> item) {
    final imageUrl = (
      item['imageUrl'] ??
      item['image'] ??
      ''
    ).toString();

    final name =
        (item['name'] ?? 'Product').toString();

    final quantity =
        _number(item['quantity']).toInt();

    final price = _number(item['price']);

    final size =
        (item['size'] ?? '').toString();

    final selectedColor =
        (item['selectedColor'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(18),
            child: Container(
              width: 76,
              height: 76,
              color: lightGrey,
              child: _buildProductImage(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (size.isNotEmpty)
                  Text(
                    'Size: $size',
                    style: const TextStyle(
                      color: pikkXGrey,
                      fontSize: 12,
                    ),
                  ),
                if (selectedColor.isNotEmpty)
                  Text(
                    'Colour: $selectedColor',
                    style: const TextStyle(
                      color: pikkXGrey,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  'Qty: $quantity',
                  style: const TextStyle(
                    color: pikkXGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatPrice(price * quantity),
            style: const TextStyle(
              color: pikkXBlack,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Delivery Address
  // ============================================================

  Widget _buildDeliveryAddress() {
    final address =
        order?['deliveryAddress'];

    if (address is! Map) {
      return _glassContainer(
        child: const Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: pikkXBlack,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No delivery address available.',
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final addressMap =
        Map<String, dynamic>.from(address);

    final name =
        (addressMap['name'] ??
                addressMap['fullName'] ??
                '')
            .toString();

    final phone =
        (addressMap['phone'] ?? '').toString();

    final street =
        (addressMap['address'] ??
                addressMap['street'] ??
                '')
            .toString();

    final city =
        (addressMap['city'] ?? '').toString();

    final state =
        (addressMap['state'] ?? '').toString();

    final country =
        (addressMap['country'] ?? '').toString();

    final location = [
      street,
      city,
      state,
      country,
    ].where((e) => e.isNotEmpty).join(', ');

    return _glassContainer(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pikkXBlack.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: pikkXBlack,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      Text(
                        name,
                        style: const TextStyle(
                          color: pikkXBlack,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: pikkXGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        location,
                        style: const TextStyle(
                          color: pikkXGrey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Status Timeline
  // ============================================================

  Widget _buildStatusTimeline() {
    final currentStatus = _status();

    final statuses = [
      'pending',
      'confirmed',
      'preparing',
      'out_for_delivery',
      'delivered',
    ];

    final effectiveStatus =
        currentStatus == 'completed'
            ? 'delivered'
            : currentStatus;

    int currentIndex =
        statuses.indexOf(effectiveStatus);

    if (currentIndex < 0) {
      currentIndex = 0;
    }

    return _glassContainer(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            statuses.length,
            (index) {
              final status = statuses[index];
              final isCompleted =
                  index <= currentIndex;
              final isLast =
                  index == statuses.length - 1;

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? pikkXBlack
                              : lightGrey,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : Icons.circle,
                          color: isCompleted
                              ? pikkXWhite
                              : pikkXGrey,
                          size: isCompleted
                              ? 16
                              : 8,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 1.5,
                          height: 42,
                          color: index < currentIndex
                              ? pikkXBlack
                              : lightGrey,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 4),
                    child: Text(
                      _prettyStatus(status),
                      style: TextStyle(
                        color: isCompleted
                            ? pikkXBlack
                            : pikkXGrey,
                        fontSize: 14,
                        fontWeight: isCompleted
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Payment
  // ============================================================

  Widget _buildPaymentSection() {
    final paymentMethod =
        (order?['paymentMethod'] ??
                'cash_on_delivery')
            .toString();

    final paymentStatus =
        (order?['paymentStatus'] ??
                'pending')
            .toString();

    String readablePayment =
        paymentMethod.replaceAll('_', ' ');

    readablePayment = readablePayment
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');

    return _glassContainer(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pikkXBlack.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: pikkXBlack,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      readablePayment,
                      style: const TextStyle(
                        color: pikkXBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Status: ${_prettyStatus(paymentStatus)}',
                      style: const TextStyle(
                        color: pikkXGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Order Summary
  // ============================================================

  Widget _buildSummary() {
    final subtotal =
        _number(order?['subtotal']);

    final deliveryFee =
        _number(order?['deliveryFee']);

    final total =
        _number(order?['total']);

    return _glassContainer(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow(
            'Subtotal',
            _formatPrice(subtotal),
          ),
          const SizedBox(height: 10),
          _summaryRow(
            'Delivery fee',
            _formatPrice(deliveryFee),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Divider(
              color: lightGrey,
              height: 1,
            ),
          ),
          _summaryRow(
            'Total',
            _formatPrice(total),
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
            color:
                isTotal ? pikkXBlack : pikkXGrey,
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: pikkXBlack,
            fontSize: isTotal ? 17 : 13,
            fontWeight: isTotal
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Track Order Button
  // ============================================================

  Widget _buildTrackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: pikkXBlack.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/dispatch-tracking',
                  arguments: widget.orderId,
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: pikkXWhite,
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Track Order',
                      style: TextStyle(
                        color: pikkXWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Error State
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: pikkXBlack.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: pikkXBlack,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: pikkXBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadOrder,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 12,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: pikkXWhite.withOpacity(0.72),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        pikkXWhite.withOpacity(0.85),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: pikkXBlack,
                    size: 18,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ),
        title: ClipRRect(
          borderRadius:
              BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color:
                    pikkXWhite.withOpacity(0.72),
                borderRadius:
                    BorderRadius.circular(50),
                border: Border.all(
                  color:
                      pikkXWhite.withOpacity(0.85),
                ),
              ),
              child: const Text(
                'Order Details',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background glow/orbs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pikkXBlack.withOpacity(0.035),
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pikkXBlack.withOpacity(0.025),
              ),
            ),
          ),

          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: pikkXBlack,
                    ),
                  )
                : errorMessage != null
                    ? _buildError()
                    : order == null
                        ? _buildError()
                        : RefreshIndicator(
                            color: pikkXBlack,
                            onRefresh: _loadOrder,
                            child: SingleChildScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(
                                16,
                                90,
                                16,
                                30,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildTrackButton(),
                                  const SizedBox(height: 16),
                                  _buildOrderHeader(),
                                  const SizedBox(height: 16),
                                  _buildOrderItems(),
                                  const SizedBox(height: 16),
                                  _buildDeliveryAddress(),
                                  const SizedBox(height: 16),
                                  _buildStatusTimeline(),
                                  const SizedBox(height: 16),
                                  _buildPaymentSection(),
                                  const SizedBox(height: 16),
                                  _buildSummary(),
                                  const SizedBox(height: 18),

                                  // Order ID
                                  _glassContainer(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    radius: 18,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.tag_outlined,
                                          color: pikkXGrey,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 9),
                                        const Text(
                                          'Order ID',
                                          style: TextStyle(
                                            color: pikkXGrey,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Flexible(
                                          child: Text(
                                            widget.orderId,
                                            textAlign:
                                                TextAlign.right,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(
                                              color: pikkXBlack,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w700,
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
          ),
        ],
      ),
    );
  }
}