import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

void showConnectWalletModal(BuildContext context, SolanaService service) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) => _ConnectWalletSheet(service: service),
  );
}

class _ConnectWalletSheet extends StatefulWidget {
  final SolanaService service;

  const _ConnectWalletSheet({required this.service});

  @override
  State<_ConnectWalletSheet> createState() => _ConnectWalletSheetState();
}

class _ConnectWalletSheetState extends State<_ConnectWalletSheet> {
  final TextEditingController _customNameCtrl = TextEditingController();

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.service.currentAccount;

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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solana Wallets & Personas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Switch accounts to test real-world RBAC permissions and gas sponsorship.',
            style: TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 16),

          // Account list
          ...widget.service.availableAccounts.map((acc) {
            final isSelected = acc.publicKey == current.publicKey;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  widget.service.switchAccount(acc);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: acc.avatarColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            acc.label[0],
                            style: TextStyle(color: acc.avatarColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  acc.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                if (acc.isSponsored) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '0 SOL GAS',
                                      style: TextStyle(color: AppColors.emerald, fontSize: 9, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${acc.role} • ${acc.shortPublicKey}',
                              style: AppTheme.mono(fontSize: 11, color: AppColors.textDim),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Connect Phantom / New Wallet Button
          OutlinedButton.icon(
            onPressed: () {
              widget.service.connectNewWallet('Phantom Wallet');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phantom Wallet connected on Solana Devnet'),
                  backgroundColor: AppColors.bgCard,
                ),
              );
            },
            icon: const Icon(Icons.wallet_rounded, size: 18, color: AppColors.cyan),
            label: const Text(
              'Connect Phantom Wallet / New Keypair',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.cyan),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.borderHover),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
