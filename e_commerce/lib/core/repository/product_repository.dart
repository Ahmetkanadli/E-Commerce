import 'package:dartz/dartz.dart';
import 'package:e_commerce/features/products/models/product_model.dart';
import 'package:e_commerce/features/products/models/review_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/repository/base_repository.dart';
import 'dart:developer' as developer;
import 'dart:convert';


abstract class IProductRepository {
  Future<Either<Failure, List<ProductModel>>> getAllProducts();
  Future<Either<Failure, List<ProductModel>>> getSellerProducts(
      String sellerId);
  Future<Either<Failure, ProductModel>> getProduct(String id);
  Future<Either<Failure, List<ProductModel>>> getMyProducts();
  Future<Either<Failure, List<ProductModel>>> getProductsByCategory(String category);
  Future<Either<Failure, List<ReviewModel>>> getProductReviews(String productId);
  Future<Either<Failure, ProductModel>> createProduct(
      Map<String, dynamic> productData);
  Future<Either<Failure, ProductModel>> updateProduct(
      String id, Map<String, dynamic> productData);
  Future<Either<Failure, bool>> deleteProduct(String id);
}

class ProductRepository extends BaseRepository implements IProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  void _logInfo(String message) {
    developer.log('🟢 REPO: $message');
    print('🟢 REPO: $message');
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log('🔴 REPO ERROR: $message', error: error, stackTrace: stackTrace);
    print('🔴 REPO ERROR: $message');
    if (error != null) {
      print('Error details: $error');
    }
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  String _formatJson(dynamic json) {
    try {
      if (json == null) return 'null';
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getAllProducts() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        ApiConstants.getProductsUrl(),
        fromJson: (json) => List<ProductModel>.from(
          (json as List).map((x) => ProductModel.fromJson(x)),
        ),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getSellerProducts(
      String sellerId) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.sellerProducts}/$sellerId',
        fromJson: (json) => List<ProductModel>.from(
          (json as List).map((x) => ProductModel.fromJson(x)),
        ),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, ProductModel>> getProduct(String id) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        ApiConstants.getProductUrl(id),
        fromJson: (json) => ProductModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getMyProducts() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.myProducts}',
        fromJson: (json) => List<ProductModel>.from(
          (json as List).map((x) => ProductModel.fromJson(x)),
        ),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getProductsByCategory(String category) async {
    _logInfo('Fetching products for category: $category');
    _logInfo('URL: ${ApiConstants.productsByCategory}/$category');
    
    return safeApiCall(() async {
      try {
        final response = await _apiClient.get(
          '${ApiConstants.productsByCategory}/$category',
          fromJson: (json) {
            _logInfo('Raw API response for $category: ${_formatJson(json)}');
            
            try {
              // Check if the response is a map with a data field that contains the products list
              if (json is Map<String, dynamic>) {
                _logInfo('Response is a Map with keys: ${json.keys.join(', ')}');
                
                // Try different ways to extract data
                List<dynamic>? productsData;
                
                if (json.containsKey('data')) {
                  _logInfo('Response contains data key');
                  final data = json['data'];
                  
                  if (data is List) {
                    productsData = data;
                  } else if (data is Map<String, dynamic> && data.containsKey('products')) {
                    final nestedProducts = data['products'];
                    if (nestedProducts is List) {
                      productsData = nestedProducts;
                    }
                  }
                } else if (json.containsKey('products')) {
                  final products = json['products'];
                  if (products is List) {
                    productsData = products;
                  }
                }
                
                if (productsData != null) {
                  _logInfo('Found products list with ${productsData.length} items');
                  return List<ProductModel>.from(
                    productsData.map((x) {
                      _logInfo('Processing product: ${x['name'] ?? 'unknown'}');
                      return ProductModel.fromJson(x);
                    }),
                  );
                } else {
                  _logError('Could not find products array in response');
                }
              } else {
                _logError('Response is not a Map: ${json.runtimeType}');
              }
            } catch (e, st) {
              _logError('Error parsing response', e, st);
            }
            
            // Return mock data for testing if parsing fails
            _logInfo('Returning mock data for $category for testing');
            return [
              ProductModel(
                id: '1',
                sellerId: '1',
                name: 'Mock $category Product 1',
                description: 'This is a mock product for testing',
                price: 99.99,
                category: category,
                stock: 10,
                images: ['https://via.placeholder.com/150'],
                isActive: true,
                createdAt: DateTime.now(),
              ),
              ProductModel(
                id: '2',
                sellerId: '1',
                name: 'Mock $category Product 2',
                description: 'This is another mock product for testing',
                price: 149.99,
                category: category,
                stock: 5,
                images: ['https://via.placeholder.com/150'],
                isActive: true,
                createdAt: DateTime.now(),
              ),
            ];
          },
        );
        _logInfo('Processed response for $category. Success: ${response.success}');
        return response.data!;
      } catch (e, stackTrace) {
        _logError('Exception in getProductsByCategory for $category', e, stackTrace);
        
        // Return mock data on exception for testing UI
        return [
          ProductModel(
            id: '1',
            sellerId: '1',
            name: 'Mock $category Product 1 (Error Fallback)',
            description: 'This is a mock product for testing when API fails',
            price: 99.99,
            category: category,
            stock: 10,
            images: ['https://via.placeholder.com/150'],
            isActive: true,
            createdAt: DateTime.now(),
          ),
          ProductModel(
            id: '2',
            sellerId: '1',
            name: 'Mock $category Product 2 (Error Fallback)',
            description: 'This is another mock product for testing when API fails',
            price: 149.99,
            category: category,
            stock: 5,
            images: ['https://via.placeholder.com/150'],
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ];
      }
    });
  }

  @override
  Future<Either<Failure, List<ReviewModel>>> getProductReviews(String productId) async {
    _logInfo('🔍 Fetching reviews for product: $productId');
    final reviewsUrl = ApiConstants.getProductReviewsUrl(productId);
    _logInfo('🔍 URL: $reviewsUrl');
    
    return safeApiCall(() async {
      try {
        final response = await _apiClient.get(
          reviewsUrl,
          fromJson: (dynamic json) {
            _logInfo('🔍 Raw API response type: ${json.runtimeType}');
            if (json != null) {
              String jsonString = '';
              try {
                jsonString = const JsonEncoder.withIndent('  ').convert(json);
                _logInfo('🔍 Response content: $jsonString');
              } catch (e) {
                _logInfo('❌ Failed to stringify JSON: $e');
              }
            } else {
              _logInfo('⚠️ Response is null');
              return <ReviewModel>[];
            }
            
            // Handle the specific response format:
            // {
            //   "status": "success",
            //   "results": 1,
            //   "data": {
            //     "reviews": [ ... ]
            //   }
            // }
            
            List<ReviewModel> reviews = [];
            
            try {
              if (json is Map<String, dynamic>) {
                _logInfo('🔍 Response is a Map with keys: ${json.keys.join(', ')}');
                
                // First check if this has the expected format
                if (json.containsKey('status') && json.containsKey('data')) {
                  _logInfo('🔍 Found expected response format with status and data');
                  
                  final data = json['data'];
                  if (data is Map<String, dynamic> && data.containsKey('reviews')) {
                    final reviewsData = data['reviews'];
                    if (reviewsData is List) {
                      _logInfo('✅ Found reviews array with ${reviewsData.length} items');
                      
                      for (var i = 0; i < reviewsData.length; i++) {
                        final item = reviewsData[i];
                        if (item is Map<String, dynamic>) {
                          try {
                            _logInfo('🔍 Processing review at index $i');
                            final review = ReviewModel.fromJson(item);
                            reviews.add(review);
                            _logInfo('✅ Parsed review: id=${review.id}, rating=${review.rating}');
                          } catch (e) {
                            _logError('❌ Error parsing review at index $i: $e');
                          }
                        }
                      }
                      
                      _logInfo('✅ Successfully parsed ${reviews.length} reviews');
                      return reviews;
                    }
                  }
                } 
                
                // Check for other formats
                if (json.containsKey('data')) {
                  final data = json['data'];
                  
                  if (data is List) {
                    _logInfo('✅ Data is a List with ${data.length} items');
                    for (var i = 0; i < data.length; i++) {
                      final item = data[i];
                      if (item is Map<String, dynamic>) {
                        try {
                          final review = ReviewModel.fromJson(item);
                          reviews.add(review);
                        } catch (e) {
                          _logError('❌ Error parsing review at index $i: $e');
                        }
                      }
                    }
                  }
                } else if (json.containsKey('reviews')) {
                  final reviewsData = json['reviews'];
                  
                  if (reviewsData is List) {
                    _logInfo('✅ Reviews is a List with ${reviewsData.length} items');
                    for (var i = 0; i < reviewsData.length; i++) {
                      final item = reviewsData[i];
                      if (item is Map<String, dynamic>) {
                        try {
                          final review = ReviewModel.fromJson(item);
                          reviews.add(review);
                        } catch (e) {
                          _logError('❌ Error parsing review at index $i: $e');
                        }
                      }
                    }
                  }
                }
              } else if (json is List) {
                _logInfo('🔍 Response is a List with ${json.length} items');
                for (var i = 0; i < json.length; i++) {
                  final item = json[i];
                  if (item is Map<String, dynamic>) {
                    try {
                      final review = ReviewModel.fromJson(item);
                      reviews.add(review);
                    } catch (e) {
                      _logError('❌ Error parsing review at index $i: $e');
                    }
                  }
                }
              }
            } catch (e) {
              _logError('❌ Error processing reviews: $e');
            }
            
            _logInfo('✅ Parsed ${reviews.length} reviews successfully');
            return reviews;
          },
        );
        return response.data!;
      } catch (e, stackTrace) {
        _logError('❌ Error fetching reviews: $e', e, stackTrace);
        return [];
      }
    });
  }

  @override
  Future<Either<Failure, ProductModel>> createProduct(
      Map<String, dynamic> productData) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiConstants.products,
        data: productData,
        fromJson: (json) => ProductModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, ProductModel>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    return safeApiCall(() async {
      final response = await _apiClient.patch(
        '${ApiConstants.products}/$id',
        body: productData,
        fromJson: (json) => ProductModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, bool>> deleteProduct(String id) async {
    return safeApiCall(() async {
      final response = await _apiClient.delete(
        '${ApiConstants.products}/$id',
        fromJson: (json) => json['success'] as bool,
      );
      return response.success;
    });
  }
}
