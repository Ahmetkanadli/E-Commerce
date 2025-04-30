import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../error/failures.dart';
import '../models/api_response.dart';
import '../cache/cache_manager.dart';

class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
      logPrint: (object) => developer.log('DIO: $object'),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_authToken == null) {
          _authToken = await CacheManager.getToken();
        }
        
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
          developer.log('🔑 API İsteği: Auth token eklendi: ${_authToken!.substring(0, min(_authToken!.length, 10))}...');
        } else {
          developer.log('⚠️ API İsteği: Auth token bulunamadı!');
        }
        
        developer.log('🔍 API İsteği: ${options.method} ${options.baseUrl}${options.path}');
        if (options.queryParameters.isNotEmpty) {
          developer.log('🔍 API İsteği sorgu parametreleri: ${options.queryParameters}');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        developer.log('✅ API Yanıtı: ${response.statusCode} - ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        developer.log('❌ API Hatası: ${error.response?.statusCode} - ${error.requestOptions.path}');
        
        if (error.response != null) {
          try {
            developer.log('❌ API Hata detayı: ${error.response?.data}');
          } catch (e) {
            developer.log('❌ API Hata detayı alınamadı: $e');
          }
        }
        
        if (error.response?.statusCode == 401) {
          developer.log('🔴 Yetki hatası (401): Token geçersiz olabilir');
          _authToken = null;
        }
        
        return handler.next(error);
      },
    ));
  }
  
  void setToken(String token) {
    _authToken = token;
    developer.log('🔑 Auth token ayarlandı: ${token.substring(0, min(token.length, 10))}...');
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    developer.log('🔍 ApiClient: GET request to $path');
    if (queryParameters != null) {
      developer.log('🔍 ApiClient: Query parameters: $queryParameters');
    }
    
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      developer.log('🔍 ApiClient: Raw response received from $path');
      developer.log('🔍 ApiClient: Response status code: ${response.statusCode}');
      developer.log('🔍 ApiClient: Response data type: ${response.data.runtimeType}');
      
      // Print the raw response data
      try {
        final jsonString = const JsonEncoder.withIndent('  ').convert(response.data);
        developer.log('🔍 ApiClient: Raw response data: $jsonString');
      } catch (e) {
        developer.log('❌ ApiClient: Error converting response to JSON: $e');
        developer.log('🔍 ApiClient: Raw response: ${response.data}');
      }
      
      if (response.data is Map) {
        developer.log('🔍 ApiClient: Response keys: ${(response.data as Map).keys.join(', ')}');
      } else if (response.data is List) {
        developer.log('🔍 ApiClient: Response is a list with ${(response.data as List).length} items');
      } else {
        developer.log('🔍 ApiClient: Response is neither a Map nor a List: ${response.data}');
      }
      
      try {
        final data = fromJson(response.data);
        developer.log('✅ ApiClient: Successfully parsed response data for $path');
        return ApiResponse<T>(
          success: true,
          message: response.data is Map ? (response.data['message'] ?? 'Success') : 'Success',
          data: data,
          statusCode: response.statusCode ?? 200,
        );
      } catch (e, stackTrace) {
        developer.log('❌ ApiClient: Error parsing response for $path',
            error: e, stackTrace: stackTrace);
        throw FormatException('Failed to parse response: $e');
      }
    } catch (e) {
      developer.log('❌ ApiClient: Exception during GET request to $path', error: e);
      if (e is DioException && e.response != null) {
        developer.log('❌ ApiClient: DioException response: ${e.response?.data}');
        try {
          final jsonString = const JsonEncoder.withIndent('  ').convert(e.response?.data);
          developer.log('🔍 ApiClient: Error response data: $jsonString');
        } catch (jsonError) {
          developer.log('🔍 ApiClient: Error response (not JSON): ${e.response?.data}');
        }
        
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
      developer.log('🔍 ApiClient: POST request to $path with data: $data');
      final response = await _dio.post(path, data: data);
      
      developer.log('✅ ApiClient: POST response received: ${response.data}');
      
      // Check if response data is a Map
      if (response.data is! Map<String, dynamic>) {
        developer.log('⚠️ ApiClient: Response is not a Map: ${response.data}');
        return ApiResponse.error(
          'Invalid response format',
          statusCode: response.statusCode ?? 500,
        );
      }
      
      final responseData = response.data as Map<String, dynamic>;
      
      // Safely extract data field for parsing
      Map<String, dynamic> dataToProcess = {};
      if (responseData.containsKey('data')) {
        if (responseData['data'] is Map<String, dynamic>) {
          dataToProcess = responseData['data'];
        } else {
          developer.log('⚠️ ApiClient: data field is not a Map: ${responseData['data']}');
          dataToProcess = responseData; // Fall back to the whole response
        }
      } else {
        dataToProcess = responseData; // No data field, use the whole response
      }
      
      return ApiResponse<T>(
        success: responseData['status'] == 'success' || responseData.containsKey('success') && responseData['success'] == true,
        message: responseData['message'] ?? 'Success',
        data: fromJson(dataToProcess),
        token: responseData['token'],
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      developer.log('❌ ApiClient: Error in POST request: $e');
      if (e is DioException && e.response != null) {
        developer.log('❌ ApiClient: DioException data: ${e.response?.data}');
        return ApiResponse.error(
          e.response?.data is Map ? e.response?.data['message'] ?? e.message ?? 'Error occurred' : e.message ?? 'Error occurred',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
      return ApiResponse.error(e.toString());
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
