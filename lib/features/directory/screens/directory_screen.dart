import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/realtime_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/models/user_model.dart';

class DirectoryScreen extends StatefulWidget {
  final UserModel user;

  const DirectoryScreen({super.key, required this.user});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchController = TextEditingController();
  final RealtimeService _realtime = RealtimeService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _loadDirectory();
    _searchController.addListener(_filterDirectory);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDirectory);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      final emps = await _realtime.fetchEmployeeDirectory(widget.user.loginId);
      if (mounted) {
        setState(() {
          _allEmployees = emps;
          _filteredEmployees = emps;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterDirectory() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _allEmployees;
      } else {
        _filteredEmployees = _allEmployees.where((emp) {
          final first = emp['FirstName']?.toString().toLowerCase() ?? '';
          final last = emp['LastName']?.toString().toLowerCase() ?? '';
          final name = '$first $last';
          final code = emp['EmpCode']?.toString().toLowerCase() ?? '';
          final desig = emp['Designation']?.toString().toLowerCase() ?? '';
          final dept = emp['DeptName']?.toString().toLowerCase() ?? '';

          return name.contains(query) || code.contains(query) || desig.contains(query) || dept.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), "")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Colleague Directory (${_allEmployees.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDirectory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, role, department or code...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Text(
                          _allEmployees.isEmpty ? 'Loading directory...' : 'No colleagues match "$_searchController.text"',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDirectory,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _filteredEmployees.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final emp = _filteredEmployees[i];
                            final first = emp['FirstName']?.toString() ?? '';
                            final last = emp['LastName']?.toString() ?? '';
                            final fullName = '$first $last'.trim().isNotEmpty ? '$first $last'.trim() : 'Employee';
                            final code = emp['EmpCode']?.toString() ?? '';
                            final desig = emp['Designation']?.toString() ?? 'Team Member';
                            final dept = emp['DeptName']?.toString() ?? 'General';
                            final phone = emp['MobileNo']?.toString() ?? '';
                            final email = emp['EmailId']?.toString() ?? '';

                            return AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fullName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (code.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  code,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          desig,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          dept,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (phone.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                                          onPressed: () => _makeCall(phone),
                                        ),
                                      if (email.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                                          onPressed: () => _sendEmail(email),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
