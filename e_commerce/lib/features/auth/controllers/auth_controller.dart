import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/show_notification.dart';
import '../../../core/models/api_response.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final IAuthRepository _authRepository;
  bool isLoading = false;
  String? error;
  String? _token;

  // Getter for token
  String? get token => _token;

  AuthController(this._authRepository);

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
          // Save token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response.token!);
        }
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
          // Save token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response.token!);
        }
        notifyListeners();
        return true;
      },
    );
  }
}
