class SellerModel {
  final String id;
  final String userId;
  final String shopName;
  final String description;
  final SellerAddress address;
  final bool isVerified;
  final String verificationStatus;
  final List<VerificationDocument> verificationDocuments;
  final String? verificationNotes;
  final List<String> followers;
  final DateTime createdAt;

  SellerModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.description,
    required this.address,
    required this.isVerified,
    required this.verificationStatus,
    required this.verificationDocuments,
    this.verificationNotes,
    required this.followers,
    required this.createdAt,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      shopName: json['shopName'] ?? '',
      description: json['description'] ?? '',
      address: SellerAddress.fromJson(json['address'] ?? {}),
      isVerified: json['isVerified'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'pending',
      verificationDocuments: (json['verificationDocuments'] as List?)
              ?.map((x) => VerificationDocument.fromJson(x))
              .toList() ??
          [],
      verificationNotes: json['verificationNotes'],
      followers: List<String>.from(json['followers'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'shopName': shopName,
      'description': description,
      'address': address.toJson(),
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationDocuments':
          verificationDocuments.map((x) => x.toJson()).toList(),
      'verificationNotes': verificationNotes,
      'followers': followers,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SellerAddress {
  final String street;
  final String city;
  final String state;
  final String country;
  final String zipCode;

  SellerAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  factory SellerAddress.fromJson(Map<String, dynamic> json) {
    return SellerAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
    };
  }
}

class VerificationDocument {
  final String type;
  final String url;
  final DateTime uploadedAt;

  VerificationDocument({
    required this.type,
    required this.url,
    required this.uploadedAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
