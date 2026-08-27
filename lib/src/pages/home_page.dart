import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
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

  String selectedFilter = 'All';

  String selectedCategory = 'All';

  final List<String> categories = const [
    'All',
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Accessories',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIREBASE PRODUCTS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _productsStream() {
    return _firestore
        .collection('products')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // FIREBASE CART
  // ============================================================

  Future<void> _addToCart(
    String productId,
    Map<String, dynamic> product,
  ) async {
    final User? user = _auth.currentUser;

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

      final existing =
          await cartReference.get();

      if (existing.exists) {
        final currentQuantity =
            (existing.data()?['quantity'] ?? 1)
                as num;

        await cartReference.update({
          'quantity':
              currentQuantity.toInt() + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await cartReference.set({
          'productId': productId,
          'name': product['name'] ?? 'Product',
          'price':
              (product['price'] ?? 0).toDouble(),
          'imageUrl':
              product['imageUrl'] ?? '',
          'quantity': 1,
          'sellerId':
              product['sellerId'] ?? '',
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
  // FIREBASE FAVOURITES
  // ============================================================

  Future<void> _toggleFavourite(
    String productId,
    Map<String, dynamic> product,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to save favourites.',
      );
      return;
    }

    try {
      final favouriteReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId);

      final existing =
          await favouriteReference.get();

      if (existing.exists) {
        await favouriteReference.delete();

        _showMessage(
          'Removed from favourites.',
        );
      } else {
        await favouriteReference.set({
          'productId': productId,
          'name':
              product['name'] ?? 'Product',
          'price':
              (product['price'] ?? 0).toDouble(),
          'imageUrl':
              product['imageUrl'] ?? '',
          'category':
              product['category'] ?? '',
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
        _searchController.text.trim().toLowerCase();

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

    return name.contains(search) ||
        description.contains(search) ||
        category.contains(search);
  }

  // ============================================================
  // PRODUCT FILTER
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

    return true;
  }

  bool _matchesCategory(
    Map<String, dynamic> product,
  ) {
    if (selectedCategory == 'All') {
      return true;
    }

    return (product['category'] ?? '')
            .toString()
            .toLowerCase() ==
        selectedCategory.toLowerCase();
  }

  // ============================================================
  // GLASS ICON
  // ============================================================

  Widget _glassIcon(
    IconData icon, {
    Color? color,
    double size = 22,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.58),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.85),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color:
            color ?? LightColor.darkText,
        size: size,
      ),
    ).ripple(
      onTap,
      borderRadius:
          BorderRadius.circular(15),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _welcomeHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to',
            style: TextStyle(
              color:
                  LightColor.mutedText,
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                'Grape',
                style: TextStyle(
                  color:
                      LightColor.darkText,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              Text(
                'Go',
                style: TextStyle(
                  color:
                      LightColor.grapePurple,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '🍇',
                style:
                    TextStyle(fontSize: 21),
              ),
            ],
          ),
        ],
      ),
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
        5,
        20,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.64),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.85),
                ),
              ),
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
                        LightColor.mutedText,
                    fontSize: 13,
                  ),
                  prefixIcon:
                      Icon(
                    Icons.search_rounded,
                    color:
                        LightColor.grapePurple,
                  ),
                  suffixIcon:
                      _searchController
                              .text
                              .isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController
                                    .clear();
                                setState(() {});
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .close_rounded,
                              ),
                            )
                          : null,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _glassIcon(
            Icons.tune_rounded,
            color:
                LightColor.grapePurple,
            onTap:
                _showFilterSheet,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilterSheet() {
    final filters = const [
      'All',
      'Trending Now',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white
                .withOpacity(0.96),
            borderRadius:
                const BorderRadius.only(
              topLeft:
                  Radius.circular(28),
              topRight:
                  Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color: LightColor
                        .grapeSoftPurple,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Filter products',
                style: TextStyle(
                  color:
                      LightColor.darkText,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              ...filters.map(
                (filter) {
                  final selected =
                      selectedFilter ==
                          filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter =
                            filter;
                      });

                      Navigator.pop(
                        context,
                      );
                    },
                    child: Container(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 10,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                      decoration:
                          BoxDecoration(
                        color: selected
                            ? LightColor
                                .grapePurple
                                .withOpacity(
                                    0.12)
                            : Colors.white
                                .withOpacity(
                                    0.65),
                        borderRadius:
                            BorderRadius.circular(
                                16),
                        border: Border.all(
                          color: selected
                              ? LightColor
                                  .grapePurple
                              : LightColor
                                  .grapeSoftPurple,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons
                                    .radio_button_checked
                                : Icons
                                    .radio_button_off,
                            color:
                                LightColor
                                    .grapePurple,
                          ),
                          const SizedBox(
                              width: 12),
                          Text(
                            filter,
                            style:
                                TextStyle(
                              color:
                                  LightColor
                                      .darkText,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PROMO
  // ============================================================

  Widget _promoBanner() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: Container(
        height: 125,
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            colors: [
              LightColor.grapePurple,
              LightColor.grapePurple
                  .withOpacity(0.72),
            ],
          ),
          borderRadius:
              BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: LightColor
                  .grapePurple
                  .withOpacity(0.25),
              blurRadius: 20,
              offset:
                  const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'Discover something',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'you will love today ✨',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                      height: 7),
                  Text(
                    'Explore our latest products',
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(
                              0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🍇',
                  style:
                      TextStyle(
                    fontSize: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _categoryWidget() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            5,
          ),
          child: Text(
            'Categories',
            style: TextStyle(
              color:
                  LightColor.darkText,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 58,
          child: ListView.builder(
            padding:
                const EdgeInsets.only(
              left: 20,
              right: 10,
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
                  right: 10,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory =
                          category;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 220,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                    ),
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? LightColor
                              .grapePurple
                          : Colors.white
                              .withOpacity(
                                  0.62),
                      borderRadius:
                          BorderRadius.circular(
                              18),
                      border: Border.all(
                        color: selected
                            ? LightColor
                                .grapePurple
                            : Colors.white
                                .withOpacity(
                                    0.85),
                      ),
                    ),
                    child: Text(
                      category,
                      style:
                          TextStyle(
                        color: selected
                            ? Colors.white
                            : LightColor
                                .darkText,
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FIREBASE PRODUCT LIST
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
                color:
                    Color(0xFFB98BEF),
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
              _matchesFilter(data) &&
              _matchesCategory(data);
        }).toList();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                15,
                20,
                5,
              ),
              child: Row(
                children: [
                  Text(
                    selectedFilter ==
                                'All' &&
                            selectedCategory ==
                                'All'
                        ? 'Popular Products'
                        : selectedCategory !=
                                'All'
                            ? selectedCategory
                            : selectedFilter,
                    style: TextStyle(
                      color:
                          LightColor.darkText,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length}',
                    style: TextStyle(
                      color:
                          LightColor.grapePurple,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              _emptyProducts()
            else
              SizedBox(
                height: 285,
                child: ListView.builder(
                  padding:
                      const EdgeInsets.only(
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

                    return _firebaseProductCard(
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

  Widget _firebaseProductCard(
    String productId,
    Map<String, dynamic> product,
  ) {
    final String name =
        product['name']?.toString() ??
            'Product';

    final double price =
        (product['price'] ?? 0)
            .toDouble();

    final String imageUrl =
        product['imageUrl']?.toString() ??
            '';

    final bool isFeatured =
        product['isFeatured'] == true;

    return Container(
      width: 205,
      margin:
          const EdgeInsets.only(
        top: 10,
        right: 15,
        bottom: 15,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
                0.70),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              Colors.white.withOpacity(
                  0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.045),
            blurRadius: 16,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    _openProduct(
                      productId,
                      product,
                    );
                  },
                  child: Container(
                    width:
                        double.infinity,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF8F5FF,
                      ),
                      borderRadius:
                          const BorderRadius
                              .vertical(
                        top:
                            Radius.circular(
                                24),
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
                                      24),
                            ),
                            child:
                                Image.network(
                              imageUrl,
                              fit: BoxFit
                                  .cover,
                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return _productPlaceholder();
                              },
                            ),
                          )
                        : _productPlaceholder(),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: _glassIcon(
                    Icons.favorite_border_rounded,
                    color:
                        LightColor.grapePurple,
                    size: 19,
                    onTap: () {
                      _toggleFavourite(
                        productId,
                        product,
                      );
                    },
                  ),
                ),

                if (isFeatured)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            LightColor
                                .grapePurple,
                        borderRadius:
                            BorderRadius.circular(
                                10),
                      ),
                      child:
                          const Text(
                        'Featured',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              13,
              10,
              13,
              12,
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
                      TextStyle(
                    color:
                        LightColor.darkText,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                    height: 5),

                Text(
                  '₦${price.toStringAsFixed(2)}',
                  style:
                      TextStyle(
                    color:
                        LightColor.grapePurple,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                    height: 9),

                SizedBox(
                  width:
                      double.infinity,
                  height: 38,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      _addToCart(
                        productId,
                        product,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          LightColor
                              .grapePurple,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    13),
                      ),
                    ),
                    child:
                        const Text(
                      'Add to Cart',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
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
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final name =
            product['name']?.toString() ??
                'Product';

        final price =
            (product['price'] ?? 0)
                .toDouble();

        final description =
            product['description']
                    ?.toString() ??
                'No description available.';

        final imageUrl =
            product['imageUrl']
                    ?.toString() ??
                '';

        return Container(
          padding:
              const EdgeInsets.all(20),
          decoration:
              BoxDecoration(
            color: Colors.white
                .withOpacity(0.97),
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                            22),
                    child:
                        Image.network(
                      imageUrl,
                      height: 190,
                      width:
                          double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(
                    height: 15),

                Text(
                  name,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                    height: 6),

                Text(
                  '₦${price.toStringAsFixed(2)}',
                  style:
                      TextStyle(
                    color:
                        LightColor
                            .grapePurple,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                    height: 10),

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
                    height: 18),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          context);

                      _addToCart(
                        productId,
                        product,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          LightColor
                              .grapePurple,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    17),
                      ),
                    ),
                    child:
                        const Text(
                      'Add to Cart',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _productPlaceholder() {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 50,
        color: Color(0xFFB98BEF),
      ),
    );
  }

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
          const EdgeInsets.all(25),
      width: double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
                0.55),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withOpacity(
                  0.85),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color:
                LightColor.grapePurple,
            size: 38,
          ),
          const SizedBox(
              height: 10),
          Text(
            _searchController
                    .text
                    .isNotEmpty
                ? 'No matching products'
                : 'No products yet',
            style:
                TextStyle(
              color:
                  LightColor.darkText,
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
              height: 4),
          Text(
            'Products added to Firebase will appear here.',
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

  Widget _firebaseError() {
    return Container(
      margin:
          const EdgeInsets.all(20),
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
                0.65),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFB98BEF),
            size: 38,
          ),
          const SizedBox(
              height: 10),
          Text(
            'Unable to load products',
            style:
                TextStyle(
              color:
                  LightColor.darkText,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
              height: 5),
          Text(
            'Firebase products will appear here once the connection is configured.',
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

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            LightColor.grapePurple,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context) {
    return SizedBox(
      height:
          MediaQuery.of(context)
                  .size
                  .height -
              210,
      child:
          SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(),
        dragStartBehavior:
            DragStartBehavior.down,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _welcomeHeader(),
            _search(),
            _promoBanner(),
            _categoryWidget(),
            _productWidget(),
            const SizedBox(
                height: 100),
          ],
        ),
      ),
    );
  }
}