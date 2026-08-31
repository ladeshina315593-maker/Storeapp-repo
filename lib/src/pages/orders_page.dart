import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  late TabController _tabController;

  bool isLoading = true;

  List<Map<String, dynamic>> orders = [];

  String? get userId => _auth.currentUser?.uid;

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

    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      // Sort locally so no composite Firestore index is required.
      loadedOrders.sort((a, b) {
        final aTime = _timestampToDate(a['createdAt']);
        final bTime = _timestampToDate(b['createdAt']);

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

      _showMessage('Unable to load your orders.');
    }
  }

  // ============================================================
  // ACTIVE ORDERS
  // ============================================================

  List<Map<String, dynamic>> get activeOrders {
    return orders.where((order) {
      final status = order['orderStatus']?.toString().toLowerCase();

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
      final status = order['orderStatus']?.toString().toLowerCase();

      return status == 'delivered' ||
          status == 'completed' ||
          status == 'cancelled';
    }).toList();
  }

  // ============================================================
  // OPEN ORDER DETAILS
  // ============================================================

  void _openOrder(Map<String, dynamic> order) {
    final orderId = order['id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      _showMessage('Order ID is unavailable.');
      return;
    }

    Navigator.pushNamed(
      context,
      '/order-details',
      arguments: orderId,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.pikkXNavy,
              ),
            )
          : Column(
              children: [
                _buildTabs(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.pikkXNavy,
                    onRefresh: _loadOrders,
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
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16,
      ),
      child: _glassContainer(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.pikkXNavy,
              borderRadius: BorderRadius.circular(17),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppTheme.pikkXWhite,
            unselectedLabelColor: AppTheme.mutedText,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        30,
      ),
      itemCount: orderList.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 12);
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

    final total = _toDouble(order['total']);

    final items = order['items'] is List
        ? List.from(order['items'])
        : <dynamic>[];

    final createdAt =
        _timestampToDate(order['createdAt']);

    return _glassContainer(
      child: InkWell(
        onTap: () {
          _openOrder(order);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // ORDER HEADER
              // ------------------------------------------------

              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.pikkXBlack,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.local_shipping_outlined
                          : Icons.inventory_2_outlined,
                      color: AppTheme.pikkXWhite,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${_shortOrderId(orderId.toString())}',
                          style: const TextStyle(
                            color: AppTheme.pikkXBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _statusBadge(status),
                ],
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // ITEMS PREVIEW
              // ------------------------------------------------

              if (items.isNotEmpty)
                Text(
                  _itemsPreview(items),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                )
              else
                const Text(
                  'Order items',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),

              const SizedBox(height: 15),

              Divider(
                color: AppTheme.pikkXBlack.withOpacity(0.08),
                height: 1,
              ),

              const SizedBox(height: 13),

              // ------------------------------------------------
              // TOTAL + ACTION
              // ------------------------------------------------

              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Text(
                    '₦${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.pikkXNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: AppTheme.pikkXNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(width: 5),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppTheme.pikkXNavy,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    String label;
    IconData icon;

    switch (normalized) {
      case 'pending':
        label = 'Pending';
        icon = Icons.access_time_rounded;
        break;

      case 'confirmed':
        label = 'Confirmed';
        icon = Icons.check_circle_outline_rounded;
        break;

      case 'preparing':
        label = 'Preparing';
        icon = Icons.inventory_2_outlined;
        break;

      case 'ready':
        label = 'Ready';
        icon = Icons.check_circle_outline_rounded;
        break;

      case 'out_for_delivery':
        label = 'On the way';
        icon = Icons.local_shipping_outlined;
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
          normalized.replaceAll('_', ' '),
        );
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.pikkXBlack,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppTheme.pikkXWhite,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.pikkXWhite,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 100),

        _glassContainer(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppTheme.pikkXBlack,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.local_shipping_outlined
                        : Icons.history_rounded,
                    size: 40,
                    color: AppTheme.pikkXWhite,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  isActive
                      ? 'No active orders'
                      : 'No order history',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.pikkXBlack,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isActive
                      ? 'Your active orders will appear here.'
                      : 'Your completed orders will appear here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    height: 1.4,
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

  String _itemsPreview(List<dynamic> items) {
    final names = <String>[];

    for (final item in items) {
      if (item is Map) {
        final name = item['name']?.toString();

        if (name != null && name.isNotEmpty) {
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

  String _shortOrderId(String orderId) {
    if (orderId.length <= 8) {
      return orderId;
    }

    return orderId.substring(0, 8);
  }

  DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Date unavailable';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }

    return text[0].toUpperCase() +
        text.substring(1);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.pikkXBlack,
      ),
    );
  }

  // ============================================================
  // BLACK / WHITE + NAVY GLASS
  // ============================================================

  Widget _glassContainer({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.pikkXBlack.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.pikkXBlack.withOpacity(0.06),
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