import 'package:dartz/dartz.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/models/api_response.dart';
import '../../../core/repository/base_repository.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<Either<Failure, ApiResponse<UserModel>>> login(
      String email, String password);
  Future<Either<Failure, ApiResponse<UserModel>>> register(
      String name, String email, String password);
  Future<Either<Failure, bool>> verifyEmail(String token);
  Future<Either<Failure, bool>> deleteUser(String email);
}

class AuthRepository extends BaseRepository implements IAuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  @override
  Future<Either<Failure, ApiResponse<UserModel>>> login(
      String email, String password) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: {'email': email, 'password': password},
        fromJson: (json) => UserModel.fromJson(json['user'] ?? json),
      );
      return response;
    });
  }

  @override
  Future<Either<Failure, ApiResponse<UserModel>>> register(
    String name,
    String email,
    String password,
  ) async {
    return safeApiCall(() async {
      final response = await _apiClient.post(
        ApiConstants.register,
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
        fromJson: (json) => UserModel.fromJson(json['user'] ?? json),
      );
      return response;
    });
  }

  @override
  Future<Either<Failure, bool>> verifyEmail(String token) async {
    return safeApiCall(() async {
      final response = await _apiClient.get(
        '${ApiConstants.verifyEmail}/$token',
      );
      return response.success;
    });
  }

  @override
  Future<Either<Failure, bool>> deleteUser(String email) async {
    return safeApiCall(() async {
      final response = await _apiClient.delete(
        '${ApiConstants.deleteUser}/$email',
      );
      return response.success;
    });
  }
}
