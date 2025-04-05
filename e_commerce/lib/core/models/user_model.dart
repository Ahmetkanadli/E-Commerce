class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool emailVerified;
  final DateTime createdAt;
  final Map<String, dynamic>? address;
  final List<Map<String, dynamic>> favorites;
  final Map<String, dynamic>? cart;
  final Map<String, dynamic>? stats;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.emailVerified,
    required this.createdAt,
    this.address,
    this.favorites = const [],
    this.cart,
    this.stats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract favorites list
    List<Map<String, dynamic>> favsList = [];
    if (json['favorites'] != null && json['favorites'] is List) {
      favsList = (json['favorites'] as List)
          .map((item) => item is Map<String, dynamic> 
              ? item 
              : <String, dynamic>{})
          .toList();
    }

    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      emailVerified: json['emailVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      address: json['address'] is Map<String, dynamic> 
          ? json['address'] as Map<String, dynamic>
          : null,
      favorites: favsList,
      cart: json['cart'] is Map<String, dynamic> ? json['cart'] as Map<String, dynamic> : null,
      stats: json['stats'] is Map<String, dynamic> ? json['stats'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'address': address,
      'favorites': favorites,
      'cart': cart,
      'stats': stats,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? emailVerified,
    DateTime? createdAt,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? favorites,
    Map<String, dynamic>? cart,
    Map<String, dynamic>? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      favorites: favorites ?? this.favorites,
      cart: cart ?? this.cart,
      stats: stats ?? this.stats,
    );
  }
}
