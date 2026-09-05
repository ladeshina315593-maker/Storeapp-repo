import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  // ============================================================
  // PIKKX COLORS
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXBackground = Color(0xFFF7F7F7);
  static const Color pikkXGrey = Color(0xFF777777);
  static const Color pikkXLightGrey = Color(0xFFE8E8E8);

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // USER
  // ============================================================

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get favouritesRef {
    final uid = userId;

    if (uid == null) {
      return _firestore
          .collection('users')
          .doc('_no_user_')
          .collection('favorites');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites');
  }

  CollectionReference<Map<String, dynamic>> get cartRef {
    final uid = userId;

    return _firestore
        .collection('users')
        .doc(uid ?? '_no_user_')
        .collection('cart');
  }

  // ============================================================
  // GLASS CONTAINER
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    double radius = 22,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(radius),
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

  // ============================================================
  // REMOVE FAVOURITE
  // ============================================================

  Future<void> _removeFavourite(
    FavouriteProduct product,
  ) async {
    if (userId == null) {
      _showMessage(
        'Please sign in first.',
        isError: true,
      );
      return;
    }

    try {
      await favouritesRef.doc(product.id).delete();

      if (!mounted) return;

      _showMessage(
        '${product.name} removed from favourites.',
      );
    } catch (e) {
      debugPrint(
        'Remove favourite error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Could not remove favourite.',
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart(
    FavouriteProduct product,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to add items to your cart.',
        isError: true,
      );
      return;
    }

    try {
      final reference = cartRef.doc(product.id);

      final existing = await reference.get();

      if (existing.exists) {
        final data = existing.data();

        int quantity = 1;

        final existingQuantity = data?['quantity'];

        if (existingQuantity is num) {
          quantity = existingQuantity.toInt();
        } else {
          quantity =
              int.tryParse(
                    existingQuantity?.toString() ?? '',
                  ) ??
                  1;
        }

        await reference.update({
          'quantity': quantity + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await reference.set({
          'productId': product.id,
          'name': product.name,
          'price': product.numericPrice,
          'imageUrl': product.image,
          'image': product.image,
          'quantity': 1,
          'sellerId': product.sellerId,
          'category': product.category,
          'description': product.description,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _showMessage(
        '${product.name} added to cart.',
      );
    } catch (e) {
      debugPrint(
        'Add to cart error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Could not add product to cart.',
        isError: true,
      );
    }
  }

  // ============================================================
  // OPEN PRODUCT
  // ============================================================

  void _openProduct(
    FavouriteProduct product,
  ) {
    Navigator.pushNamed(
      context,
      '/detail',
      arguments: product.toMap(),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.redAccent : pikkXBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        16,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        radius: 22,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your',
                    style: TextStyle(
                      color: pikkXGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Favourites',
                    style: TextStyle(
                      color: pikkXBlack,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pikkXBlack.withOpacity(0.055),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: pikkXBlack,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
        ),
        child: _glassContainer(
          padding: const EdgeInsets.all(28),
          radius: 26,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: pikkXBlack.withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: pikkXBlack,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'No favourites yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Products you save will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOT SIGNED IN
  // ============================================================

  Widget _notSignedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: _glassContainer(
          padding: const EdgeInsets.all(26),
          radius: 26,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: pikkXBlack.withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: pikkXBlack,
                  size: 36,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Sign in to view your favourites',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: _glassContainer(
          padding: const EdgeInsets.all(26),
          radius: 26,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: pikkXBlack,
                size: 45,
              ),

              const SizedBox(height: 15),

              const Text(
                'Unable to load favourites',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _favouriteCard(
    FavouriteProduct product,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 13,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.all(11),
        radius: 22,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              _openProduct(product);
            },
            child: Row(
              children: [
                _productImage(product),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: pikkXBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (product.category.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            product.category,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: pikkXGrey,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 6),

                      Text(
                        product.displayPrice,
                        style: const TextStyle(
                          color: pikkXBlack,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 9),

                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () {
                            _addToCart(product);
                          },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                pikkXBlack,
                            foregroundColor:
                                pikkXWhite,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 13,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 3),

                Column(
                  children: [
                    IconButton(
                      tooltip: 'Remove favourite',
                      onPressed: () {
                        _removeFavourite(product);
                      },
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: pikkXBlack,
                        size: 21,
                      ),
                    ),

                    IconButton(
                      tooltip: 'View product',
                      onPressed: () {
                        _openProduct(product);
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: pikkXGrey,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage(
    FavouriteProduct product,
  ) {
    final image = product.image;

    return Container(
      width: 88,
      height: 104,
      decoration: BoxDecoration(
        color: pikkXBackground,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      child: image.isEmpty
          ? const Icon(
              Icons.shopping_bag_outlined,
              color: pikkXBlack,
              size: 34,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: pikkXBlack,
                    ),
                  );
                },
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    color: pikkXBlack,
                    size: 30,
                  );
                },
              ),
            ),
    );
  }

  // ============================================================
  // FIREBASE CONTENT
  // ============================================================

  Widget _content() {
    if (userId == null) {
      return _notSignedInState();
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: favouritesRef
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          debugPrint(
            'Favourite stream error: ${snapshot.error}',
          );

          return _errorState();
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: pikkXBlack,
            ),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return _emptyState();
        }

        final favourites = documents
            .map(
              (doc) => FavouriteProduct.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();

        return ListView.builder(
          physics:
              const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            110,
          ),
          itemCount: favourites.length,
          itemBuilder: (
            context,
            index,
          ) {
            return _favouriteCard(
              favourites[index],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7F7F7),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),

            Expanded(
              child: RefreshIndicator(
                color: pikkXBlack,
                onRefresh: () async {
                  await Future<void>.delayed(
                    const Duration(
                      milliseconds: 300,
                    ),
                  );
                },
                child: _content(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FAVOURITE PRODUCT MODEL
// ================================================================

class FavouriteProduct {
  final String id;
  final String name;
  final dynamic price;
  final String image;
  final String category;
  final String description;
  final String sellerId;

  FavouriteProduct({
    required this.id,
    required this.name,
    required this.price,
    this.image = '',
    this.category = '',
    this.description = '',
    this.sellerId = '',
  });

  // ==========================================================
  // FROM FIRESTORE
  // ==========================================================

  factory FavouriteProduct.fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return FavouriteProduct(
      id: data['productId']?.toString() ??
          documentId,
      name: data['name']?.toString() ??
          data['title']?.toString() ??
          'Product',
      price: data['price'] ?? 0,
      image: _getImage(data),
      category:
          data['category']?.toString() ??
              '',
      description:
          data['description']?.toString() ??
              '',
      sellerId:
          data['sellerId']?.toString() ??
              '',
    );
  }

  // ==========================================================
  // IMAGE
  // ==========================================================

  static String _getImage(
    Map<String, dynamic> data,
  ) {
    final imageUrl =
        data['imageUrl']?.toString() ??
            '';

    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        data['image']?.toString() ??
            '';

    if (image.isNotEmpty) {
      return image;
    }

    final images = data['images'];

    if (images is List &&
        images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  // ==========================================================
  // PRICE
  // ==========================================================

  double get numericPrice {
    if (price is num) {
      return price.toDouble();
    }

    return double.tryParse(
          price?.toString() ?? '',
        ) ??
        0.0;
  }

  String get displayPrice {
    return '₦${numericPrice.toStringAsFixed(2)}';
  }

  // ==========================================================
  // MAP
  // ==========================================================

  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'name': name,
      'price': numericPrice,
      'image': image,
      'imageUrl': image,
      'category': category,
      'description': description,
      'sellerId': sellerId,
    };
  }
}