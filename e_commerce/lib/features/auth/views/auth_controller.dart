import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/show_notification.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/user_model.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/repository/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final IAuthRepository _authRepository;
  bool isLoading = false;
  String? error;
  String? _token;
  UserModel? _currentUser;

  // Getters
  String? get token => _token;
  UserModel? get currentUser => _currentUser;

  AuthController(this._authRepository);

  Future<void> checkAuthStatus() async {
    _token = await CacheManager.getToken();
    if (_token != null) {
      _currentUser = await CacheManager.getUserData();
    }
    notifyListeners();
  }

  Future<bool> login(
      String email, String password, BuildContext context) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await _authRepository.login(email, password);

    return result.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
        notifyListeners();

        ShowNotification.showNotification(
          title: 'Login Error',
          message: failure.message,
          context: context,
          onPressFunction: () => Navigator.pop(context),
        );

        return false;
      },
      (response) async {
        isLoading = false;
        if (response.token != null) {
          _token = response.token;
          _currentUser = response.data;

          // Save user data using CacheManager
          await CacheManager.saveToken(response.token!);
          if (_currentUser != null) {
            await CacheManager.saveUserData(_currentUser!);
          }
        }
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await CacheManager.clearCache();
    notifyListeners();
  }

  Future<bool> register(
      String name, String email, String password, BuildContext context) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await _authRepository.register(name, email, password);

    return result.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
        notifyListeners();

        ShowNotification.showNotification(
          title: 'Registration Error',
          message: failure.message,
          context: context,
          onPressFunction: () => Navigator.pop(context),
        );

        return false;
      },
      (response) async {
        isLoading = false;
        if (response.token != null) {
          _token = response.token;
          _currentUser = response.data;

          // Save user data using CacheManager
          await CacheManager.saveToken(response.token!);
          if (_currentUser != null) {
            await CacheManager.saveUserData(_currentUser!);
          }
        }
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> signup(
      String name, String email, String password, BuildContext context) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await _authRepository.signup(name, email, password);

    return result.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
        notifyListeners();

        ShowNotification.showNotification(
          title: 'Registration Error',
          message: failure.message,
          context: context,
          onPressFunction: () => Navigator.pop(context),
        );

        return false;
      },
      (response) async {
        isLoading = false;
        notifyListeners();
        return true;  // Başarılı kaydolmada token saklamıyoruz, sadece başarılı döndürüyoruz
      },
    );
  }
}
