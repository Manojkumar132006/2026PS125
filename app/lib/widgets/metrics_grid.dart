import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricsGrid extends StatelessWidget {
  final bool isFeeSponsored;

  const MetricsGrid({super.key, required this.isFeeSponsored});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatBadge(
            label: 'Identities',
            value: '2 PDAs',
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: 'Asset',
            value: 'PDA #1',
            color: AppColors.cyan,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: 'RBAC',
            value: 'Bitmask',
            color: AppColors.purple,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: 'Fee',
            value: isFeeSponsored ? '0 SOL' : 'User SOL',
            color: isFeeSponsored ? AppColors.emerald : AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
