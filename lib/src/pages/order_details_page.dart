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
  State<OrderDetailsPage> createState() =>
      _OrderDetailsPageState();
}

class _OrderDetailsPageState
    extends State<OrderDetailsPage> {
  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack =
      Color(0xFF050505);

  static const Color pikkXWhite =
      Color(0xFFFFFFFF);

  static const Color pikkXBackground =
      Color(0xFFF7F7F7);

  static const Color pikkXGrey =
      Color(0xFF777777);

  static const Color pikkXLightGrey =
      Color(0xFFE8E8E8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool isLoading = true;

  Map<String, dynamic>? order;

  String? get userId =>
      _auth.currentUser?.uid;

  // ============================================================
  // CURRENCY
  // ============================================================

  String selectedCurrency = 'NGN';

  static const Map<String, String>
      currencySymbols = {
    'NGN': '₦',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'ZAR': 'R',
    'GHS': 'GH₵',
    'KES': 'KSh',
    'UGX': 'USh',
    'TZS': 'TSh',
    'INR': '₹',
    'JPY': '¥',
    'CNY': '¥',
    'AED': 'د.إ',
    'SAR': '﷼',
    'CHF': 'CHF',
    'BRL': 'R\$',
    'MXN': 'MX\$',
  };

  // These are display conversion rates.
  //
  // IMPORTANT:
  // The order amounts in Firestore are assumed to be stored
  // in NGN. NGN is the base currency.
  //
  // The rates can later be replaced with a live exchange-rate
  // API without changing the Order Details UI.
  static const Map<String, double>
      currencyRates = {
    'NGN': 1.0,
    'USD': 0.00063,
    'GBP': 0.00047,
    'EUR': 0.00054,
    'CAD': 0.00086,
    'AUD': 0.00096,
    'ZAR': 0.0112,
    'GHS': 0.0097,
    'KES': 0.081,
    'UGX': 2.34,
    'TZS': 1.62,
    'INR': 0.053,
    'JPY': 0.093,
    'CNY': 0.0045,
    'AED': 0.00231,
    'SAR': 0.00236,
    'CHF': 0.00050,
    'BRL': 0.00335,
    'MXN': 0.011,
  };

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadCurrency();
    await _loadOrder();
  }

  // ============================================================
  // LOAD SELECTED CURRENCY
  // ============================================================

  Future<void> _loadCurrency() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final savedCurrency =
          prefs.getString('selected_currency');

      if (!mounted) return;

      if (savedCurrency != null &&
          currencyRates.containsKey(
            savedCurrency.toUpperCase(),
          )) {
        setState(() {
          selectedCurrency =
              savedCurrency.toUpperCase();
        });
      }
    } catch (e) {
      debugPrint(
        'Currency loading error: $e',
      );
    }
  }

  // ============================================================
  // CONVERT MONEY
  // ============================================================

  double _convertMoney(
    dynamic value,
  ) {
    final amount = _money(value);

    final rate =
        currencyRates[selectedCurrency] ??
            1.0;

    return amount * rate;
  }

  // ============================================================
  // FORMAT MONEY
  // ============================================================

  String _formatMoney(
    dynamic value,
  ) {
    final converted =
        _convertMoney(value);

    final symbol =
        currencySymbols[selectedCurrency] ??
            selectedCurrency;

    return '$symbol${converted.toStringAsFixed(2)}';
  }

  // ============================================================
  // LOAD ORDER
  // ============================================================

  Future<void> _loadOrder() async {
    final uid = userId;

    if (uid == null) {
      if (!mounted) return;

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

      if (!mounted) return;

      if (!doc.exists) {
        setState(() {
          isLoading = false;
          order = null;
        });

        return;
      }

      final data = doc.data();

      if (data == null) {
        setState(() {
          isLoading = false;
          order = null;
        });

        return;
      }

      // Only allow the owner of the order
      // to view the order.

      if (data['userId']?.toString() != uid) {
        setState(() {
          isLoading = false;
          order = null;
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
      debugPrint(
        'Order details error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        order = null;
      });

      _showMessage(
        'Could not load this order.',
      );
    }
  }

  // ============================================================
  // ORDER STATUS
  // ============================================================

  String _status() {
    final value =
        order?['orderStatus']
            ?.toString()
            .trim()
            .toLowerCase();

    if (value == null ||
        value.isEmpty) {
      return 'pending';
    }

    return value;
  }

  // ============================================================
  // MONEY
  // ============================================================

  double _money(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // FORMAT STATUS
  // ============================================================

  String _formatStatus(
    String status,
  ) {
    if (status.trim().isEmpty) {
      return 'Pending';
    }

    return status
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) {
              return '';
            }

            return word[0].toUpperCase() +
                word.substring(1).toLowerCase();
          },
        )
        .join(' ');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          pikkXBackground,

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,

        leading: Padding(
          padding:
              const EdgeInsets.only(
            left: 10,
          ),
          child: _glassIcon(
            Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ),

        title: const Text(
          'Order Details',
          style: TextStyle(
            color: pikkXBlack,
            fontSize: 21,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: Stack(
        children: [
          // ======================================================
          // GLASS BACKGROUND ACCENTS
          // ======================================================

          Positioned(
            top: -100,
            right: -90,
            child: Container(
              width: 230,
              height: 230,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.white
                    .withOpacity(
                  0.75,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.black
                    .withOpacity(
                  0.025,
                ),
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: pikkXBlack,
                  ),
                )
              : order == null
                  ? _notFound()
                  : _buildContent(),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    final rawItems =
        order?['items'];

    final List<dynamic> items =
        rawItems is List
            ? rawItems
            : <dynamic>[];

    final status =
        _status();

    final total =
        _money(order?['total']);

    final subtotal =
        _money(order?['subtotal']);

    final deliveryFee =
        _money(order?['deliveryFee']);

    final rawAddress =
        order?['deliveryAddress'];

    final Map<String, dynamic>
        address =
        rawAddress is Map
            ? Map<String, dynamic>.from(
                rawAddress,
              )
            : <String, dynamic>{};

    return RefreshIndicator(
      color: pikkXBlack,
      backgroundColor:
          pikkXWhite,
      onRefresh: _loadOrder,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          35,
        ),
        children: [
          // ======================================================
          // ORDER HEADER
          // ======================================================

          _orderHeader(status),

          const SizedBox(height: 22),

          // ======================================================
          // ORDER ITEMS
          // ======================================================

          _sectionTitle(
            'Order Items',
          ),

          _glass(
            child: items.isEmpty
                ? _emptyItems()
                : Column(
                    children:
                        List.generate(
                      items.length,
                      (index) =>
                          _item(
                        items[index],
                        isLast:
                            index ==
                                items.length -
                                    1,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 22),

          // ======================================================
          // DELIVERY ADDRESS
          // ======================================================

          _sectionTitle(
            'Delivery Address',
          ),

          _glass(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                15,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXBlack
                              .withOpacity(
                        0.055,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .location_on_outlined,
                      color:
                          pikkXBlack,
                      size: 22,
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          address[
                                          'fullName']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? address[
                                      'fullName']
                                  .toString()
                              : 'Delivery Address',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w800,
                            color:
                                pikkXBlack,
                            fontSize:
                                14,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          _addressText(
                            address,
                          ),
                          style:
                              const TextStyle(
                            color:
                                pikkXGrey,
                            fontSize:
                                13,
                            height:
                                1.45,
                          ),
                        ),

                        if (_phone(
                          address,
                        ).isNotEmpty) ...[
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            _phone(
                              address,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  pikkXGrey,
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ======================================================
          // ORDER STATUS
          // ======================================================

          _sectionTitle(
            'Order Status',
          ),

          _glass(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child:
                  _trackingTimeline(
                status,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ======================================================
          // PAYMENT
          // ======================================================

          _sectionTitle(
            'Payment',
          ),

          _glass(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                17,
              ),
              child: Column(
                children: [
                  _row(
                    'Payment method',
                    _paymentMethod(),
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _row(
                    'Payment status',
                    _paymentStatus(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ======================================================
          // SUMMARY
          // ======================================================

          _sectionTitle(
            'Order Summary',
          ),

          _glass(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                17,
              ),
              child: Column(
                children: [
                  _row(
                    'Subtotal',
                    _formatMoney(
                      subtotal,
                    ),
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _row(
                    'Delivery fee',
                    _formatMoney(
                      deliveryFee,
                    ),
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Divider(
                      color:
                          pikkXLightGrey,
                      height: 1,
                    ),
                  ),

                  _row(
                    'Total',
                    _formatMoney(
                      total,
                    ),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ======================================================
          // CURRENCY INFORMATION
          // ======================================================

          Center(
            child: Text(
              'Prices shown in $selectedCurrency',
              style:
                  const TextStyle(
                color:
                    Color(0xFF999999),
                fontSize: 10,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ======================================================
          // ORDER ID
          // ======================================================

          Center(
            child: Text(
              'Order ID: ${widget.orderId}',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(0xFF999999),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER HEADER
  // ============================================================

  Widget _orderHeader(
    String status,
  ) {
    return _glass(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration:
                  BoxDecoration(
                color:
                    pikkXBlack
                        .withOpacity(
                  0.055,
                ),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child:
                  const Icon(
                Icons
                    .local_shipping_outlined,
                color:
                    pikkXBlack,
                size: 25,
              ),
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
                    'Order #${_shortOrderId()}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      color:
                          pikkXBlack,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXBlack
                              .withOpacity(
                        0.055,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      _formatStatus(
                        status,
                      ),
                      style:
                          const TextStyle(
                        color:
                            pikkXBlack,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                      ),
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

  String _shortOrderId() {
    if (widget.orderId.length <=
        8) {
      return widget.orderId;
    }

    return widget.orderId.substring(
      0,
      8,
    );
  }

  // ============================================================
  // TRACKING TIMELINE
  // ============================================================

  Widget _trackingTimeline(
    String status,
  ) {
    const statuses = [
      'pending',
      'confirmed',
      'preparing',
      'out_for_delivery',
      'delivered',
    ];

    String normalized =
        status
            .toLowerCase()
            .replaceAll(
              '-',
              '_',
            )
            .replaceAll(
              ' ',
              '_',
            );

    if (normalized ==
        'completed') {
      normalized =
          'delivered';
    }

    int current =
        statuses.indexOf(
      normalized,
    );

    if (current < 0) {
      current = 0;
    }

    return Column(
      children:
          List.generate(
        statuses.length,
        (index) {
          final done =
              index <= current;

          final isCurrent =
              index == current;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration:
                        BoxDecoration(
                      color: done
                          ? pikkXBlack
                          : pikkXWhite,
                      shape:
                          BoxShape.circle,
                      border:
                          Border.all(
                        color: done
                            ? pikkXBlack
                            : const Color(
                                0xFFD0D0D0,
                              ),
                        width: 1.5,
                      ),
                    ),
                    child: done
                        ? const Icon(
                            Icons
                                .check_rounded,
                            color:
                                pikkXWhite,
                            size: 15,
                          )
                        : null,
                  ),

                  if (index !=
                      statuses.length -
                          1)
                    Container(
                      width: 2,
                      height: 37,
                      color: index <
                              current
                          ? pikkXBlack
                          : pikkXLightGrey,
                    ),
                ],
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    top: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatStatus(
                            statuses[
                                index],
                          ),
                          style:
                              TextStyle(
                            color: done
                                ? pikkXBlack
                                : const Color(
                                    0xFF999999,
                                  ),
                            fontWeight: done
                                ? FontWeight
                                    .w700
                                : FontWeight
                                    .w500,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      if (isCurrent)
                        const Text(
                          'Current',
                          style:
                              TextStyle(
                            color:
                                pikkXBlack,
                            fontSize:
                                10,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ITEM
  // ============================================================

  Widget _item(
    dynamic rawItem, {
    required bool isLast,
  }) {
    final item =
        rawItem is Map
            ? Map<String, dynamic>.from(
                rawItem,
              )
            : <String, dynamic>{};

    final name =
        item['name']
                ?.toString() ??
            item['productName']
                ?.toString() ??
            'Product';

    final quantity =
        item['quantity'] ??
            1;

    final price =
        _money(
      item['price'],
    );

    final imageUrl =
        item['imageUrl']
            ?.toString();

    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom:
                    BorderSide(
                  color:
                      pikkXLightGrey,
                ),
              ),
      ),
      child: Row(
        children: [
          // PRODUCT IMAGE
          Container(
            width: 58,
            height: 58,
            decoration:
                BoxDecoration(
              color:
                  pikkXBlack
                      .withOpacity(
                0.045,
              ),
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
            ),
            clipBehavior:
                Clip.antiAlias,
            child: imageUrl != null &&
                    imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _productIcon();
                    },
                  )
                : _productIcon(),
          ),

          const SizedBox(
            width: 12,
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
                    fontWeight:
                        FontWeight.w700,
                    color:
                        pikkXBlack,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Quantity: $quantity',
                  style:
                      const TextStyle(
                    color:
                        pikkXGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            _formatMoney(
              price,
            ),
            style:
                const TextStyle(
              color:
                  pikkXBlack,
              fontWeight:
                  FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productIcon() {
    return const Center(
      child: Icon(
        Icons
            .shopping_bag_outlined,
        color:
            pikkXBlack,
        size: 25,
      ),
    );
  }

  Widget _emptyItems() {
    return const Padding(
      padding:
          EdgeInsets.all(20),
      child: Center(
        child: Text(
          'No item information available.',
          style: TextStyle(
            color:
                pikkXGrey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  String _addressText(
    Map<String, dynamic>
        address,
  ) {
    final values = [
      address['addressLine'],
      address['address'],
      address['street'],
      address['city'],
      address['state'],
      address['country'],
    ];

    final result =
        <String>[];

    for (final value
        in values) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        final text =
            value.toString().trim();

        if (!result
            .contains(text)) {
          result.add(text);
        }
      }
    }

    if (result.isEmpty) {
      return 'No delivery address provided.';
    }

    return result.join(
      ', ',
    );
  }

  String _phone(
    Map<String, dynamic>
        address,
  ) {
    final value =
        address['phone'] ??
            address['phoneNumber'];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  String _paymentMethod() {
    final value =
        order?['paymentMethod']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return 'Not specified';
    }

    return _formatStatus(
      value,
    );
  }

  String _paymentStatus() {
    final value =
        order?['paymentStatus']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return 'Pending';
    }

    return _formatStatus(
      value,
    );
  }

  // ============================================================
  // ROW
  // ============================================================

  Widget _row(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: [
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              color:
                  pikkXGrey,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style: TextStyle(
              color: bold
                  ? pikkXBlack
                  : pikkXBlack,
              fontSize:
                  bold ? 15 : 12,
              fontWeight: bold
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          fontSize: 16,
          fontWeight:
              FontWeight.w800,
          color:
              pikkXBlack,
        ),
      ),
    );
  }

  // ============================================================
  // GLASS ICON
  // ============================================================

  Widget _glassIcon(
    IconData icon, {
    required VoidCallback
        onTap,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        15,
      ),
      child: BackdropFilter(
        filter:
            ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Material(
          color:
              Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(
              15,
            ),
            child: Container(
              width: 43,
              height: 43,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(
                  0.74,
                ),
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(
                    0.95,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.045,
                    ),
                    blurRadius:
                        15,
                    offset:
                        const Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color:
                    pikkXBlack,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        24,
      ),
      child: BackdropFilter(
        filter:
            ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          decoration:
              BoxDecoration(
            color: Colors.white
                .withOpacity(
              0.74,
            ),
            borderRadius:
                BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: Colors.white
                  .withOpacity(
                0.92,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.045,
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
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // NOT FOUND
  // ============================================================

  Widget _notFound() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: _glass(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: const [
                Icon(
                  Icons
                      .receipt_long_outlined,
                  size: 54,
                  color:
                      pikkXBlack,
                ),

                SizedBox(
                  height: 15,
                ),

                Text(
                  'Order not found',
                  style:
                      TextStyle(
                    color:
                        pikkXBlack,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 7,
                ),

                Text(
                  'This order may no longer exist or you may not have access to it.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        pikkXGrey,
                    fontSize: 12,
                    height: 1.4,
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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            pikkXBlack,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }
}