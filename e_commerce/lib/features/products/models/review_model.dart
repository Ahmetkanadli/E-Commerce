import 'dart:developer' as developer;

class ReviewModel {
  final String id;
  final String userId;
  final String productId;
  final String text;
  final double rating;
  final DateTime createdAt;
  final String? userAvatar;
  final String? userName;
  final String? sellerReply;
  final DateTime? sellerReplyDate;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.text,
    required this.rating,
    required this.createdAt,
    this.userAvatar,
    this.userName,
    this.sellerReply,
    this.sellerReplyDate,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    developer.log('🔍 Parsing ReviewModel from JSON: ${json.keys.join(', ')}');
    
    // Helper function to safely handle different field types
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    // Helper function to safely convert to double
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

    // Extract ID - handle different naming conventions (_id or id)
    String id = '';
    if (json.containsKey('_id')) {
      id = safeString(json['_id']);
    } else if (json.containsKey('id')) {
      id = safeString(json['id']);
    }
    developer.log('🔍 Review ID: $id');

    // Extract User ID and info - could be a direct field or nested in user object
    String userId = '';
    String? userName;
    String? userAvatar;
    
    dynamic userValue = json['user'];
    if (userValue is Map) {
      userId = safeString(userValue['_id'] ?? userValue['id'] ?? '');
      userName = userValue['name'] as String?;
      userAvatar = userValue['avatar'] as String?;
    } else {
      userId = safeString(userValue);
    }
    developer.log('🔍 User ID: $userId, Name: $userName');

    // Extract product ID
    String productId = safeString(json['product']);
    developer.log('🔍 Product ID: $productId');

    // Extract text - could be 'text', 'content', 'comment', or 'review'
    String text = '';
    if (json.containsKey('comment')) {
      text = safeString(json['comment']);
    } else if (json.containsKey('text')) {
      text = safeString(json['text']);
    } else if (json.containsKey('content')) {
      text = safeString(json['content']);
    } else if (json.containsKey('review')) {
      text = safeString(json['review']);
    }
    developer.log('🔍 Text: ${text.length > 50 ? text.substring(0, 50) + '...' : text}');

    // Extract rating
    double rating = safeDouble(json['rating']);
    developer.log('🔍 Rating: $rating');

    // Extract created date
    DateTime createdAt = DateTime.now();
    if (json.containsKey('createdAt')) {
      try {
        if (json['createdAt'] is String) {
          createdAt = DateTime.parse(json['createdAt']);
        }
      } catch (e) {
        developer.log('❌ Error parsing createdAt: $e');
      }
    }
    developer.log('🔍 Created at: $createdAt');

    // Extract seller reply and date
    String? sellerReply = json['sellerReply'] as String?;
    DateTime? sellerReplyDate;
    
    if (json.containsKey('sellerReplyDate')) {
      try {
        if (json['sellerReplyDate'] is String) {
          sellerReplyDate = DateTime.parse(json['sellerReplyDate']);
        }
      } catch (e) {
        developer.log('❌ Error parsing sellerReplyDate: $e');
      }
    }
    
    if (sellerReply != null) {
      developer.log('🔍 Seller reply: ${sellerReply.length > 50 ? sellerReply.substring(0, 50) + '...' : sellerReply}');
    }

    return ReviewModel(
      id: id,
      userId: userId,
      productId: productId,
      text: text,
      rating: rating,
      createdAt: createdAt,
      userAvatar: userAvatar,
      userName: userName,
      sellerReply: sellerReply,
      sellerReplyDate: sellerReplyDate,
    );
  }
} 