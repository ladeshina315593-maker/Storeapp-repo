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
  // LOAD NOTIFICATIONS FROM FIREBASE
  // ============================================================

  Future<void> _loadNotifications() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          notifications = [];
        });
      }
      return;
    }

    try {
      final snapshot = await notificationsRef
          .orderBy(
            'createdAt',
            descending: true,
          )
          .get();

      final result = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Notifications error: $e',
      );

      // Fallback in case createdAt is missing
      // or Firestore does not have the required index.
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

        if (!mounted) return;

        setState(() {
          notifications = result;
          isLoading = false;
        });
      } catch (fallbackError) {
        debugPrint(
          'Notifications fallback error: $fallbackError',
        );

        if (!mounted) return;

        setState(() {
          notifications = [];
          isLoading = false;
        });

        _showMessage(
          'Could not load notifications.',
        );
      }
    }
  }

  // ============================================================
  // MARK ONE NOTIFICATION AS READ
  // ============================================================

  Future<void> _markRead(String id) async {
    if (userId == null) return;

    try {
      await notificationsRef
          .doc(id)
          .update({
        'isRead': true,
      });

      if (!mounted) return;

      setState(() {
        final index = notifications.indexWhere(
          (notification) =>
              notification['id']?.toString() == id,
        );

        if (index != -1) {
          notifications[index]['isRead'] = true;
        }
      });
    } catch (e) {
      debugPrint(
        'Mark notification error: $e',
      );
    }
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================================

  Future<void> _markAllRead() async {
    if (userId == null) return;

    try {
      final snapshot =
          await notificationsRef.get();

      final batch = _firestore.batch();

      bool hasChanges = false;

      for (final doc in snapshot.docs) {
        if (doc.data()['isRead'] != true) {
          batch.update(
            doc.reference,
            {
              'isRead': true,
            },
          );

          hasChanges = true;
        }
      }

      if (hasChanges) {
        await batch.commit();
      }

      if (!mounted) return;

      setState(() {
        for (final notification
            in notifications) {
          notification['isRead'] = true;
        }
      });

      _showMessage(
        'All notifications marked as read.',
      );
    } catch (e) {
      debugPrint(
        'Mark all read error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not update notifications.',
        );
      }
    }
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
      return DateTime.tryParse(value) ??
          DateTime(1970);
    }

    return DateTime(1970);
  }

  // ============================================================
  // NOTIFICATION ICON
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
        return Icons.local_offer_outlined;

      case 'chat':
        return Icons.chat_bubble_outline_rounded;

      case 'success':
        return Icons.check_circle_outline_rounded;

      case 'warning':
        return Icons.warning_amber_rounded;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  // ============================================================
  // ICON ACCENT
  // ============================================================

  Color _iconColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return const Color(0xFF555555);

      case 'success':
        return const Color(0xFF10233F);

      default:
        return const Color(0xFF10233F);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

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
    final unread = notifications.where(
      (notification) =>
          notification['isRead'] != true,
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,

        leading: Padding(
          padding: const EdgeInsets.only(
            left: 12,
          ),
          child: _glassIcon(
            Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
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
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: _glassIcon(
                Icons.done_all_rounded,
                iconColor:
                    const Color(0xFF10233F),
                onTap: _markAllRead,
              ),
            ),
        ],
      ),

      body: Stack(
        children: [
          // ======================================================
          // SUBTLE NAVY BACKGROUND ACCENT
          // ======================================================

          Positioned(
            top: -100,
            right: -90,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10233F)
                    .withOpacity(0.035),
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
                color: Colors.black
                    .withOpacity(0.025),
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: Color(0xFF10233F),
                  ),
                )
              : notifications.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color:
                          const Color(0xFF10233F),
                      backgroundColor:
                          Colors.white,
                      onRefresh:
                          _loadNotifications,
                      child: ListView.separated(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          10,
                          16,
                          30,
                        ),
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
        ],
      ),
    );
  }

  // ============================================================
  // GLASS APP BAR ICON
  // ============================================================

  Widget _glassIcon(
    IconData icon, {
    Color? iconColor,
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
            borderRadius:
                BorderRadius.circular(15),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(0.72),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.95),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.045),
                    blurRadius: 15,
                    offset:
                        const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color:
                    iconColor ??
                    const Color(0xFF050505),
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
    final read =
        notification['isRead'] == true;

    final type =
        notification['type']
                ?.toString() ??
            'general';

    final orderId =
        notification['orderId'];

    final hasOrder =
        orderId != null &&
        orderId.toString().trim().isNotEmpty;

    return _glass(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(24),
        onTap: () async {
          if (!read) {
            await _markRead(
              notification['id'].toString(),
            );
          }

          if (!mounted) return;

          if (hasOrder) {
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
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius:
                      BorderRadius.circular(17),
                  border: Border.all(
                    color:
                        Colors.white.withOpacity(
                      0.9,
                    ),
                  ),
                ),
                child: Icon(
                  _icon(type),
                  color: _iconColor(type),
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              // ==================================================
              // TEXT
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
                            notification['title']
                                    ?.toString() ??
                                'Notification',
                            style: TextStyle(
                              color:
                                  const Color(0xFF050505),
                              fontSize: 14,
                              fontWeight: read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
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
                            width: 8,
                            height: 8,
                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(0xFF10233F),
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      notification['message']
                              ?.toString() ??
                          '',
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF666666),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    if (notification['createdAt'] !=
                        null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(
                          notification[
                              'createdAt'],
                        ),
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF999999),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],

                    if (hasOrder) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text(
                            'View order',
                            style: TextStyle(
                              color:
                                  Color(0xFF10233F),
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons
                                .arrow_forward_rounded,
                            color:
                                Color(0xFF10233F),
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
    final difference =
        now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes =
          difference.inMinutes;

      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours =
          difference.inHours;

      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays < 7) {
      final days =
          difference.inDays;

      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _empty() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: _glass(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 34,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: const [
                Icon(
                  Icons
                      .notifications_none_rounded,
                  size: 58,
                  color:
                      Color(0xFF10233F),
                ),

                SizedBox(height: 16),

                Text(
                  'No notifications',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF050505),
                  ),
                ),

                SizedBox(height: 7),

                Text(
                  'You are all caught up.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Color(0xFF777777),
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
      borderRadius:
          BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.74),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.92),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.045),
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
}