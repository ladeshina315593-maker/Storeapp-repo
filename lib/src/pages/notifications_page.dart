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

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get notificationsRef {
    final uid = userId;

    if (uid == null) {
      throw StateError('User is not signed in.');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    if (userId == null) {
      if (!mounted) return;

      setState(() {
        notifications = [];
        isLoading = false;
      });

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await notificationsRef.get();

      final result = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      result.sort((a, b) {
        return _date(b['createdAt']).compareTo(
          _date(a['createdAt']),
        );
      });

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Notifications error: $e');

      if (!mounted) return;

      setState(() {
        notifications = [];
        isLoading = false;
      });

      _showMessage('Could not load notifications.');
    }
  }

  // ============================================================
  // READ STATE
  // ============================================================

  bool _isRead(Map<String, dynamic> notification) {
    if (notification['isRead'] == true) {
      return true;
    }

    if (notification['read'] == true) {
      return true;
    }

    return false;
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> _markRead(String id) async {
    if (userId == null) return;

    try {
      await notificationsRef.doc(id).set(
        {
          'isRead': true,
          'read': true,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        final index = notifications.indexWhere(
          (notification) =>
              notification['id']?.toString() == id,
        );

        if (index != -1) {
          notifications[index]['isRead'] = true;
          notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      debugPrint('Mark notification error: $e');
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _markAllRead() async {
    if (userId == null) return;

    final unreadNotifications = notifications
        .where((notification) => !_isRead(notification))
        .toList();

    if (unreadNotifications.isEmpty) return;

    try {
      final batch = _firestore.batch();

      for (final notification in unreadNotifications) {
        final id = notification['id']?.toString();

        if (id == null || id.isEmpty) continue;

        batch.set(
          notificationsRef.doc(id),
          {
            'isRead': true,
            'read': true,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        for (final notification in notifications) {
          notification['isRead'] = true;
          notification['read'] = true;
        }
      });

      _showMessage('All notifications marked as read.');
    } catch (e) {
      debugPrint('Mark all read error: $e');

      if (mounted) {
        _showMessage('Could not update notifications.');
      }
    }
  }

  // ============================================================
  // OPEN NOTIFICATION
  // ============================================================

  Future<void> _openNotification(
    Map<String, dynamic> notification,
  ) async {
    final id = notification['id']?.toString();

    if (!_isRead(notification) && id != null) {
      await _markRead(id);
    }

    if (!mounted) return;

    final orderId = notification['orderId']?.toString();

    if (orderId != null && orderId.trim().isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/order-details',
        arguments: orderId,
      );

      return;
    }

    // Follow notifications don't need a fake route.
    // They simply become read when opened.
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime(1970);
    }

    return DateTime(1970);
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.inventory_2_outlined;

      case 'delivery':
        return Icons.local_shipping_outlined;

      case 'payment':
        return Icons.payments_outlined;

      case 'promotion':
      case 'coupon':
      case 'offer':
        return Icons.local_offer_outlined;

      case 'chat':
        return Icons.chat_bubble_outline_rounded;

      case 'follow':
      case 'merchant_follow':
        return Icons.person_add_alt_1_outlined;

      case 'success':
        return Icons.check_circle_outline_rounded;

      case 'warning':
        return Icons.warning_amber_rounded;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  // ============================================================
  // ICON COLOR
  // ============================================================

  Color _iconColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return const Color(0xFF555555);

      case 'success':
        return const Color(0xFF050505);

      default:
        return const Color(0xFF050505);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final unread = notifications
        .where((notification) => !_isRead(notification))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _glassIcon(
            Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),

        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF050505),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _glassIcon(
                Icons.done_all_rounded,
                onTap: _markAllRead,
              ),
            ),
        ],
      ),

      body: Stack(
        children: [
          // ======================================================
          // SOFT GLASS BACKGROUND SHAPES
          // ======================================================

          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.025),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.018),
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          if (isLoading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFF050505),
                ),
              ),
            )
          else if (notifications.isEmpty)
            _empty()
          else
            RefreshIndicator(
              color: const Color(0xFF050505),
              backgroundColor: Colors.white,
              onRefresh: _loadNotifications,
              child: ListView.separated(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  30,
                ),
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _notificationCard(
                    notifications[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // GLASS APP BAR ICON
  // ============================================================

  Widget _glassIcon(
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.95),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.045),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF050505),
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _notificationCard(
    Map<String, dynamic> notification,
  ) {
    final read = _isRead(notification);

    final type =
        notification['type']?.toString() ?? 'general';

    final orderId =
        notification['orderId']?.toString();

    final hasOrder =
        orderId != null && orderId.trim().isNotEmpty;

    final title =
        notification['title']?.toString() ??
            'Notification';

    final message =
        notification['message']?.toString() ?? '';

    return _glass(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openNotification(notification),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                child: Icon(
                  _icon(type),
                  color: _iconColor(type),
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color:
                                  const Color(0xFF050505),
                              fontSize: 14,
                              fontWeight: read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),

                        if (!read)
                          Container(
                            margin:
                                const EdgeInsets.only(
                              left: 8,
                              top: 4,
                            ),
                            width: 7,
                            height: 7,
                            decoration:
                                const BoxDecoration(
                              color: Color(0xFF050505),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],

                    if (notification['createdAt'] != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        _formatDate(
                          notification['createdAt'],
                        ),
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    if (hasOrder) ...[
                      const SizedBox(height: 7),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'View order',
                            style: TextStyle(
                              color: Color(0xFF050505),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF050505),
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    final date = _date(value);

    if (date.year == 1970) {
      return '';
    }

    final now = DateTime.now();

    if (date.isAfter(now)) {
      return 'Just now';
    }

    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;

      return '$minutes '
          '${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;

      return '$hours '
          '${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;

      return '$days '
          '${days == 1 ? 'day' : 'days'} ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glass(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 34,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 56,
                  color: Color(0xFF050505),
                ),

                SizedBox(height: 15),

                Text(
                  'No notifications',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF050505),
                  ),
                ),

                SizedBox(height: 7),

                Text(
                  'You are all caught up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.74),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
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
}