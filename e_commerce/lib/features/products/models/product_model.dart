class ProductModel {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stock,
    required this.images,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      sellerId: json['seller'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'seller': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    List<String>? images,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
