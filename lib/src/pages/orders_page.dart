
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_ecommerce_app/src/themes/theme.dart';

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

  // NGN-based rates.
  //
  // These are fallback/fixed rates for now.
  // The selected currency is saved locally under
  // "selected_currency".
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
  // LOAD SELECTED CURRENCY
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
  //
  // orders/{orderId}
  // ============================================================

  CollectionReference<Map<String, dynamic>> get ordersRef {
    return _firestore.collection('orders');
  }

  // ============================================================
  // LOAD USER ORDERS
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
          // IMPORTANT:
          // Firestore document ID is the real order ID.
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Sort locally so no composite Firestore index
      // is required.
      loadedOrders.sort((a, b) {
        final aTime =
            _timestampToDate(a['createdAt']);

        final bTime =
            _timestampToDate(b['createdAt']);

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
          order['orderStatus']
              ?.toString()
              .toLowerCase();

      return status != 'delivered' &&
          status != 'completed' &&
          status != 'cancelled';
    }).toList();
  }

  // ============================================================
  // COMPLETED / HISTORY
  // ============================================================

  List<Map<String, dynamic>> get completedOrders {
    return orders.where((order) {
      final status =
          order['orderStatus']
              ?.toString()
              .toLowerCase();

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
    // ALWAYS use the Firestore document ID.
    final orderId =
        order['id']?.toString();

    if (orderId == null ||
        orderId.isEmpty) {
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
  // CURRENCY CONVERSION
  // ============================================================

  double _convertMoney(double amount) {
    final rate =
        currencyRates[selectedCurrency] ??
            currencyRates['NGN']!;

    return amount * rate;
  }

  String _formatMoney(double amount) {
    final converted =
        _convertMoney(amount);

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
      backgroundColor:
          AppTheme.lightBackground,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        iconTheme: const IconThemeData(
          color: AppTheme.pikkXBlack,
        ),

        title: const Text(
          'My Orders',
          style: TextStyle(
            color: AppTheme.pikkXBlack,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Stack(
        children: [
          // ======================================================
          // SOFT BACKGROUND
          // ======================================================

          Positioned(
            top: -100,
            right: -80,
            child: _backgroundGlow(
              size: 230,
              opacity: 0.035,
            ),
          ),

          Positioned(
            bottom: -100,
            left: -80,
            child: _backgroundGlow(
              size: 240,
              opacity: 0.025,
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          isLoading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.pikkXBlack,
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildCurrencyIndicator(),

                    _buildTabs(),

                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.pikkXBlack,
                        backgroundColor:
                            AppTheme.pikkXWhite,

                        onRefresh: () async {
                          await _loadCurrency();
                          await _loadOrders();
                        },

                        child: TabBarView(
                          controller:
                              _tabController,

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
        ],
      ),
    );
  }

  // ============================================================
  // CURRENCY INDICATOR
  // ============================================================

  Widget _buildCurrencyIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        10,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: _smallGlassPill(
          icon: Icons.currency_exchange_rounded,
          text:
              'Prices in $selectedCurrency',
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
        2,
        16,
        16,
      ),
      child: _glassContainer(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: TabBar(
            controller: _tabController,

            indicator: BoxDecoration(
              color: AppTheme.pikkXBlack,
              borderRadius:
                  BorderRadius.circular(15),
            ),

            indicatorSize:
                TabBarIndicatorSize.tab,

            dividerColor:
                Colors.transparent,

            labelColor:
                AppTheme.pikkXWhite,

            unselectedLabelColor:
                AppTheme.mutedText,

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
        30,
      ),

      itemCount: orderList.length,

      separatorBuilder: (_, __) {
        return const SizedBox(
          height: 13,
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
        order['orderStatus']
            ?.toString() ??
        'pending';

    final total =
        _toDouble(order['total']);

    final items = order['items'] is List
        ? List.from(order['items'])
        : <dynamic>[];

    final createdAt =
        _timestampToDate(
      order['createdAt'],
    );

    return _glassContainer(
      radius: 25,
      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            _openOrder(order);
          },

          borderRadius:
              BorderRadius.circular(25),

          splashColor:
              AppTheme.pikkXBlack
                  .withOpacity(0.05),

          highlightColor:
              AppTheme.pikkXBlack
                  .withOpacity(0.025),

          child: Padding(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // =================================================
                // ORDER HEADER
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
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            'Order #${_shortOrderId(orderId.toString())}',

                            style:
                                const TextStyle(
                              color:
                                  AppTheme
                                      .pikkXBlack,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            _formatDate(
                              createdAt,
                            ),

                            style:
                                const TextStyle(
                              color:
                                  AppTheme
                                      .mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    _statusBadge(status),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // ITEMS PREVIEW
                // =================================================

                if (items.isNotEmpty)
                  Text(
                    _itemsPreview(items),

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          AppTheme.mutedText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  )
                else
                  const Text(
                    'Order items',

                    style:
                        TextStyle(
                      color:
                          AppTheme.mutedText,
                      fontSize: 13,
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
                  color: AppTheme.pikkXBlack
                      .withOpacity(0.07),
                ),

                const SizedBox(
                  height: 13,
                ),

                // =================================================
                // TOTAL + ACTION
                // =================================================

                Row(
                  children: [
                    const Text(
                      'Total',

                      style:
                          TextStyle(
                        color:
                            AppTheme.mutedText,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      _formatMoney(total),

                      style:
                          const TextStyle(
                        color:
                            AppTheme.pikkXBlack,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),

                      decoration:
                          BoxDecoration(
                        color: AppTheme
                            .pikkXBlack
                            .withOpacity(0.055),

                        borderRadius:
                            BorderRadius
                                .circular(11),
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Text(
                            'View Details',

                            style:
                                TextStyle(
                              color: AppTheme
                                  .pikkXBlack,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            width: 5,
                          ),

                          Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 11,
                            color: AppTheme
                                .pikkXBlack,
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
      width: 46,
      height: 46,

      decoration: BoxDecoration(
        color: AppTheme.pikkXBlack,
        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: AppTheme.pikkXBlack
                .withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Icon(
        isActive
            ? Icons.local_shipping_outlined
            : Icons.inventory_2_outlined,

        color: AppTheme.pikkXWhite,
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
        icon =
            Icons.access_time_rounded;
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
        icon =
            Icons.done_all_rounded;
        break;

      case 'completed':
        label = 'Completed';
        icon =
            Icons.check_circle_rounded;
        break;

      case 'cancelled':
        label = 'Cancelled';
        icon =
            Icons.cancel_outlined;
        break;

      default:
        label = _capitalize(
          normalized.replaceAll(
            '_',
            ' ',
          ),
        );

        icon =
            Icons.info_outline_rounded;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: AppTheme.pikkXBlack
            .withOpacity(0.07),

        borderRadius:
            BorderRadius.circular(11),

        border: Border.all(
          color: AppTheme.pikkXBlack
              .withOpacity(0.08),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 13,
            color:
                AppTheme.pikkXBlack,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            label,

            style:
                const TextStyle(
              color:
                  AppTheme.pikkXBlack,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
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
          const EdgeInsets.all(30),

      children: [
        const SizedBox(
          height: 85,
        ),

        _glassContainer(
          radius: 27,

          child: Padding(
            padding:
                const EdgeInsets.all(30),

            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,

                  decoration:
                      BoxDecoration(
                    color:
                        AppTheme.pikkXBlack,

                    borderRadius:
                        BorderRadius
                            .circular(25),

                    boxShadow: [
                      BoxShadow(
                        color: AppTheme
                            .pikkXBlack
                            .withOpacity(0.12),
                        blurRadius: 18,
                        offset:
                            const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Icon(
                    isActive
                        ? Icons
                            .local_shipping_outlined
                        : Icons
                            .history_rounded,

                    size: 40,

                    color:
                        AppTheme.pikkXWhite,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Text(
                  isActive
                      ? 'No active orders'
                      : 'No order history',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.pikkXBlack,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  isActive
                      ? 'Your active orders will appear here.'
                      : 'Your completed orders will appear here.',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    color:
                        AppTheme.mutedText,
                    height: 1.4,
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

    return orderId.substring(
      0,
      8,
    );
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
      return DateTime
          .fromMillisecondsSinceEpoch(
        value,
      );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return 'Date unavailable';
    }

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

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
            AppTheme.pikkXBlack,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
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
          decoration:
              BoxDecoration(
            color:
                AppTheme.glassWhite,

            borderRadius:
                BorderRadius.circular(
              radius,
            ),

            border: Border.all(
              color: AppTheme.pikkXBlack
                  .withOpacity(0.075),

              width: 1,
            ),

            boxShadow: [
              BoxShadow(
                color: AppTheme.pikkXBlack
                    .withOpacity(0.055),

                blurRadius: 20,

                offset:
                    const Offset(0, 9),
              ),
            ],
          ),

          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // SMALL GLASS PILL
  // ============================================================

  Widget _smallGlassPill({
    required IconData icon,
    required String text,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),

          decoration:
              BoxDecoration(
            color: AppTheme.pikkXWhite
                .withOpacity(0.58),

            borderRadius:
                BorderRadius.circular(14),

            border: Border.all(
              color: AppTheme.pikkXBlack
                  .withOpacity(0.06),
            ),
          ),

          child: Row(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                icon,
                size: 13,
                color:
                    AppTheme.pikkXBlack,
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                text,

                style:
                    const TextStyle(
                  color:
                      AppTheme.pikkXBlack,
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

        color: AppTheme.pikkXBlack
            .withOpacity(opacity),

        boxShadow: [
          BoxShadow(
            color: AppTheme.pikkXBlack
                .withOpacity(opacity),

            blurRadius: 70,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}