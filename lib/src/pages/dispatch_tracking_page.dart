import 'dart:async';
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
  // PIKKX
  // ============================================================

  static const Color pikkXBlack =
      Color(0xFF050505);

  static const Color pikkXWhite =
      Color(0xFFFFFFFF);

  static const Color background =
      Color(0xFFF7F7F7);

  static const Color lightGrey =
      Color(0xFFE8E8E8);

  static const Color muted =
      Color(0xFF777777);

  // ============================================================
  // TEST MODE
  // ============================================================
  //
  // This is ONLY for testing the tracking UI before real rider
  // GPS data exists.
  //
  // Abuja -> Lagos
  //
  // Once Firebase contains real locations, real data is used.
  // ============================================================

  static const bool _enableTestTracking = true;

  static const LatLng _testAbuja =
      LatLng(9.0765, 7.3986);

  static const LatLng _testLagos =
      LatLng(6.5244, 3.3792);

  LatLng _fakeRiderLocation =
      _testAbuja;

  Timer? _simulationTimer;

  int _simulationStep = 0;

  static const int _simulationSteps = 120;

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // MAP
  // ============================================================

  GoogleMapController? _mapController;

  bool _mapReady = false;

  LatLng? _realRiderLocation;

  LatLng? _realDestinationLocation;

  // ============================================================
  // FIRESTORE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _orderStream {
    return _firestore
        .collection('orders')
        .doc(widget.orderId)
        .snapshots();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ============================================================
  // NUMBER HELPERS
  // ============================================================

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

  bool _validCoordinates(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  LatLng? _latLngFromValue(dynamic value) {
    if (value is GeoPoint) {
      if (_validCoordinates(
        value.latitude,
        value.longitude,
      )) {
        return LatLng(
          value.latitude,
          value.longitude,
        );
      }

      return null;
    }

    if (value is Map) {
      final map =
          Map<String, dynamic>.from(value);

      final latitude = _numberToDouble(
        map['latitude'] ?? map['lat'],
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

  // ============================================================
  // STRING
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

    final result =
        value.toString().trim();

    return result.isEmpty
        ? fallback
        : result;
  }

  // ============================================================
  // REAL RIDER LOCATION
  // ============================================================

  LatLng? _getRealRiderLocation(
    Map<String, dynamic> data,
  ) {
    final direct =
        _latLngFromValue(
      data['riderLocation'],
    );

    if (direct != null) {
      return direct;
    }

    final geo =
        _latLngFromValue(
      data['riderGeoPoint'],
    );

    if (geo != null) {
      return geo;
    }

    final latitude =
        _numberToDouble(
      data['riderLatitude'],
    );

    final longitude =
        _numberToDouble(
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
  // DESTINATION
  // ============================================================

  LatLng? _getRealDestination(
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

    final pairs = [
      [
        data['destinationLatitude'],
        data['destinationLongitude'],
      ],
      [
        data['deliveryLatitude'],
        data['deliveryLongitude'],
      ],
      [
        data['latitude'],
        data['longitude'],
      ],
    ];

    for (final pair in pairs) {
      final latitude =
          _numberToDouble(pair[0]);

      final longitude =
          _numberToDouble(pair[1]);

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
        _latLngFromValue(
      data['deliveryAddress'],
    );

    return address;
  }

  // ============================================================
  // TEST LOCATION
  // ============================================================

  LatLng _getRiderLocation(
    Map<String, dynamic> data,
  ) {
    final real =
        _getRealRiderLocation(data);

    if (real != null) {
      return real;
    }

    return _fakeRiderLocation;
  }

  LatLng _getDestination(
    Map<String, dynamic> data,
  ) {
    final real =
        _getRealDestination(data);

    if (real != null) {
      return real;
    }

    return _testLagos;
  }

  bool _usingTestLocation(
    Map<String, dynamic> data,
  ) {
    return _getRealRiderLocation(data) ==
            null &&
        _enableTestTracking;
  }

  // ============================================================
  // START TEST SIMULATION
  // ============================================================

  void _startTestSimulation(
    Map<String, dynamic> data,
  ) {
    if (!_enableTestTracking) {
      return;
    }

    if (_getRealRiderLocation(data) != null) {
      _simulationTimer?.cancel();
      return;
    }

    if (_simulationTimer != null) {
      return;
    }

    _simulationTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted) {
          return;
        }

        if (_getRealRiderLocation(data) != null) {
          _simulationTimer?.cancel();
          _simulationTimer = null;
          return;
        }

        if (_simulationStep >=
            _simulationSteps) {
          _simulationTimer?.cancel();
          _simulationTimer = null;
          return;
        }

        _simulationStep++;

        final progress =
            _simulationStep /
                _simulationSteps;

        final latitude =
            _testAbuja.latitude +
                ((_testLagos.latitude -
                        _testAbuja.latitude) *
                    progress);

        final longitude =
            _testAbuja.longitude +
                ((_testLagos.longitude -
                        _testAbuja.longitude) *
                    progress);

        setState(() {
          _fakeRiderLocation =
              LatLng(
            latitude,
            longitude,
          );
        });

        _animateTo(
          _fakeRiderLocation,
          zoom: 7.5,
        );
      },
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _getStatus(
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
        status
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .trim();

    if (clean.isEmpty) {
      return 'Order placed';
    }

    return clean
        .split(RegExp(r'\s+'))
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
  // DELIVERY ADDRESS
  // ============================================================

  String _formatAddress(
    dynamic value,
  ) {
    if (value == null) {
      return 'Delivery address not available';
    }

    if (value is String) {
      return value.trim().isEmpty
          ? 'Delivery address not available'
          : value.trim();
    }

    if (value is Map) {
      final address =
          Map<String, dynamic>.from(value);

      final parts = <String>[];

      void add(dynamic value) {
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

      add(
        address['fullName'] ??
            address['name'],
      );

      add(
        address['address'] ??
            address['street'] ??
            address['addressLine'] ??
            address['addressLine1'],
      );

      add(address['addressLine2']);
      add(address['city']);
      add(address['state']);

      add(
        address['postalCode'] ??
            address['zipCode'] ??
            address['zip'],
      );

      add(address['country']);

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    return 'Delivery address not available';
  }

  // ============================================================
  // MAP MARKERS
  // ============================================================

  Set<Marker> _markers(
    Map<String, dynamic> data,
  ) {
    final rider =
        _getRiderLocation(data);

    final destination =
        _getDestination(data);

    return {
      Marker(
        markerId:
            const MarkerId('pikkx_rider'),
        position: rider,
        infoWindow:
            const InfoWindow(
          title: 'Dispatch rider',
          snippet:
              'Current delivery location',
        ),
      ),
      Marker(
        markerId:
            const MarkerId('pikkx_destination'),
        position: destination,
        infoWindow:
            const InfoWindow(
          title: 'Delivery destination',
          snippet:
              'Your order destination',
        ),
      ),
    };
  }

  // ============================================================
  // ROUTE LINE
  // ============================================================

  Set<Polyline> _polylines(
    Map<String, dynamic> data,
  ) {
    final rider =
        _getRiderLocation(data);

    final destination =
        _getDestination(data);

    return {
      Polyline(
        polylineId:
            const PolylineId(
          'pikkx_delivery_route',
        ),
        points: [
          rider,
          destination,
        ],
        width: 5,
        color: pikkXBlack,
        geodesic: true,
      ),
    };
  }

  // ============================================================
  // MAP CAMERA
  // ============================================================

  Future<void> _animateTo(
    LatLng location, {
    double zoom = 14,
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
    } catch (_) {}
  }

  Future<void> _fitRoute(
    Map<String, dynamic> data,
  ) async {
    final controller =
        _mapController;

    if (controller == null ||
        !_mapReady) {
      return;
    }

    final rider =
        _getRiderLocation(data);

    final destination =
        _getDestination(data);

    final southwest =
        LatLng(
      rider.latitude < destination.latitude
          ? rider.latitude
          : destination.latitude,
      rider.longitude < destination.longitude
          ? rider.longitude
          : destination.longitude,
    );

    final northeast =
        LatLng(
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
            southwest: southwest,
            northeast: northeast,
          ),
          55,
        ),
      );
    } catch (_) {
      await _animateTo(
        rider,
        zoom: 7,
      );
    }
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _appBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        10,
      ),
      child: Row(
        children: [
          _glassButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
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
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '#${widget.orderId}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(
    IconData icon,
    VoidCallback onTap,
  ) {
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
                    pikkXWhite.withOpacity(.75),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      pikkXWhite.withOpacity(.9),
                ),
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
  // TEST MODE CARD
  // ============================================================

  Widget _testModeCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            pikkXBlack.withOpacity(.94),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.science_outlined,
            color: pikkXWhite,
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'TEST TRACKING • Abuja → Lagos',
              style: TextStyle(
                color: pikkXWhite,
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
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
        _getStatus(data);

    return _glass(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _blackIcon(
                Icons.local_shipping_rounded,
                size: 48,
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
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatStatus(status),
                      style:
                          const TextStyle(
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
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color: pikkXBlack,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child:
                    const Text(
                  'LIVE',
                  style: TextStyle(
                    color: pikkXWhite,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
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
  // MAP CARD
  // ============================================================

  Widget _mapCard(
    Map<String, dynamic> data,
  ) {
    final rider =
        _getRiderLocation(data);

    final destination =
        _getDestination(data);

    final testMode =
        _usingTestLocation(data);

    final markers =
        _markers(data);

    final polylines =
        _polylines(data);

    return _glass(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 340,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(
                      target: rider,
                      zoom: testMode ? 7 : 14,
                    ),
                    markers: markers,
                    polylines: polylines,
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
                          if (mounted) {
                            _fitRoute(data);
                          }
                        },
                      );
                    },
                  ),

                  Positioned(
                    top: 14,
                    left: 14,
                    child: testMode
                        ? _testModeCard()
                        : _mapPill(
                            'LIVE TRACKING',
                          ),
                  ),

                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Column(
                      children: [
                        _mapControl(
                          Icons.local_shipping_rounded,
                          () => _animateTo(
                            rider,
                            zoom: testMode
                                ? 7.5
                                : 16,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        _mapControl(
                          Icons.home_outlined,
                          () => _animateTo(
                            destination,
                            zoom: testMode
                                ? 7
                                : 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(17),
            child: Column(
              children: [
                _locationRow(
                  Icons.local_shipping_outlined,
                  'Dispatch rider',
                  testMode
                      ? 'Testing from Abuja'
                      : '${rider.latitude.toStringAsFixed(5)}, '
                          '${rider.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 14),
                _locationRow(
                  Icons.location_on_outlined,
                  'Destination',
                  testMode
                      ? 'Testing destination: Lagos'
                      : _formatAddress(
                          data['deliveryAddress'],
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
  // MAP PILL
  // ============================================================

  Widget _mapPill(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        color:
            pikkXWhite.withOpacity(.9),
        borderRadius:
            BorderRadius.circular(13),
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
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP CONTROL
  // ============================================================

  Widget _mapControl(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
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
                pikkXWhite.withOpacity(.92),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  pikkXWhite,
            ),
          ),
          child: Icon(
            icon,
            color: pikkXBlack,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION ROW
  // ============================================================

  Widget _locationRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration:
              BoxDecoration(
            color:
                pikkXBlack.withOpacity(.06),
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: pikkXBlack,
            size: 16,
          ),
        ),
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
                  color: pikkXBlack,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RIDER CARD
  // ============================================================

  Widget _riderCard(
    Map<String, dynamic> data,
  ) {
    final name =
        _stringValue(
      data,
      'riderName',
      fallback: 'Dispatch rider',
    );

    final phone =
        _stringValue(
      data,
      'riderPhone',
    );

    final testMode =
        _usingTestLocation(data);

    return _glass(
      child: Row(
        children: [
          _blackIcon(
            Icons.person_rounded,
            size: 52,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your dispatcher',
                  style:
                      TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  testMode
                      ? 'Test Dispatch Rider'
                      : name,
                  style:
                      const TextStyle(
                    color: pikkXBlack,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  testMode
                      ? 'Simulated location'
                      : phone.isEmpty
                          ? 'Live location not available yet'
                          : phone,
                  style:
                      const TextStyle(
                    color: muted,
                    fontSize: 10,
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
  // ORDER INFO
  // ============================================================

  Widget _orderInfo(
    Map<String, dynamic> data,
  ) {
    final total =
        data['total'];

    final currency =
        _stringValue(
      data,
      'currency',
      fallback: 'NGN',
    );

    String totalText = '--';

    final number =
        _numberToDouble(total);

    if (number != null) {
      totalText =
          '${_currencySymbol(currency)}'
          '${number.toStringAsFixed(2)}';
    }

    return _glass(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order information',
            style:
                TextStyle(
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
            totalText,
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on_outlined,
            'Address',
            _formatAddress(
              data['deliveryAddress'],
            ),
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
          color: pikkXBlack,
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
  // ETA
  // ============================================================

  Widget _etaCard(
    Map<String, dynamic> data,
  ) {
    final testMode =
        _usingTestLocation(data);

    final eta =
        _stringValue(
      data,
      'estimatedArrival',
      fallback:
          testMode
              ? 'Test route: Abuja → Lagos'
              : 'Calculating...',
    );

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            pikkXBlack,
        borderRadius:
            BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  pikkXWhite.withOpacity(.10),
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
                  style:
                      TextStyle(
                    color:
                        Color(0xFFBDBDBD),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  eta,
                  style:
                      const TextStyle(
                    color: pikkXWhite,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
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
  // BLACK ICON
  // ============================================================

  Widget _blackIcon(
    IconData icon, {
    double size = 48,
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
        size: size * .47,
      ),
    );
  }

  // ============================================================
  // GLASS
  // ============================================================

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(17),
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
                pikkXWhite.withOpacity(.70),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  pikkXWhite.withOpacity(.9),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    pikkXBlack.withOpacity(.055),
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
  // ERROR
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
              _blackIcon(
                Icons.error_outline_rounded,
                size: 58,
              ),
              const SizedBox(height: 13),
              const Text(
                'Unable to load tracking',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color: pikkXBlack,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 10,
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
              _blackIcon(
                Icons.inventory_2_outlined,
                size: 58,
              ),
              const SizedBox(height: 13),
              const Text(
                'Order not found',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Order #${widget.orderId} '
                'does not exist yet.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    () => Navigator.pop(
                  context,
                ),
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
    final user =
        _auth.currentUser;

    return Scaffold(
      backgroundColor:
          background,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),

            Expanded(
              child:
                  StreamBuilder<
                      DocumentSnapshot<
                          Map<String, dynamic>>>(
                stream:
                    _orderStream,
                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            pikkXBlack,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorState(
                      snapshot.error
                          .toString(),
                    );
                  }

                  final document =
                      snapshot.data;

                  if (document == null ||
                      !document.exists) {
                    return _notFound();
                  }

                  final data =
                      document.data() ??
                          <String, dynamic>{};

                  if (user == null) {
                    return _errorState(
                      'Please sign in to view this order.',
                    );
                  }

                  final orderUserId =
                      _stringValue(
                    data,
                    'userId',
                  );

                  if (orderUserId.isNotEmpty &&
                      orderUserId !=
                          user.uid) {
                    return _notFound();
                  }

                  // Start fake movement only when
                  // real rider coordinates are absent.
                  _startTestSimulation(data);

                  return RefreshIndicator(
                    color: pikkXBlack,
                    backgroundColor:
                        pikkXWhite,
                    onRefresh: () async {
                      await Future<void>.delayed(
                        const Duration(
                          milliseconds: 200,
                        ),
                      );
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
                        if (_usingTestLocation(
                          data,
                        )) ...[
                          _testModeCard(),
                          const SizedBox(
                            height: 12,
                          ),
                        ],

                        _statusCard(data),

                        const SizedBox(
                          height: 14,
                        ),

                        _mapCard(data),

                        const SizedBox(
                          height: 14,
                        ),

                        _riderCard(data),

                        const SizedBox(
                          height: 14,
                        ),

                        _etaCard(data),

                        const SizedBox(
                          height: 14,
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
      ),
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _currencySymbol(
    String currency,
  ) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case r'$':
        return r'$';

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
}