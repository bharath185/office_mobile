import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import 'create_expense_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  final UserModel user;

  const ExpenseListScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Claims'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateExpenseScreen(user: user)),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateExpenseScreen(user: user)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat Summary Cards
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Claimed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('₹ 14,850.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      const Text('6 claims this month', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Approved & Settled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('₹ 12,400.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                      const SizedBox(height: 2),
                      const Text('Paid to bank account', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('My Expense Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),

          // Claim 1
          _buildExpenseItem(
            claimNo: 'EXP/26-27/0068',
            purpose: 'Client Site Visit & Travel Expenses',
            category: 'PROJECT',
            amount: '2,450.00',
            date: '16 Oct 2026',
            status: 'APPROVED',
            invoicesCount: 2,
          ),
          // Claim 2
          _buildExpenseItem(
            claimNo: 'EXP/26-27/0067',
            purpose: 'Annual Team Dinner & Refreshments',
            category: 'GENERAL',
            amount: '3,800.00',
            date: '12 Oct 2026',
            status: 'SETTLED',
            invoicesCount: 1,
          ),
          // Claim 3
          _buildExpenseItem(
            claimNo: 'EXP/26-27/0065',
            purpose: 'Customer Product Demo Travel',
            category: 'SALES',
            amount: '1,200.00',
            date: '08 Oct 2026',
            status: 'APPLIED',
            invoicesCount: 1,
          ),
          // Claim 4
          _buildExpenseItem(
            claimNo: 'Draft #69',
            purpose: 'Local Conveyance & Fuel',
            category: 'GENERAL',
            amount: '650.00',
            date: 'Today',
            status: 'DRAFT',
            invoicesCount: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem({
    required String claimNo,
    required String purpose,
    required String category,
    required String amount,
    required String date,
    required String status,
    required int invoicesCount,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(claimNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Text(purpose, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                    child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  Text('$invoicesCount ${invoicesCount == 1 ? "Bill" : "Bills"} attached', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              Text('₹ $amount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
