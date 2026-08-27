import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/model/product.dart';
import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/widgets/title_text.dart';
import 'package:flutter_ecommerce_app/src/widgets/extentions.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product>? onSelected;
  final VoidCallback? onFavoritePressed;

  const ProductCard({
    Key? key,
    required this.product,
    this.onSelected,
    this.onFavoritePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool selected = product.isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(
        vertical: selected ? 5 : 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.52),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.78),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft purple glass glow
          Positioned(
            top: -30,
            left: -25,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LightColor.grapePurple.withOpacity(0.07),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              15,
            ),
            child: Column(
              children: [
                // ==========================
                // FAVOURITE BUTTON
                // ==========================

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onFavoritePressed,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.62),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          child: Icon(
                            product.isliked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: LightColor.grapePurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // ==========================
                // PRODUCT IMAGE
                // ==========================

                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: selected ? 120 : 105,
                          height: selected ? 120 : 105,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LightColor.grapeSoftPurple
                                .withOpacity(0.30),
                          ),
                        ),

                        Container(
                          width: selected ? 100 : 88,
                          height: selected ? 100 : 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.48),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _productImage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ==========================
                // PRODUCT NAME
                // ==========================

                Align(
                  alignment: Alignment.centerLeft,
                  child: TitleText(
                    text: product.name,
                    fontSize: selected ? 16 : 14,
                    color: LightColor.darkText,
                  ),
                ),

                const SizedBox(height: 4),

                // ==========================
                // CATEGORY
                // ==========================

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LightColor.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                // ==========================
                // PRICE + DETAILS BUTTON
                // ==========================

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: LightColor.grapePurple.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TitleText(
                        text:
                            '₦${product.price.toStringAsFixed(2)}',
                        fontSize: selected ? 16 : 14,
                        color: LightColor.darkText,
                      ),
                    ),

                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: LightColor.grapePurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LightColor.grapePurple
                                .withOpacity(0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ).ripple(
        () {
          // Tell Home page which product was selected.
          onSelected?.call(product);

          // Open the real product details page.
          Navigator.of(context).pushNamed(
            '/detail',
            arguments: product,
          );
        },
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }

  // ==========================
  // FIREBASE IMAGE SUPPORT
  // ==========================

  Widget _productImage() {
    if (product.image.isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        color: LightColor.grapePurple,
        size: 38,
      );
    }

    // Firebase/Cloud Storage download URL
    if (product.image.startsWith('http')) {
      return Image.network(
        product.image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image_not_supported_outlined,
            color: LightColor.grapePurple,
            size: 34,
          );
        },
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LightColor.grapePurple,
              ),
            ),
          );
        },
      );
    }

    // Existing local asset support
    return Image.asset(
      product.image,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.image_not_supported_outlined,
          color: LightColor.grapePurple,
          size: 34,
        );
      },
    );
  }
}