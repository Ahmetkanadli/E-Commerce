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
    // Extract favorites list with better type handling
    List<Map<String, dynamic>> favsList = [];
    
    try {
      if (json['favorites'] != null) {
        if (json['favorites'] is List) {
          favsList = (json['favorites'] as List).map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              // Convert to Map<String, dynamic>
              return Map<String, dynamic>.from(item);
            }
            // Return empty map for other types to avoid crashes
            return <String, dynamic>{};
          }).toList();
        } else if (json['favorites'] is Map) {
          // Handle case where favorites might be a map instead of a list
          Map<String, dynamic> favsMap = Map<String, dynamic>.from(json['favorites'] as Map);
          favsList = [favsMap];
        }
      }
    } catch (e) {
      print('Error parsing favorites: $e');
      // Use empty list in case of any parsing error
    }

    String id = '';
    if (json['_id'] != null) {
      id = json['_id'].toString();
    } else if (json['id'] != null) {
      id = json['id'].toString();
    }

    return UserModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      emailVerified: json['emailVerified'] == true,
      createdAt: _parseDateTime(json['createdAt']),
      address: _safeMapConversion(json['address']),
      favorites: favsList,
      cart: _safeMapConversion(json['cart']),
      stats: _safeMapConversion(json['stats']),
    );
  }

  // Helper to safely convert various input types to DateTime
  static DateTime _parseDateTime(dynamic input) {
    if (input == null) return DateTime.now();
    
    if (input is String) {
      try {
        return DateTime.parse(input);
      } catch (_) {
        return DateTime.now();
      }
    } else if (input is int) {
      // Handle timestamp
      return DateTime.fromMillisecondsSinceEpoch(input);
    }
    
    return DateTime.now();
  }
  
  // Helper to safely convert to Map<String, dynamic>
  static Map<String, dynamic>? _safeMapConversion(dynamic input) {
    if (input == null) return null;
    
    if (input is Map<String, dynamic>) {
      return input;
    } else if (input is Map) {
      try {
        return Map<String, dynamic>.from(input);
      } catch (_) {
        return {};
      }
    }
    
    return null;
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
