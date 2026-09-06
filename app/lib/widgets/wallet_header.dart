import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';
import 'connect_wallet_modal.dart';

class WalletHeader extends StatelessWidget implements PreferredSizeWidget {
  final SolanaService service;

  const WalletHeader({super.key, required this.service});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final account = service.currentAccount;

    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showConnectWalletModal(context, service),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: account.avatarColor.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: account.avatarColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    account.label.isNotEmpty ? account.label[0] : 'U',
                    style: TextStyle(
                      color: account.avatarColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Account Name & Short Key
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            account.label.split('(')[0].trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textDim),
                      ],
                    ),
                    Text(
                      account.shortPublicKey,
                      style: AppTheme.mono(fontSize: 10, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Network Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Devnet',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Copy Address Button
        IconButton(
          tooltip: 'Copy Public Key',
          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textMuted),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: account.publicKey));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solana Public Key copied'),
                duration: Duration(seconds: 1),
                backgroundColor: AppColors.bgCard,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
