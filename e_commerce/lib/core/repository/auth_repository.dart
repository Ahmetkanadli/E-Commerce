import 'package:dartz/dartz.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../error/failures.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<Either<Failure, ApiResponse<UserModel>>> login(
      String email, String password);
  Future<Either<Failure, ApiResponse<UserModel>>> register(
      String name, String email, String password);
  Future<Either<Failure, bool>> verifyEmail(String token);
  Future<Either<Failure, bool>> deleteUser(String email);
}

class AuthRepository implements IAuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  @override
  Future<Either<Failure, ApiResponse<UserModel>>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
        fromJson: (json) => UserModel.fromJson(json['user'] ?? json),
      );
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ApiResponse<UserModel>>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        fromJson: (json) => UserModel.fromJson(json['user'] ?? json),
      );
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyEmail(String token) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.verifyEmail}/$token',
        fromJson: (json) => json['success'] as bool,
      );
      return Right(response.success);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUser(String email) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.deleteUser}/$email',
        fromJson: (json) => json['success'] as bool,
      );
      return Right(response.success);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
