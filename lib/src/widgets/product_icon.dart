import 'package:flutter/material.dart';

import 'package:flutter_ecommerce_app/src/model/category.dart';
import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
import 'package:flutter_ecommerce_app/src/widgets/title_text.dart';
import 'package:flutter_ecommerce_app/src/widgets/extentions.dart';

class ProductIcon extends StatelessWidget {
  final ValueChanged<Category> onSelected;
  final Category model;

  ProductIcon({
    Key? key,
    required this.model,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Empty category spacer
    if (model.id == null) {
      return const SizedBox(width: 5);
    }

    final bool selected = model.isSelected;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 12,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          // Glassy surface
          color: selected
              ? LightColor.grapePurple.withOpacity(0.18)
              : Colors.white.withOpacity(0.48),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: selected
                ? LightColor.grapePurple.withOpacity(0.45)
                : Colors.white.withOpacity(0.75),
            width: selected ? 1.3 : 1,
          ),

          boxShadow: [
            BoxShadow(
              color: selected
                  ? LightColor.grapePurple.withOpacity(0.14)
                  : Colors.black.withOpacity(0.035),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category image
            if (model.image != null) ...[
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withOpacity(0.60)
                      : LightColor.grapeSoftPurple
                          .withOpacity(0.20),
                ),
                child: Image.asset(
                  model.image!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 7),
            ],

            // Category name
            if (model.name != null)
              TitleText(
                text: model.name!,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
                color: selected
                    ? LightColor.darkText
                    : LightColor.mutedText,
              ),
          ],
        ),
      ).ripple(
        () {
          onSelected(model);
        },
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}