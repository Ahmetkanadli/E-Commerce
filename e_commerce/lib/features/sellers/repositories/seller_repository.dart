import 'package:dartz/dartz.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/repository/base_repository.dart';
import '../models/seller_model.dart';

abstract class ISellerRepository {
  Future<Either<Failure, SellerModel>> registerAsSeller(
      Map<String, dynamic> sellerData);
  Future<Either<Failure, SellerModel>> updateProfile(
      Map<String, dynamic> profileData);
  Future<Either<Failure, SellerModel>> getProfile();
  Future<Either<Failure, SellerModel>> getSeller(String id);
  Future<Either<Failure, bool>> followSeller(String id);
  Future<Either<Failure, bool>> unfollowSeller(String id);
  Future<Either<Failure, bool>> uploadVerificationDocuments(
      List<String> documents, String documentType);
  Future<Either<Failure, String>> checkVerificationStatus();
}

class SellerRepository extends BaseRepository implements ISellerRepository {
  final ApiClient _apiClient;

  SellerRepository(this._apiClient);

  @override
  Future<Either<Failure, SellerModel>> registerAsSeller(
      Map<String, dynamic> sellerData) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiConstants.registerAsSeller,
        body: sellerData,
        fromJson: (json) => SellerModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, SellerModel>> updateProfile(
      Map<String, dynamic> profileData) async {
    return safeApiCall(() async {
      final response = await _apiClient.patch(
        ApiConstants.sellers,
        body: profileData,
        fromJson: (json) => SellerModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, SellerModel>> getProfile() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        ApiConstants.sellerProfile,
        fromJson: (json) => SellerModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, SellerModel>> getSeller(String id) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        '${ApiConstants.sellers}/$id',
        fromJson: (json) => SellerModel.fromJson(json),
      );
      return response.data!;
    });
  }

  @override
  Future<Either<Failure, bool>> followSeller(String id) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        '${ApiConstants.sellers}/$id/follow',
      );
      return response.success;
    });
  }

  @override
  Future<Either<Failure, bool>> unfollowSeller(String id) async {
    return safeApiCall(() async {
      final response = await _apiClient.delete(
        '${ApiConstants.sellers}/$id/unfollow',
      );
      return response.success;
    });
  }

  @override
  Future<Either<Failure, bool>> uploadVerificationDocuments(
    List<String> documents,
    String documentType,
  ) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiConstants.verifyDocuments,
        body: {
          'documents': documents,
          'documentType': documentType,
        },
      );
      return response.success;
    });
  }

  @override
  Future<Either<Failure, String>> checkVerificationStatus() async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        ApiConstants.verificationStatus,
      );
      return response.data!['status'] as String;
    });
  }
}
