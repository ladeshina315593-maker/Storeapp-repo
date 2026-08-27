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
  Widget _glassIcon(
    IconData icon, {
    Color color,
    double size = 22,
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
      () {},
      borderRadius: BorderRadius.circular(15),
    );
  }

  Widget _welcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
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
                      style: TextStyle(fontSize: 21),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _glassIcon(
            Icons.notifications_none_rounded,
            color: LightColor.grapePurple,
          ),
        ],
      ),
    );
  }

  Widget _locationWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.48),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: LightColor.grapePurple
                    .withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: LightColor.grapePurple,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to',
                    style: TextStyle(
                      color: LightColor.mutedText,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select your location',
                    style: TextStyle(
                      color: LightColor.darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: LightColor.grapePurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
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
                    color: LightColor.grapePurple,
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
          _glassIcon(
            Icons.tune_rounded,
            color: LightColor.grapePurple,
          ),
        ],
      ),
    );
  }

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
          borderRadius: BorderRadius.circular(24),
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
                      color: Colors.white
                          .withOpacity(0.85),
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
                  style: TextStyle(fontSize: 34),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  color: LightColor.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: LightColor.grapePurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          width: AppTheme.fullWidth(context),
          height: 82,
          child: ListView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 10,
            ),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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

  Widget _productWidget() {
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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Products',
                style: TextStyle(
                  color: LightColor.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: LightColor.grapePurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          width: AppTheme.fullWidth(context),
          height:
              AppTheme.fullWidth(context) * .70,
          child: GridView(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 4 / 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 15,
            ),
            padding:
                const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            physics:
                const BouncingScrollPhysics(),
            children: AppData.productList
                .map(
                  (product) => ProductCard(
                    product: product,
                    onSelected: (model) {
                      setState(() {
                        AppData.productList
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height - 210,
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
            _locationWidget(),
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