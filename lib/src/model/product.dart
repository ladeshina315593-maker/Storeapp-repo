class Product {
  final String id;
  final String name;
  final String category;
  final String image;
  final double price;

  final bool isliked;
  final bool isSelected;

  // Product details
  final String description;
  final double rating;
  final int reviewCount;
  final int stock;

  // Available options
  final List<String> sizes;
  final List<String> images;

  // Seller information
  final String sellerId;
  final String sellerName;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id = '',
    this.name = '',
    this.category = '',
    this.image = '',
    this.price = 0.0,
    this.isliked = false,
    this.isSelected = false,
    this.description = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stock = 0,
    this.sizes = const [],
    this.images = const [],
    this.sellerId = '',
    this.sellerName = '',
    this.createdAt,
    this.updatedAt,
  });

  // ==============================
  // FIRESTORE → PRODUCT
  // ==============================

  factory Product.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      image: data['image'] ?? '',
      price: (data['price'] ?? 0).toDouble(),

      description: data['description'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      stock: data['stock'] ?? 0,

      sizes: List<String>.from(
        data['sizes'] ?? [],
      ),

      images: List<String>.from(
        data['images'] ?? [],
      ),

      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',

      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(
              data['createdAt'].toString(),
            )
          : null,

      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(
              data['updatedAt'].toString(),
            )
          : null,
    );
  }

  // ==============================
  // PRODUCT → FIRESTORE
  // ==============================

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'image': image,
      'price': price,

      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'stock': stock,

      'sizes': sizes,
      'images': images,

      'sellerId': sellerId,
      'sellerName': sellerName,

      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // ==============================
  // COPY WITH
  // ==============================

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? image,
    double? price,
    bool? isliked,
    bool? isSelected,
    String? description,
    double? rating,
    int? reviewCount,
    int? stock,
    List<String>? sizes,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      image: image ?? this.image,
      price: price ?? this.price,

      isliked: isliked ?? this.isliked,
      isSelected: isSelected ?? this.isSelected,

      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,

      sizes: sizes ?? this.sizes,
      images: images ?? this.images,

      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}