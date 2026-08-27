import 'package:flutter_ecommerce_app/src/model/category.dart';
import 'package:flutter_ecommerce_app/src/model/product.dart';

class AppData {
  // ==============================
  // PRODUCTS
  // ==============================

  static List<Product> productList = [
    Product(
      id: 1,
      name: 'Nike Air Max 200',
      category: 'Trending Now',
      price: 240.00,
      image: 'assets/shooe_tilt_1.png',
      isliked: false,
      isSelected: true,
      description:
          'Clean lines, versatile and timeless. The Nike Air Max 200 combines a classic look with comfortable cushioning for everyday movement.',
      rating: 4.8,
      reviewCount: 120,
      stock: 25,
      sizes: [
        'US 6',
        'US 7',
        'US 8',
        'US 9',
      ],
      images: [
        'assets/show_1.png',
        'assets/shoe_thumb_5.png',
        'assets/shoe_thumb_1.png',
        'assets/shoe_thumb_4.png',
      ],
    ),

    Product(
      id: 2,
      name: 'Nike Air Max 97',
      category: 'Trending Now',
      price: 220.00,
      image: 'assets/shoe_tilt_2.png',
      isliked: false,
      isSelected: false,
      description:
          'The Nike Air Max 97 delivers a smooth everyday style with a comfortable design inspired by the classic Air Max collection.',
      rating: 4.7,
      reviewCount: 96,
      stock: 18,
      sizes: [
        'US 6',
        'US 7',
        'US 8',
        'US 9',
      ],
      images: [
        'assets/shoe_tilt_2.png',
        'assets/shoe_thumb_1.png',
        'assets/shoe_thumb_3.png',
      ],
    ),
  ];

  // ==============================
  // CART
  // ==============================

  static List<Product> cartList = [
    Product(
      id: 1,
      name: 'Nike Air Max 200',
      category: 'Trending Now',
      price: 240.00,
      image: 'assets/small_tilt_shoe_1.png',
      isliked: false,
      isSelected: true,
      stock: 25,
    ),

    Product(
      id: 2,
      name: 'Nike Air Max 97',
      category: 'Trending Now',
      price: 190.00,
      image: 'assets/small_tilt_shoe_2.png',
      isliked: false,
      stock: 18,
    ),

    Product(
      id: 3,
      name: 'Nike Air Max 92607',
      category: 'Trending Now',
      price: 220.00,
      image: 'assets/small_tilt_shoe_3.png',
      isliked: false,
      stock: 12,
    ),
  ];

  // ==============================
  // CATEGORIES
  // ==============================

  static List<Category> categoryList = [
    Category(),

    Category(
      id: 1,
      name: 'Sneakers',
      image: 'assets/shoe_thumb_2.png',
      isSelected: true,
    ),

    Category(
      id: 2,
      name: 'Jacket',
      image: 'assets/jacket.png',
    ),

    Category(
      id: 3,
      name: 'Watch',
      image: 'assets/watch.png',
    ),
  ];

  // ==============================
  // DETAIL PAGE THUMBNAILS
  // ==============================

  static List<String> showThumbnailList = [
    'assets/shoe_thumb_5.png',
    'assets/shoe_thumb_1.png',
    'assets/shoe_thumb_4.png',
    'assets/shoe_thumb_3.png',
  ];
}