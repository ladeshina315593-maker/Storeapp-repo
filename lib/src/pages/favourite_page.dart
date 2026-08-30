import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

/// Firebase-ready Favourite Page.
///
/// Firebase architecture:
///
/// Firebase Authentication
///        ↓
/// current user's UID
///        ↓
/// Firestore
/// users/{uid}/favorites/{productId}
///        ↓
/// FavouriteRepository
///        ↓
/// FavouritePage
///
/// The repository layer can be connected to Firebase
/// without changing the UI structure of this page.

class FavouritePage extends StatefulWidget {
  const FavouritePage({Key? key}) : super(key: key);

  @override
  _FavouritePageState createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  /// This list is intentionally kept empty until the
  /// Firebase FavouriteRepository is connected.
  ///
  /// Do NOT put fake products here.
  final List<FavouriteProduct> _favourites = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase connection will load the current user's
      // favourites here.
      //
      // Example architecture:
      //
      // final user = FirebaseAuth.instance.currentUser;
      //
      // if (user == null) return;
      //
      // final favourites =
      //     await FavouriteRepository().getFavourites(user.uid);
      //
      // if (mounted) {
      //   setState(() {
      //     _favourites
      //       ..clear()
      //       ..addAll(favourites);
      //   });
      // }

      await Future.delayed(
        const Duration(milliseconds: 200),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavourite(
    FavouriteProduct product,
  ) async {
    try {
      // Firebase-ready removal:
      //
      // final user = FirebaseAuth.instance.currentUser;
      //
      // if (user == null) return;
      //
      // await FavouriteRepository().removeFavourite(
      //   user.uid,
      //   product.id,
      // );

      setState(() {
        _favourites.removeWhere(
          (item) => item.id == product.id,
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Removed from favourites',
          ),
          backgroundColor: AppTheme.grapePurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not remove favourite',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Widget _glassHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
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
          width: 1,
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
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
    );
  }

  Widget _exploreButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // MainPage/Home navigation can be triggered
          // by the parent navigation controller.
          //
          // This button intentionally does not contain
          // fake navigation to an unavailable screen.
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

  Widget _favouriteCard(
    FavouriteProduct product,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            height: 82,
            width: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.grapeLightPurple,
              borderRadius: BorderRadius.circular(17),
            ),
            child: product.image.isEmpty
                ? Icon(
                    Icons.shopping_bag_outlined,
                    color: AppTheme.grapePurple,
                    size: 32,
                  )
                : Image.asset(
                    product.image,
                    fit: BoxFit.contain,
                  ),
          ),

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

                const SizedBox(height: 6),

                Text(
                  product.price,
                  style: TextStyle(
                    color: AppTheme.grapePurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
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
    );
  }

  Widget _content() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_favourites.isEmpty) {
      return _emptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        110,
      ),
      itemCount: _favourites.length,
      itemBuilder: (context, index) {
        return _favouriteCard(
          _favourites[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          _glassHeader(),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.grapePurple,
              onRefresh: _loadFavourites,
              child: _content(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Firebase/Firestore-friendly product model.
///
/// Firestore document example:
///
/// users/{uid}/favorites/{productId}
///
/// {
///   "productId": "...",
///   "name": "...",
///   "price": "...",
///   "image": "..."
/// }
class FavouriteProduct {
  final String id;
  final String name;
  final String price;
  final String image;

  FavouriteProduct({
    required this.id,
    required this.name,
    required this.price,
    this.image = '',
  });

  factory FavouriteProduct.fromMap(
    Map<String, dynamic> data,
  ) {
    return FavouriteProduct(
      id: data['productId'] ?? '',
      name: data['name'] ?? '',
      price: data['price'] ?? '',
      image: data['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'name': name,
      'price': price,
      'image': image,
    };
  }
}