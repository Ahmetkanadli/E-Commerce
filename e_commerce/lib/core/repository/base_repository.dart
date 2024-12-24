import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class BaseRepository {
  Future<Either<Failure, T>> safeApiCall<T>(
      Future<T> Function() apiCall) async {
    try {
      final result = await apiCall();
      return Right(result);
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
