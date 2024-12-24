import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../error/failures.dart';
import '../models/api_response.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl}) : _client = http.Client();

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw NetworkFailure(message: 'Network error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      developer.log('Making POST request to: $url');
      developer.log('Request body: ${json.encode(body)}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: json.encode(body),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      return _handleResponse(response, fromJson);
    } catch (e) {
      developer.log('Network error: $e');
      throw NetworkFailure(message: 'Network error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: json.encode(body),
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw NetworkFailure(message: 'Network error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      throw NetworkFailure(message: 'Network error occurred: ${e.toString()}');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      developer.log('Raw response body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        throw ServerFailure(
          message:
              'Server returned HTML instead of JSON. Server might be down or URL might be incorrect.',
          statusCode: response.statusCode,
        );
      }

      final body = json.decode(response.body);
      developer.log('Decoded response body: $body');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: body['status'] == 'success',
          message: body['message'] ?? '',
          data: fromJson != null && body['data'] != null
              ? fromJson(body['data'])
              : null,
          token: body['token'],
          statusCode: response.statusCode,
        );
      }

      switch (response.statusCode) {
        case 401:
          throw AuthenticationFailure(
              message: body['message'] ?? 'Authentication failed');
        case 400:
          throw ValidationFailure(
              message: body['message'] ?? 'Validation failed');
        default:
          throw ServerFailure(
            message: body['message'] ?? 'Server error occurred',
            statusCode: response.statusCode,
          );
      }
    } catch (e) {
      developer.log('Error handling response: $e');
      if (e is FormatException) {
        throw ServerFailure(
          message: 'Invalid response format from server',
          statusCode: response.statusCode,
        );
      }
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
