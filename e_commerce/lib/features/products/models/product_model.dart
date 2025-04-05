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
    // Helper function to safely handle different field types
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    // Helper function to safely convert string or number to double
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return 0.0;
        }
      }
      return 0.0;
    }

    // Helper function to safely handle images field
    List<String> safeImages(dynamic images) {
      if (images == null) return [];
      if (images is List) {
        return images.map((e) => safeString(e)).toList();
      }
      if (images is String) {
        // Single image as string
        return [images];
      }
      return [];
    }

    return ProductModel(
      id: safeString(json['_id']),
      sellerId: safeString(json['seller']),
      name: safeString(json['name']),
      description: safeString(json['description']),
      price: safeDouble(json['price']),
      category: safeString(json['category']),
      stock: json['stock'] is int ? json['stock'] : 0,
      images: safeImages(json['images']),
      isActive: json['isActive'] is bool ? json['isActive'] : true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'])
              : DateTime.now())
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
