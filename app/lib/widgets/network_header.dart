import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class NetworkHeader extends StatelessWidget implements PreferredSizeWidget {
  final SolanaService service;

  const NetworkHeader({super.key, required this.service});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Solana Identity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Devnet',
              style: TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        // Sponsored Gas Indicator / Toggle
        IconButton(
          tooltip: service.isFeeSponsored ? 'Gas Sponsored (0 SOL)' : 'User Pays Gas',
          icon: Icon(
            Icons.local_gas_station_rounded,
            color: service.isFeeSponsored ? AppColors.emerald : AppColors.textDim,
            size: 20,
          ),
          onPressed: () {
            service.toggleFeeSponsorship(!service.isFeeSponsored);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(service.isFeeSponsored ? 'Gas Sponsored: User pays 0 SOL' : 'User Pays Gas Enabled'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.bgCard,
              ),
            );
          },
        ),

        // Copy Program ID
        IconButton(
          tooltip: 'Copy Program ID',
          icon: const Icon(Icons.copy_rounded, color: AppColors.cyan, size: 18),
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: SolanaService.programId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Program ID copied'),
                duration: Duration(seconds: 1),
                backgroundColor: AppColors.bgCard,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
