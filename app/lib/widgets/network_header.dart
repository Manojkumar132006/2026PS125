import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class NetworkHeader extends StatelessWidget {
  final SolanaService service;

  const NetworkHeader({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo & Title
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Solana Identity & RBAC',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'MVP v0.1.0',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'PDA Assets • Self-Sovereign Identity • Bitmask RBAC • Gas Sponsorship',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          const Spacer(),

          // Program ID Chip with Copy
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: SolanaService.programId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Program ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppColors.bgCard,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Text('Program: ', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  Text(
                    '${SolanaService.programId.substring(0, 6)}...${SolanaService.programId.substring(SolanaService.programId.length - 6)}',
                    style: AppTheme.mono(color: AppColors.cyan, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, color: AppColors.textDim, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sponsored Gas Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: service.isFeeSponsored
                  ? AppColors.emerald.withOpacity(0.12)
                  : AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: service.isFeeSponsored
                    ? AppColors.emerald.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_gas_station_rounded,
                  size: 16,
                  color: service.isFeeSponsored ? AppColors.emerald : AppColors.textDim,
                ),
                const SizedBox(width: 6),
                Text(
                  service.isFeeSponsored ? 'Gas Sponsored (0 SOL)' : 'User Pays Gas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: service.isFeeSponsored ? AppColors.emerald : AppColors.textDim,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: service.isFeeSponsored,
                  onChanged: (val) => service.toggleFeeSponsorship(val),
                  activeColor: AppColors.emerald,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Devnet Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Solana Devnet',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
