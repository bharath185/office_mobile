import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/models/user_model.dart';

class CreateExpenseScreen extends StatefulWidget {
  final UserModel user;

  const CreateExpenseScreen({super.key, required this.user});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _purposeController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();

  String _claimCategory = 'GENERAL';
  final List<Map<String, dynamic>> _bills = [];

  bool get _isHeaderLocked => _bills.isNotEmpty;

  double get _totalBillsAmount {
    double total = 0.0;
    for (var b in _bills) {
      total += (b['amount'] as double? ?? 0.0);
    }
    return total;
  }

  void _addBillDialog() {
    final billNoController = TextEditingController();
    final billAmountController = TextEditingController();
    String billCat = 'EXP_GEN';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Invoice / Bill Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: billNoController, decoration: const InputDecoration(labelText: 'Bill / Invoice No', hintText: 'INV-1001')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: billCat,
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  items: const [
                    DropdownMenuItem(value: 'EXP_GEN', child: Text('General Expense')),
                    DropdownMenuItem(value: 'TRANS & ACC', child: Text('Travel & Hotel')),
                    DropdownMenuItem(value: 'FOOD', child: Text('Food & Meals')),
                    DropdownMenuItem(value: 'MIL', child: Text('Mileage (Own Vehicle)')),
                  ],
                  onChanged: (v) => billCat = v ?? 'EXP_GEN',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: billAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Bill Amount (₹)', hintText: '0.00'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 42)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera simulated: Receipt image attached')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Snap Receipt Photo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                final amt = double.tryParse(billAmountController.text) ?? 0.0;
                if (amt <= 0) return;
                setState(() {
                  _bills.add({
                    'billNo': billNoController.text.trim().isEmpty ? 'INV-${_bills.length + 1}' : billNoController.text.trim(),
                    'category': billCat,
                    'amount': amt,
                    'hasProof': true,
                  });
                  _amountController.text = _totalBillsAmount.toStringAsFixed(2);
                });
                Navigator.pop(context);
              },
              child: const Text('Add Bill'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Expense Claim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isHeaderLocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF92400E), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Claim Details Locked: ${_bills.length} bills uploaded. Total is calculated from bills (₹ ${_totalBillsAmount.toStringAsFixed(2)}).',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Section 1: Header Details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Claim Header Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _purposeController,
                    enabled: !_isHeaderLocked,
                    decoration: const InputDecoration(labelText: 'Purpose / Reason *', hintText: 'e.g. Client meeting in Mumbai'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    enabled: !_isHeaderLocked,
                    decoration: const InputDecoration(labelText: 'Location', hintText: 'City / Office location'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _claimCategory,
                    decoration: const InputDecoration(labelText: 'Claim Category *'),
                    items: const [
                      DropdownMenuItem(value: 'GENERAL', child: Text('GENERAL')),
                      DropdownMenuItem(value: 'PROJECT', child: Text('PROJECT')),
                      DropdownMenuItem(value: 'SALES', child: Text('SALES')),
                    ],
                    onChanged: _isHeaderLocked ? null : (v) => setState(() => _claimCategory = v ?? 'GENERAL'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    enabled: !_isHeaderLocked,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Total Claim Amount (₹) *',
                      hintText: '0.00',
                      suffixText: _isHeaderLocked ? '(From Bills)' : '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Invoices & Receipts
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Uploaded Invoices (${_bills.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Bill'),
                        onPressed: _addBillDialog,
                      ),
                    ],
                  ),
                  if (_bills.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('No invoices attached. Click Add Bill to upload receipts.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _bills.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (ctx, i) {
                        final b = _bills[i];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b['billNo']} • ${b['category']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                const Text('Receipt image attached', style: TextStyle(fontSize: 10, color: AppColors.success)),
                              ],
                            ),
                            Row(
                              children: [
                                Text('₹ ${(b['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  onPressed: () {
                                    setState(() {
                                      _bills.removeAt(i);
                                      if (_bills.isNotEmpty) {
                                        _amountController.text = _totalBillsAmount.toStringAsFixed(2);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            PrimaryButton(
              label: 'Submit Claim for Approval',
              onPressed: () {
                if (_purposeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Purpose / Reason')));
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense claim submitted successfully!'), backgroundColor: AppColors.success),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
