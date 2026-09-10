
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DispatchTrackingPage extends StatefulWidget {
  final String orderId;

  const DispatchTrackingPage({super.key, required this.orderId});

  @override
  State<DispatchTrackingPage> createState() => _DispatchTrackingPageState();
}

class _DispatchTrackingPageState extends State<DispatchTrackingPage> {
  GoogleMapController? _map;
  Timer? _timer;

  static const LatLng _abuja = LatLng(9.0765, 7.3986);
  static const LatLng _lagos = LatLng(6.5244, 3.3792);

  double _progress = 0;
  LatLng _demoRider = _abuja;

  LatLng _lerp(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  void _startDemo() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;

      setState(() {
        _progress += 0.015;
        if (_progress >= 1) _progress = 0;
        _demoRider = _lerp(_abuja, _lagos, _progress);
      });

      _map?.animateCamera(
        CameraUpdate.newLatLng(_demoRider),
      );
    });
  }

  LatLng? _location(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }

    if (value is Map) {
      final lat = value['latitude'] ?? value['lat'];
      final lng = value['longitude'] ?? value['lng'] ?? value['lon'];

      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }

    return null;
  }

  LatLng? _findLocation(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final result = _location(data[key]);
      if (result != null) return result;
    }

    final lat = data['riderLatitude'] ?? data['latitude'];
    final lng = data['riderLongitude'] ?? data['longitude'];

    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
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

          final markers = <Marker>{
            Marker(
              markerId: const MarkerId('rider'),
              position: rider,
              infoWindow: InfoWindow(
                title: demo ? 'Demo Rider' : 'Rider',
              ),
            ),
            Marker(
              markerId: const MarkerId('destination'),
              position: destination,
              infoWindow: const InfoWindow(
                title: 'Delivery Destination',
              ),
            ),
          };

          final points = demo
              ? <LatLng>[
                  _abuja,
                  LatLng(8.2, 6.4),
                  LatLng(7.3, 5.5),
                  LatLng(6.8, 4.5),
                  _lagos,
                ]
              : <LatLng>[rider, destination];

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
                    'DEMO TRACKING • Abuja → Lagos\n'
                    'Real rider location is not available yet.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: rider,
                    zoom: demo ? 6.2 : 13,
                  ),
                  onMapCreated: (controller) {
                    _map = controller;
                  },
                  markers: markers,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: points,
                      width: 5,
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
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
