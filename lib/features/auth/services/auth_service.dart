import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<Map<String, dynamic>> login({
    required String empCode,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {
          'userName': empCode.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final token = data['token'] ?? data['Token'] ?? data['TokenId'] ?? 'dummy_token';
        final refreshToken = data['refreshToken'] ?? data['RefreshToken'];

        await _storage.saveTokens(token: token, refreshToken: refreshToken);
        await _storage.saveEmpCode(empCode.trim());

        final userData = data['User'] ?? data['user'] ?? data;
        final user = UserModel.fromJson(userData);
        await _storage.saveUser(user.toJson());

        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Invalid credentials'};
    } on DioException catch (e) {
      final msg = e.response?.data?['Message'] ?? e.response?.data?['message'] ?? e.message ?? 'Login failed';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> canCheckBiometrics() async {
    final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> authenticateBiometrically() async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access OfficeConnect',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getCachedUser() async {
    final map = await _storage.getUser();
    if (map != null) {
      return UserModel.fromJson(map);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final code = await _storage.getSavedEmpCode();
      if (code != null) {
        await _api.dio.post(ApiEndpoints.logout, data: {'userName': code});
      }
    } catch (_) {}
    await _storage.clearAll();
  }
}
