class Product {
  int id;
  String name;
  String category;
  String image;
  double price;

  bool isliked;
  bool isSelected;

  // Product details
  String description;
  double rating;
  int reviewCount;
  int stock;

  // Available options
  List<String> sizes;
  List<String> images;

  Product({
    this.id,
    this.name,
    this.category,
    this.image,
    this.price,
    this.isliked = false,
    this.isSelected = false,
    this.description = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stock = 0,
    this.sizes,
    this.images,
  }) {
    sizes ??= [];
    images ??= [];
  }
}