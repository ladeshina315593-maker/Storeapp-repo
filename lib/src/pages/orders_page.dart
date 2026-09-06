import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;

  bool isLoading = true;

  List<Map<String, dynamic>> orders = [];

  String selectedCurrency = 'NGN';

  String? get userId => _auth.currentUser?.uid;

  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color lightGrey = Color(0xFFE8E8E8);

  // ============================================================
  // CURRENCY
  // ============================================================

  static const Map<String, String> currencySymbols = {
    'NGN': '₦',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'CAD': 'C\$',
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
    'CHF': 'CHF ',
    'BRL': 'R\$',
    'MXN': 'MX\$',
  };

  static const Map<String, double> currencyRates = {
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

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _initializePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadCurrency();
    await _loadOrders();
  }

  // ============================================================
  // LOAD CURRENCY
  // ============================================================

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedCurrency =
          prefs.getString('selected_currency');

      if (!mounted) return;

      setState(() {
        if (savedCurrency != null &&
            currencyRates.containsKey(savedCurrency)) {
          selectedCurrency = savedCurrency;
        } else {
          selectedCurrency = 'NGN';
        }
      });
    } catch (e) {
      debugPrint('Load currency error: $e');
    }
  }

  // ============================================================
  // FIRESTORE
  // ============================================================

  CollectionReference<Map<String, dynamic>> get ordersRef {
    return _firestore.collection('orders');
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final snapshot = await ordersRef
          .where(
            'userId',
            isEqualTo: userId,
          )
          .get();

      final loadedOrders = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      loadedOrders.sort((a, b) {
        final aTime = _timestampToDate(
          a['createdAt'],
        );

        final bTime = _timestampToDate(
          b['createdAt'],
        );

        return bTime.compareTo(aTime);
      });

      if (!mounted) return;

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load orders error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Unable to load your orders.',
      );
    }
  }

  // ============================================================
  // ACTIVE ORDERS
  // ============================================================

  List<Map<String, dynamic>> get activeOrders {
    return orders.where((order) {
      final status =
          order['orderStatus']?.toString().toLowerCase();

      return status != 'delivered' &&
          status != 'completed' &&
          status != 'cancelled';
    }).toList();
  }

  // ============================================================
  // HISTORY
  // ============================================================

  List<Map<String, dynamic>> get completedOrders {
    return orders.where((order) {
      final status =
          order['orderStatus']?.toString().toLowerCase();

      return status == 'delivered' ||
          status == 'completed' ||
          status == 'cancelled';
    }).toList();
  }

  // ============================================================
  // OPEN ORDER DETAILS
  // ============================================================

  void _openOrder(
    Map<String, dynamic> order,
  ) {
    final orderId = order['id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      _showMessage(
        'Order ID is unavailable.',
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/order-details',
      arguments: orderId,
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  double _convertMoney(double amount) {
    final rate =
        currencyRates[selectedCurrency] ??
            currencyRates['NGN']!;

    return amount * rate;
  }

  String _formatMoney(double amount) {
    final converted = _convertMoney(amount);

    final symbol =
        currencySymbols[selectedCurrency] ??
            selectedCurrency;

    return '$symbol${converted.toStringAsFixed(2)}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pikkXBackground,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        iconTheme: const IconThemeData(
          color: pikkXBlack,
        ),

        title: const Text(
          'My Orders',
          style: TextStyle(
            color: pikkXBlack,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),

      body: Stack(
        children: [
          // ======================================================
          // BACKGROUND GLASS GLOW
          // ======================================================

          Positioned(
            top: -120,
            right: -90,
            child: _backgroundGlow(
              size: 270,
              opacity: 0.035,
            ),
          ),

          Positioned(
            top: 260,
            left: -120,
            child: _backgroundGlow(
              size: 250,
              opacity: 0.025,
            ),
          ),

          Positioned(
            bottom: -120,
            right: -80,
            child: _backgroundGlow(
              size: 260,
              opacity: 0.03,
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          SafeArea(
            top: false,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: pikkXBlack,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildCurrencyIndicator(),

                      _buildTabs(),

                      Expanded(
                        child: RefreshIndicator(
                          color: pikkXBlack,
                          backgroundColor: pikkXWhite,

                          onRefresh: () async {
                            await _loadCurrency();
                            await _loadOrders();
                          },

                          child: TabBarView(
                            controller: _tabController,

                            children: [
                              _buildOrderList(
                                activeOrders,
                                isActive: true,
                              ),

                              _buildOrderList(
                                completedOrders,
                                isActive: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENCY PILL
  // ============================================================

  Widget _buildCurrencyIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        3,
        16,
        12,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: _glassPill(
          icon: Icons.currency_exchange_rounded,
          text: 'Prices in $selectedCurrency',
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),
      child: _glassContainer(
        radius: 22,
        opacity: 0.72,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: TabBar(
            controller: _tabController,

            indicator: BoxDecoration(
              color: pikkXBlack,
              borderRadius: BorderRadius.circular(16),

              boxShadow: [
                BoxShadow(
                  color: pikkXBlack.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            indicatorSize:
                TabBarIndicatorSize.tab,

            dividerColor: Colors.transparent,

            labelColor: pikkXWhite,

            unselectedLabelColor: pikkXGrey,

            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),

            unselectedLabelStyle:
                const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),

            tabs: const [
              Tab(
                text: 'Active',
              ),
              Tab(
                text: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDER LIST
  // ============================================================

  Widget _buildOrderList(
    List<Map<String, dynamic>> orderList, {
    required bool isActive,
  }) {
    if (orderList.isEmpty) {
      return _buildEmptyState(
        isActive: isActive,
      );
    }

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        35,
      ),

      itemCount: orderList.length,

      separatorBuilder: (_, __) {
        return const SizedBox(
          height: 14,
        );
      },

      itemBuilder: (context, index) {
        return _buildOrderCard(
          orderList[index],
          isActive: isActive,
        );
      },
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    Map<String, dynamic> order, {
    required bool isActive,
  }) {
    final orderId =
        order['orderId'] ??
            order['id'] ??
            '';

    final status =
        order['orderStatus']?.toString() ??
            'pending';

    final total =
        _toDouble(order['total']);

    final items = order['items'] is List
        ? List.from(order['items'])
        : <dynamic>[];

    final createdAt = _timestampToDate(
      order['createdAt'],
    );

    return _glassContainer(
      radius: 27,
      opacity: 0.76,
      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            _openOrder(order);
          },

          borderRadius:
              BorderRadius.circular(27),

          splashColor:
              pikkXBlack.withOpacity(0.04),

          highlightColor:
              pikkXBlack.withOpacity(0.02),

          child: Padding(
            padding: const EdgeInsets.all(17),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // =================================================
                // HEADER
                // =================================================

                Row(
                  children: [
                    _orderIcon(
                      isActive: isActive,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${_shortOrderId(
                              orderId.toString(),
                            )}',

                            style: const TextStyle(
                              color: pikkXBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .calendar_today_rounded,
                                size: 11,
                                color: pikkXGrey,
                              ),

                              const SizedBox(
                                width: 5,
                              ),

                              Text(
                                _formatDate(
                                  createdAt,
                                ),
                                style:
                                    const TextStyle(
                                  color: pikkXGrey,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    _statusBadge(status),
                  ],
                ),

                const SizedBox(
                  height: 17,
                ),

                // =================================================
                // ITEM PREVIEW GLASS SECTION
                // =================================================

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(16),

                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ),

                    child: Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(12),

                      decoration:
                          BoxDecoration(
                        color:
                            pikkXWhite
                                .withOpacity(0.34),

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),

                        border: Border.all(
                          color:
                              pikkXBlack
                                  .withOpacity(
                            0.045,
                          ),
                        ),
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,

                            decoration:
                                BoxDecoration(
                              color:
                                  pikkXBlack
                                      .withOpacity(
                                0.06,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),

                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: pikkXBlack,
                              size: 18,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: items.isNotEmpty
                                ? Text(
                                    _itemsPreview(
                                      items,
                                    ),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color: pikkXGrey,
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  )
                                : const Text(
                                    'Order items',
                                    style:
                                        TextStyle(
                                      color: pikkXGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // =================================================
                // DIVIDER
                // =================================================

                Container(
                  height: 1,
                  color:
                      pikkXBlack.withOpacity(0.065),
                ),

                const SizedBox(
                  height: 13,
                ),

                // =================================================
                // TOTAL + DETAILS
                // =================================================

                Row(
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: pikkXGrey,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          _formatMoney(total),
                          style:
                              const TextStyle(
                            color: pikkXBlack,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            pikkXBlack
                                .withOpacity(0.055),

                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),

                        border: Border.all(
                          color:
                              pikkXBlack
                                  .withOpacity(
                            0.055,
                          ),
                        ),
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: pikkXBlack,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            width: 6,
                          ),

                          Icon(
                            Icons
                                .arrow_forward_rounded,
                            size: 14,
                            color: pikkXBlack,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDER ICON
  // ============================================================

  Widget _orderIcon({
    required bool isActive,
  }) {
    return Container(
      width: 47,
      height: 47,

      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color:
                pikkXBlack.withOpacity(0.14),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Icon(
        isActive
            ? Icons.local_shipping_outlined
            : Icons.inventory_2_outlined,

        color: pikkXWhite,
        size: 21,
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final normalized =
        status.toLowerCase();

    String label;
    IconData icon;

    switch (normalized) {
      case 'pending':
        label = 'Pending';
        icon = Icons.access_time_rounded;
        break;

      case 'confirmed':
        label = 'Confirmed';
        icon =
            Icons.check_circle_outline_rounded;
        break;

      case 'preparing':
        label = 'Preparing';
        icon =
            Icons.inventory_2_outlined;
        break;

      case 'ready':
        label = 'Ready';
        icon =
            Icons.check_circle_outline_rounded;
        break;

      case 'out_for_delivery':
        label = 'On the way';
        icon =
            Icons.local_shipping_outlined;
        break;

      case 'delivered':
        label = 'Delivered';
        icon = Icons.done_all_rounded;
        break;

      case 'completed':
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        break;

      case 'cancelled':
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;

      default:
        label = _capitalize(
          normalized.replaceAll(
            '_',
            ' ',
          ),
        );
        icon = Icons.info_outline_rounded;
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),

          decoration:
              BoxDecoration(
            color:
                pikkXBlack.withOpacity(0.055),

            borderRadius:
                BorderRadius.circular(12),

            border: Border.all(
              color:
                  pikkXBlack.withOpacity(0.07),
            ),
          ),

          child: Row(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                icon,
                size: 12,
                color: pikkXBlack,
              ),

              const SizedBox(
                width: 4,
              ),

              Text(
                label,
                style:
                    const TextStyle(
                  color: pikkXBlack,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required bool isActive,
  }) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.all(24),

      children: [
        const SizedBox(
          height: 65,
        ),

        _glassContainer(
          radius: 30,
          opacity: 0.75,

          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              28,
              32,
              28,
              32,
            ),

            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,

                  decoration:
                      BoxDecoration(
                    color: pikkXBlack,

                    borderRadius:
                        BorderRadius.circular(
                      27,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            pikkXBlack
                                .withOpacity(
                          0.14,
                        ),
                        blurRadius: 20,
                        offset:
                            const Offset(0, 9),
                      ),
                    ],
                  ),

                  child: Icon(
                    isActive
                        ? Icons
                            .local_shipping_outlined
                        : Icons.history_rounded,

                    size: 40,
                    color: pikkXWhite,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Text(
                  isActive
                      ? 'No active orders'
                      : 'No order history',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color: pikkXBlack,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(
                  height: 9,
                ),

                Text(
                  isActive
                      ? 'Your active orders will appear here.'
                      : 'Your completed orders will appear here.',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    color: pikkXGrey,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ITEMS PREVIEW
  // ============================================================

  String _itemsPreview(
    List<dynamic> items,
  ) {
    final names = <String>[];

    for (final item in items) {
      if (item is Map) {
        final name =
            item['name']?.toString();

        if (name != null &&
            name.isNotEmpty) {
          names.add(name);
        }
      }
    }

    if (names.isEmpty) {
      return '${items.length} item(s)';
    }

    if (names.length <= 2) {
      return names.join(', ');
    }

    return '${names.take(2).join(', ')} + '
        '${names.length - 2} more';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _shortOrderId(
    String orderId,
  ) {
    if (orderId.length <= 8) {
      return orderId;
    }

    return orderId.substring(0, 8);
  }

  DateTime _timestampToDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Date unavailable';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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

  String _capitalize(
    String text,
  ) {
    if (text.isEmpty) {
      return text;
    }

    return text[0].toUpperCase() +
        text.substring(1);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            pikkXBlack,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    double radius = 24,
    double opacity = 0.7,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(
          decoration:
              BoxDecoration(
            color:
                pikkXWhite.withOpacity(opacity),

            borderRadius:
                BorderRadius.circular(radius),

            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.65),
              width: 1,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.055),
                blurRadius: 25,
                spreadRadius: 1,
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

  // ============================================================
  // GLASS PILL
  // ============================================================

  Widget _glassPill({
    required IconData icon,
    required String text,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(15),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),

          decoration:
              BoxDecoration(
            color:
                pikkXWhite.withOpacity(0.58),

            borderRadius:
                BorderRadius.circular(15),

            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.7),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.035),
                blurRadius: 12,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                icon,
                size: 13,
                color: pikkXBlack,
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                text,
                style:
                    const TextStyle(
                  color: pikkXBlack,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND GLOW
  // ============================================================

  Widget _backgroundGlow({
    required double size,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,

      decoration:
          BoxDecoration(
        shape: BoxShape.circle,

        color:
            pikkXBlack.withOpacity(opacity),

        boxShadow: [
          BoxShadow(
            color:
                pikkXBlack.withOpacity(opacity),

            blurRadius: 80,
            spreadRadius: 25,
          ),
        ],
      ),
    );
  }
}