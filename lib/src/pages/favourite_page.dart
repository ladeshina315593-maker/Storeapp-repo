import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pikkx/src/pages/product_detail.dart';

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

    return _firestore
        .collection('users')
        .doc(uid ?? '_no_user_')
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(10),
    double radius = 20,
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
                blurRadius: 16,
                offset: const Offset(0, 6),
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
    final uid = userId;

    if (uid == null) return;

    try {
      await favouritesRef.doc(product.id).delete();

      if (!mounted) return;

      _showMessage(
        '${product.name} removed from favourites.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'REMOVE FAVOURITE ERROR: $e',
      );
      debugPrint(
        'STACK TRACE: $stackTrace',
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
      debugPrint('================================');
      debugPrint('FAVOURITES → CART');
      debugPrint('productId: ${product.id}');
      debugPrint('name: ${product.name}');
      debugPrint('price: ${product.numericPrice}');
      debugPrint('image: ${product.image}');
      debugPrint('sellerId: ${product.sellerId}');
      debugPrint('size: ${product.size}');
      debugPrint('color: ${product.color}');
      debugPrint('================================');

      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(product.id);

      final existing = await reference.get();

      if (existing.exists) {
        final data = existing.data();

        int quantity = 1;

        final existingQuantity =
            data?['quantity'];

        if (existingQuantity is num) {
          quantity = existingQuantity.toInt();
        } else {
          quantity = int.tryParse(
                existingQuantity?.toString() ?? '',
              ) ??
              1;
        }

        await reference.update({
          'quantity': quantity + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await reference.set({
          'productId': product.id,
          'name': product.name,
          'title': product.name,
          'price': product.numericPrice,
          'imageUrl': product.image,
          'image': product.image,
          'images': product.image.isNotEmpty
              ? [product.image]
              : <String>[],
          'quantity': 1,
          'sellerId': product.sellerId,
          'category': product.category,
          'description': product.description,
          'size': product.size,
          'color': product.color,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _showMessage(
        '${product.name} added to cart.',
      );
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('FAVOURITES CART ERROR');
      debugPrint('productId: ${product.id}');
      debugPrint('name: ${product.name}');
      debugPrint('image: ${product.image}');
      debugPrint('sellerId: ${product.sellerId}');
      debugPrint('error: $e');
      debugPrint('stackTrace: $stackTrace');
      debugPrint('================================');

      if (!mounted) return;

      _showMessage(
        'Could not add product to cart.',
        isError: true,
      );
    }
  }

  // ============================================================
  // OPEN PRODUCT DETAIL
  // ============================================================

  void _openProduct(
    FavouriteProduct product,
  ) {
    final productData = product.toMap();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          product: productData,
        ),
      ),
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

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.grey.shade500
                      : pikkXWhite,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: pikkXWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: pikkXBlack,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          duration: const Duration(
            seconds: 2,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
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
          horizontal: 20,
        ),
        child: _glassContainer(
          padding: const EdgeInsets.all(22),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color:
                      pikkXBlack.withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: pikkXBlack,
                  size: 33,
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'No favourites yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Products you save will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXGrey,
                  fontSize: 12,
                  height: 1.35,
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
        padding: const EdgeInsets.all(20),
        child: _glassContainer(
          padding: const EdgeInsets.all(22),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color:
                      pikkXBlack.withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: pikkXBlack,
                  size: 32,
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Sign in to view your favourites',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 16,
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
        padding: const EdgeInsets.all(20),
        child: _glassContainer(
          padding: const EdgeInsets.all(22),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: pikkXBlack,
                size: 40,
              ),
              const SizedBox(height: 11),
              const Text(
                'Unable to load favourites',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pikkXBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
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
        bottom: 9,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.all(8),
        radius: 20,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(17),
            onTap: () {
              _openProduct(product);
            },
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                // PRODUCT IMAGE
                _productImage(product),

                const SizedBox(width: 10),

                // PRODUCT INFORMATION
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
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
                            top: 3,
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

                      if (product.size.isNotEmpty ||
                          product.color.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 3,
                          ),
                          child: Text(
                            _selectionText(product),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: pikkXGrey,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 4),

                      Text(
                        product.displayPrice,
                        style: const TextStyle(
                          color: pikkXBlack,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 6),

                      SizedBox(
                        height: 31,
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
                              horizontal: 11,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                9,
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

                const SizedBox(width: 1),

                // ACTIONS
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity:
                          VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      tooltip:
                          'Remove favourite',
                      onPressed: () {
                        _removeFavourite(product);
                      },
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: pikkXBlack,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      visualDensity:
                          VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      tooltip: 'View product',
                      onPressed: () {
                        _openProduct(product);
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: pikkXGrey,
                        size: 13,
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
  // SIZE + COLOR DISPLAY
  // ============================================================

  String _selectionText(
    FavouriteProduct product,
  ) {
    final parts = <String>[];

    if (product.size.isNotEmpty) {
      parts.add(product.size);
    }

    if (product.color.isNotEmpty) {
      parts.add(product.color);
    }

    return parts.join(' • ');
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage(
    FavouriteProduct product,
  ) {
    final image = product.image.trim();

    return Container(
      width: 86,
      height: 100,
      decoration: BoxDecoration(
        color: pikkXBackground,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.9),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child: image.isEmpty
            ? _imageFallback()
            : _buildImage(image),
      ),
    );
  }

  // ============================================================
  // IMAGE LOADER
  // ============================================================

  Widget _buildImage(
    String image,
  ) {
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.contain,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            'Favourite asset image error: '
            '$image → $error',
          );

          return _imageFallback();
        },
      );
    }

    return Image.network(
      image,
      fit: BoxFit.contain,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: pikkXBlack,
            ),
          ),
        );
      },
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        debugPrint(
          'Favourite network image error: '
          '$image → $error',
        );

        return _imageFallback();
      },
    );
  }

  // ============================================================
  // BRANDED IMAGE FALLBACK
  // ============================================================

  Widget _imageFallback() {
    return Container(
      color: pikkXBlack.withOpacity(0.035),
      alignment: Alignment.center,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: pikkXWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: pikkXLightGrey,
          ),
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: pikkXBlack,
          size: 24,
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
            'Favourite stream error: '
            '${snapshot.error}',
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
              (doc) =>
                  FavouriteProduct.fromMap(
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
          padding:
              const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            90,
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
        child: RefreshIndicator(
          color: pikkXBlack,
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(
                milliseconds: 250,
              ),
            );
          },
          child: _content(),
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
  final String size;
  final String color;

  FavouriteProduct({
    required this.id,
    required this.name,
    required this.price,
    this.image = '',
    this.category = '',
    this.description = '',
    this.sellerId = '',
    this.size = '',
    this.color = '',
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

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
          data['category']?.toString() ?? '',
      description:
          data['description']?.toString() ?? '',
      sellerId:
          data['sellerId']?.toString() ?? '',
      size:
          data['size']?.toString() ?? '',
      color:
          data['color']?.toString() ?? '',
    );
  }

  // ============================================================
  // IMAGE RESOLVER
  // ============================================================

  static String _getImage(
    Map<String, dynamic> data,
  ) {
    final imageUrl =
        data['imageUrl']?.toString().trim() ??
            '';

    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        data['image']?.toString().trim() ??
            '';

    if (image.isNotEmpty) {
      return image;
    }

    final images = data['images'];

    if (images is List &&
        images.isNotEmpty) {
      final first =
          images.first?.toString().trim() ??
              '';

      if (first.isNotEmpty) {
        return first;
      }
    }

    return '';
  }

  // ============================================================
  // PRICE
  // ============================================================

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

  // ============================================================
  // PRODUCT DETAIL MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'name': name,
      'title': name,
      'price': numericPrice,
      'image': image,
      'imageUrl': image,
      'images': image.isNotEmpty
          ? [image]
          : <String>[],
      'category': category,
      'description': description,
      'sellerId': sellerId,
      'size': size,
      'color': color,
    };
  }
}