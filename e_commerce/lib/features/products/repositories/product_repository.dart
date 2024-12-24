import 'package:dartz/dartz.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/repository/base_repository.dart';
import '../models/product_model.dart';

abstract class IProductRepository {
  Future<Either<Failure, List<ProductModel>>> getAllProducts();
  Future<Either<Failure, List<ProductModel>>> getSellerProducts(
      String sellerId);
  Future<Either<Failure, ProductModel>> getProduct(String id);
  Future<Either<Failure, List<ProductModel>>> getMyProducts();
  Future<Either<Failure, ProductModel>> createProduct(
      Map<String, dynamic> productData);
  Future<Either<Failure, ProductModel>> updateProduct(
      String id, Map<String, dynamic> productData);
  Future<Either<Failure, bool>> deleteProduct(String id);
}

class ProductRepository extends BaseRepository implements IProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  @override
  Future<Either<Failure, List<ProductModel>>> getAllProducts() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        ApiConstants.products,
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
        '${ApiConstants.sellerProducts}/$sellerId',
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
        '${ApiConstants.products}/$id',
        fromJson: (json) => ProductModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getMyProducts() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        ApiConstants.myProducts,
        fromJson: (json) => List<ProductModel>.from(
          (json as List).map((x) => ProductModel.fromJson(x)),
        ),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, ProductModel>> createProduct(
      Map<String, dynamic> productData) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiConstants.products,
        body: productData,
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
      );
      return response.success;
    });
  }
}
