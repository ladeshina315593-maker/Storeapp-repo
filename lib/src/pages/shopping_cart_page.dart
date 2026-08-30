import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/model/data.dart';
import 'package:flutter_ecommerce_app/src/model/product.dart';
import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
import 'package:flutter_ecommerce_app/src/widgets/title_text.dart';

class ShoppingCartPage extends StatelessWidget {
  const ShoppingCartPage({super.key});

  Widget _cartItems() {
    return Column(
      children: AppData.cartList
          .map((product) => _item(product))
          .toList(),
    );
  }

  Widget _item(Product model) {
    return Container(
      height: 92,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: LightColor.grapeSoftPurple
                  .withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                model.image,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Product information
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                TitleText(
                  text: model.name,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LightColor.darkText,
                ),

                const SizedBox(height: 5),

                Text(
                  model.category,
                  style: const TextStyle(
                    color: LightColor.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                TitleText(
                  text: '\$${model.price.toString()}',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LightColor.grapePurple,
                ),
              ],
            ),
          ),

          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.60),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            child: Text(
              'x${model.id}',
              style: const TextStyle(
                color: LightColor.darkText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _price() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              TitleText(
                text:
                    '${AppData.cartList.length} Items',
                color: LightColor.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),

              const SizedBox(height: 4),

              const Text(
                'Total',
                style: TextStyle(
                  color: LightColor.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          TitleText(
            text: '\$${getPrice()}',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: LightColor.grapePurple,
          ),
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: LightColor.grapePurple,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: LightColor.grapePurple
                .withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          // Checkout action will be connected
          // after we inspect the repository's
          // checkout/order structure.
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  double getPrice() {
    double price = 0;

    AppData.cartList.forEach((product) {
      price += product.price;
    });

    return price;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.padding,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _cartItems(),

            const SizedBox(height: 12),

            Divider(
              color: LightColor.divider,
              thickness: 1,
              height: 30,
            ),

            const SizedBox(height: 15),

            _price(),

            const SizedBox(height: 20),

            _submitButton(context),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}