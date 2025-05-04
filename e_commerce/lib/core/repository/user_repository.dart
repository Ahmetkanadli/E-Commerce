import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/models/user_model.dart';
import 'package:e_commerce/core/models/card_model.dart';
import 'package:e_commerce/core/error/failure.dart';
import 'package:e_commerce/core/repository/base_repository.dart';
import 'package:e_commerce/core/models/api_response.dart';
import 'dart:developer' as developer;
import 'dart:convert';

abstract class IUserRepository {
  Future<Either<Failure, UserModel>> getUserProfile();
  Future<Either<Failure, UserModel>> updateUserProfile(Map<String, dynamic> userData);
  Future<Either<Failure, bool>> updatePassword(String currentPassword, String newPassword);
  Future<Either<Failure, bool>> deleteUserAccount();
  Future<Either<Failure, List<CardModel>>> getUserCards();
  Future<Either<Failure, CardModel>> addCard(Map<String, dynamic> cardData);
  Future<Either<Failure, CardModel>> updateCard(String cardId, Map<String, dynamic> cardData);
  Future<Either<Failure, bool>> deleteCard(String cardId);
}

class UserRepository extends BaseRepository implements IUserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);
  
  // Handle API response and convert to Either type
  Future<Either<Failure, T>> handleResponse<T>(
    ApiResponse<dynamic> response,
    T Function(dynamic) dataConverter,
  ) async {
    developer.log('🔵 handleResponse: Response başarı durumu: ${response.success}, statusCode: ${response.statusCode}');
    developer.log('🔵 handleResponse: Message: ${response.message}');
    developer.log('🔵 handleResponse: Data type: ${response.data?.runtimeType}');
    
    if (response.data != null) {
      try {
        final jsonString = const JsonEncoder.withIndent('  ').convert(response.data);
        developer.log('🔵 handleResponse: Data içeriği: $jsonString');
      } catch (e) {
        developer.log('🔵 handleResponse: Data JSON formatına dönüştürülemedi: $e');
      }
    }
    
    if (response.success) {
      try {
        final result = dataConverter(response.data);
        developer.log('✅ handleResponse: Veri başarıyla dönüştürüldü, tür: ${result.runtimeType}');
        return Right(result);
      } catch (e, stackTrace) {
        developer.log('🔴 handleResponse: Error converting data', error: e, stackTrace: stackTrace);
        return Left(Failure(
          message: 'Veri dönüştürme hatası: ${e.toString()}',
          statusCode: response.statusCode,
        ));
      }
    } else {
      developer.log('🔴 handleResponse: API başarısız yanıt verdi');
      return Left(Failure(
        message: response.message ?? 'Bilinmeyen hata',
        statusCode: response.statusCode,
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> getUserProfile() async {
    try {
      developer.log('🔵 Kullanıcı profili getiriliyor: ${ApiConstants.getUserProfileUrl()}');
      
      final response = await _apiClient.get(
        ApiConstants.getUserProfileUrl(),
        fromJson: (data) => data,
      );
      
      developer.log('🔵 API yanıtı alındı, işleniyor...');

      return handleResponse<UserModel>(
        response,
        (data) {
          // API returns data.user structure
          if (data is Map<String, dynamic>) {
            developer.log('🔵 API yanıt yapısı: ${data.keys.join(', ')}');
            
            // Extract the user data
            Map<String, dynamic> userData = {};
            
            if (data.containsKey('user')) {
              userData = data['user'] is Map ? Map<String, dynamic>.from(data['user']) : {};
              developer.log('🔵 User verisi bulundu, içerik: ${userData.keys.join(', ')}');
            } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('user')) {
              // Handle nested data.user structure
              userData = data['data']['user'] is Map ? Map<String, dynamic>.from(data['data']['user']) : {};
              developer.log('🔵 Nested user verisi bulundu, içerik: ${userData.keys.join(', ')}');
            } else {
              userData = data;
              developer.log('🔵 Tüm veri user verisi olarak kullanılıyor');
            }
            
            // Extract cart and stats 
            Map<String, dynamic>? cartData = null;
            Map<String, dynamic>? statsData = null;
            
            // Try to get cart and stats from different locations
            if (data.containsKey('cart') && data['cart'] is Map) {
              cartData = Map<String, dynamic>.from(data['cart']);
              developer.log('🔵 Root seviyesinde cart verisi bulundu');
            } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('cart')) {
              cartData = Map<String, dynamic>.from(data['data']['cart']);
              developer.log('🔵 data.cart seviyesinde cart verisi bulundu');
            }
            
            if (data.containsKey('stats') && data['stats'] is Map) {
              statsData = Map<String, dynamic>.from(data['stats']);
              developer.log('🔵 Root seviyesinde stats verisi bulundu');
            } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('stats')) {
              statsData = Map<String, dynamic>.from(data['data']['stats']);
              developer.log('🔵 data.stats seviyesinde stats verisi bulundu');
            }
            
            // Add cart and stats to userData if found
            if (cartData != null) {
              userData['cart'] = cartData;
              developer.log('🔵 Cart verisi user modele eklendi');
            }
            
            if (statsData != null) {
              userData['stats'] = statsData;
              developer.log('🔵 Stats verisi user modele eklendi');
            }
            
            developer.log('🔵 UserModel oluşturuluyor, veriler: ${userData.keys.join(', ')}');
            
            try {
              final model = UserModel.fromJson(userData);
              developer.log('✅ UserModel başarıyla oluşturuldu: ${model.name}');
              return model;
            } catch (e, stackTrace) {
              developer.log('🔴 UserModel oluşturulurken hata oluştu', error: e, stackTrace: stackTrace);
              rethrow;
            }
          } else {
            // Fallback to direct parsing if structure is different
            developer.log('🔴 Veri Map değil, tür: ${data.runtimeType}');
            return UserModel.fromJson({});
          }
        },
      );
    } catch (e, stackTrace) {
      developer.log('🔴 Kullanıcı profili getirilirken hata oluştu', error: e, stackTrace: stackTrace);
      return Left(Failure(message: 'Kullanıcı bilgileri alınamadı: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      developer.log('🔵 Updating user profile: $userData');
      final response = await _apiClient.patch(
        ApiConstants.getUserProfileUrl(),
        body: userData,
        fromJson: (data) => data,
      );

      return handleResponse<UserModel>(
        response,
        (data) => UserModel.fromJson(data),
      );
    } catch (e) {
      developer.log('🔴 Error updating user profile: $e');
      return Left(Failure(message: 'Kullanıcı bilgileri güncellenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePassword(String currentPassword, String newPassword) async {
    try {
      developer.log('🔵 Updating user password');
      final response = await _apiClient.patch(
        ApiConstants.getUserUpdatePasswordUrl(),
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        fromJson: (data) => data,
      );

      return handleResponse<bool>(
        response,
        (_) => true, // Başarılı yanıt alındığında true döndür
      );
    } catch (e) {
      developer.log('🔴 Error updating password: $e');
      return Left(Failure(message: 'Şifre güncellenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUserAccount() async {
    try {
      developer.log('🔵 Deleting user account');
      final response = await _apiClient.delete(
        ApiConstants.getUserProfileUrl(),
        fromJson: (data) => data,
      );

      return handleResponse<bool>(
        response,
        (_) => true, // Başarılı yanıt alındığında true döndür
      );
    } catch (e) {
      developer.log('🔴 Error deleting user account: $e');
      return Left(Failure(message: 'Hesap silinemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CardModel>>> getUserCards() async {
    try {
      developer.log('🔵 Fetching user cards');
      final response = await _apiClient.get(
        ApiConstants.getUserCardsUrl(),
        fromJson: (data) => data,
      );

      return handleResponse<List<CardModel>>(
        response,
        (data) {
          developer.log('🔵 Card data structure: ${data.runtimeType}');
          
          if (data is List) {
            return data.map((card) => CardModel.fromJson(card)).toList();
          } else if (data is Map<String, dynamic>) {
            // Check for cards in data field
            if (data.containsKey('cards') && data['cards'] is List) {
              return (data['cards'] as List).map((card) => CardModel.fromJson(card)).toList();
            } 
            // Check for data.cards structure
            else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('cards') && data['data']['cards'] is List) {
              return (data['data']['cards'] as List).map((card) => CardModel.fromJson(card)).toList();
            }
            // Check if the whole response is a single card
            else if (data.containsKey('cardNumber')) {
              return [CardModel.fromJson(data)];
            }
            // Check user structure as fallback
            else if (data.containsKey('user') && data['user'] is Map) {
              final userData = data['user'] as Map<String, dynamic>;
              
              // Check if savedCards exists in the user data
              if (userData.containsKey('savedCards') && userData['savedCards'] is List) {
                developer.log('🔵 Found ${(userData['savedCards'] as List).length} saved cards in user profile');
                return (userData['savedCards'] as List)
                    .map((card) => CardModel.fromJson(card))
                    .toList();
              }
            }
          }
          
          developer.log('🔴 Card data structure not recognized, returning empty list');
          return <CardModel>[];
        },
      );
    } catch (e) {
      developer.log('🔴 Error fetching user cards: $e');
      return Left(Failure(message: 'Kartlar alınamadı: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CardModel>> addCard(Map<String, dynamic> cardData) async {
    try {
      developer.log('🔵 Adding new card: $cardData');
      final response = await _apiClient.post(
        ApiConstants.getUserCardsUrl(),
        data: cardData,
        fromJson: (data) => data,
      );

      return handleResponse<CardModel>(
        response,
        (data) => CardModel.fromJson(data),
      );
    } catch (e) {
      developer.log('🔴 Error adding card: $e');
      return Left(Failure(message: 'Kart eklenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CardModel>> updateCard(String cardId, Map<String, dynamic> cardData) async {
    try {
      developer.log('🔵 Updating card $cardId: $cardData');
      final response = await _apiClient.patch(
        ApiConstants.getUserCardUrl(cardId),
        body: cardData,
        fromJson: (data) => data,
      );

      return handleResponse<CardModel>(
        response,
        (data) => CardModel.fromJson(data),
      );
    } catch (e) {
      developer.log('🔴 Error updating card: $e');
      return Left(Failure(message: 'Kart güncellenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteCard(String cardId) async {
    try {
      developer.log('🔵 Deleting card $cardId');
      final response = await _apiClient.delete(
        ApiConstants.getUserCardUrl(cardId),
        fromJson: (data) => data,
      );

      return handleResponse<bool>(
        response,
        (_) => true, // Başarılı yanıt alındığında true döndür
      );
    } catch (e) {
      developer.log('🔴 Error deleting card: $e');
      return Left(Failure(message: 'Kart silinemedi: ${e.toString()}'));
    }
  }
} 