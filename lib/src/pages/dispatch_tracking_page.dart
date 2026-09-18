
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DispatchTrackingPage extends StatefulWidget {
  final String orderId;

  const DispatchTrackingPage({super.key, required this.orderId});

  @override
  State<DispatchTrackingPage> createState() => _DispatchTrackingPageState();
}

class _DispatchTrackingPageState extends State<DispatchTrackingPage> {
  MapboxMap? _map;
  Timer? _timer;

  static final Position _abuja = Position(7.3986, 9.0765);
  static final Position _lagos = Position(3.3792, 6.5244);

  double _progress = 0;

  Position _demoRider = _abuja;

  Position _lerp(
    Position a,
    Position b,
    double t,
  ) {
    final aLat = a.lat.toDouble();
    final aLng = a.lng.toDouble();

    final bLat = b.lat.toDouble();
    final bLng = b.lng.toDouble();

    return Position(
      aLng + (bLng - aLng) * t,
      aLat + (bLat - aLat) * t,
    );
  }

  void _startDemo() {
    if (_timer != null) return;

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted) return;

        setState(() {
          _progress += 0.015;

          if (_progress >= 1) {
            _progress = 0;
          }

          _demoRider = _lerp(
            _abuja,
            _lagos,
            _progress,
          );
        });

        final map = _map;

        if (map != null) {
          map.flyTo(
            CameraOptions(
              center: Point(
                coordinates: _demoRider,
              ),
            ),
            MapAnimationOptions(
              duration: 900,
            ),
          );
        }
      },
    );
  }

  Position? _location(dynamic value) {
    if (value is GeoPoint) {
      return Position(
        value.longitude,
        value.latitude,
      );
    }

    if (value is Map) {
      final lat =
          value['latitude'] ?? value['lat'];

      final lng =
          value['longitude'] ??
          value['lng'] ??
          value['lon'];

      if (lat is num && lng is num) {
        return Position(
          lng.toDouble(),
          lat.toDouble(),
        );
      }
    }

    return null;
  }

  Position? _findLocation(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final result = _location(data[key]);

      if (result != null) {
        return result;
      }
    }

    final lat =
        data['riderLatitude'] ??
        data['latitude'];

    final lng =
        data['riderLongitude'] ??
        data['longitude'];

    if (lat is num && lng is num) {
      return Position(
        lng.toDouble(),
        lat.toDouble(),
      );
    }

    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _map = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Dispatch Tracking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final realRider = _findLocation(
            data,
            ['riderLocation', 'riderGeoPoint'],
          );

          final realDestination = _findLocation(
            data,
            [
              'destinationLocation',
              'destinationGeoPoint',
              'deliveryLocation',
              'deliveryGeoPoint',
            ],
          );

          final demo = realRider == null;
          final rider = realRider ?? _demoRider;
          final destination = realDestination ?? _lagos;

          if (demo) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startDemo();
            });
          } else {
            _timer?.cancel();
            _timer = null;
          }

          final status =
              data['orderStatus'] ??
              data['status'] ??
              data['deliveryStatus'] ??
              (demo ? 'Demo Tracking' : 'Dispatched');

          final routePoints = demo
              ? <Position>[
                  _abuja,
                  Position(6.4, 8.2),
                  Position(5.5, 7.3),
                  Position(4.5, 6.8),
                  _lagos,
                ]
              : <Position>[rider, destination];

          return Column(
            children: [
              if (demo)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'DEMO TRACKING • Abuja → Lagos\\n'
                    'Real rider location is not available yet.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Expanded(
                child: MapWidget(
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: rider,
                    ),
                    zoom: demo ? 6.2 : 13,
                  ),
                  onMapCreated: (mapboxMap) async {
                    _map = mapboxMap;

                    final pointManager =
                        await mapboxMap.annotations
                            .createPointAnnotationManager();

                    await pointManager.create(
                      PointAnnotationOptions(
                        geometry: Point(
                          coordinates: rider,
                        ),
                        textField: demo ? 'Rider' : 'Rider',
                        textColor: Colors.black.value,
                        textHaloColor: Colors.white.value,
                        textHaloWidth: 2,
                        textSize: 14,
                      ),
                    );

                    await pointManager.create(
                      PointAnnotationOptions(
                        geometry: Point(
                          coordinates: destination,
                        ),
                        textField: 'Destination',
                        textColor: Colors.black.value,
                        textHaloColor: Colors.white.value,
                        textHaloWidth: 2,
                        textSize: 14,
                      ),
                    );

                    final lineManager =
                        await mapboxMap.annotations
                            .createPolylineAnnotationManager();

                    await lineManager.create(
                      PolylineAnnotationOptions(
                        geometry: LineString(
                          coordinates: routePoints,
                        ),
                        lineColor: Colors.black.value,
                        lineWidth: 5,
                      ),
                    );
                  },
                ),
              ),

              Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'DEMO TRACKING • Abuja → Lagos\n'
                    'Real rider location is not available yet.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Expanded(
                child: MapWidget(
                  cameraOptions: CameraOptions(
                    center: Point(coordinates: rider),
                    zoom: demo ? 6.2 : 13,
                  ),
                  onMapCreated: (controller) {
                    _map = controller;
                  },
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demo ? 'Demo delivery' : 'Your delivery',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status: $status',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      demo
                          ? 'Rider: Abuja'
                          : 'Live rider location available',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demo
                          ? 'Destination: Lagos'
                          : 'Destination location available',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
