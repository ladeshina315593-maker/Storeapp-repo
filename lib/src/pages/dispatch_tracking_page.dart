import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DispatchTrackingPage extends StatefulWidget {
  final String orderId;

  const DispatchTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<DispatchTrackingPage> createState() =>
      _DispatchTrackingPageState();
}

class _DispatchTrackingPageState
    extends State<DispatchTrackingPage> {
  // ============================================================
  // pikkX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);

  static const Color background = Color(0xFFF7F7F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF777777);
  static const Color lightBorder = Color(0xFFE8E8E8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // FIRESTORE ORDER STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _orderStream {
    return _firestore
        .collection('orders')
        .doc(widget.orderId)
        .snapshots();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _stringValue(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  double? _doubleValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  String _formatStatus(String status) {
    if (status.trim().isEmpty) {
      return 'Order placed';
    }

    final formatted = status
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    if (formatted.isEmpty) {
      return 'Order placed';
    }

    return formatted
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  int _statusIndex(String status) {
    final value = status.toLowerCase().trim();

    switch (value) {
      case 'placed':
      case 'order_placed':
      case 'pending':
        return 0;

      case 'confirmed':
      case 'accepted':
      case 'preparing':
      case 'processing':
        return 1;

      case 'dispatched':
      case 'out_for_delivery':
      case 'out-for-delivery':
        return 2;

      case 'delivered':
      case 'completed':
        return 3;

      default:
        return 0;
    }
  }

  // ============================================================
  // TOP APP BAR
  // ============================================================

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        10,
      ),
      child: Row(
        children: [
          _glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Order',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '#${widget.orderId}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          _glassIconButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
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
            color: pikkXWhite.withOpacity(0.72),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: pikkXBlack,
            size: 18,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _statusCard(
    Map<String, dynamic> data,
  ) {
    final status = _stringValue(
      data,
      'status',
      fallback: 'order_placed',
    );

    final statusText = _formatStatus(status);

    return _glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      pikkXNavy.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: pikkXNavy,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery status',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      statusText,
                      style: const TextStyle(
                        color: pikkXBlack,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      pikkXNavy.withOpacity(0.09),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: pikkXNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _deliveryProgress(
            status,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERY PROGRESS
  // ============================================================

  Widget _deliveryProgress(
    String status,
  ) {
    final current =
        _statusIndex(status);

    final steps = [
      (
        'Order placed',
        Icons.receipt_long_rounded,
      ),
      (
        'Order confirmed',
        Icons.check_circle_outline_rounded,
      ),
      (
        'Dispatched',
        Icons.local_shipping_outlined,
      ),
      (
        'Delivered',
        Icons.home_outlined,
      ),
    ];

    return Column(
      children: List.generate(
        steps.length,
        (index) {
          final completed =
              index <= current;

          final last =
              index == steps.length - 1;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 250,
                    ),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: completed
                          ? pikkXNavy
                          : const Color(
                              0xFFEDEDED,
                            ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      completed
                          ? Icons.check_rounded
                          : steps[index].$2,
                      color: completed
                          ? pikkXWhite
                          : const Color(
                              0xFF999999,
                            ),
                      size: 17,
                    ),
                  ),

                  if (!last)
                    Container(
                      width: 2,
                      height: 28,
                      color: index < current
                          ? pikkXNavy
                          : const Color(
                              0xFFE5E5E5,
                            ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 7,
                ),
                child: Text(
                  steps[index].$1,
                  style: TextStyle(
                    color: completed
                        ? pikkXBlack
                        : muted,
                    fontSize: 12,
                    fontWeight: completed
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

  // ============================================================
  // MAP / LOCATION CARD
  // ============================================================

  Widget _locationCard(
    Map<String, dynamic> data,
  ) {
    final latitude =
        _doubleValue(data, 'riderLatitude');

    final longitude =
        _doubleValue(data, 'riderLongitude');

    return _glass(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 185,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED),
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                // Simple map-style background.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(),
                  ),
                ),

                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: pikkXWhite
                          .withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: pikkXWhite,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pikkXBlack
                              .withOpacity(0.12),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons
                          .local_shipping_rounded,
                      color: pikkXNavy,
                      size: 27,
                    ),
                  ),
                ),

                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: pikkXWhite
                          .withOpacity(0.86),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              const BoxDecoration(
                            color: pikkXNavy,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Tracking active',
                          style: TextStyle(
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
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: pikkXNavy,
                  size: 21,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current dispatch location',
                        style: TextStyle(
                          color: pikkXBlack,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        latitude != null &&
                                longitude != null
                            ? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
                            : 'Location will appear when dispatch tracking starts.',
                        style:
                            const TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
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
  // RIDER CARD
  // ============================================================

  Widget _riderCard(
    Map<String, dynamic> data,
  ) {
    final riderName = _stringValue(
      data,
      'riderName',
      fallback: 'Dispatch rider',
    );

    final riderPhone = _stringValue(
      data,
      'riderPhone',
    );

    return _glass(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  pikkXNavy.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: pikkXNavy,
              size: 26,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your dispatcher',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  riderName,
                  style: const TextStyle(
                    color: pikkXBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (riderPhone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    riderPhone,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          _circleAction(
            icon: Icons.phone_outlined,
            onTap: riderPhone.isEmpty
                ? null
                : () {
                    // Phone calling can be
                    // connected later.
                  },
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: onTap == null
                ? const Color(0xFFEDEDED)
                : pikkXNavy.withOpacity(0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? const Color(0xFFAAAAAA)
                : pikkXNavy,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ETA CARD
  // ============================================================

  Widget _etaCard(
    Map<String, dynamic> data,
  ) {
    final eta = _stringValue(
      data,
      'estimatedArrival',
      fallback: 'Calculating...',
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pikkXNavy,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                pikkXNavy.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  pikkXWhite.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: pikkXWhite,
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated arrival',
                  style: TextStyle(
                    color: Color(0xFFB9C3D0),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  eta,
                  style: const TextStyle(
                    color: pikkXWhite,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFFB9C3D0),
            size: 14,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER INFORMATION
  // ============================================================

  Widget _orderInfo(
    Map<String, dynamic> data,
  ) {
    final total = _stringValue(
      data,
      'total',
      fallback: '--',
    );

    final address = _stringValue(
      data,
      'deliveryAddress',
      fallback: 'Delivery address',
    );

    return _glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order information',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          _infoRow(
            Icons.receipt_long_outlined,
            'Order ID',
            widget.orderId,
          ),

          const SizedBox(height: 12),

          _infoRow(
            Icons.payments_outlined,
            'Total',
            total,
          ),

          const SizedBox(height: 12),

          _infoRow(
            Icons.location_on_outlined,
            'Delivery address',
            address,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: pikkXNavy,
          size: 19,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: muted,
                  fontSize: 9,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  color: pikkXBlack,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
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
          padding: padding,
          decoration: BoxDecoration(
            color:
                pikkXWhite.withOpacity(0.72),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.92),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.045),
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

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState(
    String message,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: _glass(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: pikkXNavy,
                size: 45,
              ),

              const SizedBox(height: 13),

              const Text(
                'Unable to load tracking',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: pikkXNavy,
                    fontWeight:
                        FontWeight.w800,
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
  // NOT FOUND STATE
  // ============================================================

  Widget _notFound() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: _glass(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: pikkXNavy,
                size: 45,
              ),

              const SizedBox(height: 13),

              const Text(
                'Order not found',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'We could not find this order in your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUser =
        _auth.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),

            Expanded(
              child: StreamBuilder<
                  DocumentSnapshot<
                      Map<String, dynamic>>>(
                stream: _orderStream,
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color: pikkXNavy,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorState(
                      snapshot.error.toString(),
                    );
                  }

                  if (!snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return _notFound();
                  }

                  final data =
                      snapshot.data!.data() ??
                          <String, dynamic>{};

                  // If an order contains a userId,
                  // only display it to the matching
                  // authenticated user.
                  final orderUserId =
                      _stringValue(
                    data,
                    'userId',
                  );

                  if (orderUserId.isNotEmpty &&
                      currentUser != null &&
                      orderUserId !=
                          currentUser.uid) {
                    return _notFound();
                  }

                  return RefreshIndicator(
                    color: pikkXNavy,
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView(
                      physics:
                          const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        5,
                        20,
                        35,
                      ),
                      children: [
                        _statusCard(data),

                        const SizedBox(height: 15),

                        _locationCard(data),

                        const SizedBox(height: 15),

                        _riderCard(data),

                        const SizedBox(height: 15),

                        _etaCard(data),

                        const SizedBox(height: 15),

                        _orderInfo(data),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SIMPLE MAP-STYLE BACKGROUND
// ================================================================

class _MapPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFDCDCDC)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Horizontal roads
    for (double y = 20;
        y < size.height;
        y += 42) {
      path.moveTo(0, y);
      path.lineTo(size.width, y + 25);
    }

    // Vertical roads
    for (double x = 20;
        x < size.width;
        x += 55) {
      path.moveTo(x, 0);
      path.lineTo(x + 35, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}