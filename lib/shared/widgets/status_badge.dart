import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final cleanStatus = status.trim().toUpperCase();
    Color bg;
    Color text;
    Color dotColor;

    switch (cleanStatus) {
      case 'APPROVED':
      case 'SYNCED':
      case 'SETTLED':
      case 'ACTIVE':
      case 'PRESENT':
        bg = AppColors.emerald50;
        text = const Color(0xFF047857);
        dotColor = const Color(0xFF10B981);
        break;
      case 'APPLIED':
      case 'PENDING':
      case 'PENDING SYNC':
      case 'WAITING':
        bg = AppColors.amber50;
        text = const Color(0xFFB45309);
        dotColor = const Color(0xFFF59E0B);
        break;
      case 'REJECTED':
      case 'FAILED':
      case 'INACTIVE':
      case 'ABSENT':
        bg = AppColors.rose50;
        text = const Color(0xFFB91C1C);
        dotColor = const Color(0xFFEF4444);
        break;
      case 'PAID':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        dotColor = const Color(0xFF3B82F6);
        break;
      case 'DRAFT':
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        dotColor = const Color(0xFF94A3B8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            cleanStatus,
            style: TextStyle(
              color: text,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
