import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final Map<String, dynamic> _memoryCache = {};

  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'cached_user_profile';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keySavedEmpCode = 'saved_emp_code';

  Future<void> saveTokens({required String token, String? refreshToken}) async {
    _memoryCache[_keyToken] = token;
    if (refreshToken != null) _memoryCache[_keyRefreshToken] = refreshToken;
    try {
      await _secureStorage.write(key: _keyToken, value: token);
      if (refreshToken != null) {
        await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
      }
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        if (refreshToken != null) {
          await prefs.setString(_keyRefreshToken, refreshToken);
        }
      } catch (_) {}
    }
  }

  Future<String?> getToken() async {
    if (_memoryCache.containsKey(_keyToken)) {
      return _memoryCache[_keyToken] as String?;
    }
    try {
      final val = await _secureStorage.read(key: _keyToken);
      if (val != null) {
        _memoryCache[_keyToken] = val;
        return val;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyToken);
      if (val != null) _memoryCache[_keyToken] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memoryCache.containsKey(_keyRefreshToken)) {
      return _memoryCache[_keyRefreshToken] as String?;
    }
    try {
      final val = await _secureStorage.read(key: _keyRefreshToken);
      if (val != null) {
        _memoryCache[_keyRefreshToken] = val;
        return val;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyRefreshToken);
      if (val != null) _memoryCache[_keyRefreshToken] = val;
      return val;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    _memoryCache[_keyUser] = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getUser() async {
    if (_memoryCache.containsKey(_keyUser)) {
      return _memoryCache[_keyUser] as Map<String, dynamic>?;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyUser);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _memoryCache[_keyUser] = map;
        return map;
      }
    } catch (_) {}
    return null;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _memoryCache[_keyBiometricEnabled] = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricEnabled, enabled);
    } catch (_) {}
  }

  Future<bool> isBiometricEnabled() async {
    if (_memoryCache.containsKey(_keyBiometricEnabled)) {
      return _memoryCache[_keyBiometricEnabled] as bool? ?? false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyBiometricEnabled) ?? false;
      _memoryCache[_keyBiometricEnabled] = enabled;
      return enabled;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveEmpCode(String empCode) async {
    _memoryCache[_keySavedEmpCode] = empCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySavedEmpCode, empCode);
    } catch (_) {}
  }

  Future<String?> getSavedEmpCode() async {
    if (_memoryCache.containsKey(_keySavedEmpCode)) {
      return _memoryCache[_keySavedEmpCode] as String?;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_keySavedEmpCode);
      if (code != null) _memoryCache[_keySavedEmpCode] = code;
      return code;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken);
    } catch (_) {}
  }
}
