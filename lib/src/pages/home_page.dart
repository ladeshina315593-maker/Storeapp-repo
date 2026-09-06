import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_ecommerce_app/src/pages/product_detail.dart';
import 'package:flutter_ecommerce_app/src/pages/profile_page.dart';

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

  User? get _currentUser => _auth.currentUser;

  String get _userId => _currentUser?.uid ?? '';

  // ============================================================
  // FIREBASE STREAMS
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userProfileStream() {
    if (_userId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _favouritesStream() {
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
  // THE TWO HOME PRODUCTS
  //
  // These are LOCAL ASSET products.
  // They are sent directly to the EXISTING ProductDetailPage.
  // ProductDetailPage already supports assets/ images.
  // ============================================================

  List<Map<String, dynamic>> _homeProducts() {
    return [
      {
        'id': 'pikkx-jacket',
        'name': 'Premium Jacket',
        'category': 'Fashion',
        'price': 45000.0,
        'originalPrice': 55000.0,
        'currency': '₦',
        'imageUrl': 'assets/jacket.png',
        'image': 'assets/jacket.png',
        'rating': 4.8,
        'deliveryTime': '25 min',
        'sellerId': 'pikkx_demo_seller',
        'sellerName': 'PikkX Fashion',
        'description':
            'A stylish premium jacket selected for the PikkX marketplace.',
        'isFeatured': true,
      },
      {
        'id': 'pikkx-shoe',
        'name': 'Classic Sneakers',
        'category': 'Fashion',
        'price': 38000.0,
        'originalPrice': 45000.0,
        'currency': '₦',
        'imageUrl': 'assets/shoe_thumb_1.png',
        'image': 'assets/shoe_thumb_1.png',
        'rating': 4.7,
        'deliveryTime': '25 min',
        'sellerId': 'pikkx_demo_seller',
        'sellerName': 'PikkX Footwear',
        'description':
            'A clean everyday sneaker from the PikkX footwear collection.',
        'isFeatured': true,
      },
    ];
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

  String _imagePath(
    Map<String, dynamic> product,
  ) {
    final imageUrl =
        product['imageUrl']?.toString().trim();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final image =
        product['image']?.toString().trim();

    if (image != null && image.isNotEmpty) {
      return image;
    }

    return '';
  }

  double _rating(
    Map<String, dynamic> product,
  ) {
    final value =
        product['rating'] ??
            product['averageRating'] ??
            product['stars'];

    final rating = _toDouble(value);

    if (rating <= 0) {
      return 0;
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
            product['prepTime'];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

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

    final oldPrice = _toDouble(value);
    final price = _toDouble(product['price']);

    if (oldPrice <= price) {
      return null;
    }

    return oldPrice;
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
                    Icons.shopping_bag_outlined,
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
                fontWeight: FontWeight.w600,
                letterSpacing: -.5,
              ),
            ),
          ),

          // NOTIFICATIONS
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
                    Icons.notifications_none_rounded,
                    _openNotifications,
                  ),

                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -3,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 17,
                        ),
                        height: 17,
                        padding:
                            const EdgeInsets.symmetric(
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
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 7),

          // DISPATCH TRACKING
          _headerButton(
            Icons.delivery_dining_rounded,
            _openDispatchTracking,
          ),

          const SizedBox(width: 7),

          // PROFILE
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
                      Icons.person_outline_rounded,
                      color: pikkXBlack,
                      size: 22,
                    );
                  },
                )
              : const Icon(
                  Icons.person_outline_rounded,
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
                    Icons.camera_alt_outlined,
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
                        FontWeight.w600,
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
                            FontWeight.w600,
                        letterSpacing: -.3,
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
                  Icons.shopping_bag_outlined,
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
    final products =
        _homeProducts()
            .where(
              _matchesSearch,
            )
            .where(
              _matchesCategory,
            )
            .toList();

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

        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            8,
            0,
            25,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Padding(
                padding:
                    EdgeInsets.only(
                  right: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Products · Trending Now',
                        style:
                            TextStyle(
                          color:
                              pikkXBlack,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing:
                              -.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              SizedBox(
                height: 315,
                child: ListView.builder(
                  scrollDirection:
                      Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),
                  itemCount:
                      products.length,
                  itemBuilder:
                      (context, index) {
                    final product =
                        products[index];

                    final productId =
                        product['id']
                            .toString();

                    return _productCard(
                      productId,
                      product,
                      favouriteIds
                          .contains(
                        productId,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // RATING STARS
  // ============================================================

  Widget _ratingStars(
    double rating,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - .5
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded,
            color: pikkXBlack,
            size: 14,
          ),

        const SizedBox(width: 5),

        Text(
          rating.toStringAsFixed(1),
          style:
              const TextStyle(
            color: pikkXBlack,
            fontSize: 10,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
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
        _productName(product);

    final category =
        _category(product);

    final imagePath =
        _imagePath(product);

    final price =
        _toDouble(
      product['price'],
    );

    final originalPrice =
        _originalPrice(product);

    final rating =
        _rating(product);

    final deliveryTime =
        _deliveryTime(product);

    final currency =
        product['currency']
            ?.toString();

    return Container(
      width: 205,
      margin:
          const EdgeInsets.only(
        right: 12,
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
              height: 145,
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
                        child: Container(
                          color:
                              pikkXBackground,
                          child:
                              imagePath
                                      .startsWith(
                            'assets/',
                          )
                                  ? Image.asset(
                                      imagePath,
                                      width:
                                          double.infinity,
                                      height:
                                          double.infinity,
                                      fit: BoxFit
                                          .contain,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              _productPlaceholder(),
                                    )
                                  : Image.network(
                                      imagePath,
                                      width:
                                          double.infinity,
                                      height:
                                          double.infinity,
                                      fit: BoxFit
                                          .cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              _productPlaceholder(),
                                    ),
                        ),
                      ),
                    ),
                  ),

                  // FAVOURITE
                  Positioned(
                    right: 9,
                    top: 9,
                    child: GestureDetector(
                      onTap: () =>
                          _toggleFavourite(
                        productId,
                        product,
                        isFavourite,
                      ),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(
                          color:
                              pikkXWhite
                                  .withOpacity(
                            .94,
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
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // INFORMATION
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                13,
                10,
                10,
                10,
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
                      color:
                          pikkXBlack,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  if (category.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 3,
                      ),
                      child: Text(
                        category,
                        style:
                            const TextStyle(
                          color:
                              pikkXGrey,
                          fontSize: 10,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 5,
                  ),

                  _ratingStars(
                    rating,
                  ),

                  if (deliveryTime !=
                      null) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .schedule_rounded,
                          size: 12,
                          color:
                              pikkXGrey,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          deliveryTime,
                          style:
                              const TextStyle(
                            color:
                                pikkXGrey,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
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
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),

                            if (originalPrice !=
                                null) ...[
                              const SizedBox(
                                width: 5,
                              ),
                              Flexible(
                                child: Text(
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
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () =>
                            _openProduct(
                          productId,
                          product,
                        ),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration:
                              const BoxDecoration(
                            color:
                                pikkXBlack,
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .add_rounded,
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
  // PRODUCT IMAGE PLACEHOLDER
  // ============================================================

  Widget _productPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: pikkXGrey,
        size: 40,
      ),
    );
  }

  // ============================================================
  // OPEN EXISTING PRODUCT DETAIL PAGE
  // ============================================================

  void _openProduct(
    String productId,
    Map<String, dynamic> product,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailPage(
          productId: productId,
          product: product,
        ),
      ),
    );
  }

  // ============================================================
  // FAVOURITES
  // ============================================================

  Future<void> _toggleFavourite(
    String productId,
    Map<String, dynamic> product,
    bool isFavourite,
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

      if (isFavourite) {
        await reference.delete();

        _showMessage(
          'Removed from favourites.',
        );
      } else {
        await reference.set({
          'productId': productId,
          'name':
              _productName(product),
          'price':
              _toDouble(
            product['price'],
          ),
          'imageUrl':
              _imagePath(product),
          'image':
              _imagePath(product),
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
          'rating':
              _rating(product),
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
  // DISPATCH TRACKING
  // ============================================================

  Future<void> _openDispatchTracking() async {
    final user =
        _currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to track your order.',
      );
      return;
    }

    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .where(
                'userId',
                isEqualTo: user.uid,
              )
              .get();

      final activeOrders =
          snapshot.docs.where((doc) {
        final data =
            doc.data();

        final status =
            data['status']
                ?.toString()
                .toLowerCase()
                .trim();

        return status != 'delivered' &&
            status != 'completed' &&
            status != 'cancelled';
      }).toList();

      if (activeOrders.isEmpty) {
        _showMessage(
          'You do not have an active order to track.',
        );
        return;
      }

      activeOrders.sort(
        (a, b) {
          final aCreated =
              a.data()['createdAt'];

          final bCreated =
              b.data()['createdAt'];

          if (aCreated is Timestamp &&
              bCreated is Timestamp) {
            return bCreated.compareTo(
              aCreated,
            );
          }

          return 0;
        },
      );

      final orderId =
          activeOrders.first.id;

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamed(
        '/dispatch-tracking',
        arguments: orderId,
      );
    } catch (e) {
      debugPrint(
        'Dispatch tracking error: $e',
      );

      _showMessage(
        'Could not load your active order.',
      );
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const ProfilePage(),
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          height:
              MediaQuery.of(
                    sheetContext,
                  ).size.height *
                  .70,
          decoration:
              const BoxDecoration(
            color: pikkXBackground,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),

              Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(
                  color:
                      pikkXLightGrey,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications',
                        style:
                            TextStyle(
                          color:
                              pikkXBlack,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String,
                            dynamic>>>(
                  stream:
                      _notificationsStream(),
                  builder:
                      (context, snapshot) {
                    if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              pikkXBlack,
                          strokeWidth: 2,
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
                        snapshot.data?.docs ??
                            [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .notifications_none_rounded,
                              color:
                                  pikkXGrey,
                              size: 45,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'No notifications yet.',
                              style:
                                  TextStyle(
                                color:
                                    pikkXGrey,
                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        18,
                        5,
                        18,
                        20,
                      ),
                      itemCount:
                          docs.length,
                      itemBuilder:
                          (context, index) {
                        final data =
                            docs[index]
                                .data();

                        final title =
                            data['title']
                                    ?.toString() ??
                                'PikkX';

                        final message =
                            data['message']
                                    ?.toString() ??
                                data['body']
                                    ?.toString() ??
                                '';

                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          child: _glass(
                            radius: 18,
                            padding:
                                const EdgeInsets
                                    .all(
                              15,
                            ),
                            color:
                                pikkXWhite
                                    .withOpacity(
                              .82,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
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
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        title,
                                        style:
                                            const TextStyle(
                                          color:
                                              pikkXBlack,
                                          fontSize:
                                              13,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                      if (message
                                          .isNotEmpty) ...[
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          message,
                                          style:
                                              const TextStyle(
                                            color:
                                                pikkXGrey,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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
        source:
            ImageSource.camera,
        imageQuality: 80,
      );

      if (!mounted) {
        return;
      }

      if (image != null) {
        setState(() {
          _cameraImage = image;
        });

        _showMessage(
          'Camera image selected.',
        );
      }
    } catch (e) {
      debugPrint(
        'Camera error: $e',
      );

      _showMessage(
        'Could not open the camera.',
      );
    }
  }

  // ============================================================
  // EMPTY SEARCH
  // ============================================================

  Widget _emptySearchState() {
    return Padding(
      padding:
          const EdgeInsets.all(30),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: pikkXGrey,
              size: 42,
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'No products found',
              style:
                  TextStyle(
                color:
                    pikkXBlack,
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              'Try another search or category.',
              style:
                  const TextStyle(
                color:
                    pikkXGrey,
                fontSize: 11,
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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style:
                const TextStyle(
              color: pikkXWhite,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              pikkXBlack,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
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
    return Scaffold(
      backgroundColor:
          pikkXBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: pikkXBlack,
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            physics:
                const BouncingScrollPhysics(
              parent:
                  AlwaysScrollableScrollPhysics(),
            ),
            padding:
                const EdgeInsets.only(
              bottom: 25,
            ),
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

// ============================================================
// TAP EXTENSION
// ============================================================

extension _HomeTapExtension on Widget {
  Widget _tap(
    VoidCallback onTap, {
    double radius = 20,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          radius,
        ),
        child: this,
      ),
    );
  }
}