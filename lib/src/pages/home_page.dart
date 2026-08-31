import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/widgets/extentions.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    this.title,
  });

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String selectedFilter = 'All';
  String selectedCategory = 'All';

  XFile? _cameraImage;

  final List<String> categories = const [
    'All',
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Accessories',
    'Other',
  ];

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXNavy = Color(0xFF10233F);
  static const Color pikkXBackground = Color(0xFFF7F7F7);

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // AUTH
  // ============================================================

  User? get _currentUser => _auth.currentUser;

  String get _userId => _currentUser?.uid ?? '';

  // ============================================================
  // FIRESTORE PRODUCTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream() {
    return _firestore
        .collection('products')
        .snapshots();
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userProfileStream() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots();
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .snapshots();
  }

  // ============================================================
  // CAMERA / VISUAL SEARCH
  // ============================================================

  Future<void> _openCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _cameraImage = image;
      });

      if (!mounted) return;

      _showMessage(
        'Product image captured.',
      );
    } catch (e) {
      debugPrint('Camera error: $e');

      if (!mounted) return;

      _showMessage(
        'Could not open the camera.',
      );
    }
  }

  // ============================================================
  // CART
  // ============================================================

  Future<void> _addToCart(
    String productId,
    Map<String, dynamic> product,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to add items to your cart.',
      );
      return;
    }

    try {
      final cartReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId);

      final existing = await cartReference.get();

      final price = _toDouble(product['price']);

      if (existing.exists) {
        final existingData = existing.data();

        final currentQuantity =
            _toInt(existingData?['quantity'], fallback: 1);

        await cartReference.update({
          'quantity': currentQuantity + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartReference.set({
          'productId': productId,
          'name': product['name'] ?? 'Product',
          'price': price,
          'imageUrl': product['imageUrl'] ?? '',
          'quantity': 1,
          'sellerId': product['sellerId'] ?? '',
          'category': product['category'] ?? '',
          'description': product['description'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _showMessage('Added to cart.');
    } catch (e) {
      debugPrint('Add to cart error: $e');

      _showMessage(
        'Could not add product to cart.',
      );
    }
  }

  // ============================================================
  // FAVOURITES
  // ============================================================

  Future<void> _toggleFavourite(
    String productId,
    Map<String, dynamic> product,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to save favourites.',
      );
      return;
    }

    try {
      final reference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId);

      final existing = await reference.get();

      if (existing.exists) {
        await reference.delete();

        _showMessage(
          'Removed from favourites.',
        );
      } else {
        await reference.set({
          'productId': productId,
          'name': product['name'] ?? 'Product',
          'price': _toDouble(product['price']),
          'imageUrl': product['imageUrl'] ?? '',
          'category': product['category'] ?? '',
          'sellerId': product['sellerId'] ?? '',
          'description': product['description'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showMessage(
          'Added to favourites.',
        );
      }
    } catch (e) {
      debugPrint('Favourite error: $e');

      _showMessage(
        'Could not update favourite.',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  bool _matchesSearch(
    Map<String, dynamic> product,
  ) {
    final search =
        _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return true;
    }

    final name =
        (product['name'] ?? '').toString().toLowerCase();

    final description =
        (product['description'] ?? '')
            .toString()
            .toLowerCase();

    final category =
        (product['category'] ?? '')
            .toString()
            .toLowerCase();

    final seller =
        (product['sellerName'] ?? '')
            .toString()
            .toLowerCase();

    return name.contains(search) ||
        description.contains(search) ||
        category.contains(search) ||
        seller.contains(search);
  }

  // ============================================================
  // FILTER
  // ============================================================

  bool _matchesFilter(
    Map<String, dynamic> product,
  ) {
    if (selectedFilter == 'All') {
      return true;
    }

    if (selectedFilter == 'Trending Now') {
      return product['isTrending'] == true;
    }

    if (selectedFilter == 'Featured') {
      return product['isFeatured'] == true;
    }

    return true;
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  bool _matchesCategory(
    Map<String, dynamic> product,
  ) {
    if (selectedCategory == 'All') {
      return true;
    }

    final category =
        (product['category'] ?? '')
            .toString()
            .toLowerCase();

    return category ==
        selectedCategory.toLowerCase();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  String _formatPrice(dynamic value) {
    return '₦${_toDouble(value).toStringAsFixed(2)}';
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
        12,
      ),
      child: Row(
        children: [
          // ----------------------------------------------------
          // LOGO - UPPER LEFT
          // ----------------------------------------------------

          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: pikkXWhite,
              borderRadius:
                  BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color:
                      pikkXBlack.withOpacity(.06),
                  blurRadius: 15,
                  offset:
                      const Offset(0, 5),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/pikkx_icon(1).png',
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) {
                return const Icon(
                  Icons.shopping_bag_rounded,
                  color: pikkXNavy,
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: TextStyle(
                    color:
                        LightColor.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'pikkX',
                  style: TextStyle(
                    color: pikkXBlack,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------------------
          // NOTIFICATIONS
          // ----------------------------------------------------

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: _notificationsStream(),
            builder:
                (context, snapshot) {
              int unread = 0;

              if (snapshot.hasData) {
                unread = snapshot
                    .data!
                    .docs
                    .where(
                      (doc) =>
                          doc.data()[
                              'read'] !=
                          true,
                    )
                    .length;
              }

              return Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  _headerButton(
                    Icons
                        .notifications_none_rounded,
                    onTap:
                        _openNotifications,
                  ),

                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -3,
                      child:
                          Container(
                        width: 18,
                        height: 18,
                        alignment:
                            Alignment
                                .center,
                        decoration:
                            const BoxDecoration(
                          color:
                              pikkXNavy,
                          shape:
                              BoxShape
                                  .circle,
                        ),
                        child:
                            Text(
                          unread >
                                  9
                              ? '9+'
                              : '$unread',
                          style:
                              const TextStyle(
                            color:
                                pikkXWhite,
                            fontSize:
                                8,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 8),

          // ----------------------------------------------------
          // PROFILE
          // ----------------------------------------------------

          StreamBuilder<
              DocumentSnapshot<
                  Map<String, dynamic>>>(
            stream:
                _userProfileStream(),
            builder:
                (context, snapshot) {
              final data =
                  snapshot.data?.data();

              final imageUrl =
                  data?['photoUrl']
                          ?.toString() ??
                      '';

              return _profileButton(
                imageUrl,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER BUTTON
  // ============================================================

  Widget _headerButton(
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: pikkXWhite,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              pikkXNavy.withOpacity(.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                pikkXBlack.withOpacity(.035),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: pikkXNavy,
        size: 23,
      ),
    ).ripple(
      onTap,
      borderRadius:
          BorderRadius.circular(15),
    );
  }

  // ============================================================
  // PROFILE BUTTON
  // ============================================================

  Widget _profileButton(
    String imageUrl,
  ) {
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: pikkXWhite,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              pikkXNavy.withOpacity(.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                pikkXBlack.withOpacity(.035),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(13),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons.person_outline_rounded,
                    color: pikkXNavy,
                    size: 24,
                  );
                },
              )
            : const Icon(
                Icons.person_outline_rounded,
                color: pikkXNavy,
                size: 24,
              ),
      ),
    ).ripple(
      _openProfile,
      borderRadius:
          BorderRadius.circular(15),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        14,
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: pikkXWhite,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color:
                pikkXNavy.withOpacity(.08),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  pikkXBlack.withOpacity(.045),
              blurRadius: 18,
              offset:
                  const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),

            const Icon(
              Icons.search_rounded,
              color: pikkXNavy,
              size: 24,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller:
                    _searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration:
                    InputDecoration(
                  border:
                      InputBorder.none,
                  hintText:
                      'Search products...',
                  hintStyle:
                      TextStyle(
                    color:
                        LightColor
                            .mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // CAMERA
            // --------------------------------------------------

            GestureDetector(
              onTap: _openCamera,
              child: Container(
                margin:
                    const EdgeInsets.only(
                  right: 6,
                ),
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color: pikkXNavy,
                  borderRadius:
                      BorderRadius
                          .circular(14),
                ),
                child: const Icon(
                  Icons
                      .camera_alt_outlined,
                  color: pikkXWhite,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK FILTERS
  // ============================================================

  Widget _quickFilters() {
    return SizedBox(
      height: 43,
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            categories.length,
        itemBuilder:
            (context, index) {
          final category =
              categories[index];

          final selected =
              selectedCategory ==
                  category;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 9,
            ),
            child:
                GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory =
                      category;
                });
              },
              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 180,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 17,
                ),
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: selected
                      ? pikkXNavy
                      : pikkXWhite,
                  borderRadius:
                      BorderRadius
                          .circular(14),
                  border:
                      Border.all(
                    color: selected
                        ? pikkXNavy
                        : pikkXNavy
                            .withOpacity(
                                .09),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: selected
                        ? pikkXWhite
                        : pikkXNavy,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PROMO
  // ============================================================

  Widget _promoBanner() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        6,
      ),
      child: Container(
        height: 138,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pikkXNavy,
          borderRadius:
              BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Shop beyond\nshopping.',
                    style: TextStyle(
                      color: pikkXWhite,
                      fontSize: 21,
                      height: 1.05,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Discover products made for you.',
                    style: TextStyle(
                      color: pikkXWhite
                          .withOpacity(.72),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 65,
              height: 65,
              decoration:
                  BoxDecoration(
                color: pikkXWhite
                    .withOpacity(.10),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .shopping_bag_outlined,
                color: pikkXWhite,
                size: 31,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Widget _productWidget() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: _productsStream(),
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding:
                EdgeInsets.all(35),
            child: Center(
              child:
                  CircularProgressIndicator(
                color: pikkXNavy,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            'Products error: ${snapshot.error}',
          );

          return _firebaseError();
        }

        final documents =
            snapshot.data?.docs ?? [];

        final products =
            documents.where((doc) {
          final data =
              doc.data();

          return _matchesSearch(
                data,
              ) &&
              _matchesFilter(
                data,
              ) &&
              _matchesCategory(
                data,
              );
        }).toList();

        // Newest products first.
        products.sort(
          (a, b) {
            final aData =
                a.data();

            final bData =
                b.data();

            final aTime =
                aData['createdAt'];

            final bTime =
                bData['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(
                aTime,
              );
            }

            return 0;
          },
        );

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                20,
                24,
                20,
                8,
              ),
              child: Row(
                children: [
                  const Text(
                    'Popular Products',
                    style: TextStyle(
                      color: pikkXBlack,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length}',
                    style:
                        const TextStyle(
                      color: pikkXNavy,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            if (products.isEmpty)
              _emptyProducts()
            else
              SizedBox(
                height: 292,
                child:
                    ListView.builder(
                  padding:
                      const EdgeInsets
                          .only(
                    left: 20,
                    right: 10,
                  ),
                  scrollDirection:
                      Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),
                  itemCount:
                      products.length,
                  itemBuilder:
                      (context, index) {
                    final document =
                        products[index];

                    return _productCard(
                      document.id,
                      document.data(),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _productCard(
    String productId,
    Map<String, dynamic> product,
  ) {
    final name =
        product['name']?.toString() ??
            'Product';

    final price =
        _toDouble(product['price']);

    final imageUrl =
        product['imageUrl']
                ?.toString() ??
            '';

    final featured =
        product['isFeatured'] ==
            true;

    final sellerName =
        product['sellerName']
                ?.toString() ??
            '';

    return Container(
      width: 205,
      margin:
          const EdgeInsets.only(
        top: 8,
        right: 15,
        bottom: 15,
      ),
      decoration:
          BoxDecoration(
        color: pikkXWhite,
        borderRadius:
            BorderRadius.circular(
          23,
        ),
        border:
            Border.all(
          color: pikkXNavy
              .withOpacity(.07),
        ),
        boxShadow: [
          BoxShadow(
            color: pikkXBlack
                .withOpacity(.055),
            blurRadius: 16,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () =>
                      _openProduct(
                    productId,
                    product,
                  ),
                  child:
                      Container(
                    width:
                        double.infinity,
                    decoration:
                        const BoxDecoration(
                      color:
                          pikkXBackground,
                      borderRadius:
                          BorderRadius
                              .vertical(
                        top:
                            Radius.circular(
                          23,
                        ),
                      ),
                    ),
                    child: imageUrl
                            .isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                const BorderRadius
                                    .vertical(
                              top:
                                  Radius.circular(
                                23,
                              ),
                            ),
                            child:
                                Image.network(
                              imageUrl,
                              fit: BoxFit
                                  .cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _productPlaceholder(),
                            ),
                          )
                        : _productPlaceholder(),
                  ),
                ),

                // ------------------------------------------------
                // FAVOURITE
                // ------------------------------------------------

                Positioned(
                  top: 10,
                  right: 10,
                  child:
                      Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color: pikkXWhite
                          .withOpacity(
                              .92),
                      shape:
                          BoxShape
                              .circle,
                    ),
                    child:
                        IconButton(
                      padding:
                          EdgeInsets.zero,
                      onPressed:
                          () =>
                              _toggleFavourite(
                        productId,
                        product,
                      ),
                      icon:
                          const Icon(
                        Icons
                            .favorite_border_rounded,
                        color:
                            pikkXNavy,
                        size: 19,
                      ),
                    ),
                  ),
                ),

                // ------------------------------------------------
                // FEATURED
                // ------------------------------------------------

                if (featured)
                  Positioned(
                    left: 10,
                    top: 10,
                    child:
                        Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            pikkXNavy,
                        borderRadius:
                            BorderRadius
                                .circular(
                          9,
                        ),
                      ),
                      child:
                          const Text(
                        'Featured',
                        style:
                            TextStyle(
                          color:
                              pikkXWhite,
                          fontSize:
                              9,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              13,
              10,
              13,
              12,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        pikkXBlack,
                    fontSize: 14,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                if (sellerName
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 2,
                    ),
                    child: Text(
                      sellerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        color: LightColor
                            .mutedText,
                        fontSize: 9,
                      ),
                    ),
                  ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  _formatPrice(
                    price,
                  ),
                  style:
                      const TextStyle(
                    color:
                        pikkXNavy,
                    fontSize: 14,
                    fontWeight:
                        FontWeight
                            .w900,
                  ),
                ),

                const SizedBox(
                  height: 9,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 38,
                  child:
                      ElevatedButton(
                    onPressed:
                        () =>
                            _addToCart(
                      productId,
                      product,
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          pikkXBlack,
                      foregroundColor:
                          pikkXWhite,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Add to Cart',
                      style:
                          TextStyle(
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT DETAILS
  // ============================================================

  void _openProduct(
    String productId,
    Map<String, dynamic> product,
  ) {
    final name =
        product['name']?.toString() ??
            'Product';

    final price =
        _toDouble(product['price']);

    final description =
        product['description']
                ?.toString() ??
            'No description available.';

    final imageUrl =
        product['imageUrl']
                ?.toString() ??
            '';

    final category =
        product['category']
                ?.toString() ??
            '';

    final seller =
        product['sellerName']
                ?.toString() ??
            '';

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.all(
            20,
          ),
          decoration:
              const BoxDecoration(
            color: pikkXWhite,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(
                30,
              ),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  if (imageUrl
                      .isNotEmpty)
                    ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                      child:
                          Image.network(
                        imageUrl,
                        height: 190,
                        width:
                            double.infinity,
                        fit: BoxFit
                            .cover,
                        errorBuilder:
                            (_, __, ___) =>
                                _productPlaceholder(),
                      ),
                    ),

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    name,
                    style:
                        const TextStyle(
                      color:
                          pikkXBlack,
                      fontSize: 20,
                      fontWeight:
                          FontWeight
                              .w900,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    _formatPrice(
                      price,
                    ),
                    style:
                        const TextStyle(
                      color:
                          pikkXNavy,
                      fontSize: 18,
                      fontWeight:
                          FontWeight
                              .w900,
                    ),
                  ),

                  if (category
                      .isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 8,
                      ),
                      child: Text(
                        category,
                        style:
                            TextStyle(
                          color: LightColor
                              .mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  if (seller
                      .isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 3,
                      ),
                      child: Text(
                        'Seller: $seller',
                        style:
                            TextStyle(
                          color: LightColor
                              .mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    description,
                    style:
                        TextStyle(
                      color: LightColor
                          .mutedText,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed:
                              () =>
                                  _toggleFavourite(
                            productId,
                            product,
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                pikkXNavy,
                            side:
                                const BorderSide(
                              color:
                                  pikkXNavy,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .favorite_border_rounded,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        flex: 3,
                        child:
                            SizedBox(
                          height: 52,
                          child:
                              ElevatedButton(
                            onPressed:
                                () {
                              Navigator.pop(
                                context,
                              );

                              _addToCart(
                                productId,
                                product,
                              );
                            },
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  pikkXBlack,
                              foregroundColor:
                                  pikkXWhite,
                              elevation:
                                  0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Add to Cart',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    final User? user =
        _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to view your profile.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream:
              _userProfileStream(),
          builder:
              (context, snapshot) {
            final data =
                snapshot.data?.data();

            final name =
                data?['name']
                        ?.toString() ??
                    data?['displayName']
                        ?.toString() ??
                    user.displayName ??
                    'pikkX User';

            final email =
                data?['email']
                        ?.toString() ??
                    user.email ??
                    '';

            final photoUrl =
                data?['photoUrl']
                        ?.toString() ??
                    user.photoURL ??
                    '';

            return Container(
              padding:
                  const EdgeInsets.all(
                22,
              ),
              decoration:
                  const BoxDecoration(
                color: pikkXWhite,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(
                    30,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration:
                          BoxDecoration(
                        color:
                            pikkXBackground,
                        shape:
                            BoxShape.circle,
                        image: photoUrl
                                .isNotEmpty
                            ? DecorationImage(
                                image:
                                    NetworkImage(
                                  photoUrl,
                                ),
                                fit: BoxFit
                                    .cover,
                              )
                            : null,
                      ),
                      child: photoUrl
                              .isEmpty
                          ? const Icon(
                              Icons
                                  .person_outline_rounded,
                              color:
                                  pikkXNavy,
                              size: 35,
                            )
                          : null,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      name,
                      style:
                          const TextStyle(
                        color:
                            pikkXBlack,
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),

                    if (email
                        .isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 4,
                        ),
                        child: Text(
                          email,
                          style:
                              TextStyle(
                            color: LightColor
                                .mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 20,
                    ),

                    _profileAction(
                      Icons.person_outline_rounded,
                      'Profile',
                      () {
                        Navigator.pop(
                          context,
                        );

                        _showMessage(
                          'Profile is connected to Firebase.',
                        );
                      },
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _profileAction(
                      Icons.favorite_border_rounded,
                      'My Favourites',
                      () {
                        Navigator.pop(
                          context,
                        );

                        _showMessage(
                          'Favourites are connected to Firebase.',
                        );
                      },
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _profileAction(
                      Icons.logout_rounded,
                      'Sign Out',
                      () async {
                        Navigator.pop(
                          context,
                        );

                        await _auth
                            .signOut();

                        if (!mounted) {
                          return;
                        }

                        _showMessage(
                          'Signed out.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _profileAction(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration:
          BoxDecoration(
        color:
            pikkXBackground,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: pikkXNavy,
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            color:
                pikkXBlack,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        trailing:
            const Icon(
          Icons
              .chevron_right_rounded,
          color:
              pikkXNavy,
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    final User? user =
        _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to view notifications.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  .72,
          decoration:
              const BoxDecoration(
            color: pikkXWhite,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(
                30,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding:
                      EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    14,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style:
                            TextStyle(
                          color:
                              pikkXBlack,
                          fontSize:
                              20,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<
                          Map<String,
                              dynamic>>>(
                    stream:
                        _notificationsStream(),
                    builder:
                        (context,
                            snapshot) {
                      if (snapshot
                              .connectionState ==
                          ConnectionState
                              .waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                pikkXNavy,
                          ),
                        );
                      }

                      if (snapshot
                          .hasError) {
                        return Center(
                          child:
                              Text(
                            'Unable to load notifications.',
                            style:
                                TextStyle(
                              color: LightColor
                                  .mutedText,
                            ),
                          ),
                        );
                      }

                      final docs =
                          snapshot
                                  .data
                                  ?.docs ??
                              [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              const Icon(
                                Icons
                                    .notifications_none_rounded,
                                color:
                                    pikkXNavy,
                                size: 48,
                              ),
                              const SizedBox(
                                height:
                                    10,
                              ),
                              const Text(
                                'No notifications yet',
                                style:
                                    TextStyle(
                                  color:
                                      pikkXBlack,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView
                          .builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          20,
                          0,
                          20,
                          20,
                        ),
                        itemCount:
                            docs.length,
                        itemBuilder:
                            (context,
                                index) {
                          final doc =
                              docs[index];

                          final data =
                              doc.data();

                          final title =
                              data['title']
                                      ?.toString() ??
                                  'Notification';

                          final message =
                              data['message']
                                      ?.toString() ??
                                  '';

                          final read =
                              data['read'] ==
                                  true;

                          return Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom:
                                  10,
                            ),
                            decoration:
                                BoxDecoration(
                              color: read
                                  ? pikkXBackground
                                  : pikkXWhite,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                17,
                              ),
                              border:
                                  Border.all(
                                color:
                                    pikkXNavy.withOpacity(
                                  .07,
                                ),
                              ),
                            ),
                            child:
                                ListTile(
                              onTap:
                                  () async {
                                if (!read) {
                                  await doc
                                      .reference
                                      .update({
                                    'read':
                                        true,
                                  });
                                }
                              },
                              leading:
                                  Container(
                                width:
                                    42,
                                height:
                                    42,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      pikkXNavy.withOpacity(
                                    .08,
                                  ),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .notifications_none_rounded,
                                  color:
                                      pikkXNavy,
                                ),
                              ),
                              title:
                                  Text(
                                title,
                                style:
                                    const TextStyle(
                                  color:
                                      pikkXBlack,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              subtitle:
                                  message
                                          .isNotEmpty
                                      ? Text(
                                          message,
                                          style:
                                              TextStyle(
                                            color:
                                                LightColor.mutedText,
                                          ),
                                        )
                                      : null,
                              trailing:
                                  read
                                      ? null
                                      : Container(
                                          width:
                                              8,
                                          height:
                                              8,
                                          decoration:
                                              const BoxDecoration(
                                            color:
                                                pikkXNavy,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                        ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _productPlaceholder() {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 48,
        color: pikkXNavy,
      ),
    );
  }

  // ============================================================
  // EMPTY PRODUCTS
  // ============================================================

  Widget _emptyProducts() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20,
      ),
      padding:
          const EdgeInsets.all(
        25,
      ),
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color: pikkXWhite,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: pikkXNavy,
            size: 38,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            _searchController
                    .text
                    .isNotEmpty
                ? 'No matching products'
                : 'No products yet',
            style:
                const TextStyle(
              color:
                  pikkXBlack,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            'Products added to Firebase will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: LightColor
                  .mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  Widget _firebaseError() {
    return Container(
      margin:
          const EdgeInsets.all(
        20,
      ),
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color: pikkXWhite,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: pikkXNavy,
            size: 38,
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'Unable to load products',
            style:
                TextStyle(
              color:
                  pikkXBlack,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Check your Firebase connection and Firestore rules.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  LightColor.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            pikkXNavy,
        behavior:
            SnackBarBehavior
                .floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
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
      color:
          pikkXBackground,
      child: SizedBox(
        height:
            MediaQuery.of(
                  context,
                ).size.height -
                210,
        child:
            SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          dragStartBehavior:
              DragStartBehavior
                  .down,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              _header(),
              _search(),
              _quickFilters(),
              _promoBanner(),
              _productWidget(),
              const SizedBox(
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}