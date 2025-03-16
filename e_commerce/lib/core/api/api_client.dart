import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../error/failures.dart';
import '../models/api_response.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
        ));

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse<T>(
        success: true,
        message: response.data['message'] ?? 'Success',
        data: fromJson(response.data),
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          e.response?.data['message'] ?? e.message ?? 'Error occurred',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return ApiResponse<T>(
        success: true,
        message: response.data['message'] ?? 'Success',
        data: fromJson(response.data['data'] ?? response.data),
        token: response.data['token'],
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          e.response?.data['message'] ?? e.message ?? 'Error occurred',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw NetworkFailure(message: 'Network error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.delete(path);
      return ApiResponse<T>(
        success: true,
        message: response.data['message'] ?? 'Success',
        data: fromJson(response.data),
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          e.response?.data['message'] ?? e.message ?? 'Error occurred',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
      throw Exception(e.toString());
    }
  }

  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      developer.log('Raw response body: ${response.data}');

      // Check if response is HTML (error page)
      if (response.data.toString().trim().startsWith('<!DOCTYPE html>')) {
        throw ServerFailure(
          message:
              'Server returned HTML instead of JSON. Server might be down or URL might be incorrect.',
          statusCode: response.statusCode ?? 500,
        );
      }

      final body = json.decode(response.data.toString());
      developer.log('Decoded response body: $body');

      final statusCode = response.statusCode ?? 500;
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Success',
          data: fromJson != null && body['data'] != null
              ? fromJson(body['data'])
              : null,
          token: body['token'],
          statusCode: statusCode,
        );
      }

      switch (statusCode) {
        case 401:
          throw AuthenticationFailure(
              message: body['message'] ?? 'Authentication failed');
        case 400:
          throw ValidationFailure(
              message: body['message'] ?? 'Validation failed');
        default:
          throw ServerFailure(
            message: body['message'] ?? 'Server error occurred',
            statusCode: statusCode,
          );
      }
    } catch (e) {
      developer.log('Error handling response: $e');
      if (e is FormatException) {
        throw ServerFailure(
          message: 'Invalid response format from server',
          statusCode: response.statusCode ?? 500,
        );
      }
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
}
