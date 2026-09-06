import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showReceiveModal(BuildContext context, SolanaService service) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ReceiveSheet(service: service),
  );
}

class _ReceiveSheet extends StatelessWidget {
  final SolanaService service;

  const _ReceiveSheet({required this.service});

  @override
  Widget build(BuildContext context) {
    final account = service.currentAccount;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Receive Assets & Identity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stylized QR Placeholder
          Center(
            child: Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 148, color: Colors.black),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Public Key Box
          _CopyCard(
            label: 'Solana Public Key',
            value: account.publicKey,
            shortValue: account.shortPublicKey,
          ),
          const SizedBox(height: 10),

          // Identity PDA Box
          _CopyCard(
            label: 'Self-Sovereign Identity PDA',
            value: account.identityPda,
            shortValue: account.shortIdentityPda,
            badge: 'PDA',
          ),
          const SizedBox(height: 16),

          // Info
          Center(
            child: Text(
              'Accepts Solana Devnet transfers, native PDA assets, and RBAC grants.',
              style: TextStyle(fontSize: 11, color: AppColors.textDim),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyCard extends StatelessWidget {
  final String label;
  final String value;
  final String shortValue;
  final String? badge;

  const _CopyCard({
    required this.label,
    required this.value,
    required this.shortValue,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(fontSize: 9, color: AppColors.primaryLight, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.mono(fontSize: 11, color: AppColors.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.cyan),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.bgCard,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
