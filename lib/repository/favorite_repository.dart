import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FavoriteRepository({
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

  /// Reference to the current user's favorites collection.
  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites');

  /// Get all favorite products.
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _favorites.get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  /// Listen to favorites in real time.
  Stream<List<Map<String, dynamic>>> favoritesStream() {
    return _favorites.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Check whether a product is already a favorite.
  Future<bool> isFavorite(String productId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await _favorites.doc(productId).get();

      return document.exists;
    } catch (e) {
      throw Exception('Failed to check favorite status: $e');
    }
  }

  /// Add a product to favorites.
  Future<void> addFavorite({
    required String productId,
    required String name,
    required double price,
    String imageUrl,
    String category,
  }) async {
    try {
      await _favorites.doc(productId).set({
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'category': category ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove a product from favorites.
  Future<void> removeFavorite(
    String productId,
  ) async {
    try {
      await _favorites.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Toggle favorite status.
  ///
  /// If the product is already saved, it is removed.
  /// Otherwise it is added.
  Future<bool> toggleFavorite({
    required String productId,
    required String name,
    required double price,
    String imageUrl,
    String category,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> favorite =
          _favorites.doc(productId);

      final DocumentSnapshot<Map<String, dynamic>> document =
          await favorite.get();

      if (document.exists) {
        await favorite.delete();
        return false;
      }

      await favorite.set({
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'category': category ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Remove all favorite products.
  Future<void> clearFavorites() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _favorites.get();

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear favorites: $e');
    }
  }

  /// Get the number of favorite products.
  Future<int> getFavoriteCount() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _favorites.get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get favorite count: $e');
    }
  }
}