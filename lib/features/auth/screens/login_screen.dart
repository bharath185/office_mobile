import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _empCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _storage = SecureStorageService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final savedCode = await _storage.getSavedEmpCode();
      if (savedCode != null && savedCode.isNotEmpty && mounted) {
        _empCodeController.text = savedCode;
      } else {
        _empCodeController.text = 'RIM-887';
      }
      if (_passwordController.text.isEmpty) {
        _passwordController.text = 'Bharath@123';
      }
      final canBio = await _authService.canCheckBiometrics();
      final bioEnabled = await _storage.isBiometricEnabled();
      if (mounted) {
        setState(() {
          _hasBiometrics = canBio && bioEnabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _triggerBiometricLogin() async {
    final authenticated = await _authService.authenticateBiometrically();
    if (authenticated && mounted) {
      final user = await _authService.getCachedUser();
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final code = _empCodeController.text.trim();
    final pass = _passwordController.text;

    if (code.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Employee Code and Password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.login(empCode: code, password: pass);
    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      if (_rememberMe) {
        await _storage.setBiometricEnabled(true);
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(user: result['user'])),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Mark
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 133, 219, 0.3),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OfficeConnect',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Employee Self-Service Mobile Portal',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.03),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employee Code / ID',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _empCodeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. EMP1001',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Password',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Remember Me', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contact your HR or IT Admin to reset your password.')),
                              );
                            },
                            child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      PrimaryButton(
                        label: 'Sign In',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),

                      if (_hasBiometrics) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _triggerBiometricLogin,
                          icon: const Icon(Icons.fingerprint, color: AppColors.primary),
                          label: const Text('Sign in with Biometrics', style: TextStyle(color: AppColors.primaryDark)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
