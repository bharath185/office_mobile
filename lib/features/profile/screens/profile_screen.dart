import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = SecureStorageService();
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _storage.isBiometricEnabled();
    setState(() => _biometricEnabled = bio);
  }

  void _showDigitalIdDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('OfficeConnect Digital ID Badge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                QrImageView(
                  data: 'OFFICECONNECT:${widget.user.empCode}:${widget.user.empId}',
                  version: QrVersions.auto,
                  size: 180.0,
                ),
                const SizedBox(height: 16),
                Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${widget.user.designation} • ${widget.user.empCode}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${widget.user.designation} • ${widget.user.empCode}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(widget.user.department, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 28),
                  tooltip: 'View Digital ID',
                  onPressed: _showDigitalIdDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real Employment Details Card
          const Text('Employment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildInfoRow('Company', widget.user.company),
                const Divider(height: 16),
                _buildInfoRow('Employee Code', widget.user.empCode),
                const Divider(height: 16),
                _buildInfoRow('Department', widget.user.department),
                const Divider(height: 16),
                _buildInfoRow('Designation', widget.user.designation),
                if (widget.user.email.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildInfoRow('Email Address', widget.user.email),
                ],
                if (widget.user.mobileNo.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildInfoRow('Mobile Number', widget.user.mobileNo),
                ],
                if (widget.user.reportEmpCode != null) ...[
                  const Divider(height: 16),
                  _buildInfoRow('Reporting Manager', widget.user.reportEmpCode!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Security & Hardware Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Authentication (Face/Touch ID)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Fast secure sign-in without password', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  value: _biometricEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _biometricEnabled = val);
                    await _storage.setBiometricEnabled(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_outlined, size: 20, color: AppColors.textSecondary),
                  title: const Text('Server Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('https://newofficeconnect.3dcad-global.com:8099 (Production)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  trailing: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _storage.clearAll();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out of OfficeConnect'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'OfficeConnect Mobile v1.0.0 (Production Live)',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
