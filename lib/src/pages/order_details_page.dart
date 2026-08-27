import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() =>
      _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool isLoading = true;
  Map<String, dynamic>? order;

  String? get userId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await _firestore
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final data = doc.data();

      if (data == null || data['userId'] != userId) {
        setState(() {
          isLoading = false;
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
      debugPrint('Order details error: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  String _status() {
    return order?['orderStatus']?.toString() ?? 'pending';
  }

  double _money(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() +
                  word.substring(1),
        )
        .join(' ');
  }

  bool _completed(String status) {
    return status == 'delivered' ||
        status == 'completed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Order Details',
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
          : order == null
              ? const Center(
                  child: Text(
                    'Order not found.',
                    style: TextStyle(
                      color: Color(0xFF797878),
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final items = order!['items'] is List
        ? List.from(order!['items'])
        : <dynamic>[];

    final status = _status();

    final total = _money(order!['total']);
    final subtotal = _money(order!['subtotal']);
    final deliveryFee = _money(order!['deliveryFee']);

    final address =
        order!['deliveryAddress'] is Map
            ? Map<String, dynamic>.from(
                order!['deliveryAddress'],
              )
            : <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        30,
      ),
      children: [
        _orderHeader(status),

        const SizedBox(height: 18),

        _sectionTitle('Order Items'),

        _glass(
          child: Column(
            children: items
                .map(
                  (item) => _item(item),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 22),

        _sectionTitle('Delivery Address'),

        _glass(
          child: ListTile(
            contentPadding:
                const EdgeInsets.all(12),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF8F5FF),
              child: Icon(
                Icons.location_on_rounded,
                color: Color(0xFFB98BEF),
              ),
            ),
            title: Text(
              address['fullName']?.toString() ??
                  'Delivery Address',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2635),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                _addressText(address),
                style: const TextStyle(
                  color: Color(0xFF797878),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        _sectionTitle('Order Status'),

        _glass(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _trackingTimeline(status),
          ),
        ),

        const SizedBox(height: 22),

        _sectionTitle('Payment'),

        _glass(
          child: Column(
            children: [
              _row(
                'Payment method',
                order!['paymentMethod']
                        ?.toString() ??
                    'Not specified',
              ),
              const SizedBox(height: 12),
              _row(
                'Payment status',
                order!['paymentStatus']
                        ?.toString() ??
                    'Pending',
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        _sectionTitle('Order Summary'),

        _glass(
          child: Column(
            children: [
              _row(
                'Subtotal',
                '₦${subtotal.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _row(
                'Delivery fee',
                '₦${deliveryFee.toStringAsFixed(2)}',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Divider(
                  color: Color(0xFFE1E2E4),
                ),
              ),
              _row(
                'Total',
                '₦${total.toStringAsFixed(2)}',
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderHeader(String status) {
    return _glass(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFFB98BEF),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2635),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatStatus(status),
                    style: const TextStyle(
                      color: Color(0xFF8F62D9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingTimeline(String status) {
    final statuses = [
      'pending',
      'confirmed',
      'preparing',
      'out_for_delivery',
      'delivered',
    ];

    int current =
        statuses.indexOf(status);

    if (current < 0) current = 0;

    return Column(
      children: List.generate(
        statuses.length,
        (index) {
          final done = index <= current;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: done
                        ? const Color(0xFFB98BEF)
                        : const Color(0xFFA1A3A6),
                    size: 22,
                  ),
                  if (index != statuses.length - 1)
                    Container(
                      width: 2,
                      height: 35,
                      color: done
                          ? const Color(0xFFB98BEF)
                          : const Color(0xFFE1E2E4),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding:
                    const EdgeInsets.only(top: 2),
                child: Text(
                  _formatStatus(statuses[index]),
                  style: TextStyle(
                    color: done
                        ? const Color(0xFF1D2635)
                        : const Color(0xFFA1A3A6),
                    fontWeight: done
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(dynamic rawItem) {
    final item = rawItem is Map
        ? Map<String, dynamic>.from(rawItem)
        : <String, dynamic>{};

    final name =
        item['name']?.toString() ?? 'Product';

    final quantity =
        item['quantity'] ?? 1;

    final price = _money(item['price']);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFFB98BEF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name × $quantity',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D2635),
              ),
            ),
          ),
          Text(
            '₦${price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF8F62D9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _addressText(
    Map<String, dynamic> address,
  ) {
    return [
      address['addressLine'],
      address['city'],
      address['state'],
      address['country'],
    ]
        .where(
          (e) =>
              e != null &&
              e.toString().isNotEmpty,
        )
        .join(', ');
  }

  Widget _row(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF747F8F),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: bold
                ? const Color(0xFF8F62D9)
                : const Color(0xFF1D2635),
            fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D2635),
        ),
      ),
    );
  }

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
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.76),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.88),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.04),
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