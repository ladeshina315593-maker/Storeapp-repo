import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/model/data.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

class ProductDetailPage extends StatefulWidget {
  ProductDetailPage({super.key});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  bool isLiked = false;
  int selectedSize = 1;
  int selectedColor = 0;
  int selectedImage = 0;

  final List<String> sizes = [
    "US 6",
    "US 7",
    "US 8",
    "US 9",
  ];

  // Grape Go purple-only palette.
  final List<Color> colors = [
    AppTheme.grapePurple,
    AppTheme.grapeSoftPurple,
    Color(0xFF9670D8),
    Color(0xFF7450B5),
    Color(0xFFC9A8F5),
  ];

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // GLASS BUTTON
  // ------------------------------------------------------------

  Widget _glassButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
              width: 1,
            ),
            boxShadow: AppTheme.shadow,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.darkText,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _appBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _glassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: AppTheme.darkText,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),

          _glassButton(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: isLiked
                ? AppTheme.grapePurple
                : AppTheme.darkText,
            onPressed: () {
              setState(() {
                isLiked = !isLiked;
              });
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PRODUCT IMAGE
  // ------------------------------------------------------------

  Widget _productImage() {
    String image = AppData.showThumbnailList[selectedImage];

    return Expanded(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.92,
                end: 1.0,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.96),
                  AppTheme.grapeLightPurple,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.2,
              ),
              boxShadow: AppTheme.shadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft decorative glow.
                Positioned(
                  top: -30,
                  left: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.grapePurple
                          .withOpacity(0.08),
                    ),
                  ),
                ),

                // Trending badge.
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    child: Text(
                      "TRENDING",
                      style: TextStyle(
                        color: AppTheme.grapePurple,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Main product image.
                Padding(
                  padding: EdgeInsets.all(35),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // THUMBNAILS
  // ------------------------------------------------------------

  Widget _thumbnail(String image, int index) {
    final bool selected = selectedImage == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImage = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        margin: EdgeInsets.symmetric(horizontal: 5),
        height: 58,
        width: 58,
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.grapePurple
                : Colors.white.withOpacity(0.8),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.grapePurple
                        .withOpacity(0.18),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Image.asset(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _thumbnailRow() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: AppData.showThumbnailList
            .asMap()
            .entries
            .map(
              (entry) => _thumbnail(
                entry.value,
                entry.key,
              ),
            )
            .toList(),
      ),
    );
  }

  // ------------------------------------------------------------
  // RATING
  // ------------------------------------------------------------

  Widget _rating() {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          color: AppTheme.grapePurple,
          size: 19,
        ),

        SizedBox(width: 4),

        Text(
          "4.8",
          style: TextStyle(
            color: AppTheme.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(width: 5),

        Text(
          "(120 reviews)",
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DETAILS SHEET
  // ------------------------------------------------------------

  Widget _detailWidget() {
    return DraggableScrollableSheet(
      maxChildSize: 0.82,
      initialChildSize: 0.56,
      minChildSize: 0.56,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
            ),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 25,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle.
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.grapeSoftPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: 18),

                // PRODUCT TITLE + PRICE
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NIKE AIR MAX 200",
                            style: TextStyle(
                              color: AppTheme.darkText,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "Trending Now",
                            style: TextStyle(
                              color: AppTheme.grapePurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(height: 10),

                          _rating(),
                        ],
                      ),
                    ),

                    SizedBox(width: 15),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$240",
                          style: TextStyle(
                            color: AppTheme.darkText,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "In stock",
                          style: TextStyle(
                            color: AppTheme.grapePurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 25),

                // SIZE
                _sectionTitle("Available Size"),

                SizedBox(height: 12),

                Row(
                  children: List.generate(
                    sizes.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index ==
                                  sizes.length - 1
                              ? 0
                              : 8,
                        ),
                        child: _sizeWidget(
                          sizes[index],
                          index,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // COLOR
                _sectionTitle("Available Color"),

                SizedBox(height: 14),

                Row(
                  children: List.generate(
                    colors.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        right: 18,
                      ),
                      child: _colorWidget(
                        colors[index],
                        index,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 25),

                // DESCRIPTION
                _sectionTitle("Description"),

                SizedBox(height: 10),

                Text(
                  "Quality product from a trusted seller",
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),

                SizedBox(height: 25),

                // DELIVERY
                _infoRow(
                  Icons.local_shipping_outlined,
                  "Fast delivery",
                  "Get your order delivered quickly",
                ),

                SizedBox(height: 12),

                // VERIFICATION
                _infoRow(
                  Icons.verified_outlined,
                  "Grape Go verified",
                  "Quality product from a trusted seller",
                ),

                SizedBox(height: 90),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.darkText,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ------------------------------------------------------------
  // SIZE SELECTOR
  // ------------------------------------------------------------

  Widget _sizeWidget(String text, int index) {
    final bool selected = selectedSize == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.grapePurple
              : AppTheme.grapeLightPurple,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.grapePurple
                : AppTheme.grapeSoftPurple,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.grapePurple
                        .withOpacity(0.20),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppTheme.darkText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // COLOR SELECTOR
  // ------------------------------------------------------------

  Widget _colorWidget(Color color, int index) {
    final bool selected = selectedColor == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 38,
        width: 38,
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppTheme.grapePurple
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 17,
                )
              : null,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMATION ROW
  // ------------------------------------------------------------

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.grapeLightPurple,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppTheme.grapeSoftPurple
              .withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.grapePurple
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.grapePurple,
              size: 20,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD TO CART
  // ------------------------------------------------------------

  Widget _floatingCartButton() {
    return Container(
      margin: EdgeInsets.only(
        right: 5,
        bottom: 8,
      ),
      child: FloatingActionButton.extended(
        elevation: 8,
        backgroundColor: AppTheme.grapePurple,
        onPressed: () {
          // Add the selected product to the cart.
          if (AppData.cartList.isEmpty ||
              !AppData.cartList.any(
                (item) => item.name == "Nike Air Max 200",
              )) {
            AppData.cartList.add(
              AppData.productList.first,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Nike Air Max 200 added to cart",
              ),
              backgroundColor:
                  AppTheme.grapePurple,
              behavior:
                  SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
              duration:
                  Duration(seconds: 2),
            ),
          );
        },
        icon: Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white,
        ),
        label: Text(
          "Add to Cart",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.grapeLightPurple,

      floatingActionButton:
          _floatingCartButton(),

      body: SafeArea(
        child: Container(
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
          child: Stack(
            children: [
              Column(
                children: [
                  _appBar(),
                  _productImage(),
                  _thumbnailRow(),
                ],
              ),

              _detailWidget(),
            ],
          ),
        ),
      ),
    );
  }
}