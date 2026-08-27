import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CartRepository({
    FirebaseFirestore firestore,
    FirebaseAuth auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Current authenticated user's UID.
  String get _userId {
    final User user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    return user.uid;
  }

  /// Current user's cart reference.
  CollectionReference<Map<String, dynamic>> get _cart =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart');

  /// Get all cart items.
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _cart.get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load cart: $e');
    }
  }

  /// Listen to the cart in real time.
  Stream<List<Map<String, dynamic>>> cartStream() {
    return _cart.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Add a product to the cart.
  ///
  /// If the product already exists, its quantity is increased.
  Future<void> addToCart({
    required String productId,
    required String name,
    required double price,
    String imageUrl,
    int quantity = 1,
    Map<String, dynamic> options,
  }) async {
    try {
      if (quantity <= 0) {
        throw Exception('Quantity must be greater than zero.');
      }

      final DocumentReference<Map<String, dynamic>> item =
          _cart.doc(productId);

      final DocumentSnapshot<Map<String, dynamic>> existing =
          await item.get();

      if (existing.exists) {
        final data = existing.data() ?? {};

        final int oldQuantity =
            (data['quantity'] as num?)?.toInt() ?? 0;

        await item.update({
          'quantity': oldQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await item.set({
          'productId': productId,
          'name': name,
          'price': price,
          'imageUrl': imageUrl ?? '',
          'quantity': quantity,
          'options': options ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  /// Update the quantity of a cart item.
  Future<void> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> item =
          _cart.doc(productId);

      if (quantity <= 0) {
        await item.delete();
        return;
      }

      await item.update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update cart quantity: $e');
    }
  }

  /// Increase an item's quantity by one.
  Future<void> increaseQuantity(
    String productId,
  ) async {
    try {
      final DocumentReference<Map<String, dynamic>> item =
          _cart.doc(productId);

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await item.get();

      if (!snapshot.exists) {
        throw Exception('Cart item does not exist.');
      }

      final data = snapshot.data() ?? {};

      final int quantity =
          (data['quantity'] as num?)?.toInt() ?? 0;

      await item.update({
        'quantity': quantity + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to increase quantity: $e');
    }
  }

  /// Decrease an item's quantity by one.
  ///
  /// If the quantity reaches zero, the item is removed.
  Future<void> decreaseQuantity(
    String productId,
  ) async {
    try {
      final DocumentReference<Map<String, dynamic>> item =
          _cart.doc(productId);

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await item.get();

      if (!snapshot.exists) {
        throw Exception('Cart item does not exist.');
      }

      final data = snapshot.data() ?? {};

      final int quantity =
          (data['quantity'] as num?)?.toInt() ?? 0;

      if (quantity <= 1) {
        await item.delete();
      } else {
        await item.update({
          'quantity': quantity - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to decrease quantity: $e');
    }
  }

  /// Remove one product completely from the cart.
  Future<void> removeFromCart(
    String productId,
  ) async {
    try {
      await _cart.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to remove cart item: $e');
    }
  }

  /// Remove every item from the user's cart.
  Future<void> clearCart() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _cart.get();

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// Calculate the current cart subtotal.
  Future<double> getCartTotal() async {
    try {
      final items = await getCartItems();

      double total = 0;

      for (final item in items) {
        final double price =
            (item['price'] as num?)?.toDouble() ?? 0;

        final int quantity =
            (item['quantity'] as num?)?.toInt() ?? 0;

        total += price * quantity;
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate cart total: $e');
    }
  }

  /// Get the number of products currently in the cart.
  Future<int> getCartItemCount() async {
    try {
      final items = await getCartItems();

      int count = 0;

      for (final item in items) {
        count +=
            (item['quantity'] as num?)?.toInt() ?? 0;
      }

      return count;
    } catch (e) {
      throw Exception('Failed to calculate cart count: $e');
    }
  }
}