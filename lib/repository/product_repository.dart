import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({
    FirebaseFirestore firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Firestore collection:
  // products/{productId}
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  /// Get all products.
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _products
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  /// Get one product by its Firebase document ID.
  Future<Map<String, dynamic>?> getProductById(
    String productId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await _products.doc(productId).get();

      if (!document.exists) {
        return null;
      }

      return {
        'id': document.id,
        ...document.data()!,
      };
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  /// Listen to products in real time.
  Stream<List<Map<String, dynamic>>> productsStream() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Get products belonging to a category.
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _products
              .where('category', isEqualTo: category)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception(
        'Failed to load products in category: $e',
      );
    }
  }

  /// Search products by name.
  ///
  /// Firestore does not provide normal "contains" searching,
  /// so this performs a prefix search on the product name.
  Future<List<Map<String, dynamic>>> searchProducts(
    String searchText,
  ) async {
    final String query = searchText.trim();

    if (query.isEmpty) {
      return getProducts();
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _products
              .orderBy('name')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Add a product to Firestore.
  ///
  /// This is mainly for the merchant/admin side later.
  Future<String> addProduct(
    Map<String, dynamic> product,
  ) async {
    try {
      final DocumentReference<Map<String, dynamic>> document =
          await _products.add({
        ...product,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return document.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Update an existing product.
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _products.doc(productId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete a product.
  ///
  /// This should normally only be available to an authorized
  /// merchant/admin account.
  Future<void> deleteProduct(
    String productId,
  ) async {
    try {
      await _products.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}