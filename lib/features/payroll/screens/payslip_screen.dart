import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/models/user_model.dart';

class PayslipScreen extends StatelessWidget {
  final UserModel user;

  const PayslipScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Salary & Payslips'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Highlight Net Salary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(7, 47, 95, 0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LATEST NET PAYOUT', style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                const Text('₹ 78,450.00', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('September 2026 • Credited to HDFC Bank ****4120', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const Divider(height: 24, color: Colors.white24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gross Earnings', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text('₹ 88,200.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Deductions (PF/Tax)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text('₹ 9,750.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Available Payslips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),

          _buildPayslipMonthItem(
            context: context,
            month: 'September 2026',
            payoutDate: 'Paid on 30-Sep-2026',
            amount: '₹ 78,450.00',
          ),
          _buildPayslipMonthItem(
            context: context,
            month: 'August 2026',
            payoutDate: 'Paid on 31-Aug-2026',
            amount: '₹ 78,450.00',
          ),
          _buildPayslipMonthItem(
            context: context,
            month: 'July 2026',
            payoutDate: 'Paid on 31-Jul-2026',
            amount: '₹ 76,200.00',
          ),
          _buildPayslipMonthItem(
            context: context,
            month: 'June 2026',
            payoutDate: 'Paid on 30-Jun-2026',
            amount: '₹ 76,200.00',
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipMonthItem({
    required BuildContext context,
    required String month,
    required String payoutDate,
    required String amount,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(payoutDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.download, size: 20, color: AppColors.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading payslip for $month (Encrypted PDF)...'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
