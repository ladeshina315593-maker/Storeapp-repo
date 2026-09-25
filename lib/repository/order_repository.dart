import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  OrderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('users').doc(_userId).collection('orders');

  Future<String> createOrder({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required Map<String, dynamic> deliveryAddress,
    String paymentMethod = 'pending',
    String paymentStatus = 'pending',
    String orderStatus = 'pending',
    String note = '',
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> order = _orders.doc();

      await order.set({
        'orderId': order.id,
        'userId': _userId,
        'items': items,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return order.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _orders
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> ordersStream() {
    return _orders
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

  Future<Map<String, dynamic>?> getOrderById(
    String orderId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await _orders.doc(orderId).get();

      if (!document.exists) {
        return null;
      }

      final data = document.data();

      if (data == null) {
        return null;
      }

      return {
        'id': document.id,
        ...data,
      };
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await _orders.doc(orderId).update({
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (paymentMethod != null) {
        updates['paymentMethod'] = paymentMethod;
      }

      if (transactionId != null) {
        updates['transactionId'] = transactionId;
      }

      await _orders.doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  Future<void> cancelOrder(
    String orderId, {
    String reason = '',
  }) async {
    try {
      await _orders.doc(orderId).update({
        'orderStatus': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}