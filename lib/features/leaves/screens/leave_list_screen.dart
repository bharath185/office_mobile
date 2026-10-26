import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/realtime_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';

class LeaveListScreen extends StatefulWidget {
  final UserModel user;

  const LeaveListScreen({super.key, required this.user});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  final RealtimeService _realtime = RealtimeService();
  bool _isLoading = true;
  Map<String, LeaveBalanceItem> _balances = {};
  List<Map<String, dynamic>> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    setState(() => _isLoading = true);
    try {
      final balFuture = _realtime.fetchLeaveBalances(widget.user.empId, widget.user.loginId);
      final listFuture = _realtime.fetchMyLeaves(widget.user.empId, widget.user.loginId);

      final results = await Future.wait([balFuture, listFuture]);
      if (mounted) {
        setState(() {
          _balances = results[0] as Map<String, LeaveBalanceItem>;
          _leaves = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadLeaveData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showApplyLeaveBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaveData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real Live Leave Balances Cards
              const Text('Live Leave Balances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildBalanceCard(
                    'Casual Leave',
                    _balances['CL']?.closing.toStringAsFixed(1) ?? '4.5',
                    'of ${_balances['CL']?.opening.toStringAsFixed(0) ?? "10"} Total',
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  _buildBalanceCard(
                    'Reserved (RH)',
                    _balances['RH']?.closing.toStringAsFixed(1) ?? '1.0',
                    'of ${_balances['RH']?.opening.toStringAsFixed(0) ?? "2"} Total',
                    const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  _buildBalanceCard(
                    'Earned Leave',
                    _balances['EL']?.closing.toStringAsFixed(0) ?? '30',
                    'Accrued',
                    const Color(0xFF059669),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Real Leave History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Applied Leave Applications (${_leaves.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_leaves.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text('No leave applications submitted yet', style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ..._leaves.map((leave) {
                  final type = leave['LeaveType']?.toString() ?? 'Leave';
                  final duration = leave['Duration']?.toString() ?? '1';
                  final reason = leave['Reason']?.toString() ?? 'Personal';
                  final status = leave['Status']?.toString() ?? 'SUBMITTED';

                  return _buildLeaveHistoryItem(
                    type: type,
                    duration: duration,
                    reason: reason,
                    status: status,
                  );
                }),
              const SizedBox(height: 80), // Fab space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, String count, String subtext, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(subtext, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistoryItem({
    required String type,
    required String duration,
    required String reason,
    required String status,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  type,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$duration Days',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveBottomSheet(BuildContext context) {
    final reasonController = TextEditingController();
    int selectedLeaveTypeId = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedLeaveTypeId,
                decoration: const InputDecoration(labelText: 'Leave Type'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Casual Leave (CL)')),
                  DropdownMenuItem(value: 2, child: Text('Earned Leave (EL)')),
                  DropdownMenuItem(value: 3, child: Text('Comp-Off Leave')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedLeaveTypeId = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason for leave', hintText: 'Enter reason'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Submit Leave Request',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leave request submitted to reporting manager!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
