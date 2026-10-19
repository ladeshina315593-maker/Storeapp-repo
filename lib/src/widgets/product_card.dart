
import 'package:flutter/material.dart';

import 'package:pikkx/src/model/product.dart';
import 'package:pikkx/src/widgets/title_text.dart';
import 'package:pikkx/src/widgets/extentions.dart';

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

  static const Color _black = Color(0xFF050505);
  static const Color _background = Color(0xFFF7F7F7);
  static const Color _muted = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final bool selected = product.isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(
        vertical: selected ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? _black.withOpacity(0.18)
              : const Color(0xFFEEEEEE),
          width: selected ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image and favourite button.
                  SizedBox(
                    height: 118,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _background,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: _productImage(),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: onFavoritePressed,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  product.isliked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: product.isliked
                                      ? _black
                                      : _muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Product name.
                  TitleText(
                    text: product.name,
                    fontSize: 14,
                    color: _black,
                    fontWeight: FontWeight.w700,
                  ),

                  const SizedBox(height: 4),

                  // Product category.
                  Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  const SizedBox(height: 10),

                  // Price and details arrow.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₦${product.price.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _black,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Subtle selection indicator.
            if (selected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: _black,
                ),
              ),
          ],
        ),
      ).ripple(
        () {
          onSelected?.call(product);

          Navigator.of(context).pushNamed(
            '/detail',
            arguments: product,
          );
        },
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _productImage() {
    if (product.image.isEmpty) {
      return const Icon(
        Icons.shopping_bag_outlined,
        color: _muted,
        size: 38,
      );
    }

    if (product.image.startsWith('http')) {
      return Image.network(
        product.image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: _muted,
            size: 34,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _black,
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      product.image,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported_outlined,
          color: _muted,
          size: 34,
        );
      },
    );
  }
}
