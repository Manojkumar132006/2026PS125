import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'transfer_modal.dart';
import 'receive_modal.dart';

class BalanceCard extends StatelessWidget {
  final SolanaService service;

  const BalanceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final user = service.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF141927),
            Color(0xFF0D101A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.textDim),
                onPressed: () => service.refreshBalance(),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Balance Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '◎ ${user.solBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'SOL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Fee Sponsorship Pill (Wise / Phantom transparency)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.isGasSponsored
                  ? AppColors.emerald.withValues(alpha: 0.12)
                  : AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: user.isGasSponsored
                    ? AppColors.emerald.withValues(alpha: 0.3)
                    : AppColors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isGasSponsored ? Icons.bolt_rounded : Icons.account_balance_wallet_rounded,
                  size: 14,
                  color: user.isGasSponsored ? AppColors.emerald : AppColors.amber,
                ),
                const SizedBox(width: 5),
                Text(
                  user.isGasSponsored
                      ? '⚡ Gas-Free: 100% Sponsored by Org'
                      : 'User Pays Gas Fees',
                  style: TextStyle(
                    color: user.isGasSponsored ? AppColors.emerald : AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Quick Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickActionBtn(
                icon: Icons.arrow_upward_rounded,
                label: 'Send',
                color: AppColors.primary,
                onTap: () => showTransferModal(context, service),
              ),
              _QuickActionBtn(
                icon: Icons.arrow_downward_rounded,
                label: 'Receive',
                color: AppColors.cyan,
                onTap: () => showReceiveModal(context, service),
              ),
              _QuickActionBtn(
                icon: Icons.add_moderator_rounded,
                label: 'Grant',
                color: AppColors.purple,
                onTap: () => showTransferModal(context, service, isGrantMode: true),
              ),
              _QuickActionBtn(
                icon: service.isLoading ? Icons.hourglass_top_rounded : Icons.water_drop_rounded,
                label: 'Airdrop',
                color: AppColors.emerald,
                onTap: service.isLoading
                    ? null
                    : () async {
                        final ok = await service.requestAirdrop();
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Received ◎ 1.0 SOL Devnet Airdrop!'),
                              backgroundColor: AppColors.bgCard,
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
