import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserModel? _currentUser;
  String? _authToken;

  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_session');
    final token = prefs.getString('auth_token');

    if (userJson != null && token != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        _authToken = token;
        notifyListeners();
      } catch (e) {
        debugPrint('Error restoring session: $e');
      }
    }
  }

  Future<void> loginSuccess(UserModel user, String token) async {
    _currentUser = user;
    _authToken = token;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toJson()));
    await prefs.setString('auth_token', token);

    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.remove('auth_token');

    notifyListeners();
  }

  /// Helper for quick role switching during demo / testing
  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser != null) {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        username: _currentUser!.username,
        fullName: _currentUser!.fullName,
        role: newRole,
        pairingCode: _currentUser!.pairingCode,
        phoneNumber: _currentUser!.phoneNumber,
      );
      await loginSuccess(updatedUser, _authToken ?? 'demo_token');
    }
  }
}
