import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  // ============================================================
  // PIKKX IDENTITY
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
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  final ImagePicker _imagePicker =
      ImagePicker();

  // ============================================================
  // STATE
  // ============================================================

  String selectedCategory = 'All';

  XFile? _cameraImage;

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<String> categories = const [
    'All',
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Accessories',
    'Food',
    'Drinks',
    'Other',
  ];

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // USER
  // ============================================================

  User? get _currentUser =>
      _auth.currentUser;

  String get _userId =>
      _currentUser?.uid ?? '';

  // ============================================================
  // FIRESTORE STREAMS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _productsStream() {
    return _firestore
        .collection('products')
        .snapshots();
  }

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
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
    dynamic value, {
    String? currency,
  }) {
    final amount = _toDouble(value);

    final symbol =
        currency == null || currency.trim().isEmpty
            ? '₦'
            : currency.trim();

    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String _productName(
    Map<String, dynamic> product,
  ) {
    final name =
        product['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Product';
    }

    return name;
  }

  String _category(
    Map<String, dynamic> product,
  ) {
    return product['category']
            ?.toString()
            .trim() ??
        '';
  }

  String _imageUrl(
    Map<String, dynamic> product,
  ) {
    final imageUrl =
        product['imageUrl']?.toString().trim();

    if (imageUrl != null &&
        imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        product['image']?.toString().trim();

    if (image != null && image.isNotEmpty) {
      return image;
    }

    return '';
  }

  bool _isFood(
    Map<String, dynamic> product,
  ) {
    final category =
        _category(product).toLowerCase();

    final type =
        product['type']
                ?.toString()
                .toLowerCase() ??
            '';

    return category == 'food' ||
        category == 'meals' ||
        category == 'drinks' ||
        category == 'drink' ||
        type == 'food' ||
        type == 'meal' ||
        type == 'drink';
  }

  double? _rating(
    Map<String, dynamic> product,
  ) {
    final value =
        product['rating'] ??
            product['averageRating'] ??
            product['stars'];

    if (value == null) {
      return null;
    }

    final rating = _toDouble(value);

    if (rating <= 0) {
      return null;
    }

    return rating.clamp(0, 5);
  }

  String? _deliveryTime(
    Map<String, dynamic> product,
  ) {
    final value =
        product['deliveryTime'] ??
            product['delivery_time'] ??
            product['estimatedTime'] ??
            product['prepTime'] ??
            product['preparationTime'];

    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    if (text.toLowerCase().contains('min')) {
      return text;
    }

    return '$text min';
  }

  double? _originalPrice(
    Map<String, dynamic> product,
  ) {
    final value =
        product['originalPrice'] ??
            product['oldPrice'] ??
            product['compareAtPrice'];

    if (value == null) {
      return null;
    }

    final price = _toDouble(value);

    if (price <= _toDouble(product['price'])) {
      return null;
    }

    return price;
  }

  bool _isFeatured(
    Map<String, dynamic> product,
  ) {
    return product['isFeatured'] == true ||
        product['featured'] == true;
  }

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

    final fields = [
      product['name'],
      product['description'],
      product['category'],
      product['sellerName'],
      product['seller'],
      product['type'],
    ];

    return fields.any(
      (field) => field
          .toString()
          .toLowerCase()
          .contains(search),
    );
  }

  bool _matchesCategory(
    Map<String, dynamic> product,
  ) {
    if (selectedCategory == 'All') {
      return true;
    }

    final category =
        _category(product).toLowerCase();

    final selected =
        selectedCategory.toLowerCase();

    if (selected == 'food') {
      return category == 'food' ||
          category == 'meal' ||
          category == 'meals';
    }

    if (selected == 'drinks') {
      return category == 'drink' ||
          category == 'drinks';
    }

    return category == selected;
  }

  // ============================================================
  // GLASSMORPHISM
  // ============================================================

  BoxDecoration _glassDecoration({
    double radius = 20,
    Color? color,
  }) {
    return BoxDecoration(
      color:
          color ??
          pikkXWhite.withOpacity(.70),
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(
        color:
            pikkXWhite.withOpacity(.88),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color:
              pikkXBlack.withOpacity(.035),
          blurRadius: 18,
          offset:
              const Offset(0, 7),
        ),
      ],
    );
  }

  Widget _glass({
    required Widget child,
    double radius = 20,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: padding,
          decoration:
              _glassDecoration(
            radius: radius,
            color: color,
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        2,
        18,
        6,
      ),
      child: Row(
        children: [
          _glass(
            radius: 14,
            padding:
                const EdgeInsets.all(6),
            color: pikkXWhite,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Image.asset(
                'assets/images/pikkx_icon (1).png',
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons
                        .shopping_bag_outlined,
                    color: pikkXBlack,
                    size: 23,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'PikkX',
              style: TextStyle(
                color: pikkXBlack,
                fontSize: 23,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
          ),

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream:
                _notificationsStream(),
            builder:
                (context, snapshot) {
              int unread = 0;

              if (snapshot.hasData) {
                unread = snapshot
                    .data!
                    .docs
                    .where(
                      (doc) =>
                          doc.data()['read'] !=
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
                    _openNotifications,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -3,
                      child:
                          Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 17,
                        ),
                        height: 17,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 4,
                        ),
                        alignment:
                            Alignment.center,
                        decoration:
                            const BoxDecoration(
                          color: pikkXBlack,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9
                              ? '9+'
                              : '$unread',
                          style:
                              const TextStyle(
                            color:
                                pikkXWhite,
                            fontSize: 8,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 7),

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
                      data?['profileImage']
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

  Widget _headerButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return _glass(
      radius: 14,
      padding: EdgeInsets.zero,
      color:
          pikkXWhite.withOpacity(.74),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          icon,
          color: pikkXBlack,
          size: 21,
        ),
      ),
    )._tap(
      onTap,
      radius: 14,
    );
  }

  Widget _profileButton(
    String imageUrl,
  ) {
    return _glass(
      radius: 14,
      padding:
          const EdgeInsets.all(2),
      color: pikkXWhite,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) {
                    return const Icon(
                      Icons
                          .person_outline_rounded,
                      color: pikkXBlack,
                      size: 22,
                    );
                  },
                )
              : const Icon(
                  Icons
                      .person_outline_rounded,
                  color: pikkXBlack,
                  size: 22,
                ),
        ),
      ),
    )._tap(
      _openProfile,
      radius: 14,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _search() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        8,
      ),
      child: _glass(
        radius: 17,
        padding: EdgeInsets.zero,
        color:
            pikkXWhite.withOpacity(.72),
        child: SizedBox(
          height: 51,
          child: Row(
            children: [
              const SizedBox(width: 14),

              const Icon(
                Icons.search_rounded,
                color: pikkXBlack,
                size: 22,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: TextField(
                  controller:
                      _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  textInputAction:
                      TextInputAction.search,
                  style:
                      const TextStyle(
                    color: pikkXBlack,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
                  ),
                  decoration:
                      const InputDecoration(
                    border:
                        InputBorder.none,
                    isDense: true,
                    hintText:
                        'Search PikkX...',
                    hintStyle:
                        TextStyle(
                      color: pikkXGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: _openCamera,
                child: Container(
                  margin:
                      const EdgeInsets.only(
                    right: 5,
                  ),
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: pikkXBlack,
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .camera_alt_outlined,
                    color: pikkXWhite,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _quickFilters() {
    return SizedBox(
      height: 39,
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
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
              right: 7,
            ),
            child: GestureDetector(
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
                  milliseconds: 160,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 15,
                ),
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: selected
                      ? pikkXBlack
                      : pikkXWhite
                          .withOpacity(.70),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                  border: Border.all(
                    color: selected
                        ? pikkXBlack
                        : pikkXWhite
                            .withOpacity(.90),
                  ),
                ),
                child: Text(
                  category,
                  style:
                      TextStyle(
                    color: selected
                        ? pikkXWhite
                        : pikkXBlack,
                    fontSize: 11,
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
        18,
        9,
        18,
        5,
      ),
      child: _glass(
        radius: 21,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        color: pikkXBlack,
        child: SizedBox(
          height: 92,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Everything you need.',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color: pikkXWhite,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Shop products, discover food.',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color: pikkXWhite
                            .withOpacity(.68),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 55,
                height: 55,
                decoration:
                    BoxDecoration(
                  color: pikkXWhite
                      .withOpacity(.10),
                  shape:
                      BoxShape.circle,
                  border:
                      Border.all(
                    color: pikkXWhite
                        .withOpacity(.12),
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .shopping_bag_outlined,
                  color: pikkXWhite,
                  size: 27,
                ),
              ),
            ],
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
      stream: _productsStream(),
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 35,
            ),
            child: Center(
              child:
                  CircularProgressIndicator(
                color: pikkXBlack,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _firebaseError();
        }

        final documents =
            snapshot.data?.docs ?? [];

        final products =
            documents.where((doc) {
          final data = doc.data();

          return _matchesSearch(data) &&
              _matchesCategory(data);
        }).toList();

        products.sort(
          (a, b) {
            final aData = a.data();
            final bData = b.data();

            final aFeatured =
                _isFeatured(aData);
            final bFeatured =
                _isFeatured(bData);

            if (aFeatured != bFeatured) {
              return bFeatured
                  ? 1
                  : -1;
            }

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

        if (products.isEmpty) {
          return _emptySearchState();
        }

        return StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: _favouritesStream(),
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
                favouriteIds.add(doc.id);

                final data =
                    doc.data();

                final productId =
                    data['productId']
                        ?.toString();

                if (productId != null &&
                    productId.isNotEmpty) {
                  favouriteIds.add(
                    productId,
                  );
                }
              }
            }

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  'Products · Trending Now',
                  onSeeAll: _showAllProducts,
                ),
                _horizontalProducts(
                  products,
                  favouriteIds,
                  height: 242,
                ),
                if (_searchController.text
                    .trim()
                    .isEmpty)
                  ...[
                    const SizedBox(
                      height: 5,
                    ),
                    _sectionHeader(
                      'Picked for you',
                      onSeeAll:
                          _showAllProducts,
                    ),
                    _horizontalProducts(
                      _pickedProducts(products),
                      favouriteIds,
                      height: 242,
                    ),
                  ],
                const SizedBox(
                  height: 78,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(
    String title, {
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: pikkXBlack,
                fontSize: 17,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all',
              style:
                  TextStyle(
                color: pikkXGrey,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HORIZONTAL PRODUCTS
  // ============================================================

  Widget _horizontalProducts(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        products,
    Set<String> favouriteIds, {
    required double height,
  }) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(
          left: 18,
          right: 7,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder:
            (context, index) {
          final document =
              products[index];

          return _productCard(
            document.id,
            document.data(),
            favouriteIds.contains(
              document.id,
            ),
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<
          Map<String, dynamic>>>
      _pickedProducts(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        products,
  ) {
    final copy =
        List<QueryDocumentSnapshot<
            Map<String, dynamic>>>.from(
      products,
    );

    copy.sort(
      (a, b) {
        final aRating =
            _rating(a.data()) ?? 0;
        final bRating =
            _rating(b.data()) ?? 0;

        return bRating.compareTo(
          aRating,
        );
      },
    );

    return copy;
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
        _productName(product);

    final category =
        _category(product);

    final imageUrl =
        _imageUrl(product);

    final price =
        _toDouble(product['price']);

    final originalPrice =
        _originalPrice(product);

    final rating =
        _rating(product);

    final deliveryTime =
        _deliveryTime(product);

    final seller =
        product['sellerName']
                ?.toString()
                .trim() ??
            '';

    final currency =
        product['currencySymbol']
                ?.toString() ??
            product['currency']
                ?.toString();

    final food =
        _isFood(product);

    return Container(
      width: 190,
      margin:
          const EdgeInsets.only(
        right: 11,
        bottom: 7,
      ),
      child: _glass(
        radius: 20,
        padding: EdgeInsets.zero,
        color:
            pikkXWhite.withOpacity(.76),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // IMAGE
            SizedBox(
              height: 124,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () =>
                          _openProduct(
                        productId,
                        product,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius
                                .vertical(
                          top:
                              Radius.circular(
                            20,
                          ),
                        ),
                        child:
                            Container(
                          color:
                              pikkXBackground,
                          child:
                              imageUrl
                                      .isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width:
                                          double.infinity,
                                      height:
                                          double.infinity,
                                      fit:
                                          BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              _productPlaceholder(),
                                    )
                                  : _productPlaceholder(),
                        ),
                      ),
                    ),
                  ),

                  // FAVOURITE
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () =>
                          _toggleFavourite(
                        productId,
                        product,
                      ),
                      child:
                          Container(
                        width: 32,
                        height: 32,
                        decoration:
                            BoxDecoration(
                          color:
                              pikkXWhite
                                  .withOpacity(
                            .92,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            Icon(
                          isFavourite
                              ? Icons
                                  .favorite_rounded
                              : Icons
                                  .favorite_border_rounded,
                          color:
                              pikkXBlack,
                          size: 17,
                        ),
                      ),
                    ),
                  ),

                  // SALE
                  if (originalPrice !=
                      null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              pikkXBlack,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            7,
                          ),
                        ),
                        child:
                            const Text(
                          'SALE',
                          style:
                              TextStyle(
                            color:
                                pikkXWhite,
                            fontSize:
                                8,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // DETAILS
            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                11,
                8,
                9,
                9,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: pikkXBlack,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  if (category.isNotEmpty ||
                      seller.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 2,
                      ),
                      child: Text(
                        category.isNotEmpty
                            ? category
                            : seller,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              pikkXGrey,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 5,
                  ),

                  // RATING / DELIVERY
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: pikkXBlack,
                          size: 13,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          rating
                              .toStringAsFixed(
                            1,
                          ),
                          style:
                              const TextStyle(
                            color:
                                pikkXBlack,
                            fontSize: 9,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ],

                      if (rating != null &&
                          deliveryTime !=
                              null)
                        const Padding(
                          padding:
                              EdgeInsets
                                  .symmetric(
                            horizontal: 5,
                          ),
                          child: Text(
                            '·',
                            style:
                                TextStyle(
                              color:
                                  pikkXGrey,
                            ),
                          ),
                        ),

                      if (deliveryTime !=
                          null)
                        Expanded(
                          child: Text(
                            food
                                ? deliveryTime
                                : deliveryTime,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  pikkXGrey,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // PRICE + PLUS
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              _formatPrice(
                                price,
                                currency:
                                    currency,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    pikkXBlack,
                                fontSize:
                                    14,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                            if (originalPrice !=
                                null)
                              Text(
                                _formatPrice(
                                  originalPrice,
                                  currency:
                                      currency,
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      pikkXGrey,
                                  fontSize:
                                      9,
                                  decoration:
                                      TextDecoration
                                          .lineThrough,
                                  fontWeight:
                                      FontWeight
                                          .600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () =>
                            _addToCart(
                          productId,
                          product,
                        ),
                        child:
                            Container(
                          width: 34,
                          height: 34,
                          decoration:
                              const BoxDecoration(
                            color:
                                pikkXBlack,
                            shape:
                                BoxShape
                                    .circle,
                          ),
                          child:
                              const Icon(
                            Icons.add_rounded,
                            color:
                                pikkXWhite,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT PLACEHOLDER
  // ============================================================

  Widget _productPlaceholder() {
    return const Center(
      child: Icon(
        Icons
            .shopping_bag_outlined,
        color: pikkXBlack,
        size: 38,
      ),
    );
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart(
    String productId,
    Map<String, dynamic> product,
  ) async {
    final user =
        _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to add items to your cart.',
      );
      return;
    }

    try {
      final reference =
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(productId);

      final existing =
          await reference.get();

      if (existing.exists) {
        final data =
            existing.data();

        final quantity =
            _toInt(
          data?['quantity'],
          fallback: 1,
        );

        await reference.update({
          'quantity':
              quantity + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await reference.set({
          'productId':
              productId,
          'name':
              _productName(product),
          'price':
              _toDouble(
                product['price'],
              ),
          'imageUrl':
              _imageUrl(product),
          'image':
              product['image']
                      ?.toString() ??
                  _imageUrl(product),
          'quantity':
              1,
          'sellerId':
              product['sellerId']
                      ?.toString() ??
                  '',
          'sellerName':
              product['sellerName']
                      ?.toString() ??
                  '',
          'category':
              _category(product),
          'description':
              product['description']
                      ?.toString() ??
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
    final user =
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
              _productName(product),
          'price':
              _toDouble(
                product['price'],
              ),
          'imageUrl':
              _imageUrl(product),
          'image':
              product['image']
                      ?.toString() ??
                  _imageUrl(product),
          'category':
              _category(product),
          'sellerId':
              product['sellerId']
                      ?.toString() ??
                  '',
          'sellerName':
              product['sellerName']
                      ?.toString() ??
                  '',
          'description':
              product['description']
                      ?.toString() ??
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
  // PRODUCT DETAILS
  // ============================================================

  void _openProduct(
    String productId,
    Map<String, dynamic> product,
  ) {
    final name =
        _productName(product);

    final description =
        product['description']
                ?.toString()
                .trim() ??
            'No description available.';

    final imageUrl =
        _imageUrl(product);

    final category =
        _category(product);

    final seller =
        product['sellerName']
                ?.toString()
                .trim() ??
            '';

    final rating =
        _rating(product);

    final deliveryTime =
        _deliveryTime(product);

    final currency =
        product['currencySymbol']
                ?.toString() ??
            product['currency']
                ?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled:
          true,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius:
              const BorderRadius
                  .vertical(
            top: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: Container(
              constraints:
                  BoxConstraints(
                maxHeight:
                    MediaQuery.of(
                          sheetContext,
                        ).size.height *
                        .88,
              ),
              decoration:
                  BoxDecoration(
                color:
                    pikkXWhite.withOpacity(
                  .94,
                ),
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(28),
                ),
                border:
                    Border.all(
                  color:
                      pikkXWhite.withOpacity(
                    .95,
                  ),
                ),
              ),
              child: SafeArea(
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Center(
                        child:
                            Container(
                          width: 38,
                          height: 4,
                          decoration:
                              BoxDecoration(
                            color:
                                pikkXLightGrey,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

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
                            width:
                                double.infinity,
                            height: 210,
                            fit:
                                BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    _productPlaceholder(),
                          ),
                        ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        name,
                        style:
                            const TextStyle(
                          color:
                              pikkXBlack,
                          fontSize: 21,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      if (category
                          .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),
                          child:
                              Text(
                            category,
                            style:
                                const TextStyle(
                              color:
                                  pikkXGrey,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 8,
                      ),

                      Row(
                        children: [
                          if (rating !=
                              null) ...[
                            const Icon(
                              Icons
                                  .star_rounded,
                              color:
                                  pikkXBlack,
                              size: 16,
                            ),
                            const SizedBox(
                              width: 3,
                            ),
                            Text(
                              rating
                                  .toStringAsFixed(
                                1,
                              ),
                              style:
                                  const TextStyle(
                                color:
                                    pikkXBlack,
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ],
                          if (deliveryTime !=
                              null) ...[
                            const SizedBox(
                              width: 10,
                            ),
                            const Icon(
                              Icons
                                  .schedule_rounded,
                              color:
                                  pikkXGrey,
                              size: 15,
                            ),
                            const SizedBox(
                              width: 3,
                            ),
                            Text(
                              deliveryTime,
                              style:
                                  const TextStyle(
                                color:
                                    pikkXGrey,
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight
                                        .600,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        _formatPrice(
                          product['price'],
                          currency:
                              currency,
                        ),
                        style:
                            const TextStyle(
                          color:
                              pikkXBlack,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      if (seller.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),
                          child:
                              Text(
                            'Seller: $seller',
                            style:
                                const TextStyle(
                              color:
                                  pikkXGrey,
                              fontSize:
                                  10,
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        description,
                        style:
                            const TextStyle(
                          color:
                              pikkXGrey,
                          fontSize:
                              12,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _toggleFavourite(
                                productId,
                                product,
                              );
                            },
                            child:
                                Container(
                              width: 52,
                              height: 52,
                              decoration:
                                  BoxDecoration(
                                color:
                                    pikkXBackground,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      pikkXLightGrey,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .favorite_border_rounded,
                                color:
                                    pikkXBlack,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 9,
                          ),

                          Expanded(
                            child:
                                SizedBox(
                              height: 52,
                              child:
                                  ElevatedButton(
                                onPressed:
                                    () {
                                  Navigator
                                      .pop(
                                    sheetContext,
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
                                    fontSize:
                                        13,
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
  // CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    try {
      final image =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

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
  // PROFILE
  // ============================================================

  void _openProfile() {
    final user =
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
      builder: (sheetContext) {
        return _glass(
          radius: 28,
          color:
              pikkXWhite.withOpacity(.94),
          child:
              SafeArea(
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
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
                          user.displayName ??
                          'PikkX User';

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
                        width: 38,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color:
                              pikkXLightGrey,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      CircleAvatar(
                        radius: 37,
                        backgroundColor:
                            pikkXBackground,
                        backgroundImage:
                            photoUrl.isNotEmpty
                                ? NetworkImage(
                                    photoUrl,
                                  )
                                : null,
                        child: photoUrl
                                .isEmpty
                            ? const Icon(
                                Icons
                                    .person_outline_rounded,
                                color:
                                    pikkXBlack,
                                size: 35,
                              )
                            : null,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        name,
                        style:
                            const TextStyle(
                          color:
                              pikkXBlack,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      if (email.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 3,
                          ),
                          child:
                              Text(
                            email,
                            style:
                                const TextStyle(
                              color:
                                  pikkXGrey,
                              fontSize:
                                  11,
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 16,
                      ),

                      _profileAction(
                        Icons
                            .person_outline_rounded,
                        'Open Profile',
                        () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _showMessage(
                            'Open Profile from the profile section.',
                          );
                        },
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      _profileAction(
                        Icons
                            .favorite_border_rounded,
                        'My Favourites',
                        () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _showMessage(
                            'Favourites are connected to Firebase.',
                          );
                        },
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      _profileAction(
                        Icons.logout_rounded,
                        'Sign Out',
                        () async {
                          Navigator.pop(
                            sheetContext,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: pikkXBackground,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: pikkXLightGrey,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: pikkXBlack,
              size: 21,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(
                  color: pikkXBlack,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color: pikkXGrey,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    final user =
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
      builder: (sheetContext) {
        return _glass(
          radius: 28,
          color:
              pikkXWhite.withOpacity(.95),
          child: SizedBox(
            height:
                MediaQuery.of(
                      sheetContext,
                    ).size.height *
                    .70,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Container(
                    width: 38,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color:
                          pikkXLightGrey,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.fromLTRB(
                      18,
                      14,
                      18,
                      10,
                    ),
                    child: Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'Notifications',
                        style:
                            TextStyle(
                          color:
                              pikkXBlack,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w900,
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
                                  pikkXBlack,
                              strokeWidth:
                                  2,
                            ),
                          );
                        }

                        if (snapshot
                            .hasError) {
                          return const Center(
                            child: Text(
                              'Unable to load notifications.',
                              style:
                                  TextStyle(
                                color:
                                    pikkXGrey,
                              ),
                            ),
                          );
                        }

                        final docs =
                            snapshot.data
                                    ?.docs ??
                                [];

                        if (docs.isEmpty) {
                          return const Center(
                            child:
                                Column(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Icon(
                                  Icons
                                      .notifications_none_rounded,
                                  color:
                                      pikkXBlack,
                                  size: 42,
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                Text(
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
                            18,
                            0,
                            18,
                            18,
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

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom: 8,
                              ),
                              child:
                                  _glass(
                                radius: 17,
                                color: read
                                    ? pikkXBackground
                                    : pikkXWhite,
                                child:
                                    ListTile(
                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        12,
                                  ),
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
                                        39,
                                    height:
                                        39,
                                    decoration:
                                        const BoxDecoration(
                                      color:
                                          pikkXBlack,
                                      shape:
                                          BoxShape
                                              .circle,
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .notifications_none_rounded,
                                      color:
                                          pikkXWhite,
                                      size:
                                          19,
                                    ),
                                  ),
                                  title:
                                      Text(
                                    title,
                                    style:
                                        const TextStyle(
                                      color:
                                          pikkXBlack,
                                      fontSize:
                                          12,
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
                                                  const TextStyle(
                                                color:
                                                    pikkXGrey,
                                                fontSize:
                                                    10,
                                              ),
                                            )
                                          : null,
                                  trailing:
                                      read
                                          ? null
                                          : Container(
                                              width:
                                                  7,
                                              height:
                                                  7,
                                              decoration:
                                                  const BoxDecoration(
                                                color:
                                                    pikkXBlack,
                                                shape:
                                                    BoxShape
                                                        .circle,
                                              ),
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
          ),
        );
      },
    );
  }

  // ============================================================
  // SEE ALL
  // ============================================================

  void _showAllProducts() {
    _showMessage(
      'Showing all available products.',
    );
  }

  // ============================================================
  // EMPTY SEARCH
  // ============================================================

  Widget _emptySearchState() {
    final searching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        28,
        18,
        80,
      ),
      child: _glass(
        radius: 20,
        padding:
            const EdgeInsets.all(22),
        color:
            pikkXWhite.withOpacity(.68),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: pikkXBlack,
              size: 38,
            ),
            const SizedBox(
              height: 9,
            ),
            Text(
              searching
                  ? 'No products found'
                  : 'No products available',
              style:
                  const TextStyle(
                color: pikkXBlack,
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              searching
                  ? 'Try another search or category.'
                  : 'Products added to PikkX will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: pikkXGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  Widget _firebaseError() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        70,
      ),
      child: _glass(
        radius: 20,
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: pikkXBlack,
              size: 36,
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Unable to load products',
              style:
                  TextStyle(
                color: pikkXBlack,
                fontSize: 15,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            const Text(
              'Check your Firebase connection and Firestore rules.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: pikkXGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
        content: Text(
          message,
          style:
              const TextStyle(
            color: pikkXWhite,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        backgroundColor:
            pikkXBlack,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(14),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            13,
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
      color: pikkXBackground,
      child: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _header(),
            _search(),
            _quickFilters(),
            _promoBanner(),
            _productWidget(),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SMALL TAP EXTENSION
// ================================================================

extension _HomeTapExtension
    on Widget {
  Widget _tap(
    VoidCallback onTap, {
    double radius = 16,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(radius),
        child: this,
      ),
    );
  }
}