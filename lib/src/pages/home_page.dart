import 'dart:ui';

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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController _searchController =
      TextEditingController();

  final ImagePicker _imagePicker =
      ImagePicker();

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

  // ============================================================
  // PILKX IDENTITY
  // ============================================================

  static const Color pikkXBlack =
      Color(0xFF050505);

  static const Color pikkXWhite =
      Color(0xFFFFFFFF);

  static const Color pikkXNavy =
      Color(0xFF10233F);

  static const Color pikkXBackground =
      Color(0xFFF7F7F7);

  static const Color pikkXGlass =
      Color(0xCCFFFFFF);

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

  User? get _currentUser =>
      _auth.currentUser;

  String get _userId =>
      _currentUser?.uid ?? '';

  // ============================================================
  // FIRESTORE PRODUCTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _productsStream() {
    return _firestore
        .collection('products')
        .snapshots();
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _userProfileStream() {
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

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _notificationsStream() {
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
  // FAVOURITES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _favouritesStream() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .snapshots();
  }

  // ============================================================
  // DISPATCH TRACKING
  // ============================================================

  void _openDispatchTracking() {
    Navigator.of(context).pushNamed(
      '/dispatch-tracking',
    );
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(
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
      debugPrint(
        'Camera error: $e',
      );

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
    final User? user =
        _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to add items to your cart.',
      );
      return;
    }

    try {
      final cartReference =
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(productId);

      final existing =
          await cartReference.get();

      final price =
          _toDouble(product['price']);

      if (existing.exists) {
        final existingData =
            existing.data();

        final currentQuantity =
            _toInt(
          existingData?['quantity'],
          fallback: 1,
        );

        await cartReference.update({
          'quantity':
              currentQuantity + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await cartReference.set({
          'productId':
              productId,
          'name':
              product['name'] ??
                  'Product',
          'price':
              price,
          'imageUrl':
              product['imageUrl'] ??
                  product['image'] ??
                  '',
          'quantity':
              1,
          'sellerId':
              product['sellerId'] ??
                  '',
          'sellerName':
              product['sellerName'] ??
                  '',
          'category':
              product['category'] ??
                  '',
          'description':
              product['description'] ??
                  '',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      _showMessage(
        'Added to cart.',
      );
    } catch (e) {
      debugPrint(
        'Add to cart error: $e',
      );

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
    final User? user =
        _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to save favourites.',
      );
      return;
    }

    try {
      final reference =
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc(productId);

      final existing =
          await reference.get();

      if (existing.exists) {
        await reference.delete();

        _showMessage(
          'Removed from favourites.',
        );
      } else {
        await reference.set({
          'productId':
              productId,
          'name':
              product['name'] ??
                  'Product',
          'price':
              _toDouble(
                product['price'],
              ),
          'imageUrl':
              product['imageUrl'] ??
                  product['image'] ??
                  '',
          'image':
              product['image'] ??
                  product['imageUrl'] ??
                  '',
          'category':
              product['category'] ??
                  '',
          'sellerId':
              product['sellerId'] ??
                  '',
          'sellerName':
              product['sellerName'] ??
                  '',
          'description':
              product['description'] ??
                  '',
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        _showMessage(
          'Added to favourites.',
        );
      }
    } catch (e) {
      debugPrint(
        'Favourite error: $e',
      );

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
        _searchController.text
            .trim()
            .toLowerCase();

    if (search.isEmpty) {
      return true;
    }

    final name =
        (product['name'] ?? '')
            .toString()
            .toLowerCase();

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
  // CATEGORY
  // ============================================================

  bool _matchesCategory(
    Map<String, dynamic> product,
  ) {
    if (selectedCategory ==
        'All') {
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

  double _toDouble(
    dynamic value,
  ) {
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

  String _formatPrice(
    dynamic value,
  ) {
    return '₦${_toDouble(value).toStringAsFixed(2)}';
  }

  // ============================================================
  // GLASS DECORATION
  // ============================================================

  BoxDecoration _glassDecoration({
    double radius = 20,
    Color? color,
    bool navyBorder = false,
  }) {
    return BoxDecoration(
      color:
          color ?? pikkXGlass,
      borderRadius:
          BorderRadius.circular(
        radius,
      ),
      border: Border.all(
        color: navyBorder
            ? pikkXNavy.withOpacity(.10)
            : pikkXWhite.withOpacity(.82),
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
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        4,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding:
                const EdgeInsets.all(7),
            decoration:
                _glassDecoration(
              radius: 15,
              color:
                  pikkXWhite,
              navyBorder: true,
            ),
            child:
                Image.asset(
              'assets/images/pikkx_icon (1).png',
              fit:
                  BoxFit.contain,
              errorBuilder:
                  (_, __, ___) {
                return const Icon(
                  Icons
                      .shopping_bag_rounded,
                  color:
                      pikkXNavy,
                );
              },
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Text(
              'PilkX',
              style:
                  TextStyle(
                color:
                    pikkXBlack,
                fontSize: 25,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    -.8,
              ),
            ),
          ),

          StreamBuilder<
              QuerySnapshot<
                  Map<String,
                      dynamic>>>(
            stream:
                _notificationsStream(),
            builder:
                (context, snapshot) {
              int unread = 0;

              if (snapshot
                  .hasData) {
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
                          unread > 9
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

          const SizedBox(
            width: 8,
          ),

          _headerButton(
            Icons.delivery_dining_rounded,
            onTap:
                _openDispatchTracking,
          ),

          const SizedBox(
            width: 8,
          ),

          StreamBuilder<
              DocumentSnapshot<
                  Map<String,
                      dynamic>>>(
            stream:
                _userProfileStream(),
            builder:
                (context, snapshot) {
              final data =
                  snapshot.data
                      ?.data();

              final imageUrl =
                  data?['photoUrl']
                          ?.toString() ??
                      _currentUser
                          ?.photoURL ??
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
      decoration:
          _glassDecoration(
        radius: 15,
        color:
            pikkXWhite.withOpacity(.82),
        navyBorder: true,
      ),
      child: Icon(
        icon,
        color:
            pikkXNavy,
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
      padding:
          const EdgeInsets.all(2),
      decoration:
          _glassDecoration(
        radius: 15,
        color:
            pikkXWhite,
        navyBorder: true,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(13),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit:
                    BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons
                        .person_outline_rounded,
                    color:
                        pikkXNavy,
                    size: 24,
                  );
                },
              )
            : const Icon(
                Icons
                    .person_outline_rounded,
                color:
                    pikkXNavy,
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
      padding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        8,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(19),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            height: 56,
            decoration:
                _glassDecoration(
              radius: 19,
              color:
                  pikkXWhite.withOpacity(.76),
              navyBorder: true,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                const Icon(
                  Icons.search_rounded,
                  color:
                      pikkXNavy,
                  size: 24,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      TextField(
                    controller:
                        _searchController,
                    onChanged:
                        (_) {
                      setState(
                        () {},
                      );
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
                        fontSize:
                            13,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap:
                      _openCamera,
                  child:
                      Container(
                    margin:
                        const EdgeInsets
                            .only(
                      right: 6,
                    ),
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXNavy,
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .camera_alt_outlined,
                      color:
                          pikkXWhite,
                      size: 21,
                    ),
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
  // CATEGORY FILTERS
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
                  milliseconds:
                      180,
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
                      : pikkXWhite
                          .withOpacity(.82),
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        selected
                            ? pikkXNavy
                            : pikkXNavy
                                .withOpacity(
                                .09,
                              ),
                  ),
                  boxShadow: [
                    if (!selected)
                      BoxShadow(
                        color:
                            pikkXBlack
                                .withOpacity(
                          .025,
                        ),
                        blurRadius:
                            10,
                        offset:
                            const Offset(
                          0,
                          4,
                        ),
                      ),
                  ],
                ),
                child: Text(
                  category,
                  style:
                      TextStyle(
                    color: selected
                        ? pikkXWhite
                        : pikkXNavy,
                    fontSize:
                        12,
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
  // PROMO BANNER
  // ============================================================

  Widget _promoBanner() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        2,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8,
            sigmaY: 8,
          ),
          child: Container(
            height: 138,
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  pikkXNavy,
              borderRadius:
                  BorderRadius.circular(
                25,
              ),
              border:
                  Border.all(
                color:
                    pikkXWhite.withOpacity(
                  .10,
                ),
              ),
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
                        style:
                            TextStyle(
                          color:
                              pikkXWhite,
                          fontSize:
                              21,
                          height:
                              1.05,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Discover products made for you.',
                        style:
                            TextStyle(
                          color:
                              pikkXWhite
                                  .withOpacity(
                            .72,
                          ),
                          fontSize:
                              11,
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
                    color:
                        pikkXWhite
                            .withOpacity(
                      .10,
                    ),
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          pikkXWhite
                              .withOpacity(
                        .12,
                      ),
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .shopping_bag_outlined,
                    color:
                        pikkXWhite,
                    size: 31,
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
  // PRODUCTS
  // ============================================================

  Widget _productWidget() {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream:
          _productsStream(),
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
                color:
                    pikkXNavy,
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
            snapshot.data?.docs ??
                [];

        final products =
            documents.where(
          (doc) {
            final data =
                doc.data();

            return _matchesSearch(
                  data,
                ) &&
                _matchesCategory(
                  data,
                );
          },
        ).toList();

        products.sort(
          (a, b) {
            final aTime =
                a.data()['createdAt'];

            final bTime =
                b.data()['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(
                aTime,
              );
            }

            return 0;
          },
        );

        return StreamBuilder<
            QuerySnapshot<
                Map<String,
                    dynamic>>>(
          stream:
              _favouritesStream(),
          builder:
              (context, favouriteSnapshot) {
            final favouriteIds =
                <String>{};

            if (favouriteSnapshot
                .hasData) {
              for (final doc
                  in favouriteSnapshot
                      .data!
                      .docs) {
                favouriteIds.add(
                  doc.id,
                );

                final data =
                    doc.data();

                final productId =
                    data['productId']
                        ?.toString();

                if (productId !=
                        null &&
                    productId.isNotEmpty) {
                  favouriteIds.add(
                    productId,
                  );
                }
              }
            }

            // No "Popular Products" heading.
            // No product count.
            // No empty-state product box.
            //
            // If there are no products, simply
            // return an empty widget.

            if (products.isEmpty) {
              return const SizedBox
                  .shrink();
            }

            return SizedBox(
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
                    favouriteIds
                        .contains(
                      document.id,
                    ),
                  );
                },
              ),
            );
          },
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
    bool isFavourite,
  ) {
    final name =
        product['name']
                ?.toString() ??
            'Product';

    final price =
        _toDouble(
      product['price'],
    );

    final imageUrl =
        product['imageUrl']
                ?.toString() ??
            product['image']
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
          _glassDecoration(
        radius: 23,
        color:
            pikkXWhite.withOpacity(.82),
        navyBorder: true,
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
                              fit:
                                  BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _productPlaceholder(),
                            ),
                          )
                        : _productPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child:
                      Container(
                    width: 39,
                    height: 39,
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXWhite.withOpacity(
                        .92,
                      ),
                      shape:
                          BoxShape.circle,
                      border:
                          Border.all(
                        color:
                            pikkXNavy.withOpacity(
                          .08,
                        ),
                      ),
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
                          Icon(
                        isFavourite
                            ? Icons
                                .favorite_rounded
                            : Icons
                                .favorite_border_rounded,
                        color:
                            isFavourite
                                ? pikkXNavy
                                : pikkXBlack,
                        size: 20,
                      ),
                    ),
                  ),
                ),
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
                        FontWeight.w800,
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
                    child:
                        Text(
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
                        FontWeight.w900,
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
        product['name']
                ?.toString() ??
            'Product';

    final price =
        _toDouble(
      product['price'],
    );

    final description =
        product['description']
                ?.toString() ??
            'No description available.';

    final imageUrl =
        product['imageUrl']
                ?.toString() ??
            product['image']
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
      isScrollControlled:
          true,
      builder: (context) {
        return ClipRRect(
          borderRadius:
              const BorderRadius
                  .vertical(
            top: Radius.circular(
              30,
            ),
          ),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              decoration:
                  BoxDecoration(
                color:
                    pikkXWhite.withOpacity(
                  .96,
                ),
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(
                    30,
                  ),
                ),
                border:
                    Border.all(
                  color:
                      pikkXNavy.withOpacity(
                    .08,
                  ),
                ),
              ),
              child: SafeArea(
                child:
                    SingleChildScrollView(
                  child:
                      Column(
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
                            height:
                                190,
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
                          fontSize:
                              20,
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
                          fontSize:
                              18,
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
                          child:
                              Text(
                            category,
                            style:
                                TextStyle(
                              color:
                                  LightColor
                                      .mutedText,
                              fontSize:
                                  11,
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
                          child:
                              Text(
                            'Seller: $seller',
                            style:
                                TextStyle(
                              color:
                                  LightColor
                                      .mutedText,
                              fontSize:
                                  11,
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
                          color:
                              LightColor
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
                              height:
                                  52,
                              child:
                                  ElevatedButton(
                                onPressed:
                                    () {
                                  Navigator
                                      .pop(
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
      isScrollControlled:
          true,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.all(
            22,
          ),
          decoration:
              const BoxDecoration(
            color:
                pikkXWhite,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(
                30,
              ),
            ),
          ),
          child: SafeArea(
            child:
                StreamBuilder<
                    DocumentSnapshot<
                        Map<String,
                            dynamic>>>(
              stream:
                  _userProfileStream(),
              builder:
                  (context, snapshot) {
                final data =
                    snapshot.data
                        ?.data();

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

                return Column(
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
                      child:
                          photoUrl.isEmpty
                              ? const Icon(
                                  Icons
                                      .person_outline_rounded,
                                  color:
                                      pikkXNavy,
                                  size:
                                      35,
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
                        fontSize:
                            20,
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
                        child:
                            Text(
                          email,
                          style:
                              TextStyle(
                            color:
                                LightColor
                                    .mutedText,
                            fontSize:
                                12,
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    _profileAction(
                      Icons
                          .person_outline_rounded,
                      'Profile',
                      () {
                        Navigator
                            .pop(
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
                      Icons
                          .favorite_border_rounded,
                      'My Favourites',
                      () {
                        Navigator
                            .pop(
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
                      Icons
                          .logout_rounded,
                      'Sign Out',
                      () async {
                        Navigator
                            .pop(
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
                );
              },
            ),
          ),
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
      width:
          double.infinity,
      decoration:
          _glassDecoration(
        radius: 16,
        color:
            pikkXBackground,
        navyBorder: true,
      ),
      child:
          ListTile(
        onTap: onTap,
        leading:
            Icon(
          icon,
          color:
              pikkXNavy,
        ),
        title:
            Text(
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
      isScrollControlled:
          true,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(
                    context,
                  ).size.height *
                  .72,
          decoration:
              const BoxDecoration(
            color:
                pikkXWhite,
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
                  child:
                      Align(
                    alignment:
                        Alignment
                            .centerLeft,
                    child:
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
                  ),
                ),
                Expanded(
                  child:
                      StreamBuilder<
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
                              color:
                                  LightColor
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
                          child:
                              Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              const Icon(
                                Icons
                                    .notifications_none_rounded,
                                color:
                                    pikkXNavy,
                                size:
                                    48,
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
                                _glassDecoration(
                              radius:
                                  17,
                              color:
                                  read
                                      ? pikkXBackground
                                      : pikkXWhite,
                              navyBorder:
                                  true,
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
        Icons
            .shopping_bag_outlined,
        size: 48,
        color:
            pikkXNavy,
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
          _glassDecoration(
        radius: 20,
        color:
            pikkXWhite.withOpacity(.82),
        navyBorder: true,
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .cloud_off_rounded,
            color:
                pikkXNavy,
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
                  LightColor
                      .mutedText,
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
      child:
          SizedBox(
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
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              _header(),
              _search(),
              _quickFilters(),
              _promoBanner(),
              _productWidget(),
            ],
          ),
        ),
      ),
    );
  }
}