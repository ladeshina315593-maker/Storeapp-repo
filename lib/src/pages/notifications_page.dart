import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool isLoading = true;

  List<Map<String, dynamic>> notifications = [];

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>
      get notificationsRef {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot =
          await notificationsRef.get();

      final result =
          snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      result.sort((a, b) {
        final aTime = _date(a['createdAt']);
        final bTime = _date(b['createdAt']);

        return bTime.compareTo(aTime);
      });

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Notifications error: $e',
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markRead(
    String id,
  ) async {
    if (userId == null) return;

    try {
      await notificationsRef
          .doc(id)
          .update({
        'isRead': true,
      });

      await _loadNotifications();
    } catch (e) {
      debugPrint(
        'Mark notification error: $e',
      );
    }
  }

  Future<void> _markAllRead() async {
    if (userId == null) return;

    try {
      final snapshot =
          await notificationsRef.get();

      final batch =
          _firestore.batch();

      for (final doc in snapshot.docs) {
        if (doc.data()['isRead'] != true) {
          batch.update(
            doc.reference,
            {
              'isRead': true,
            },
          );
        }
      }

      await batch.commit();

      await _loadNotifications();
    } catch (e) {
      debugPrint(
        'Mark all read error: $e',
      );
    }
  }

  DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime(1970);
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.inventory_2_outlined;

      case 'delivery':
        return Icons.local_shipping_outlined;

      case 'payment':
        return Icons.payments_outlined;

      case 'promotion':
        return Icons.local_offer_outlined;

      case 'chat':
        return Icons.chat_bubble_outline;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread =
        notifications.where(
      (n) => n['isRead'] != true,
    ).length;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1D2635),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (unread > 0)
            IconButton(
              onPressed: _markAllRead,
              tooltip: 'Mark all as read',
              icon: const Icon(
                Icons.done_all_rounded,
                color: Color(0xFF8F62D9),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB98BEF),
              ),
            )
          : notifications.isEmpty
              ? _empty()
              : RefreshIndicator(
                  color:
                      const Color(0xFFB98BEF),
                  onRefresh:
                      _loadNotifications,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        notifications.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      return _notificationCard(
                        notifications[index],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _notificationCard(
    Map<String, dynamic> notification,
  ) {
    final read =
        notification['isRead'] == true;

    final type =
        notification['type']
                ?.toString() ??
            'general';

    return _glass(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(24),
        onTap: () {
          if (!read) {
            _markRead(
              notification['id'].toString(),
            );
          }

          final orderId =
              notification['orderId'];

          if (orderId != null &&
              orderId.toString().isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/order-details',
              arguments:
                  orderId.toString(),
            );
          }
        },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF8F5FF),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  _icon(type),
                  color:
                      const Color(0xFFB98BEF),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title']
                              ?.toString() ??
                          'Notification',
                      style: TextStyle(
                        color:
                            const Color(0xFF1D2635),
                        fontWeight: read
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['message']
                              ?.toString() ??
                          '',
                      style: const TextStyle(
                        color:
                            Color(0xFF797878),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!read)
                Container(
                  width: 9,
                  height: 9,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFB98BEF),
                    shape:
                        BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: _glass(
        child: Padding(
          padding:
              const EdgeInsets.all(30),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: const [
              Icon(
                Icons.notifications_none_rounded,
                size: 58,
                color: Color(0xFFB98BEF),
              ),
              SizedBox(height: 16),
              Text(
                'No notifications',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF1D2635),
                ),
              ),
              SizedBox(height: 7),
              Text(
                'You are all caught up.',
                style: TextStyle(
                  color:
                      Color(0xFF797878),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glass({
    required Widget child,
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
          decoration:
              BoxDecoration(
            color:
                Colors.white.withOpacity(0.76),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.88),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.04),
                blurRadius: 18,
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
}