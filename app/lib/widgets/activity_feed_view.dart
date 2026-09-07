import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class ActivityFeedView extends StatelessWidget {
  final SolanaService service;

  const ActivityFeedView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final activities = service.activities;

    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.textDim),
              const SizedBox(height: 12),
              const Text('No transaction activity yet', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Transfers, grants, and airdrops will appear here.', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'On-Chain Activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = activities[index];
            return _ActivityCard(
              item: item,
              onTap: () => _showReceiptModal(context, item),
            );
          },
        ),
      ],
    );
  }

  void _showReceiptModal(BuildContext context, ActivityItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderHover,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getTypeColor(item.type).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getTypeIcon(item.type), color: _getTypeColor(item.type), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                        Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Receipt Data
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _ReceiptRow(
                      label: 'Status',
                      value: item.isRejected ? 'REJECTED (Constraint Enforced)' : 'CONFIRMED ON DEVNET',
                      color: item.isRejected ? AppColors.rose : AppColors.emerald,
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _ReceiptRow(
                      label: 'Network Fee',
                      value: item.isGasSponsored ? '◎ 0.00 SOL (Sponsored)' : '◎ 0.000005 SOL',
                      color: item.isGasSponsored ? AppColors.emerald : AppColors.textMain,
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _ReceiptRow(
                      label: 'Tx Signature',
                      value: item.shortSignature,
                      isCopyable: true,
                      fullValue: item.signature,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.explorerUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solana Explorer link copied!'),
                      backgroundColor: AppColors.bgCard,
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                label: const Text('Copy Solana Explorer Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _getTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.send:
        return AppColors.cyan;
      case ActivityType.receive:
        return AppColors.primary;
      case ActivityType.grant:
        return AppColors.purple;
      case ActivityType.airdrop:
        return AppColors.emerald;
      case ActivityType.securityReject:
        return AppColors.rose;
      case ActivityType.deploy:
        return AppColors.amber;
      case ActivityType.auth:
        return AppColors.primaryLight;
    }
  }

  static IconData _getTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.send:
        return Icons.arrow_upward_rounded;
      case ActivityType.receive:
        return Icons.arrow_downward_rounded;
      case ActivityType.grant:
        return Icons.verified_user_rounded;
      case ActivityType.airdrop:
        return Icons.water_drop_rounded;
      case ActivityType.securityReject:
        return Icons.shield_rounded;
      case ActivityType.deploy:
        return Icons.account_tree_rounded;
      case ActivityType.auth:
        return Icons.lock_open_rounded;
    }
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback onTap;

  const _ActivityCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = ActivityFeedView._getTypeColor(item.type);
    final icon = ActivityFeedView._getTypeIcon(item.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRejected ? AppColors.rose.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.timeFormatted} • ${item.isGasSponsored ? "0 SOL Gas" : "Standard"}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: item.isRejected
                    ? AppColors.rose.withValues(alpha: 0.15)
                    : AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.isRejected ? 'BLOCKED' : 'CONFIRMED',
                style: TextStyle(
                  color: item.isRejected ? AppColors.rose : AppColors.emerald,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isCopyable;
  final String? fullValue;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.color,
    this.isCopyable = false,
    this.fullValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: fullValue ?? value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction signature copied!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: AppColors.bgCard,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.cyan),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
