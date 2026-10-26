import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';

class ApprovalsScreen extends StatefulWidget {
  final UserModel user;

  const ApprovalsScreen({super.key, required this.user});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAction(String itemTitle, bool isApproved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemTitle has been ${isApproved ? "Approved" : "Rejected"}'),
        backgroundColor: isApproved ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manager Approvals (To-Do)'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Leave Requests (2)'),
            Tab(text: 'Expense Claims (1)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Leaves
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildApprovalCard(
                empName: 'Vikram Sharma',
                empCode: 'EMP1045',
                type: 'Casual Leave (2 Days)',
                details: '23 Oct 2026 - 24 Oct 2026 • Sister wedding in Pune',
                badgeText: 'LEAVE',
                onApprove: () => _handleAction('Leave for Vikram', true),
                onReject: () => _handleAction('Leave for Vikram', false),
              ),
              _buildApprovalCard(
                empName: 'Priya Nambiar',
                empCode: 'EMP1082',
                type: 'Sick Leave (1 Day)',
                details: 'Today, 19 Oct 2026 • Medical prescription attached',
                badgeText: 'LEAVE',
                onApprove: () => _handleAction('Leave for Priya', true),
                onReject: () => _handleAction('Leave for Priya', false),
              ),
            ],
          ),

          // Tab 2: Expenses
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildApprovalCard(
                empName: 'Rahul Deshmukh',
                empCode: 'EMP1012',
                type: 'EXP-0069 • ₹ 3,450.00',
                details: 'Client Onsite Inspection • 2 Bills attached (Fuel & Hotel)',
                badgeText: 'CLAIM',
                onApprove: () => _handleAction('Claim for Rahul', true),
                onReject: () => _handleAction('Claim for Rahul', false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard({
    required String empName,
    required String empCode,
    required String type,
    required String details,
    required String badgeText,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(empName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(empCode, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              StatusBadge(status: badgeText),
            ],
          ),
          const SizedBox(height: 10),
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(details, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
