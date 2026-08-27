import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/model/data.dart';
import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
import 'package:flutter_ecommerce_app/src/widgets/product_card.dart';
import 'package:flutter_ecommerce_app/src/widgets/product_icon.dart';
import 'package:flutter_ecommerce_app/src/widgets/extentions.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedFilter = 'All';

  Widget _glassIcon(
    IconData icon, {
    Color color,
    double size = 22,
    VoidCallback onTap,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.58),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color ?? LightColor.darkText,
        size: size,
      ),
    ).ripple(
      onTap,
      borderRadius: BorderRadius.circular(15),
    );
  }

  // ==============================
  // WELCOME HEADER
  // ==============================

  Widget _welcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: TextStyle(
                    color: LightColor.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Grape',
                      style: TextStyle(
                        color: LightColor.darkText,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Go',
                      style: TextStyle(
                        color: LightColor.grapePurple,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '🍇',
                      style: TextStyle(
                        fontSize: 21,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // SEARCH + FILTER
  // ==============================

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.64),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.85),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.035),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    color: LightColor.mutedText,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color:
                        LightColor.grapePurple,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // WORKING FILTER BUTTON
          _glassIcon(
            Icons.tune_rounded,
            color: LightColor.grapePurple,
            onTap: _showFilterSheet,
          ),
        ],
      ),
    );
  }

  // ==============================
  // FILTER SHEET
  // ==============================

  void _showFilterSheet() {
    final List<String> filters = [
      'All',
      'Trending Now',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        LightColor.grapeSoftPurple,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Filter products',
                style: TextStyle(
                  color: LightColor.darkText,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 15),

              ...filters.map(
                (filter) {
                  final bool selected =
                      selectedFilter == filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = filter;
                      });

                      Navigator.pop(context);
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? LightColor
                                .grapePurple
                                .withOpacity(0.12)
                            : Colors.white
                                .withOpacity(0.65),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? LightColor.grapePurple
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
                                LightColor.grapePurple,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            filter,
                            style: TextStyle(
                              color:
                                  LightColor.darkText,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).toList(),
            ],
          ),
        );
      },
    );
  }

  // ==============================
  // PROMO BANNER
  // ==============================

  Widget _promoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: Container(
        height: 125,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LightColor.grapePurple,
              LightColor.grapePurple
                  .withOpacity(0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: LightColor.grapePurple
                  .withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'Discover something',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'you will love today ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Explore our latest products',
                    style: TextStyle(
                      color:
                          Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🍇',
                  style: TextStyle(
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

  // ==============================
  // CATEGORIES
  // ==============================

  Widget _categoryWidget() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            5,
          ),
          child: Text(
            'Categories',
            style: TextStyle(
              color: LightColor.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        Container(
          margin:
              const EdgeInsets.symmetric(
            vertical: 8,
          ),
          width:
              AppTheme.fullWidth(context),
          height: 82,
          child: ListView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 10,
            ),
            scrollDirection:
                Axis.horizontal,
            physics:
                const BouncingScrollPhysics(),
            children: AppData.categoryList
                .map(
                  (category) => ProductIcon(
                    model: category,
                    onSelected: (model) {
                      setState(() {
                        AppData.categoryList
                            .forEach((item) {
                          item.isSelected = false;
                        });

                        model.isSelected = true;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ==============================
  // PRODUCTS
  // ==============================

  Widget _productWidget() {
    final products =
        selectedFilter == 'All'
            ? AppData.productList
            : AppData.productList
                .where(
                  (product) =>
                      product.category ==
                      selectedFilter,
                )
                .toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            5,
          ),
          child: Row(
            children: [
              Text(
                selectedFilter == 'All'
                    ? 'Popular Products'
                    : selectedFilter,
                style: TextStyle(
                  color: LightColor.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Spacer(),

              if (selectedFilter != 'All')
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = 'All';
                    });
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color:
                          LightColor.grapePurple,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (products.isEmpty)
          _emptyProducts()
        else
          Container(
            margin:
                const EdgeInsets.symmetric(
              vertical: 8,
            ),
            width:
                AppTheme.fullWidth(context),
            height:
                AppTheme.fullWidth(context) *
                    .70,
            child: GridView(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 4 / 3,
                mainAxisSpacing: 18,
                crossAxisSpacing: 15,
              ),
              padding:
                  const EdgeInsets.only(
                left: 20,
              ),
              scrollDirection:
                  Axis.horizontal,
              physics:
                  const BouncingScrollPhysics(),
              children: products
                  .map(
                    (product) => ProductCard(
                      product: product,
                      onSelected: (model) {
                        setState(() {
                          AppData.productList
                              .forEach((item) {
                            item.isSelected =
                                false;
                          });

                          model.isSelected =
                              true;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _emptyProducts() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20,
      ),
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.85),
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
          const SizedBox(height: 10),
          Text(
            'No products found',
            style: TextStyle(
              color: LightColor.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another filter.',
            style: TextStyle(
              color: LightColor.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height -
              210,
      child: SingleChildScrollView(
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}