import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7F7);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color muted = Color(0xFF777777);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // GOOGLE MAP
  // ============================================================

  GoogleMapController? _mapController;

  Set<Marker> _markers = {};

  LatLng? _lastRiderLocation;

  static const LatLng _defaultLocation = LatLng(
    9.0765,
    7.3986,
  );

  // ============================================================
  // FIRESTORE ORDER STREAM
  //
  // IMPORTANT:
  // This page expects:
  //
  // orders/{orderId}
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
              : '${word[0].toUpperCase()}'
                  '${word.substring(1).toLowerCase()}',
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  overflow: TextOverflow.ellipsis,
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
            icon: Icons.my_location_rounded,
            onTap: () {
              _moveToRider();
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pikkXWhite.withOpacity(0.68),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: pikkXWhite.withOpacity(0.90),
                ),
                boxShadow: [
                  BoxShadow(
                    color: pikkXBlack.withOpacity(0.055),
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

    return _glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _blackCircleIcon(
                Icons.local_shipping_rounded,
                size: 48,
                iconSize: 23,
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatStatus(status),
                      style: const TextStyle(
                        color: pikkXBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              _blackPill(
                text: 'LIVE',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _deliveryProgress(status),
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
    final current = _statusIndex(status);

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
          final completed = index <= current;
          final last = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: completed
                          ? pikkXBlack
                          : lightGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      completed
                          ? Icons.check_rounded
                          : steps[index].$2,
                      color: completed
                          ? pikkXWhite
                          : muted,
                      size: 17,
                    ),
                  ),

                  if (!last)
                    Container(
                      width: 2,
                      height: 28,
                      color: index < current
                          ? pikkXBlack
                          : lightGrey,
                    ),
                ],
              ),

              const SizedBox(width: 12),

              Padding(
                padding: const EdgeInsets.only(
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
  // GOOGLE MAP CARD
  // ============================================================

  Widget _locationCard(
    Map<String, dynamic> data,
  ) {
    final latitude = _doubleValue(
      data,
      'riderLatitude',
    );

    final longitude = _doubleValue(
      data,
      'riderLongitude',
    );

    final hasLocation =
        latitude != null && longitude != null;

    final initialPosition = hasLocation
        ? LatLng(
            latitude!,
            longitude!,
          )
        : _defaultLocation;

    // IMPORTANT:
    // Do not call setState directly while the widget
    // is building. Schedule marker updates after build.
    if (hasLocation) {
      final riderLocation = LatLng(
        latitude!,
        longitude!,
      );

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            _updateRiderMarker(
              riderLocation,
            );
          }
        },
      );
    }

    return _glass(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(
                      target: initialPosition,
                      zoom: hasLocation ? 15 : 11,
                    ),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    buildingsEnabled: true,
                    markers: _markers,

                    onMapCreated:
                        (GoogleMapController controller) {
                      _mapController = controller;

                      if (hasLocation) {
                        _moveCamera(
                          initialPosition,
                        );
                      }
                    },
                  ),

                  // ==================================================
                  // TRACKING PILL
                  // ==================================================

                  Positioned(
                    top: 14,
                    left: 14,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: pikkXWhite
                                .withOpacity(0.88),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: pikkXWhite
                                  .withOpacity(0.95),
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
                                  color: pikkXBlack,
                                  shape: BoxShape.circle,
                                ),
                              ),

                              const SizedBox(width: 6),

                              Text(
                                hasLocation
                                    ? 'Tracking active'
                                    : 'Waiting for rider',
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
                    ),
                  ),

                  // ==================================================
                  // MAP LOCATION BUTTON
                  // ==================================================

                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: _mapGlassButton(),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // LOCATION INFORMATION
          // ========================================================

          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                _smallBlackIcon(
                  Icons.location_on_outlined,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        hasLocation
                            ? '${latitude!.toStringAsFixed(5)}, '
                                '${longitude!.toStringAsFixed(5)}'
                            : 'Location will appear when '
                                'dispatch tracking starts.',
                        style: const TextStyle(
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
  // MAP GLASS BUTTON
  // ============================================================

  Widget _mapGlassButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _moveToRider,
            borderRadius:
                BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pikkXWhite.withOpacity(0.90),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: pikkXWhite.withOpacity(0.95),
                ),
                boxShadow: [
                  BoxShadow(
                    color: pikkXBlack.withOpacity(0.08),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: pikkXBlack,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UPDATE RIDER MARKER
  // ============================================================

  void _updateRiderMarker(
    LatLng location,
  ) {
    if (_lastRiderLocation == location &&
        _markers.isNotEmpty) {
      return;
    }

    _lastRiderLocation = location;

    final marker = Marker(
      markerId: const MarkerId(
        'dispatch_rider',
      ),
      position: location,
      infoWindow: const InfoWindow(
        title: 'Dispatch rider',
        snippet: 'Your order is on the way',
      ),

      // Neutral default marker.
      // No blue/navy/purple PikkX accent.
      icon: BitmapDescriptor.defaultMarker,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _markers = {marker};
    });

    _moveCamera(
      location,
    );
  }

  // ============================================================
  // MOVE MAP TO RIDER
  // ============================================================

  Future<void> _moveToRider() async {
    final location = _lastRiderLocation;

    if (location == null) {
      return;
    }

    await _moveCamera(location);
  }

  Future<void> _moveCamera(
    LatLng location,
  ) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 16,
          ),
        ),
      );
    } catch (_) {
      // Map controller may not be ready yet.
    }
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
          _blackCircleIcon(
            Icons.person_rounded,
            size: 52,
            iconSize: 26,
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
                    // Phone calling can be connected later.
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
                ? lightGrey
                : pikkXBlack.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: pikkXBlack.withOpacity(0.06),
            ),
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? const Color(0xFFAAAAAA)
                : pikkXBlack,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: pikkXBlack.withOpacity(0.94),
            borderRadius:
                BorderRadius.circular(23),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.14),
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
                  color: pikkXWhite.withOpacity(0.10),
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
                        color: Color(0xFFBDBDBD),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      eta,
                      style: const TextStyle(
                        color: pikkXWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFBDBDBD),
                size: 14,
              ),
            ],
          ),
        ),
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
        _smallBlackIcon(icon),

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
  // BLACK CIRCLE ICON
  // ============================================================

  Widget _blackCircleIcon(
    IconData icon, {
    double size = 48,
    double iconSize = 23,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: pikkXBlack,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: pikkXWhite,
        size: iconSize,
      ),
    );
  }

  // ============================================================
  // SMALL BLACK ICON
  // ============================================================

  Widget _smallBlackIcon(
    IconData icon,
  ) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: pikkXBlack.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: pikkXBlack.withOpacity(0.06),
        ),
      ),
      child: Icon(
        icon,
        color: pikkXBlack,
        size: 16,
      ),
    );
  }

  // ============================================================
  // BLACK PILL
  // ============================================================

  Widget _blackPill({
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: pikkXWhite,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
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
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.70),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.90),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.055),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
        padding: const EdgeInsets.all(25),
        child: _glass(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _blackCircleIcon(
                Icons.error_outline_rounded,
                size: 58,
                iconSize: 30,
              ),

              const SizedBox(height: 13),

              const Text(
                'Unable to load tracking',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
  // NOT FOUND
  // ============================================================

  Widget _notFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: _glass(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _blackCircleIcon(
                Icons.inventory_2_outlined,
                size: 58,
                iconSize: 30,
              ),

              const SizedBox(height: 13),

              const Text(
                'Order not found',
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'We could not find order #${widget.orderId} '
                'in your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Go back',
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // SOFT BACKGROUND GLASS LIGHT
            // ==================================================

            Positioned(
              top: -80,
              right: -90,
              child: _backgroundGlow(
                size: 220,
                opacity: 0.025,
              ),
            ),

            Positioned(
              bottom: -100,
              left: -100,
              child: _backgroundGlow(
                size: 240,
                opacity: 0.02,
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Column(
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
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: pikkXBlack,
                            ),
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

                      // ==================================================
                      // SECURITY:
                      // Make sure the order belongs to the
                      // currently signed-in user when userId
                      // exists on the order.
                      // ==================================================

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
                        color: pikkXBlack,
                        backgroundColor: pikkXWhite,
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

                            const SizedBox(
                              height: 15,
                            ),

                            _locationCard(data),

                            const SizedBox(
                              height: 15,
                            ),

                            _riderCard(data),

                            const SizedBox(
                              height: 15,
                            ),

                            _etaCard(data),

                            const SizedBox(
                              height: 15,
                            ),

                            _orderInfo(data),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pikkXBlack.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: pikkXBlack.withOpacity(opacity),
            blurRadius: 70,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}