import 'package:dio/dio.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/services/storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio();
  
  // Giriş yapar ve token'ı saklar
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        if (data is Map && data.containsKey('token')) {
          final token = data['token'] as String;
          await _storageService.saveAuthToken(token);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  // Kullanıcıyı çıkış yapar
  Future<void> logout() async {
    await _storageService.deleteAuthToken();
  }
  
  // Kullanıcının giriş yapıp yapmadığını kontrol eder
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }
  
  // Token'ı alır
  Future<String?> getToken() async {
    return await _storageService.getAuthToken();
  }
} 