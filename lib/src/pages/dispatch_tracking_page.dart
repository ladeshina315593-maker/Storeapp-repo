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

  LatLng? _currentRiderLocation;
  LatLng? _currentDestinationLocation;

  bool _mapReady = false;

  // Abuja fallback only.
  // This is NOT treated as the customer's actual location.
  static const LatLng _defaultLocation = LatLng(
    9.0765,
    7.3986,
  );

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
  // BASIC HELPERS
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

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  double? _numberToDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  double? _doubleValue(
    Map<String, dynamic> data,
    String key,
  ) {
    return _numberToDouble(data[key]);
  }

  // ============================================================
  // SAFE COORDINATE READER
  //
  // Supports:
  // latitude / longitude
  // GeoPoint
  // Map latitude/longitude
  // ============================================================

  LatLng? _latLngFromValue(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final latitude = _numberToDouble(
        map['latitude'] ??
            map['lat'],
      );

      final longitude = _numberToDouble(
        map['longitude'] ??
            map['lng'] ??
            map['lon'],
      );

      if (latitude != null &&
          longitude != null &&
          _validCoordinates(
            latitude,
            longitude,
          )) {
        return LatLng(
          latitude,
          longitude,
        );
      }
    }

    return null;
  }

  bool _validCoordinates(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // ============================================================
  // RIDER LOCATION
  //
  // Supports several safe Firebase formats.
  // ============================================================

  LatLng? _getRiderLocation(
    Map<String, dynamic> data,
  ) {
    final directLocation =
        _latLngFromValue(
      data['riderLocation'],
    );

    if (directLocation != null) {
      return directLocation;
    }

    final geoLocation =
        _latLngFromValue(
      data['riderGeoPoint'],
    );

    if (geoLocation != null) {
      return geoLocation;
    }

    final latitude = _numberToDouble(
      data['riderLatitude'],
    );

    final longitude = _numberToDouble(
      data['riderLongitude'],
    );

    if (latitude != null &&
        longitude != null &&
        _validCoordinates(
          latitude,
          longitude,
        )) {
      return LatLng(
        latitude,
        longitude,
      );
    }

    return null;
  }

  // ============================================================
  // DESTINATION LOCATION
  //
  // Supports:
  // destinationLocation
  // destinationGeoPoint
  // deliveryLocation
  // deliveryGeoPoint
  // deliveryLatitude / deliveryLongitude
  // destinationLatitude / destinationLongitude
  // latitude / longitude
  // inside deliveryAddress
  // ============================================================

  LatLng? _getDestinationLocation(
    Map<String, dynamic> data,
  ) {
    final possibleValues = [
      data['destinationLocation'],
      data['destinationGeoPoint'],
      data['deliveryLocation'],
      data['deliveryGeoPoint'],
    ];

    for (final value in possibleValues) {
      final location =
          _latLngFromValue(value);

      if (location != null) {
        return location;
      }
    }

    final coordinatePairs = [
      (
        data['destinationLatitude'],
        data['destinationLongitude'],
      ),
      (
        data['deliveryLatitude'],
        data['deliveryLongitude'],
      ),
      (
        data['latitude'],
        data['longitude'],
      ),
    ];

    for (final pair in coordinatePairs) {
      final latitude =
          _numberToDouble(pair.$1);

      final longitude =
          _numberToDouble(pair.$2);

      if (latitude != null &&
          longitude != null &&
          _validCoordinates(
            latitude,
            longitude,
          )) {
        return LatLng(
          latitude,
          longitude,
        );
      }
    }

    final address =
        data['deliveryAddress'];

    final addressLocation =
        _latLngFromValue(address);

    if (addressLocation != null) {
      return addressLocation;
    }

    return null;
  }

  // ============================================================
  // ORDER STATUS
  // ============================================================

  String _getOrderStatus(
    Map<String, dynamic> data,
  ) {
    final values = [
      data['orderStatus'],
      data['status'],
      data['deliveryStatus'],
    ];

    for (final value in values) {
      if (value == null) {
        continue;
      }

      final text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'pending';
  }

  String _formatStatus(
    String status,
  ) {
    final clean =
        status.trim();

    if (clean.isEmpty) {
      return 'Order placed';
    }

    final formatted = clean
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (formatted.isEmpty) {
      return 'Order placed';
    }

    return formatted
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) {
              return word;
            }

            return word[0].toUpperCase() +
                word.substring(1).toLowerCase();
          },
        )
        .join(' ');
  }

  int _statusIndex(
    String status,
  ) {
    final value =
        status.toLowerCase().trim();

    switch (value) {
      case 'placed':
      case 'order placed':
      case 'order_placed':
      case 'pending':
        return 0;

      case 'confirmed':
      case 'accepted':
      case 'preparing':
      case 'processing':
        return 1;

      case 'dispatched':
      case 'out for delivery':
      case 'out_for_delivery':
      case 'out-for-delivery':
        return 2;

      case 'delivered':
      case 'completed':
        return 3;

      case 'cancelled':
      case 'canceled':
        return 0;

      default:
        return 0;
    }
  }

  // ============================================================
  // DELIVERY ADDRESS
  // ============================================================

  String _formatDeliveryAddress(
    dynamic value,
  ) {
    if (value == null) {
      return 'Delivery address not available';
    }

    if (value is String) {
      final text =
          value.trim();

      return text.isEmpty
          ? 'Delivery address not available'
          : text;
    }

    if (value is Map) {
      final address =
          Map<String, dynamic>.from(value);

      final parts = <String>[];

      void addValue(
        dynamic value,
      ) {
        if (value == null) {
          return;
        }

        final text =
            value.toString().trim();

        if (text.isNotEmpty &&
            !parts.contains(text)) {
          parts.add(text);
        }
      }

      addValue(
        address['fullName'] ??
            address['name'],
      );

      addValue(
        address['address'] ??
            address['street'] ??
            address['addressLine'] ??
            address['addressLine1'],
      );

      addValue(
        address['addressLine2'],
      );

      addValue(
        address['city'],
      );

      addValue(
        address['state'],
      );

      addValue(
        address['postalCode'] ??
            address['zipCode'] ??
            address['zip'],
      );

      addValue(
        address['country'],
      );

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    return 'Delivery address not available';
  }

  // ============================================================
  // MAP MARKERS
  // ============================================================

  Set<Marker> _buildMarkers(
    Map<String, dynamic> data,
  ) {
    final markers = <Marker>{};

    final rider =
        _getRiderLocation(data);

    final destination =
        _getDestinationLocation(data);

    if (rider != null) {
      markers.add(
        Marker(
          markerId:
              const MarkerId('dispatch_rider'),
          position: rider,
          infoWindow:
              const InfoWindow(
            title: 'Dispatch rider',
            snippet:
                'Your order is being delivered',
          ),
        ),
      );
    }

    if (destination != null) {
      markers.add(
        Marker(
          markerId:
              const MarkerId('delivery_destination'),
          position: destination,
          infoWindow:
              const InfoWindow(
            title: 'Delivery destination',
            snippet:
                'Your order will be delivered here',
          ),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // MAP INITIAL POSITION
  // ============================================================

  LatLng _getInitialMapPosition(
    Map<String, dynamic> data,
  ) {
    final rider =
        _getRiderLocation(data);

    if (rider != null) {
      return rider;
    }

    final destination =
        _getDestinationLocation(data);

    if (destination != null) {
      return destination;
    }

    return _defaultLocation;
  }

  // ============================================================
  // MAP CAMERA
  // ============================================================

  Future<void> _moveToRider() async {
    final location =
        _currentRiderLocation;

    if (location == null) {
      return;
    }

    await _moveCamera(
      location,
      zoom: 16,
    );
  }

  Future<void> _moveToDestination() async {
    final location =
        _currentDestinationLocation;

    if (location == null) {
      return;
    }

    await _moveCamera(
      location,
      zoom: 15,
    );
  }

  Future<void> _moveCamera(
    LatLng location, {
    double zoom = 15,
  }) async {
    final controller =
        _mapController;

    if (controller == null ||
        !_mapReady) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom,
          ),
        ),
      );
    } catch (_) {
      // Camera errors must never crash tracking.
    }
  }

  Future<void> _fitBothLocations() async {
    final controller =
        _mapController;

    if (controller == null ||
        !_mapReady) {
      return;
    }

    final rider =
        _currentRiderLocation;

    final destination =
        _currentDestinationLocation;

    if (rider == null &&
        destination == null) {
      return;
    }

    if (rider != null &&
        destination != null) {
      final southWest = LatLng(
        rider.latitude < destination.latitude
            ? rider.latitude
            : destination.latitude,
        rider.longitude < destination.longitude
            ? rider.longitude
            : destination.longitude,
      );

      final northEast = LatLng(
        rider.latitude > destination.latitude
            ? rider.latitude
            : destination.latitude,
        rider.longitude > destination.longitude
            ? rider.longitude
            : destination.longitude,
      );

      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: southWest,
              northeast: northEast,
            ),
            60,
          ),
        );
      } catch (_) {
        await _moveCamera(
          rider,
          zoom: 13,
        );
      }

      return;
    }

    await _moveCamera(
      rider ?? destination!,
      zoom: rider != null ? 16 : 15,
    );
  }

  // ============================================================
  // APP BAR
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
            icon:
                Icons.arrow_back_ios_new_rounded,
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
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _glassIconButton(
            icon:
                Icons.my_location_rounded,
            onTap: _moveToRider,
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
      borderRadius:
          BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(15),
            child: Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                color:
                    pikkXWhite.withOpacity(0.68),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      pikkXWhite.withOpacity(0.90),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        pikkXBlack.withOpacity(0.055),
                    blurRadius: 16,
                    offset:
                        const Offset(0, 6),
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
    final status =
        _getOrderStatus(data);

    return _glass(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatStatus(status),
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
                    decoration:
                        BoxDecoration(
                      color: completed
                          ? pikkXBlack
                          : lightGrey,
                      shape:
                          BoxShape.circle,
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
  // LOCATION CARD
  // ============================================================

  Widget _locationCard(
    Map<String, dynamic> data,
  ) {
    final rider =
        _getRiderLocation(data);

    final destination =
        _getDestinationLocation(data);

    // Keep these fields available to the buttons.
    _currentRiderLocation = rider;
    _currentDestinationLocation =
        destination;

    final hasRider =
        rider != null;

    final hasDestination =
        destination != null;

    final initialPosition =
        _getInitialMapPosition(data);

    final markers =
        _buildMarkers(data);

    return _glass(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
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
                      zoom:
                          hasRider ||
                                  hasDestination
                              ? 14
                              : 11,
                    ),
                    markers: markers,
                    myLocationButtonEnabled:
                        false,
                    zoomControlsEnabled:
                        false,
                    mapToolbarEnabled:
                        false,
                    compassEnabled:
                        false,
                    buildingsEnabled:
                        true,
                    rotateGesturesEnabled:
                        true,
                    scrollGesturesEnabled:
                        true,
                    tiltGesturesEnabled:
                        false,
                    zoomGesturesEnabled:
                        true,
                    onMapCreated:
                        (controller) {
                      _mapController =
                          controller;
                      _mapReady = true;

                      WidgetsBinding
                          .instance
                          .addPostFrameCallback(
                        (_) {
                          if (!mounted) {
                            return;
                          }

                          if (rider != null &&
                              destination != null) {
                            _fitBothLocations();
                          } else if (rider != null) {
                            _moveCamera(
                              rider,
                              zoom: 16,
                            );
                          } else if (destination != null) {
                            _moveCamera(
                              destination,
                              zoom: 15,
                            );
                          }
                        },
                      );
                    },
                  ),

                  // ==================================================
                  // MAP STATUS
                  // ==================================================

                  Positioned(
                    top: 14,
                    left: 14,
                    child: _mapStatusPill(
                      hasRider:
                          hasRider,
                      hasDestination:
                          hasDestination,
                    ),
                  ),

                  // ==================================================
                  // MAP CONTROLS
                  // ==================================================

                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Row(
                      children: [
                        if (hasDestination)
                          _mapControlButton(
                            icon:
                                Icons.home_outlined,
                            onTap:
                                _moveToDestination,
                          ),
                        if (hasDestination &&
                            hasRider)
                          const SizedBox(
                            width: 8,
                          ),
                        if (hasRider)
                          _mapControlButton(
                            icon:
                                Icons.my_location_rounded,
                            onTap:
                                _moveToRider,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // LOCATION INFORMATION
          // ========================================================

          Padding(
            padding:
                const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                            'Delivery destination',
                            style: TextStyle(
                              color:
                                  pikkXBlack,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            _formatDeliveryAddress(
                              data[
                                  'deliveryAddress'],
                            ),
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

                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _smallBlackIcon(
                      Icons.local_shipping_outlined,
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
                              color:
                                  pikkXBlack,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            hasRider
                                ? '${rider!.latitude.toStringAsFixed(5)}, '
                                    '${rider.longitude.toStringAsFixed(5)}'
                                : 'Waiting for dispatch location.',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP STATUS PILL
  // ============================================================

  Widget _mapStatusPill({
    required bool hasRider,
    required bool hasDestination,
  }) {
    String text;

    if (hasRider &&
        hasDestination) {
      text = 'Tracking active';
    } else if (hasRider) {
      text = 'Rider location active';
    } else if (hasDestination) {
      text = 'Destination saved';
    } else {
      text = 'Waiting for location';
    }

    return ClipRRect(
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
          decoration:
              BoxDecoration(
            color:
                pikkXWhite.withOpacity(0.88),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.95),
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
                  shape:
                      BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
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
  // MAP CONTROL
  // ============================================================

  Widget _mapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                color:
                    pikkXWhite.withOpacity(0.90),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      pikkXWhite.withOpacity(0.95),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        pikkXBlack.withOpacity(0.08),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Icon(
                icon,
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
  // RIDER CARD
  // ============================================================

  Widget _riderCard(
    Map<String, dynamic> data,
  ) {
    final riderName =
        _stringValue(
      data,
      'riderName',
      fallback: 'Dispatch rider',
    );

    final riderPhone =
        _stringValue(
      data,
      'riderPhone',
    );

    final riderLocation =
        _getRiderLocation(data);

    return _glass(
      padding:
          const EdgeInsets.all(17),
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
                  style:
                      const TextStyle(
                    color: pikkXBlack,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                if (riderPhone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    riderPhone,
                    style:
                        const TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                ],
                if (riderLocation == null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Live location not available yet',
                    style: TextStyle(
                      color: muted,
                      fontSize: 9,
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
          decoration:
              BoxDecoration(
            color: onTap == null
                ? lightGrey
                : pikkXBlack
                    .withOpacity(0.06),
            shape:
                BoxShape.circle,
            border: Border.all(
              color:
                  pikkXBlack.withOpacity(0.06),
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
    final eta =
        _stringValue(
      data,
      'estimatedArrival',
      fallback: 'Calculating...',
    );

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(18),
          decoration:
              BoxDecoration(
            color:
                pikkXBlack.withOpacity(0.94),
            borderRadius:
                BorderRadius.circular(23),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.14),
                blurRadius: 22,
                offset:
                    const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      pikkXWhite.withOpacity(0.10),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
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
                        color:
                            Color(0xFFBDBDBD),
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      eta,
                      style:
                          const TextStyle(
                        color:
                            pikkXWhite,
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
                color:
                    Color(0xFFBDBDBD),
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
    final total =
        _formatOrderTotal(data);

    final address =
        _formatDeliveryAddress(
      data['deliveryAddress'],
    );

    return _glass(
      padding:
          const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order information',
            style: TextStyle(
              color: pikkXBlack,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
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

  String _formatOrderTotal(
    Map<String, dynamic> data,
  ) {
    final total =
        data['total'];

    if (total == null) {
      return '--';
    }

    final currency =
        _stringValue(
      data,
      'currency',
      fallback: 'NGN',
    );

    final numeric =
        _numberToDouble(total);

    if (numeric != null) {
      return '${_currencySymbol(currency)}'
          '${numeric.toStringAsFixed(2)}';
    }

    return total.toString();
  }

  String _currencySymbol(
    String currency,
  ) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case '\$':
        return '\$';

      case 'GBP':
        return '£';

      case 'EUR':
        return '€';

      case 'NGN':
      case '₦':
      default:
        return '₦';
    }
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
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style:
                    const TextStyle(
                  color: pikkXBlack,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
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
      decoration:
          const BoxDecoration(
        color: pikkXBlack,
        shape:
            BoxShape.circle,
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
      decoration:
          BoxDecoration(
        color:
            pikkXBlack.withOpacity(0.06),
        shape:
            BoxShape.circle,
        border: Border.all(
          color:
              pikkXBlack.withOpacity(0.06),
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: pikkXBlack,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color: pikkXWhite,
          fontSize: 9,
          fontWeight:
              FontWeight.w800,
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
        filter:
            ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration:
              BoxDecoration(
            color:
                pikkXWhite.withOpacity(0.70),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(0.90),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(0.055),
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
              _blackCircleIcon(
                Icons.error_outline_rounded,
                size: 58,
                iconSize: 30,
              ),
              const SizedBox(height: 13),
              const Text(
                'Unable to load tracking',
                textAlign:
                    TextAlign.center,
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
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  setState(() {});
                },
                child:
                    const Text(
                  'Try again',
                  style:
                      TextStyle(
                    color: pikkXBlack,
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
  // NOT FOUND
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
              _blackCircleIcon(
                Icons.inventory_2_outlined,
                size: 58,
                iconSize: 30,
              ),
              const SizedBox(height: 13),
              const Text(
                'Order not found',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We could not find order '
                '#${widget.orderId} '
                'in your account.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child:
                    const Text(
                  'Go back',
                  style:
                      TextStyle(
                    color: pikkXBlack,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser =
        _auth.currentUser;

    return Scaffold(
      backgroundColor:
          background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -90,
              child:
                  _backgroundGlow(
                size: 220,
                opacity: 0.025,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child:
                  _backgroundGlow(
                size: 240,
                opacity: 0.02,
              ),
            ),

            Column(
              children: [
                _appBar(),

                Expanded(
                  child: StreamBuilder<
                      DocumentSnapshot<
                          Map<String, dynamic>>>(
                    stream:
                        _orderStream,
                    builder:
                        (
                      context,
                      snapshot,
                    ) {
                      if (snapshot
                              .connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child:
                              SizedBox(
                            width: 28,
                            height: 28,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              color:
                                  pikkXBlack,
                            ),
                          ),
                        );
                      }

                      if (snapshot
                          .hasError) {
                        return _errorState(
                          snapshot.error
                              .toString(),
                        );
                      }

                      final order =
                          snapshot.data;

                      if (order == null ||
                          !order.exists) {
                        return _notFound();
                      }

                      final data =
                          order.data() ??
                              <String,
                                  dynamic>{};

                      // ==================================================
                      // SECURITY
                      // ==================================================

                      if (currentUser ==
                          null) {
                        return _errorState(
                          'Please sign in to view this order.',
                        );
                      }

                      final orderUserId =
                          _stringValue(
                        data,
                        'userId',
                      );

                      if (orderUserId
                              .isNotEmpty &&
                          orderUserId !=
                              currentUser.uid) {
                        return _notFound();
                      }

                      // ==================================================
                      // CONTENT
                      // ==================================================

                      return RefreshIndicator(
                        color:
                            pikkXBlack,
                        backgroundColor:
                            pikkXWhite,
                        onRefresh:
                            () async {
                          // The StreamBuilder is already live.
                          // No extra Firestore read is necessary.
                          await Future<void>.delayed(
                            const Duration(
                              milliseconds: 150,
                            ),
                          );
                        },
                        child:
                            ListView(
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
                            _statusCard(
                              data,
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            _locationCard(
                              data,
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            _riderCard(
                              data,
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            _etaCard(
                              data,
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            _orderInfo(
                              data,
                            ),
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
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        color:
            pikkXBlack.withOpacity(
          opacity,
        ),
        boxShadow: [
          BoxShadow(
            color:
                pikkXBlack.withOpacity(
              opacity,
            ),
            blurRadius: 70,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}