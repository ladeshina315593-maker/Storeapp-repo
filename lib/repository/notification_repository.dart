import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationRepository({
    FirebaseFirestore firestore,
    FirebaseAuth auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the currently authenticated user's UID.
  String get _userId {
    final User user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return user.uid;
  }

  /// Current user's notifications collection.
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('notifications');

  /// Get all notifications.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _notifications
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Listen to notifications in real time.
  Stream<List<Map<String, dynamic>>> notificationsStream() {
    return _notifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get the number of unread notifications.
  Future<int> getUnreadCount() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _notifications
              .where('isRead', isEqualTo: false)
              .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception(
        'Failed to get unread notification count: $e',
      );
    }
  }

  /// Listen to the unread notification count in real time.
  Stream<int> unreadCountStream() {
    return _notifications
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a notification for the current user.
  ///
  /// In a production app, sensitive/system notifications should
  /// preferably be created by trusted backend code rather than
  /// directly from the client.
  Future<String> createNotification({
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic> data,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> notification =
          await _notifications.add({
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return notification.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Mark one notification as read.
  Future<void> markAsRead(
    String notificationId,
  ) async {
    try {
      await _notifications.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark every notification as read.
  Future<void> markAllAsRead() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _notifications
              .where('isRead', isEqualTo: false)
              .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception(
        'Failed to mark all notifications as read: $e',
      );
    }
  }

  /// Delete one notification.
  Future<void> deleteNotification(
    String notificationId,
  ) async {
    try {
      await _notifications.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications.
  Future<void> clearNotifications() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _notifications.get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception(
        'Failed to clear notifications: $e',
      );
    }
  }
}