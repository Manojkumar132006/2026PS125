import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class WalletHeader extends StatelessWidget implements PreferredSizeWidget {
  final SolanaService service;

  const WalletHeader({super.key, required this.service});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final user = service.currentUser;
    if (user == null) return const SizedBox.shrink();

    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showUserProfileSheet(context, service),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: user.avatarColor.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: user.avatarColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : 'U',
                    style: TextStyle(
                      color: user.avatarColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name & Email/Domain
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
                            user.name,
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
                      user.email,
                      style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Network Badge
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

        // Copy Key
        IconButton(
          tooltip: 'Copy Public Key',
          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textMuted),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: user.publicKey));
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

  void _showUserProfileSheet(BuildContext context, SolanaService service) {
    final user = service.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

              // Profile Card
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: user.avatarColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: user.avatarColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : 'U',
                        style: TextStyle(color: user.avatarColor, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.providerDisplayName,
                            style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Keys Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _ProfileKeyRow(label: 'Public Key', value: user.publicKey),
                    const Divider(height: 16, color: AppColors.border),
                    _ProfileKeyRow(label: 'Identity PDA', value: user.identityPda),
                    const Divider(height: 16, color: AppColors.border),
                    _ProfileKeyRow(label: 'Role', value: '${user.role} (0x${user.permissionsMask.toRadixString(16).toUpperCase()})', isKey: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sign Out Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  service.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.rose),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose.withValues(alpha: 0.12),
                  foregroundColor: AppColors.rose,
                  minimumSize: const Size.fromHeight(46),
                  elevation: 0,
                  side: BorderSide(color: AppColors.rose.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileKeyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isKey;

  const _ProfileKeyRow({required this.label, required this.value, this.isKey = true});

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
                  isKey && value.length > 16
                      ? '${value.substring(0, 8)}...${value.substring(value.length - 8)}'
                      : value,
                  style: isKey ? AppTheme.mono(fontSize: 11, color: AppColors.textMain) : const TextStyle(fontSize: 11, color: AppColors.textMain, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isKey) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied'),
                        duration: const Duration(seconds: 1),
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
