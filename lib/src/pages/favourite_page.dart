import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

/// ============================================================
/// FAVOURITE PAGE
///
/// Firebase structure:
///
/// users/{uid}/favorites/{productId}
///
/// Example:
/// users
///   └── USER_ID
///       └── favorites
///           └── PRODUCT_ID
///               ├── productId
///               ├── name
///               ├── price
///               ├── image
///               ├── imageUrl
///               └── createdAt
///
/// This page is designed to be used as one of the
/// bottom-navigation pages.
///
/// It does NOT create its own Scaffold/AppBar.
/// ============================================================

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>
      get favouritesRef {
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

  // ============================================================
  // REMOVE FAVOURITE
  // ============================================================

  Future<void> _removeFavourite(
    FavouriteProduct product,
  ) async {
    if (userId == null) {
      _showMessage('Please sign in first.');
      return;
    }

    try {
      await favouritesRef
          .doc(product.id)
          .delete();

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
  // OPEN PRODUCT
  // ============================================================

  void _openProduct(
    FavouriteProduct product,
  ) {
    /*
     * The exact product-detail route can be connected here
     * to the existing ProductDetailPage in the project.
     *
     * We pass the complete product data so the detail page
     * can use the real Firebase product information.
     */

    Navigator.pushNamed(
      context,
      '/product-detail',
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Colors.redAccent
            : AppTheme.grapePurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _glassHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Your',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Favourites',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _glassIcon(
            Icons.favorite_rounded,
            color: AppTheme.grapePurple,
          ),
        ],
      ),
    );
  }

  Widget _glassIcon(
    IconData icon, {
    Color? color,
  }) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
        ),
        boxShadow: AppTheme.shadow,
      ),
      child: Icon(
        icon,
        color: color ?? AppTheme.darkText,
        size: 21,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 35,
            vertical: 30,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                height: 88,
                width: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.grapePurple
                      .withOpacity(0.10),
                  border: Border.all(
                    color: AppTheme.grapePurple
                        .withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: AppTheme.grapePurple,
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'No favourites yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Products you save will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              _exploreButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exploreButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // The bottom-navigation controller should switch
          // to the Home tab here.
          //
          // This page intentionally does not push a fake
          // home route.
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: AppTheme.grapePurple,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.grapePurple
                    .withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Text(
            'Explore Products',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FAVOURITE CARD
  // ============================================================

  Widget _favouriteCard(
    FavouriteProduct product,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            _openProduct(product);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _productImage(product),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        product.displayPrice,
                        style: TextStyle(
                          color: AppTheme.grapePurple,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (product.category.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          product.category,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Remove favourite',
                  onPressed: () {
                    _removeFavourite(product);
                  },
                  icon: Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.grapePurple,
                    size: 22,
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
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage(
    FavouriteProduct product,
  ) {
    final image = product.image;

    return Container(
      height: 82,
      width: 82,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.grapeLightPurple,
        borderRadius: BorderRadius.circular(17),
      ),
      child: image.isEmpty
          ? Icon(
              Icons.shopping_bag_outlined,
              color: AppTheme.grapePurple,
              size: 32,
            )
          : _isNetworkImage(image)
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    loadingBuilder:
                        (
                      context,
                      child,
                      loadingProgress,
                    ) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return Center(
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              AppTheme.grapePurple,
                        ),
                      );
                    },
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Icon(
                        Icons
                            .image_not_supported_outlined,
                        color:
                            AppTheme.grapePurple,
                        size: 30,
                      );
                    },
                  ),
                )
              : ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Icon(
                        Icons
                            .image_not_supported_outlined,
                        color:
                            AppTheme.grapePurple,
                        size: 30,
                      );
                    },
                  ),
                ),
    );
  }

  bool _isNetworkImage(
    String image,
  ) {
    return image.startsWith('http://') ||
        image.startsWith('https://');
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
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.grapePurple,
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
  // NOT SIGNED IN
  // ============================================================

  Widget _notSignedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_rounded,
              size: 55,
              color: AppTheme.grapePurple,
            ),
            const SizedBox(height: 18),
            Text(
              'Sign in to view your favourites',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: AppTheme.grapePurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load favourites',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.grapeLightPurple,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _glassHeader(),

            Expanded(
              child: RefreshIndicator(
                color: AppTheme.grapePurple,
                onRefresh: () async {
                  // The StreamBuilder automatically receives
                  // the latest Firestore data.
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

// ============================================================
// FAVOURITE PRODUCT MODEL
// ============================================================

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
    );
  }

  static String _getImage(
    Map<String, dynamic> data,
  ) {
    final imageUrl =
        data['imageUrl']?.toString() ?? '';

    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        data['image']?.toString() ?? '';

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

  String get displayPrice {
    if (price is num) {
      return '₦${price.toStringAsFixed(2)}';
    }

    final parsed =
        double.tryParse(price.toString());

    if (parsed != null) {
      return '₦${parsed.toStringAsFixed(2)}';
    }

    return '₦$price';
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'name': name,
      'price': price,
      'image': image,
      'imageUrl': image,
      'category': category,
      'description': description,
      'sellerId': sellerId,
    };
  }
}